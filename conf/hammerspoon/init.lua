local terminal_bundle_ids = {
  ["net.kovidgoyal.kitty"] = true,
  ["com.apple.Terminal"] = true,
  ["com.googlecode.iterm2"] = true
}

local directional_keys = {
  [hs.keycodes.map.b] = "b",
  [hs.keycodes.map.f] = "f",
  [hs.keycodes.map.h] = "h",
  [hs.keycodes.map.j] = "j",
  [hs.keycodes.map.k] = "k",
  [hs.keycodes.map.l] = "l",
  [hs.keycodes.map.s] = "s"
}

local half_screen_units = {
  h = hs.layout.left50,
  j = { 0, 0.5, 1, 0.5 },
  k = { 0, 0, 1, 0.5 },
  l = hs.layout.right50
}

local screenshot_dir = os.getenv "HOME" .. "/Desktop"
local previous_frames = {}

local function frontmost_bundle_id()
  local app = hs.application.frontmostApplication()
  return app and app:bundleID() or nil
end

local function in_terminal_app()
  local bundle_id = frontmost_bundle_id()
  return bundle_id ~= nil and terminal_bundle_ids[bundle_id] == true
end

local function flags_match(flags, expected)
  local modifiers = { "cmd", "shift", "alt", "ctrl", "fn" }

  for _, modifier in ipairs(modifiers) do
    if (flags[modifier] or false) ~= (expected[modifier] or false) then
      return false
    end
  end

  return true
end

local function focused_window()
  local win = hs.window.focusedWindow()
  if not win or not win:isStandard() then
    return nil
  end

  return win
end

local function place_in_half(key)
  local win = focused_window()
  if not win then
    return
  end

  win:moveToUnit(half_screen_units[key])
end

local function move_to_screen_direction(key)
  local win = focused_window()
  if not win then
    return
  end

  if key == "h" then
    win:moveOneScreenWest()
  elseif key == "j" then
    win:moveOneScreenSouth()
  elseif key == "k" then
    win:moveOneScreenNorth()
  elseif key == "l" then
    win:moveOneScreenEast()
  end
end

local function interactive_screenshot()
  local file_name = ("Screenshot_%s.png"):format(os.date "%Y-%m-%d_%H-%M-%S")
  hs.task.new("/usr/sbin/screencapture", nil, { "-i", screenshot_dir .. "/" .. file_name }):start()
end

local function frames_match(frame_a, frame_b)
  local tolerance = 2

  return math.abs(frame_a.x - frame_b.x) <= tolerance
    and math.abs(frame_a.y - frame_b.y) <= tolerance
    and math.abs(frame_a.w - frame_b.w) <= tolerance
    and math.abs(frame_a.h - frame_b.h) <= tolerance
end

local function maximize_window()
  local win = focused_window()
  if not win then
    return
  end

  local window_id = win:id()
  if not window_id then
    return
  end

  local current_frame = win:frame()
  local target_frame = win:screen():frame()
  if frames_match(current_frame, target_frame) then
    return
  end

  previous_frames[window_id] = current_frame
  win:setFrame(target_frame)
end

local function restore_window()
  local win = focused_window()
  if not win then
    return
  end

  local window_id = win:id()
  if not window_id then
    return
  end

  local previous_frame = previous_frames[window_id]
  if not previous_frame then
    return
  end

  win:setFrame(previous_frame)
  previous_frames[window_id] = nil
end

local function handle_hotkey(key, flags)
  if flags_match(flags, { cmd = true }) then
    if half_screen_units[key] then
      place_in_half(key)
      return true
    end

    if key == "f" then
      maximize_window()
      return true
    end

    if key == "b" then
      restore_window()
      return true
    end
  end

  if flags_match(flags, { cmd = true, shift = true }) then
    if key == "s" then
      interactive_screenshot()
      return true
    end

    if half_screen_units[key] then
      move_to_screen_direction(key)
      return true
    end
  end

  return false
end

local hotkey_tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local key = directional_keys[event:getKeyCode()]
  if not key then
    return false
  end

  local flags = event:getFlags()

  if flags_match(flags, { cmd = true, shift = true }) then
    return handle_hotkey(key, flags)
  end

  if flags_match(flags, { cmd = true }) and (key == "f" or key == "b") then
    return handle_hotkey(key, flags)
  end

  if in_terminal_app() then
    return false
  end

  return handle_hotkey(key, flags)
end)

hotkey_tap:start()
