local db = require('dashboard')

db.custom_header = {
'                                                            ',
'                                                            ',
'⣿⣿⣷⡀     ⣿                                 ⣿⡇               ',
'⣿⡇⢻⣿⡀    ⣿                                                  ',
'⣿⣧ ⠻⣿⡀   ⣿    ⣴⣿⠿⠿⣿⣦⡀   ⣠⣶⣿⣿⣷⣤⡀ ⠈⣿⣆    ⣾⡿  ⣿   ⢸⣿⣤⣾⣿⣷⣄⣠⣶⣿⣿⣦⡀',
'⣿⣿  ⠹⣿⡀  ⣿   ⣿⡟    ⢿⣧  ⣾⣿⠁   ⢻⣿⡀ ⠹⣿⡀  ⢰⣿   ⣿   ⢸⣿⠋  ⠘⣿⡟   ⣿⣇',
'⣿⣿   ⠹⣿⡄ ⣿   ⣿⠿⠿⠿⠿⠿⠿⠿  ⣿⠃     ⣿⡇  ⢿⣷⡀ ⣿⠃   ⣿   ⢸⣿    ⣿    ⣿⣿',
'⣿⣿    ⠙⣿⡄⣿   ⣿⣆        ⣿⡆    ⢀⣿⠇   ⣿⡆⣼⡟    ⣿   ⢸⣿    ⣿    ⣿⣿',
'⣿⣿     ⠘⣿⣿   ⠙⣿⣶⣄⣀⣠⣾⠟  ⠙⣿⣦⣀⣀⣤⣿⠟    ⠘⣿⣿     ⣿   ⢸⣿    ⣿    ⣿⣿',
'⠛⠋      ⠈⠛     ⠉⠛⠛⠋      ⠉⠛⠛⠋       ⠛⠃     ⠉   ⠈⠉    ⠉    ⠉⠉',
'                                                            ',
'                                                            ',
}


db.custom_center = {
  { icon = '  ',
    --- More whitespace chars since
    desc = ' New File                                  ',
    --- the line doesn't include a shortcut.
    action = 'DashboardNewFile' },
  { icon = '  ',
    desc = ' Find File                              ',
    shortcut = '\\ff',
    action = 'Telescope find_files' },
  { icon = '  ',
    desc = ' Recent Files                           ',
    shortcut = '\\fo',
    action = 'Telescope oldfiles' },
  { icon = '  ',
    desc = ' Find Word                              ',
    shortcut = '\\fg',
    action = 'Telescope live_grep' },
  { icon = '  ',
    desc = ' Find Project                           ',
    shortcut = '\\fp',
    action = 'Telescope projects' },
  { icon = ' ﴚ ',
    desc = ' Quit                                   ',
    shortcut = ' ZZ' ,
    action = ':q' },
}


db.custom_footer = {
  '',
  '',
  '',
  [[ ,---,---,---,---,---,---,---,---,---,---,---,---,---,-------, ]],
  [[ | ~ | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | [ | ] | <-    | ]],
  [[ |---'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-----| ]],
  [[ | ->| | " | , | . | π | η | φ | ψ | ξ | ρ | μ | / | = |  \  | ]],
  [[ |-----',--',--',--',--',--',--',--',--',--',--',--',--'-----| ]],
  [[ | Caps | ϊ | ο | ; | υ | ω | δ | θ | ζ | ν | ϋ | - |  Enter | ]],
  [[ |------'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'-,-'--------| ]],
  [[ | Shift  | 🅔 | 🅥 | 🅐 | 🅝 | 🅖 | 🅔 | 🅛 | 🅘 | 🅢 | 🅣 |    Shift | ]],
  [[ |------,-',--'--,'---'---'---'---'---'---'-,-'---',--,------| ]],
  [[ | Ctrl |  | Alt |                          | Alt  |  | Ctrl | ]],
  [[ '------'  '-----'--------------------------'------'  '------' ]],
}
