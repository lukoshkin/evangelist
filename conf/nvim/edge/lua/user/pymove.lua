local api = vim.api
local fn = vim.fn
local M = {}

local Path = require "plenary.path"
log = require("plenary.log").new {
  plugin = "py-imports-refactor",
  use_console = true,
}

local function split_python_import_path(dotted_name)
  local components = {}
  local leading_dots = dotted_name:match "^[%.]+"
  if leading_dots then
    table.insert(components, leading_dots)
  end
  for component in dotted_name:gmatch "([^%.]+)" do
    table.insert(components, component)
  end
  return components
end

function estimate_change(old_dotted, new_dotted)
  local old_table = split_python_import_path(old_dotted)
  local new_table = split_python_import_path(new_dotted)
  local changes = {}
  local new_set = {}

  for _, value in ipairs(new_table) do
    new_set[value] = true
  end

  for _, value in ipairs(old_table) do
    if not new_set[value] then
      table.insert(changes, value)
    end
  end

  if #changes == 0 then
    return old_table
  end

  return changes
end

local function file_change_pattern(change)
  change = table.concat(change, ".*")
  return "import.*" .. change .. "|" .. change .. ".*import"
end

local function path_to_dotted_name(input)
  local chopped = input:gsub("%.py$", "")
  if
    chopped:find "\\"
    or input:find "/" and chopped:find "%."
    or chopped:find "%." and chopped:find "-"
  then
    error "The broken Python's import path!"
  end

  if string.find(chopped, "/") then
    chopped = chopped:gsub("-", "_")
    local chopped = chopped:gsub("/", ".")
    return chopped
  else
    return input
  end
end

local function absolute_dotted_path(rel_path, rel_dotted_path)
  local suffix = rel_dotted_path:gsub("^%.+", "")
  local parent_lvl = rel_dotted_path:len() - suffix:len()
  if parent_lvl == 0 then
    parent_lvl = 1
  end

  local parents = Path:new(rel_path):parents()
  local prefix = parents[parent_lvl]
  local _, max_lvl = rel_path:gsub("/", "")
  max_lvl = max_lvl + 1
  if parent_lvl > max_lvl then
    error "The rel_dotted_path leads outside of the project!"
  end
  local _prefix = parents[max_lvl]
  prefix = Path:new(prefix):make_relative(_prefix)
  return path_to_dotted_name(prefix) .. "." .. suffix
end

local function update_imports(
  file,
  old_dotted_name,
  new_dotted_name,
  project_root
)
  local bufnr = fn.bufadd(file)
  fn.bufload(bufnr)

  -- Add error handling for treesitter parsing
  local success, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
  if not success then
    log.warn("Failed to get parser for file: " .. file)
    return
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    log.warn("Failed to parse file: " .. file)
    return
  end

  local tree = trees[1]
  local root = tree:root()
  local query = [[
    (import_from_statement
      module_name: (dotted_name) @module_name)
    (import_statement
      (dotted_name) @module_name)
  ]]
  local query_obj = vim.treesitter.query.parse("python", query)
  local changes = {}

  -- Use iter_captures to properly handle capture groups
  for id, node, metadata in query_obj:iter_captures(root, bufnr) do
    if node then
      local capture_name = query_obj.captures[id]
      if capture_name == "module_name" then
        local success, name = pcall(vim.treesitter.get_node_text, node, bufnr)
        if not success then
          log.warn("Failed to get node text: " .. tostring(name))
          goto continue
        end

        if name:find "^%." then
          local rel_path = Path:new(file):make_relative(project_root)
          name = absolute_dotted_path(rel_path, name)
        end

        if name:find("^" .. old_dotted_name) then
          local new_import = name:gsub("^" .. old_dotted_name, new_dotted_name)
          table.insert(
            changes,
            { node = node, old_import = name, new_import = new_import }
          )
        end
        ::continue::
      end
    end
  end

  for _, change in ipairs(changes) do
    local start_row, start_col, end_row, end_col = change.node:range()
    api.nvim_buf_set_text(
      bufnr,
      start_row,
      start_col,
      end_row,
      end_col,
      { change.new_import }
    )
  end

  -- Only write and format if there were changes
  if #changes > 0 then
    api.nvim_buf_call(bufnr, function()
      vim.cmd "write!"
      -- Check if conform is available before using it
      local success, conform = pcall(require, "conform")
      if success then
        conform.format()
      end
    end)
  end
end

local function find_files_with_pattern(pattern, directory, extension)
  local results = {}
  local rg_cmd = string.format(
    "rg --files-with-matches --no-messages -g '%s' -e '%s' %s",
    extension,
    pattern,
    directory
  )
  local grep_cmd = string.format(
    "grep -rlE --include '%s' '%s' %s",
    extension,
    pattern,
    directory
  )

  local function run_command(cmd)
    local output = fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 then
      return nil, output
    end
    return output
  end

  local output, err = run_command(rg_cmd)
  if not output then
    output, err = run_command(grep_cmd)
    if not output then
      log.debug("Error running command: ", err)
      return results
    end
  end

  for _, file in ipairs(output) do
    table.insert(results, file)
  end

  return results
end

local function validate_move_possible(old_path, new_path)
  local old_full_path = Path:new(old_path)
  local new_full_path = Path:new(new_path)

  if not old_full_path:exists() then
    return false, "Source path does not exist: " .. tostring(old_full_path)
  end

  if new_full_path:exists() then
    return false,
      "Destination path already exists: " .. tostring(new_full_path)
  end

  if old_full_path:is_file() and not old_path:match "%.py$" then
    return false, "Source file is not a Python file: " .. old_path
  end

  if old_full_path:is_dir() then
    local init_file = old_full_path / "__init__.py"
    if not init_file:exists() then
      log.warn(
        "Source directory is not a Python package (no __init__.py): "
          .. old_path
      )
    end
  end

  return true, nil
end

local function create_parent_dirs(file_path)
  local path = Path:new(file_path)
  local parent = path:parent()

  if not parent:exists() then
    local success, err = parent:mkdir { parents = true }
    if not success then
      return false, "Failed to create parent directories: " .. tostring(err)
    end
    log.info("Created parent directories: " .. tostring(parent))
  end

  return true, nil
end

local function move_file_or_directory(old_path, new_path, use_git)
  local old_full_path = Path:new(old_path):absolute()
  local new_full_path = Path:new(new_path):absolute()

  -- Create parent directories for destination
  local success, err = create_parent_dirs(new_path)
  if not success then
    return false, err
  end

  if use_git then
    -- Try git mv first
    local git_cmd = string.format("git mv '%s' '%s'", old_path, new_path)
    local output = fn.system(git_cmd)
    if vim.v.shell_error == 0 then
      log.info(
        "Successfully moved using git: " .. old_path .. " -> " .. new_path
      )
      return true, nil
    else
      log.warn("Git mv failed, falling back to filesystem move: " .. output)
    end
  end

  -- Fallback to filesystem move
  local success, err = pcall(function()
    old_full_path:rename { new_name = tostring(new_full_path) }
  end)

  if success then
    log.info("Successfully moved: " .. old_path .. " -> " .. new_path)
    return true, nil
  else
    return false, "Failed to move file/directory: " .. tostring(err)
  end
end

local function is_git_repo(project_root)
  local git_dir = Path:new(project_root) / ".git"
  return git_dir:exists()
end

function M.move_module_or_package(old_name, new_name, project_root, options)
  options = options or {}
  local dry_run = options.dry_run or false
  local use_git = options.use_git

  project_root = project_root or fn.getcwd()

  -- Auto-detect git if not specified
  if use_git == nil then
    use_git = is_git_repo(project_root)
  end

  log.info(
    string.format(
      "Moving Python module/package: %s -> %s (dry_run: %s, use_git: %s)",
      old_name,
      new_name,
      tostring(dry_run),
      tostring(use_git)
    )
  )

  -- Convert to absolute paths within project
  local old_path = Path:new(project_root) / old_name
  local new_path = Path:new(project_root) / new_name

  -- Validate the move is possible
  local valid, err =
    validate_move_possible(tostring(old_path), tostring(new_path))
  if not valid then
    log.error("Cannot move module/package: " .. err)
    return false, err
  end

  local old_dotted = path_to_dotted_name(old_name)
  local new_dotted = path_to_dotted_name(new_name)
  local change = estimate_change(old_dotted, new_dotted)
  local pattern = file_change_pattern(change)
  local files = find_files_with_pattern(pattern, project_root, "*.py")

  if dry_run then
    log.info "DRY RUN - Would perform the following actions:"
    log.info(
      "  1. Move: " .. tostring(old_path) .. " -> " .. tostring(new_path)
    )
    log.info("  2. Update imports in " .. #files .. " files:")
    for _, file in ipairs(files) do
      log.info("     - " .. file)
    end
    log.info("  3. Import changes: " .. old_dotted .. " -> " .. new_dotted)
    return true, "Dry run completed successfully"
  end

  -- Step 1: Move the actual file/directory
  local move_success, move_err =
    move_file_or_directory(tostring(old_path), tostring(new_path), use_git)
  if not move_success then
    log.error("Failed to move file/directory: " .. move_err)
    return false, move_err
  end

  -- Step 2: Update imports in all affected files
  local updated_files = 0
  for _, file in ipairs(files) do
    local before_update = fn.getftime(file)
    update_imports(file, old_dotted, new_dotted, project_root)
    local after_update = fn.getftime(file)

    if after_update > before_update then
      updated_files = updated_files + 1
    end
  end

  log.info(
    string.format(
      "Successfully moved module/package and updated imports in %d files",
      updated_files
    )
  )
  return true,
    string.format(
      "Moved %s -> %s and updated %d files",
      old_name,
      new_name,
      updated_files
    )
end

-- Convenience function for dry run
function M.preview_move(old_name, new_name, project_root)
  return M.move_module_or_package(
    old_name,
    new_name,
    project_root,
    { dry_run = true }
  )
end

-- Example usage functions that you can call from command line
function M.move_with_ui()
  local old_name = fn.input "Source module/package path: "
  if old_name == "" then
    return
  end

  local new_name = fn.input "Destination module/package path: "
  if new_name == "" then
    return
  end

  local preview = fn.input "Preview changes first? (y/N): "
  if preview:lower() == "y" or preview:lower() == "yes" then
    local success, result = M.preview_move(old_name, new_name)
    if success then
      local confirm = fn.input "Proceed with the move? (y/N): "
      if confirm:lower() == "y" or confirm:lower() == "yes" then
        M.move_module_or_package(old_name, new_name)
      end
    else
      log.error("Preview failed: " .. result)
    end
  else
    M.move_module_or_package(old_name, new_name)
  end
end

function M.setup()
  api.nvim_create_user_command("PyMove", function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    if #args < 2 then
      log.error "Usage: :PyMove <old_path> <new_path> [options]"
      return
    end

    local old_name, new_name = args[1], args[2]
    local options = {}

    for i = 3, #args do
      if args[i] == "--dry-run" then
        options.dry_run = true
      elseif args[i] == "--no-git" then
        options.use_git = false
      elseif args[i] == "--git" then
        options.use_git = true
      end
    end

    M.move_module_or_package(old_name, new_name, nil, options)
  end, {
    nargs = "*",
    desc = "Move Python module/package and update imports (old_path -> new_path)",
    complete = function(arglead, cmdline, curpos)
      -- Could add file completion here
      return {}
    end,
  })

  api.nvim_create_user_command("PyMovePreview", function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    if #args < 2 then
      log.error "Usage: :PyMovePreview <old_path> <new_path>"
      return
    end
    M.preview_move(args[1], args[2])
  end, {
    nargs = "*",
    desc = "Preview Python module/package move without executing",
  })

  api.nvim_create_user_command("PyMoveUI", function()
    M.move_with_ui()
  end, {
    desc = "Interactive Python module/package move",
  })
end

return M
