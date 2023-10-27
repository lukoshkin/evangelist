local Hydra = require('hydra')

Hydra({
  name = 'diff mode (forward)',
  mode = 'n',
  body = ']',
  heads = {
    { 'c', ']c' },
    { 'p', 'dp' },
    { 'o', 'do' },
  }
})
Hydra({
  name = 'diff mode (backward)',
  mode = 'n',
  body = '[',
  heads = {
    { 'c', '[c' },
    { 'p', 'dp' },
    { 'o', 'do' },
  }
})
