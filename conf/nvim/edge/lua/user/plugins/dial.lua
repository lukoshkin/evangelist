local augend = require "dial.augend"
require("dial.config").augends:register_group {
  default = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias["%Y/%m/%d"],
    -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
    augend.constant.new {
      elements = { "and", "or" },
      word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
      cyclic = true, -- "or" is incremented into "and".
    },
    augend.constant.new {
      elements = { "&&", "||" },
      word = false,
      cyclic = true,
    },
    augend.constant.new {
      elements = { "true", "false" },
      word = false,
      cyclic = true,
    },
    augend.constant.new {
      elements = { "True", "False" },
      word = false,
      cyclic = true,
    },
    augend.constant.new {
      elements = { "import", "from" },
      word = true,
      cyclic = true,
    },
  },
  typescript = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.constant.new{ elements = {"let", "const"} },
  },
}
