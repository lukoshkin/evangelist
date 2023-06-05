local notify = require'notify'

--- Suppress error messages from lang servers.
vim.notify = function(msg, log_level, _)
  if msg:match 'exit code' then
    return
  end

  notify(msg, log_level)
end
