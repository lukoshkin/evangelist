local augend = require "dial.augend"
require("dial.config").augends:register_group {
  default = {
    -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
    augend.constant.new {
      elements = { "and", "or" },
      word = true,   -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
      cyclic = true, -- "or" is incremented into "and".
    },
    augend.constant.new {
      elements = { "&&", "||" },
      word = false,
      cyclic = true,
    },
  },
}
require("dial.config").augends:register_group {
  default = {
    augend.constant.new {
      elements = { "true", "false" },
      word = true,
      cyclic = true,
    },
    augend.constant.new {
      elements = { "True", "False" },
      word = true,
      cyclic = true,
    },
  },
}
