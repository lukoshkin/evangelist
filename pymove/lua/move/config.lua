---@class MoveConfig
---@field preserve_methods string[] Methods to keep at top (e.g., __init__)
---@field categories string[] Order of method categories
---@field sort_within_categories boolean Sort alphabetically within each category
---@field visual_selection_lexsort boolean Always use lexsort for visual selections
---@field enable_dependency_sort boolean Use topological sort for module functions
---@field module_categories string[]|nil Module-level categories (nil/empty disables module sorting)
---@field put_functions_before_classes boolean|nil Order functions before classes (nil = preserve original order)
---@field default_keymaps boolean Enable default keymaps

local M = {}

---@type MoveConfig
M.defaults = {
  -- Methods that should always stay at the top in their original order
  preserve_methods = { "__init__", "__new__", "__str__", "__repr__" },

  -- Order of categories for sorting (first to last)
  categories = { "dunder", "public", "private" },

  -- Sort alphabetically within each category
  sort_within_categories = false,

  -- Always use lexicographic sorting for visual selections
  visual_selection_lexsort = true,

  -- Enable topological sorting for module-level functions
  -- (respects dependencies between functions)
  enable_dependency_sort = true,

  -- Module-level sorting categories
  -- Categories: "constants" (module-level assignments), "public" (no underscore),
  --            "utility" (single underscore), "private" (double underscore)
  -- Set to nil or {} to disable module-level sorting
  module_categories = { "constants", "public", "utility" },

  -- Order functions before classes at module level
  -- true: functions always before classes
  -- false: classes always before functions
  -- nil: preserve original function/class order (only sort by category)
  put_functions_before_classes = nil,

  -- Enable default keymaps
  default_keymaps = true,
}

---@type MoveConfig
M.options = {}

---Merge user options with defaults
---@param opts MoveConfig?
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
