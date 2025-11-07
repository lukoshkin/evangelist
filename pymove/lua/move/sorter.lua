local config = require "move.config"

local M = {}

---Categorize a function/method name
---@param name string
---@return string Category: "dunder", "public", or "private"
local function categorize(name)
  if name:match "^__.*__$" then
    return "dunder"
  elseif name:match "^_" then
    return "private"
  else
    return "public"
  end
end

---Check if a method should be preserved at the top
---@param name string
---@return boolean
local function should_preserve(name)
  for _, preserved in ipairs(config.options.preserve_methods) do
    if name == preserved then
      return true
    end
  end
  return false
end

---Topological sort using Kahn's algorithm
---@param functions FunctionInfo[]
---@return FunctionInfo[]
local function topological_sort(functions)
  -- Build name to function map
  local func_map = {}
  for _, func in ipairs(functions) do
    func_map[func.name] = func
  end

  -- Build adjacency list and in-degree count
  local adj = {} -- adjacency list: func -> list of funcs that depend on it
  local in_degree = {} -- number of dependencies for each func

  for _, func in ipairs(functions) do
    adj[func.name] = {}
    in_degree[func.name] = 0
  end

  -- Build graph: if A calls B, then B -> A (B must come before A)
  for _, func in ipairs(functions) do
    for _, called in ipairs(func.calls) do
      if func_map[called] then
        -- 'called' is a function in our list
        table.insert(adj[called], func.name)
        in_degree[func.name] = in_degree[func.name] + 1
      end
    end
  end

  -- Find all nodes with in-degree 0
  local queue = {}
  for _, func in ipairs(functions) do
    if in_degree[func.name] == 0 then
      table.insert(queue, func.name)
    end
  end

  -- Sort alphabetically for deterministic order
  table.sort(queue)

  local sorted = {}
  while #queue > 0 do
    local current = table.remove(queue, 1)
    table.insert(sorted, func_map[current])

    -- Reduce in-degree for neighbors
    local neighbors = adj[current]
    table.sort(neighbors)
    for _, neighbor in ipairs(neighbors) do
      in_degree[neighbor] = in_degree[neighbor] - 1
      if in_degree[neighbor] == 0 then
        table.insert(queue, neighbor)
        -- Keep queue sorted
        table.sort(queue)
      end
    end
  end

  -- If we couldn't sort all functions, there's a cycle
  -- In this case, append the remaining functions
  if #sorted < #functions then
    local sorted_names = {}
    for _, func in ipairs(sorted) do
      sorted_names[func.name] = true
    end

    for _, func in ipairs(functions) do
      if not sorted_names[func.name] then
        table.insert(sorted, func)
      end
    end
  end

  return sorted
end

---Sort functions/methods by category and name
---@param functions FunctionInfo[]
---@param use_dependency_sort boolean
---@param sort_within_categories boolean? Optional override for lexicographic sorting
---@return FunctionInfo[]
function M.sort_functions(
  functions,
  use_dependency_sort,
  sort_within_categories
)
  if #functions == 0 then
    return {}
  end

  -- Use provided parameter or fall back to config
  if sort_within_categories == nil then
    sort_within_categories = config.options.sort_within_categories
  end

  -- Separate preserved methods
  local preserved = {}
  local to_sort = {}

  for _, func in ipairs(functions) do
    if should_preserve(func.name) then
      table.insert(preserved, func)
    else
      table.insert(to_sort, func)
    end
  end

  -- If dependency sorting is enabled and we're sorting module functions
  if use_dependency_sort then
    to_sort = topological_sort(to_sort)
  end

  -- Group by category
  local categories = {
    dunder = {},
    public = {},
    private = {},
  }

  for _, func in ipairs(to_sort) do
    local cat = categorize(func.name)
    table.insert(categories[cat], func)
  end

  -- Sort within categories if enabled
  if sort_within_categories then
    for _, funcs in pairs(categories) do
      table.sort(funcs, function(a, b)
        return a.name < b.name
      end)
    end
  end

  -- Combine in order: preserved, then categories
  local result = {}
  for _, func in ipairs(preserved) do
    table.insert(result, func)
  end

  for _, category in ipairs(config.options.categories) do
    for _, func in ipairs(categories[category]) do
      table.insert(result, func)
    end
  end

  return result
end

---Apply sorted functions to buffer
---@param bufnr integer
---@param functions FunctionInfo[]
function M.apply_sort(bufnr, functions)
  if #functions == 0 then
    return
  end

  -- Get the range to replace (find actual min/max positions)
  local start_row = math.huge
  local end_row = -1

  for _, func in ipairs(functions) do
    start_row = math.min(start_row, func.start_row)
    end_row = math.max(end_row, func.end_row)
  end

  -- Build new text
  local new_lines = {}
  for i, func in ipairs(functions) do
    -- Add function text
    for _, line in ipairs(func.text) do
      table.insert(new_lines, line)
    end

    -- Add blank line between functions (except after last)
    if i < #functions then
      table.insert(new_lines, "")
    end
  end

  -- Replace the range
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, new_lines)

  vim.notify(
    string.format("Sorted %d functions/methods", #functions),
    vim.log.levels.INFO
  )
end

---Topological sort for module objects using dependencies
---@param objects ModuleObject[]
---@return ModuleObject[]
local function topological_sort_objects(objects)
  -- Build name to object map
  local obj_map = {}
  for _, obj in ipairs(objects) do
    obj_map[obj.name] = obj
  end

  -- Build adjacency list and in-degree count
  local adj = {} -- adjacency list: obj -> list of objs that depend on it
  local in_degree = {} -- number of dependencies for each obj

  for _, obj in ipairs(objects) do
    adj[obj.name] = {}
    in_degree[obj.name] = 0
  end

  -- Build graph: if A depends on B, then B -> A (B must come before A)
  for _, obj in ipairs(objects) do
    for _, dep in ipairs(obj.dependencies) do
      if obj_map[dep] then
        -- 'dep' is an object in our list
        table.insert(adj[dep], obj.name)
        in_degree[obj.name] = in_degree[obj.name] + 1
      end
    end
  end

  -- Find all nodes with in-degree 0
  local queue = {}
  for _, obj in ipairs(objects) do
    if in_degree[obj.name] == 0 then
      table.insert(queue, obj.name)
    end
  end

  -- Sort alphabetically for deterministic order
  table.sort(queue)

  local sorted = {}
  while #queue > 0 do
    local current = table.remove(queue, 1)
    table.insert(sorted, obj_map[current])

    -- Reduce in-degree for neighbors
    local neighbors = adj[current]
    table.sort(neighbors)
    for _, neighbor in ipairs(neighbors) do
      in_degree[neighbor] = in_degree[neighbor] - 1
      if in_degree[neighbor] == 0 then
        table.insert(queue, neighbor)
        -- Keep queue sorted
        table.sort(queue)
      end
    end
  end

  -- If we couldn't sort all objects, there's a cycle
  -- In this case, append the remaining objects
  if #sorted < #objects then
    local sorted_names = {}
    for _, obj in ipairs(sorted) do
      sorted_names[obj.name] = true
    end

    for _, obj in ipairs(objects) do
      if not sorted_names[obj.name] then
        table.insert(sorted, obj)
      end
    end
  end

  return sorted
end

---Check if a category should be sorted
---@param category string
---@param module_categories string[]
---@return boolean
local function is_sortable_category(category, module_categories)
  if not module_categories or #module_categories == 0 then
    return false
  end

  for _, cat in ipairs(module_categories) do
    if cat == category then
      return true
    end
  end
  return false
end

---Sort module-level objects with category preservation and type ordering
---Dependencies ALWAYS override category ordering to prevent breaking code
---@param objects ModuleObject[]
---@return ModuleObject[]
function M.sort_module_objects(objects)
  if #objects == 0 then
    return {}
  end

  local module_categories = config.options.module_categories
  if not module_categories or #module_categories == 0 then
    -- Module sorting disabled
    return objects
  end

  local put_funcs_before_classes = config.options.put_functions_before_classes

  -- Separate objects into sortable and anchored (preserved in place)
  local sortable = {}
  local anchored = {}

  for i, obj in ipairs(objects) do
    if is_sortable_category(obj.category, module_categories) then
      table.insert(sortable, { obj = obj, original_index = i })
    else
      table.insert(anchored, { obj = obj, original_index = i })
    end
  end

  -- Extract just the objects for sorting
  local sortable_objs = {}
  for _, item in ipairs(sortable) do
    table.insert(sortable_objs, item.obj)
  end

  -- STEP 1: Apply topological sort (respects dependencies)
  -- This gives us a valid order where all dependencies are satisfied
  -- For Option 1 (dependencies always take precedence), this is our final order
  sortable_objs = topological_sort_objects(sortable_objs)

  -- Merge sorted and anchored objects
  local result = {}
  local sorted_idx = 1
  local anchored_idx = 1

  for i = 1, #objects do
    -- Check if current position should be an anchored object
    local should_anchor = anchored_idx <= #anchored
      and anchored[anchored_idx].original_index == i

    if should_anchor then
      table.insert(result, anchored[anchored_idx].obj)
      anchored_idx = anchored_idx + 1
    elseif sorted_idx <= #sortable_objs then
      table.insert(result, sortable_objs[sorted_idx])
      sorted_idx = sorted_idx + 1
    end
  end

  -- Add any remaining sorted objects
  while sorted_idx <= #sortable_objs do
    table.insert(result, sortable_objs[sorted_idx])
    sorted_idx = sorted_idx + 1
  end

  return result
end

---Apply sorted module objects to buffer
---@param bufnr integer
---@param objects ModuleObject[]
function M.apply_module_sort(bufnr, objects)
  if #objects == 0 then
    return
  end

  -- Get the range to replace
  local start_row = math.huge
  local end_row = -1

  for _, obj in ipairs(objects) do
    start_row = math.min(start_row, obj.start_row)
    end_row = math.max(end_row, obj.end_row)
  end

  -- Build new text
  local new_lines = {}
  for i, obj in ipairs(objects) do
    -- Add object text
    for _, line in ipairs(obj.text) do
      table.insert(new_lines, line)
    end

    -- Add blank line between objects (except after last)
    if i < #objects then
      table.insert(new_lines, "")
    end
  end

  -- Replace the range
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, new_lines)

  vim.notify(
    string.format(
      "Sorted %d module-level objects (functions, classes, constants)",
      #objects
    ),
    vim.log.levels.INFO
  )
end

return M
