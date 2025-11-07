# move.nvim

A Neovim plugin for intelligently sorting Python functions and class methods.

## Features

- **Smart categorization**: Sorts methods by dunder/magic → public → private
- **Preserve special methods**: Keeps `__init__`, `__new__`, etc. at the top
- **Dependency-aware**: Uses topological sorting for module-level functions
- **Multiple scopes**: Sort visual selection, current class, or entire file
- **Treesitter-powered**: Fast and accurate Python parsing
- **Configurable**: Customize sorting rules via `opts`

## Requirements

- Neovim 0.11+
- Python treesitter parser: `:TSInstall python`

## Installation

### lazy.nvim

```lua
{
  dir = "~/.config/evangelist",
  name = "move.nvim",
  ft = "python",
  opts = {
    -- Optional: customize configuration
    preserve_methods = { "__init__", "__new__", "__str__", "__repr__" },
    categories = { "dunder", "public", "private" },
    sort_within_categories = true,
    enable_dependency_sort = true,
    default_keymaps = true,
  },
}
```

## Usage

### Commands

- `:PySortClass` - Sort methods in the class at cursor
- `:PySortFile` - Sort all functions and methods in the file
- `:PySortMethods [scope]` - Sort with scope: `visual`, `class`, or `file`

### Default Keymaps

- `<leader>sm` - Sort methods in current class
- `<leader>sf` - Sort all functions/methods in file
- `<leader>sv` - Sort functions/methods in visual selection (visual mode)

### Lua API

```lua
local move = require("move")

-- Sort current class
move.sort_class()

-- Sort entire file
move.sort_file()

-- Sort visual selection (call after visual selection)
move.sort_visual()

-- Generic function with scope
move.sort_python("class")  -- "visual" | "class" | "file"
```

## Configuration

### Default Configuration

```lua
{
  -- Methods that should always stay at the top
  preserve_methods = { "__init__", "__new__", "__str__", "__repr__" },

  -- Order of categories for sorting
  categories = { "dunder", "public", "private" },

  -- Sort alphabetically within each category
  sort_within_categories = true,

  -- Enable topological sorting for module-level functions
  -- (respects dependencies between functions)
  enable_dependency_sort = true,

  -- Enable default keymaps
  default_keymaps = true,
}
```

### Custom Keymaps

Disable default keymaps and set your own:

```lua
{
  dir = "~/.config/evangelist",
  name = "move.nvim",
  ft = "python",
  opts = {
    default_keymaps = false,
  },
  keys = {
    { "<leader>ps", function() require("move").sort_class() end,
      desc = "Sort Python class methods" },
    { "<leader>pf", function() require("move").sort_file() end,
      desc = "Sort Python file" },
    { "<leader>pv", function() require("move").sort_visual() end,
      mode = "v", desc = "Sort Python selection" },
  },
}
```

## How It Works

### Method Categorization

Methods are categorized into three groups:

1. **Dunder methods** (`__method__`): Magic methods like `__init__`, `__str__`
2. **Public methods** (`method`): Regular methods without underscore prefix
3. **Private methods** (`_method`): Methods starting with underscore

### Preserved Methods

Certain methods are kept at the top in their original order:

- `__init__`
- `__new__`
- `__str__`
- `__repr__`

### Dependency Sorting

For module-level functions, the plugin analyzes function calls and uses
topological sorting to ensure dependencies are defined before use:

```python
# Before
def caller():
    helper()

def helper():
    pass

# After (dependency-aware)
def helper():
    pass

def caller():
    helper()
```

### Example

**Before:**

```python
class MyClass:
    def _private_helper(self):
        pass

    def __str__(self):
        return "MyClass"

    def public_method(self):
        pass

    def __init__(self):
        pass

    def another_public(self):
        pass
```

**After:**

```python
class MyClass:
    def __init__(self):
        pass

    def __str__(self):
        return "MyClass"

    def another_public(self):
        pass

    def public_method(self):
        pass

    def _private_helper(self):
        pass
```

## License

MIT
