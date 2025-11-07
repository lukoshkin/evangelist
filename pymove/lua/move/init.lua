local config = require "move.config"
local parser = require "move.parser"
local sorter = require "move.sorter"

local M = {}

---Sort methods within a class at cursor
function M.sort_class()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if buffer is Python
  if vim.bo[bufnr].filetype ~= "python" then
    vim.notify("Not a Python file", vim.log.levels.WARN)
    return
  end

  -- Find class at cursor
  local class_node = parser.get_class_node(bufnr)
  if not class_node then
    vim.notify("No class found at cursor", vim.log.levels.WARN)
    return
  end

  -- Parse methods
  local methods = parser.parse_class_methods(class_node, bufnr)
  if #methods == 0 then
    vim.notify("No methods found in class", vim.log.levels.INFO)
    return
  end

  -- Sort methods (no dependency sort for class methods)
  local sorted = sorter.sort_functions(methods, false)

  -- Apply changes
  sorter.apply_sort(bufnr, sorted)
end

---Sort functions/methods in visual selection
function M.sort_visual()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "python" then
    vim.notify("Not a Python file", vim.log.levels.WARN)
    return
  end

  -- Get current visual selection range
  local start_pos = vim.fn.getpos "v"
  local end_pos = vim.fn.getpos "."
  local start_line = start_pos[2]
  local end_line = end_pos[2]

  -- Ensure start_line <= end_line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Convert to 0-indexed
  local start_row = start_line - 1
  local end_row = end_line - 1
  print(start_row, end_row)

  -- Try to find a class in the selection
  local functions
  local class_node = parser.get_class_node(bufnr, start_row, end_row)
  if class_node then
    -- Sort methods within the selected class
    vim.notify "Class node"
    local all_methods = parser.parse_class_methods(class_node, bufnr)

    -- Filter methods to only those within the visual selection
    functions = {}
    for _, method in ipairs(all_methods) do
      if method.start_row >= start_row and method.end_row <= end_row then
        table.insert(functions, method)
      end
    end
  else
    -- Parse module-level functions in the selection
    local root = parser.get_root_node(bufnr)
    if not root then
      return
    end

    local all_funcs = parser.parse_module_functions(root, bufnr)

    -- Filter functions within selection
    functions = {}
    for _, func in ipairs(all_funcs) do
      if func.start_row >= start_row and func.end_row <= end_row then
        table.insert(functions, func)
      end
    end
  end

  if #functions == 0 then
    vim.notify("No functions/methods found in selection", vim.log.levels.INFO)
    return
  end

  -- Sort with dependency analysis if module-level functions
  -- Use config option for lexicographic sorting in visual selections
  local use_deps = config.options.enable_dependency_sort and not class_node
  local sorted = sorter.sort_functions(
    functions,
    use_deps,
    config.options.visual_selection_lexsort
  )

  -- Apply changes
  sorter.apply_sort(bufnr, sorted)
end

---Sort all functions and methods in the file
function M.sort_file()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if buffer is Python
  if vim.bo[bufnr].filetype ~= "python" then
    vim.notify("Not a Python file", vim.log.levels.WARN)
    return
  end

  local root = parser.get_root_node(bufnr)
  if not root then
    return
  end

  -- PHASE 1: Sort module-level objects (functions, classes, constants)
  local module_objects = parser.parse_module_objects(root, bufnr)
  local module_sorted = false

  if #module_objects > 0 then
    local sorted_objects = sorter.sort_module_objects(module_objects)

    -- Check if order actually changed
    local order_changed = false
    for i, obj in ipairs(sorted_objects) do
      if obj.name ~= module_objects[i].name then
        order_changed = true
        break
      end
    end

    if order_changed then
      sorter.apply_module_sort(bufnr, sorted_objects)
      module_sorted = true

      -- Re-parse after module-level changes
      root = parser.get_root_node(bufnr)
      if not root then
        return
      end
    end
  end

  -- PHASE 2: Sort methods within each class
  local sorted_class_names = {}
  local classes_sorted = 0
  local query = vim.treesitter.query.parse(
    "python",
    [[
    (class_definition) @class
    ]]
  )

  -- Keep sorting classes until we've sorted them all
  while true do
    local found_unsorted = false

    for pattern, match, _ in query:iter_matches(root, bufnr) do
      for id, nodes in pairs(match) do
        for _, class_node in ipairs(nodes) do
          -- Get class name
          local name_fields = class_node:field "name"
          if name_fields and #name_fields > 0 then
            local class_name = vim.treesitter.get_node_text(name_fields[1], bufnr)

            -- Skip if already sorted
            if not sorted_class_names[class_name] then
              local methods = parser.parse_class_methods(class_node, bufnr)
              sorted_class_names[class_name] = true -- Mark as processed

              if #methods > 0 then
                local sorted = sorter.sort_functions(methods, false)
                sorter.apply_sort(bufnr, sorted)
                classes_sorted = classes_sorted + 1
                found_unsorted = true

                -- Re-parse after modification
                root = parser.get_root_node(bufnr)
                if not root then
                  return
                end

                break -- Start over with fresh parse
              end
            end
          end
        end
        if found_unsorted then
          break
        end
      end
      if found_unsorted then
        break
      end
    end

    if not found_unsorted then
      break -- No more classes to sort
    end
  end

  if #module_objects == 0 and classes_sorted == 0 then
    vim.notify("No functions or classes found", vim.log.levels.INFO)
  elseif not module_sorted and classes_sorted == 0 then
    vim.notify("Nothing to sort (already in order)", vim.log.levels.INFO)
  end
end

---Generic sort function with scope parameter
---@param scope string "visual"|"class"|"file"
function M.sort_python(scope)
  if scope == "visual" then
    M.sort_visual()
  elseif scope == "class" then
    M.sort_class()
  elseif scope == "file" then
    M.sort_file()
  else
    vim.notify(
      "Invalid scope: " .. scope .. '. Use "visual", "class", or "file"',
      vim.log.levels.ERROR
    )
  end
end

---Setup function called by lazy.nvim
---@param opts MoveConfig?
function M.setup(opts)
  config.setup(opts)

  -- Load commands if not already loaded
  require "move.commands"
end

return M
