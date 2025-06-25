local format_cmds = vim.g.format_cmds
  or {
    {
      check_code = true,
      cmd = {
        "ruff",
        "format",
        "--no-preview",
        "--line-length",
        "79",
      },
    },
    {
      check_code = false,
      cmd = {
        "ruff",
        "check",
        "--fix",
        "--extend-select",
        "I",
      },
    },
  }

local list_loaded_bufs = {
  name = "list-loaded-buffers",
  description = "List all currently loaded buffers in Neovim.",
  handler = function(_, res)
    local bufs = {}
    for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if vim.uv.fs_stat(bufname) then
          table.insert(bufs, { bufnr = bufnr, name = bufname })
        end
      end
    end
    return res:text(vim.inspect(bufs)):send()
  end,
}

local format_from_cli = {
  name = "format-files-from-cli",
  description = "Format the provided file or directory"
    .. " or the files in the current folder if none is provided.",
  inputSchema = {
    type = "object",
    properties = {
      path = {
        type = "string",
        description = "Path to the file or directory to format",
      },
    },
  },
  handler = function(req, res)
    local target_path = req.params.path or ""
    if target_path ~= "" then
      if not vim.uv.fs_stat(target_path) then
        return res:error("Path not found: " .. target_path)
      end
    end

    local cmd_log = {}
    for _, cmd in pairs(format_cmds) do
      if target_path ~= "" then
        table.insert(cmd.cmd, target_path)
      end
      local obj = vim.system(cmd.cmd, { text = true }):wait()
      if cmd.check_code and obj.code ~= 0 then
        return res:error(obj.stderr or "Unknown error")
      end
      if obj.stderr then
        table.insert(cmd_log, vim.trim(obj.stderr))
      end
      if obj.stdout then
        table.insert(cmd_log, vim.trim(obj.stdout))
      end
    end
    vim.cmd "checktime" -- Update buffers modified outside Neovim
    return res:text(vim.trim(table.concat(cmd_log, "\n"))):send()
  end,
}

local format_buffer_in_neovim = {
  name = "format-neovim-buffer",
  description = "Format the specified buffer using the Neovim API."
    .. " Works for any loaded buffer based on the attached formatters",
  inputSchema = {
    type = "object",
    properties = {
      bufnr = {
        type = "integer",
        description = "Buffer number to format, defaults to the current one"
          .. " if the only file modified with the assistant",
      },
    },
  },
  handler = function(req, res)
    local bufnr = req.params.bufnr or 1
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      return res:error("Invalid buffer number: " .. tostring(bufnr))
    end
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    require("conform").format {
      bufnr = bufnr,
      lsp_fallback = true,
      async = false,
      timeout = 500,
    }
    return res:text("Buffer " .. bufname .. " formatted successfully."):send()
  end,
}

return {
  "ravitemer/mcphub.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  --- May require manual installation with "sudo"
  build = "npm install -g mcp-hub@latest",
  opts = {
    native_servers = {
      formatters = {
        name = "formatters",
        displayName = "Formatters",
        capabilities = {
          tools = {
            list_loaded_bufs,
            format_from_cli,
            format_buffer_in_neovim,
          },
        },
        custom_instructions = {
          text = "Format files taking into account the user preferences.\n"
            .. "Use these tools when dealing with indentation issues,"
            .. " fixing text overflow errors from linters, or whitespace"
            .. " trimming is needed. It is much more efficient than manual"
            .. " line splitting or trimming.\n"
            .. "  - `list-loaded-buffers` is used to list all currently"
            .. " loaded buffers in Neovim. Helps to find out which buffers"
            .. " to format. Because likely the current buffer will be a chat"
            .. " with the assistant or the dashboard, thus, no need to format"
            .. " it.\n"
            .. "  - `format-files-from-cli` is used to format multiple"
            .. " files at once by specifying the path to either a folder with"
            .. " files or a certain file. When no path is provided, the CWD"
            .. " path is used.\n"
            .. "  - `format-neovim-buffer` is used to format a specific"
            .. " buffer. This tool can only format a loaded buffer. To"
            .. " ensure the right buffer is to be formatted, use"
            .. " `list-loaded-buffers` tool first.\n",
        },
      },
    },
  },
}
