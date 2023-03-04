local keymap = require'lib.utils'.keymap
local dapui = require'dapui'
local dap = require'dap'
local fn = vim.fn


local function cpp_like_cfg (build_fn)
  local base_program = function ()
    return fn.input(
      'Path to the executable: ',
      vim.loop.cwd() .. '/', 'file')
  end

  local program = base_program
  if build_fn ~= nil and build_fn ~= '' then
    program = function ()
      fn.jobstart(build_fn)
      return base_program()
    end
  end

  local cfg = {
    type = 'lldb',
    request = 'launch',
    program = program,
    cwd = '${workspaceFolder}',
    args = {},
  }

  if io.open('/.dockerenv', 'r') then
    cfg.initCommands = { 'settings set target.disable-aslr false' }
  end

  return { cfg }
end


--- TODO: make sure codelldb is installed with mason.
local mason = fn.stdpath 'data' .. '/mason'
local lldb_ext = mason .. '/packages/codelldb/extension'
local lldb_lib = lldb_ext .. '/lldb/lib/liblldb.so'
local lldb_exe = lldb_ext .. '/adapter/codelldb'

dap.configurations.rust = cpp_like_cfg('cargo build')
dap.adapters.lldb = {
  type = 'server',
  host = '127.0.0.1',
  port = '${port}',
  executable = {
    args = { '--liblldb', lldb_lib, '--port', '${port}' },
    command = lldb_exe,
  },
}

require('dap-python').setup('python', {})
dapui.setup()

--- Toggle 'dapui' on debugging start/end.
dap.listeners.after.event_initialized['dapui_config'] = function()
  dapui.open()
end

dap.listeners.before.event_terminated['dapui_config'] = function()
  dapui.close()
end

dap.listeners.before.event_exited['dapui_config'] = function()
  dapui.close()
end

--- Not every mapping from Vimspector can migrate here.
keymap('n', '<Leader>dc', dap.continue)
keymap('n', '<Leader>dr', dap.terminate)
keymap('n', '<Leader>di', dapui.toggle)
keymap('n', '<Leader>dd', dap.pause)  -- takes thread id as argument
--- Not exactly the same as '<Plug>VimspectorRestart'
keymap('n', '<Leader>d0', dap.restart)

keymap('n', '<Space>=', dap.step_into)
keymap('n', '<Space>+', dap.step_over)
keymap('n', '<Space>-', dap.step_out)
keymap('n', '<Space><', dap.step_back)

--- No special fn for fun 'FunctionBreakpoint's.
keymap('n', '<Space>g', dap.run_to_cursor)
keymap('n', '<Space>.', dap.toggle_breakpoint)

keymap('n', '<Space>,', function ()
  dap.set_breakpoint(
    fn.input('Breakpoint condition: '),
    fn.input('Number of hits: ', 1))
end)

keymap('n', '<Space>;', function ()
  dap.set_breakpoint(nil, nil, fn.input('Log point message: '))
end)
