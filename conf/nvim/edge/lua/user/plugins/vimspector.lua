local keymap = require'lib.utils'.keymap
local api = vim.api
local fn = vim.fn

--- BP & BPCond & BPDisabled (green bullet) priorities are increased
--- to 200 to ensure their visibility.
vim.g.vimspector_sign_priority = {
  vimspectorBP                 = 200,
  vimspectorBPCond             = 200,
  vimspectorBPLog              = 200,
  vimspectorBPDisabled         = 200,
  vimspectorPC                 = 201,
  vimspectorPCBP               = 201,
  vimspectorCurrentThread      = 201,
  vimspectorCurrentFrame       = 201,
}
--- 'singcolumn' is wide enough to fit both a bp and the dbg cursor.
--- Having two circles near to each other is vague; thus, it is better
--- to change the default 'vimspectorPCBP' sign.
vim.cmd [[ sign define vimspectorPCBP text=➲ ]]

-- vim.cmd [[ sign define vimspectorPCBP text= ]]


local dap_caller = {}
local default_config = {
  python = {
    attach = {
      adapter = 'debugpy',
      configuration = {
        request = 'launch',
        program = '${file}',
        stopOnEntry = true,
      },
      breakpoints = {
        exception = {
          raised = '',
          uncaught = 'Y',
          --- It will still ask about "User Uncaught Exceptions".
        }
      }
    }
  },
  rust = {
    launch = {
      hint = '/target/debug/',
      adapter = 'CodeLLDB',
      configuration = {
        request = 'launch',
        --- This adapter is not able to parse StopAtEntry properly.
        -- stopAtEntry = true,
      },
      breakpoints = {
        exception = {
          cpp_throw = '',
          cpp_catch = ''
        }
      }
    }
  }
}

default_config.cpp = vim.deepcopy(default_config.rust)
default_config.cpp.launch.hint = nil
default_config.rust.launch.build = { 'cargo', 'build' }


local function vimspector_reset ()
  if dap_caller['buf'] == nil then
    return
  end

  --- Save terminal window id for later use.
  local twid
  if vim.g.vimspector_session_windows ~= nil then
    twid = vim.g.vimspector_session_windows.terminal
    vim.cmd ':call vimspector#Reset()'
  end

  --- Cleaning.
  dap_caller['tab'] = nil
  dap_caller['buf'] = nil

  if twid ~= nil then
    --- Delete terminal buf if it was open.
    api.nvim_buf_delete(fn.winbufnr(twid), {force=true})
  end
end


local function vimspector_continue ()
  local bnr = api.nvim_buf_get_number(0)
  local tnr = api.nvim_tabpage_get_number(0)

  if tnr == dap_caller['tab'] or bnr == dap_caller['buf'] then
    vim.cmd ':call vimspector#Continue()'
    return
  end

  if dap_caller['buf'] ~= nil then
    vim.notify(
      ' Vimspector: Several debug instances are not supported!\n' ..
      ' Close the first instance before opening a new one.')
    return
  end

  local ft = api.nvim_buf_get_option(0, 'filetype')
  if default_config[ft] == nil then
    vim.notify("No default config for '"
      .. ft .."' file", vim.log.levels.WARN)
    return
  end

  dap_caller['buf'] = bnr
  local query, cfg = next(default_config[ft])
  cfg = vim.deepcopy(cfg)

  if cfg.build ~= nil and cfg.build ~= '' then
    fn.jobstart(cfg.build)
  end

  if cfg.configuration.program == nil then
    local hint = vim.loop.cwd() .. (cfg.hint or '/')
    local name = fn.input('Path to the executable: ', hint, 'file')

    if name == '' then
      vim.notify(' Vimspector: Aborted!')
      vimspector_reset()
      return
    end

    cfg.configuration.program = name
    cfg.hint = nil
  end

  local ft_cfg = {}
  ft_cfg[query] = cfg
  vim.g.dap_cfg = ft_cfg
  --- At the time, this crutch (use of an intermediate buf variable `vim.g`)
  --- is the only possible conversion to a Vim dict. Vimspector's Python
  --- code does not take into account conversion from Lua table.
  fn['vimspector#LaunchWithConfigurations'](vim.g.dap_cfg)
  dap_caller['tab'] = vim.g.vimspector_session_windows.tabpage
end


keymap('n', '<Leader>dc', vimspector_continue)
keymap('n', '<Leader>dr', vimspector_reset)

keymap('n', '<Leader>ds', '<Plug>VimspectorStop')
keymap('n', '<Leader>dd', '<Plug>VimspectorPause')
keymap('n', '<Leader>d0', '<Plug>VimspectorRestart')

keymap('n', '<Space>=', '<Plug>VimspectorStepInto')
keymap('n', '<Space>+', '<Plug>VimspectorStepOver')
keymap('n', '<Space>-', '<Plug>VimspectorStepOut')

keymap('n', '<Space>g', '<Plug>VimspectorRunToCursor')
keymap('n', '<Space>.', '<Plug>VimspectorToggleBreakpoint')
keymap('n', '<Space>,', '<Plug>VimspectorToggleConditionalBreakpoint')
keymap('n', '<Space>:', '<Plug>VimspectorAddFunctionBreakpoint')

keymap('n', '<Space>db', '<Plug>VimspectorBreakpoints')
keymap('n', '<Space>dd', function ()
  if fn.win_getid() ~= vim.g.vimspector_session_windows.code then
    api.nvim_set_current_win(vim.g.vimspector_session_windows.code)
    return
  end

  fn['vimspector#GoToCurrentLine']()
end)
keymap('n', '<Space>dv', function ()
  fn.win_gotoid(vim.g.vimspector_session_windows.variables)
end)
keymap('n', '<Space>dw', function ()
  fn.win_gotoid(vim.g.vimspector_session_windows.watches)
end)
keymap('n', '<Space>do', function ()
  fn.win_gotoid(vim.g.vimspector_session_windows.output)
end)
keymap('n', '<Space>dt', function ()
  fn.win_gotoid(vim.g.vimspector_session_windows.terminal)
end)
keymap('n', '<Space>ds', function ()
  fn.win_gotoid(vim.g.vimspector_session_windows.stack_trace)
end)
