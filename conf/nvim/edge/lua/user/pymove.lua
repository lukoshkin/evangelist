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

  local parser = vim.treesitter.get_parser(bufnr, "python")
  local tree = parser:parse()[1]
  local root = tree:root()
  local query = [[
    (import_from_statement
      module_name: (dotted_name) @module_name)
    (import_statement
      (dotted_name) @module_name)
  ]]
  local query_obj = vim.treesitter.query.parse("python", query)
  local changes = {}
  for _, match in query_obj:iter_matches(root, bufnr) do
    for _, node in pairs(match) do
      local name = vim.treesitter.get_node_text(node, bufnr)
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

  api.nvim_buf_call(bufnr, function()
    vim.cmd "write!"
  end)
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

function M.move_module_or_package(old_name, new_name, project_root)
  project_root = project_root or fn.getcwd()
  local old_dotted = path_to_dotted_name(old_name)
  local new_dotted = path_to_dotted_name(new_name)
  local change = estimate_change(old_dotted, new_dotted)
  local pattern = file_change_pattern(change)
  local files = find_files_with_pattern(pattern, project_root, "*.py")
  for _, file in ipairs(files) do
    update_imports(file, old_dotted, new_dotted)
  end
end

return M
