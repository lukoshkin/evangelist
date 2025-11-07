local M = {}

---@class FunctionInfo
---@field name string Function/method name
---@field node TSNode Treesitter node
---@field start_row integer Start line (0-indexed)
---@field end_row integer End line (0-indexed)
---@field decorators string[] List of decorator names
---@field calls string[] Functions called within this function
---@field text string[] Full text of the function

---@class ModuleObject
---@field name string Object name (function/class/constant)
---@field type string Object type: "function", "class", "constant"
---@field node TSNode Treesitter node
---@field start_row integer Start line (0-indexed)
---@field end_row integer End line (0-indexed)
---@field text string[] Full text of the object
---@field dependencies string[] Names of objects this depends on
---@field category string Category: "constants", "public", "utility", "private"

---Get Python parser for the buffer
---@param bufnr integer
---@return LanguageTree?
local function get_python_parser(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
  if not ok then
    vim.notify("Python treesitter parser not found", vim.log.levels.ERROR)
    return nil
  end
  return parser
end

---Extract decorator names from a function definition
---@param func_node TSNode
---@return string[]
local function get_decorators(func_node)
  local decorators = {}
  local parent = func_node:parent()

  -- Check if parent is decorated_definition
  if parent and parent:type() == "decorated_definition" then
    for child in parent:iter_children() do
      if child:type() == "decorator" then
        -- Get the decorator name (identifier after @)
        for deco_child in child:iter_children() do
          if
            deco_child:type() == "identifier"
            or deco_child:type() == "attribute"
          then
            local text = vim.treesitter.get_node_text(deco_child, 0)
            table.insert(decorators, text)
            break
          end
        end
      end
    end
  end

  return decorators
end

---Find all function calls within a function body
---@param func_node TSNode
---@param bufnr integer
---@return string[]
local function get_function_calls(func_node, bufnr)
  local calls = {}
  local seen = {}

  -- Query for call expressions
  local query = vim.treesitter.query.parse(
    "python",
    [[
    (call
      function: (identifier) @func_name)
    ]]
  )

  for pattern, match, _ in query:iter_matches(func_node, bufnr) do
    -- match is a table: capture_id -> array of nodes
    for id, nodes in pairs(match) do
      for _, node in ipairs(nodes) do
        local name = vim.treesitter.get_node_text(node, bufnr)
        if name and not seen[name] then
          seen[name] = true
          table.insert(calls, name)
        end
      end
    end
  end

  return calls
end

---Extract function information from a function_definition node
---@param func_node TSNode
---@param bufnr integer
---@return FunctionInfo?
local function extract_function_info(func_node, bufnr)
  if not func_node then
    return nil
  end

  -- Get function name using named child by field
  local name_fields = func_node:field "name"
  if not name_fields or #name_fields == 0 then
    return nil
  end

  local name_node = name_fields[1]
  local name = vim.treesitter.get_node_text(name_node, bufnr)
  local start_row, _, end_row, _ = func_node:range()

  -- Check if this is part of a decorated definition
  local parent = func_node:parent()
  local actual_node = func_node
  if parent and parent:type() == "decorated_definition" then
    actual_node = parent
    start_row, _, end_row, _ = parent:range()
  end

  -- Get function text
  local text = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

  return {
    name = name,
    node = actual_node,
    start_row = start_row,
    end_row = end_row,
    decorators = get_decorators(func_node),
    calls = get_function_calls(func_node, bufnr),
    text = text,
  }
end

---Parse functions at a specific tree level
---@param root TSNode Root node to search within
---@param bufnr integer Buffer number
---@return FunctionInfo[]
function M.parse_functions(root, bufnr)
  local functions = {}

  -- Query for function definitions
  local query = vim.treesitter.query.parse(
    "python",
    [[
    (function_definition) @func
    ]]
  )

  for pattern, match, _ in query:iter_matches(root, bufnr) do
    -- match is a table: capture_id -> array of nodes
    for id, nodes in pairs(match) do
      for _, node in ipairs(nodes) do
        local func_info = extract_function_info(node, bufnr)
        if func_info then
          table.insert(functions, func_info)
        end
      end
    end
  end

  return functions
end

---Get class node at cursor or within range
---@param bufnr integer
---@param start_row integer?
---@param end_row integer?
---@return TSNode?
function M.get_class_node(bufnr, start_row, end_row)
  local parser = get_python_parser(bufnr)
  if not parser then
    return nil
  end

  parser:parse()
  local tree = parser:trees()[1]
  local root = tree:root()

  if start_row and end_row then
    -- Find class within range
    local query = vim.treesitter.query.parse(
      "python",
      [[
      (class_definition) @class
      ]]
    )

    for pattern, match, _ in query:iter_matches(root, bufnr) do
      -- match is a table: capture_id -> array of nodes
      for id, nodes in pairs(match) do
        for _, node in ipairs(nodes) do
          local s_row, _, e_row, _ = node:range()
          -- Check if the class contains the selection
          if s_row <= start_row and e_row >= end_row then
            return node
          end
        end
      end
    end
  else
    -- Find class at cursor
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1 -- Convert to 0-indexed

    local node = vim.treesitter.get_node { bufnr = bufnr, pos = { row, 0 } }
    if not node then
      return nil
    end

    -- Walk up the tree to find class_definition
    while node do
      if node:type() == "class_definition" then
        return node
      end
      node = node:parent()
    end
  end

  return nil
end

---Get all top-level nodes (functions and classes)
---@param bufnr integer
---@return TSNode?
function M.get_root_node(bufnr)
  local parser = get_python_parser(bufnr)
  if not parser then
    return nil
  end

  parser:parse()
  local tree = parser:trees()[1]
  return tree:root()
end

---Parse methods within a class
---@param class_node TSNode
---@param bufnr integer
---@return FunctionInfo[]
function M.parse_class_methods(class_node, bufnr)
  -- Validate class_node is not nil
  if not class_node then
    return {}
  end

  -- Find the class body
  local body_fields = class_node:field "body"
  if not body_fields or #body_fields == 0 then
    return {}
  end

  local body_node = body_fields[1]

  local methods = {}

  -- Iterate through direct children of the class body
  for child in body_node:iter_children() do
    if child:type() == "function_definition" then
      local method_info = extract_function_info(child, bufnr)
      if method_info then
        table.insert(methods, method_info)
      end
    elseif child:type() == "decorated_definition" then
      -- Handle decorated methods
      for deco_child in child:iter_children() do
        if deco_child:type() == "function_definition" then
          local method_info = extract_function_info(deco_child, bufnr)
          if method_info then
            table.insert(methods, method_info)
          end
          break
        end
      end
    end
  end

  return methods
end

---Get module-level functions (excluding those inside classes)
---@param root TSNode
---@param bufnr integer
---@return FunctionInfo[]
function M.parse_module_functions(root, bufnr)
  local functions = {}

  -- Only get direct children that are functions
  for child in root:iter_children() do
    if child:type() == "function_definition" then
      local func_info = extract_function_info(child, bufnr)
      if func_info then
        table.insert(functions, func_info)
      end
    elseif child:type() == "decorated_definition" then
      -- Handle decorated functions
      for deco_child in child:iter_children() do
        if deco_child:type() == "function_definition" then
          local func_info = extract_function_info(deco_child, bufnr)
          if func_info then
            table.insert(functions, func_info)
          end
          break
        end
      end
    end
  end

  return functions
end

---Extract all identifiers from a node (for dependency detection)
---@param node TSNode
---@param bufnr integer
---@return string[]
local function extract_identifiers(node, bufnr)
  local identifiers = {}
  local seen = {}

  local query = vim.treesitter.query.parse(
    "python",
    [[
    (identifier) @id
    ]]
  )

  for pattern, match, _ in query:iter_matches(node, bufnr) do
    for id, nodes in pairs(match) do
      for _, id_node in ipairs(nodes) do
        local name = vim.treesitter.get_node_text(id_node, bufnr)
        if name and not seen[name] then
          seen[name] = true
          table.insert(identifiers, name)
        end
      end
    end
  end

  return identifiers
end

---Get comprehensive dependencies for a function or class
---Detects: inheritance, decorators, type hints, default arguments, function calls
---@param node TSNode Function or class node
---@param bufnr integer
---@return string[]
local function get_comprehensive_dependencies(node, bufnr)
  local deps = {}
  local seen = {}

  local function add_dep(name)
    if name and not seen[name] then
      seen[name] = true
      table.insert(deps, name)
    end
  end

  -- 1. Decorators
  local parent = node:parent()
  if parent and parent:type() == "decorated_definition" then
    for child in parent:iter_children() do
      if child:type() == "decorator" then
        for deco_child in child:iter_children() do
          if
            deco_child:type() == "identifier"
            or deco_child:type() == "attribute"
          then
            add_dep(vim.treesitter.get_node_text(deco_child, bufnr))
            break
          end
        end
      end
    end
  end

  -- 2. Inheritance (for classes)
  if node:type() == "class_definition" then
    local arg_list_fields = node:field "superclasses"
    if arg_list_fields and #arg_list_fields > 0 then
      for _, base in ipairs(extract_identifiers(arg_list_fields[1], bufnr)) do
        add_dep(base)
      end
    end

    -- Also check type hints in class methods
    local body_fields = node:field "body"
    if body_fields and #body_fields > 0 then
      local body_node = body_fields[1]

      -- Find all function definitions in class body
      for method in body_node:iter_children() do
        local method_node = method
        if method:type() == "decorated_definition" then
          for deco_child in method:iter_children() do
            if deco_child:type() == "function_definition" then
              method_node = deco_child
              break
            end
          end
        end

        if method_node:type() == "function_definition" then
          -- Check type hints in method parameters
          local params_fields = method_node:field "parameters"
          if params_fields and #params_fields > 0 then
            local params_node = params_fields[1]

            local type_query = vim.treesitter.query.parse(
              "python",
              [[
              (type) @type_annotation
              ]]
            )

            for pattern, match, _ in
              type_query:iter_matches(params_node, bufnr)
            do
              for id, nodes in pairs(match) do
                for _, type_node in ipairs(nodes) do
                  for _, name in ipairs(extract_identifiers(type_node, bufnr)) do
                    add_dep(name)
                  end
                end
              end
            end

            -- Check default values in method parameters
            local default_query = vim.treesitter.query.parse(
              "python",
              [[
              (default_parameter
                value: (_) @default_value)
              (typed_default_parameter
                value: (_) @default_value)
              ]]
            )

            for pattern, match, _ in
              default_query:iter_matches(params_node, bufnr)
            do
              for id, nodes in pairs(match) do
                for _, default_node in ipairs(nodes) do
                  for _, name in
                    ipairs(extract_identifiers(default_node, bufnr))
                  do
                    add_dep(name)
                  end
                end
              end
            end
          end

          -- Check return type hints
          local return_type_fields = method_node:field "return_type"
          if return_type_fields and #return_type_fields > 0 then
            for _, name in
              ipairs(extract_identifiers(return_type_fields[1], bufnr))
            do
              add_dep(name)
            end
          end
        end
      end
    end
  end

  -- 3. Type hints in function parameters
  if node:type() == "function_definition" then
    local params_fields = node:field "parameters"
    if params_fields and #params_fields > 0 then
      local params_node = params_fields[1]

      -- Query for type annotations
      local type_query = vim.treesitter.query.parse(
        "python",
        [[
        (type) @type_annotation
        ]]
      )

      for pattern, match, _ in type_query:iter_matches(params_node, bufnr) do
        for id, nodes in pairs(match) do
          for _, type_node in ipairs(nodes) do
            for _, name in ipairs(extract_identifiers(type_node, bufnr)) do
              add_dep(name)
            end
          end
        end
      end

      -- Query for default values
      local default_query = vim.treesitter.query.parse(
        "python",
        [[
        (default_parameter
          value: (_) @default_value)
        (typed_default_parameter
          value: (_) @default_value)
        ]]
      )

      for pattern, match, _ in
        default_query:iter_matches(params_node, bufnr)
      do
        for id, nodes in pairs(match) do
          for _, default_node in ipairs(nodes) do
            for _, name in ipairs(extract_identifiers(default_node, bufnr)) do
              add_dep(name)
            end
          end
        end
      end
    end

    -- 4. Return type annotation
    local return_type_fields = node:field "return_type"
    if return_type_fields and #return_type_fields > 0 then
      for _, name in
        ipairs(extract_identifiers(return_type_fields[1], bufnr))
      do
        add_dep(name)
      end
    end
  end

  -- 5. Function calls in body
  local calls = get_function_calls(node, bufnr)
  for _, call in ipairs(calls) do
    add_dep(call)
  end

  -- 6. Any other references in the node body
  -- This catches class instantiations, attribute access, etc.
  local body_fields = node:field "body"
  if body_fields and #body_fields > 0 then
    local body_node = body_fields[1]

    -- Look for identifiers that might be class references
    local ref_query = vim.treesitter.query.parse(
      "python",
      [[
      (call
        function: (identifier) @class_ref)
      (call
        function: (attribute
          object: (identifier) @obj_ref))
      ]]
    )

    for pattern, match, _ in ref_query:iter_matches(body_node, bufnr) do
      for id, nodes in pairs(match) do
        for _, ref_node in ipairs(nodes) do
          add_dep(vim.treesitter.get_node_text(ref_node, bufnr))
        end
      end
    end
  end

  return deps
end

---Categorize a module-level object by name
---@param name string
---@return string Category: "constants", "public", "utility", "private"
local function categorize_module_object(name)
  if name:match "^__" then
    return "private"
  elseif name:match "^_" then
    return "utility"
  elseif name:match "^[A-Z_][A-Z0-9_]*$" then
    -- ALL_CAPS names are typically constants
    return "constants"
  else
    return "public"
  end
end

---Parse all module-level objects (functions, classes, constants)
---@param root TSNode
---@param bufnr integer
---@return ModuleObject[]
function M.parse_module_objects(root, bufnr)
  local objects = {}

  for child in root:iter_children() do
    local obj = nil
    local actual_node = child

    -- Handle decorated definitions
    if child:type() == "decorated_definition" then
      for deco_child in child:iter_children() do
        if
          deco_child:type() == "function_definition"
          or deco_child:type() == "class_definition"
        then
          child = deco_child
          break
        end
      end
    end

    if child:type() == "function_definition" then
      local name_fields = child:field "name"
      if name_fields and #name_fields > 0 then
        local name = vim.treesitter.get_node_text(name_fields[1], bufnr)
        local start_row, _, end_row, _ = actual_node:range()
        local text =
          vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

        obj = {
          name = name,
          type = "function",
          node = actual_node,
          start_row = start_row,
          end_row = end_row,
          text = text,
          dependencies = get_comprehensive_dependencies(child, bufnr),
          category = categorize_module_object(name),
        }
      end
    elseif child:type() == "class_definition" then
      local name_fields = child:field "name"
      if name_fields and #name_fields > 0 then
        local name = vim.treesitter.get_node_text(name_fields[1], bufnr)
        local start_row, _, end_row, _ = actual_node:range()
        local text =
          vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

        obj = {
          name = name,
          type = "class",
          node = actual_node,
          start_row = start_row,
          end_row = end_row,
          text = text,
          dependencies = get_comprehensive_dependencies(child, bufnr),
          category = categorize_module_object(name),
        }
      end
    elseif
      child:type() == "expression_statement"
      or child:type() == "assignment"
    then
      -- Detect constants (module-level assignments)
      -- Look for simple assignments like: CONSTANT = value
      local assign_node = child
      if child:type() == "expression_statement" then
        for expr_child in child:iter_children() do
          if expr_child:type() == "assignment" then
            assign_node = expr_child
            break
          end
        end
      end

      if assign_node:type() == "assignment" then
        local left_fields = assign_node:field "left"
        if left_fields and #left_fields > 0 then
          local left_node = left_fields[1]
          if left_node:type() == "identifier" then
            local name = vim.treesitter.get_node_text(left_node, bufnr)
            -- Only consider it a constant if it matches naming pattern
            if name:match "^[A-Z_][A-Z0-9_]*$" or name:match "^_" then
              local start_row, _, end_row, _ = actual_node:range()
              local text =
                vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

              -- Get dependencies from the right side of assignment
              local right_fields = assign_node:field "right"
              local deps = {}
              if right_fields and #right_fields > 0 then
                deps = extract_identifiers(right_fields[1], bufnr)
              end

              obj = {
                name = name,
                type = "constant",
                node = actual_node,
                start_row = start_row,
                end_row = end_row,
                text = text,
                dependencies = deps,
                category = categorize_module_object(name),
              }
            end
          end
        end
      end
    end

    if obj then
      table.insert(objects, obj)
    end
  end

  return objects
end

return M
