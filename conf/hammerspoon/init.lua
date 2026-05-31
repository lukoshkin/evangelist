local hidden_desktop_apps = {}
local last_desktop_toggle_at = 0
local previous_frames = {}
local half_screen_units = {
  h = hs.layout.left50,
  j = { 0, 0.5, 1, 0.5 },
  k = { 0, 0, 1, 0.5 },
  l = hs.layout.right50
}

local function focused_window()
  local win = hs.window.focusedWindow()
  if not win or not win:isStandard() then
    return nil
  end

 return win
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

local function place_in_half(key)
  local win = focused_window()
  if not win then
    return
  end

  win:moveToUnit(half_screen_units[key])
end

local function interactive_screenshot()
 hs.task.new("/usr/sbin/screencapture", nil, { "-i", "-c" }):start()
end

local function reveal_desktop()
 local now = hs.timer.secondsSinceEpoch()
 if now - last_desktop_toggle_at < 1 then
   return
  end
  last_desktop_toggle_at = now

  if next(hidden_desktop_apps) ~= nil then
    for pid, _ in pairs(hidden_desktop_apps) do
      local app = hs.application.get(pid)
      if app then
        app:unhide()
      end
    end
    hidden_desktop_apps = {}
    return
  end

  for _, app in ipairs(hs.application.runningApplications()) do
    local bundle_id = app:bundleID()
    if bundle_id ~= "com.apple.finder"
      and bundle_id ~= "org.hammerspoon.Hammerspoon"
      and not app:isHidden()
      and app:kind() == 1 then
      hidden_desktop_apps[app:pid()] = true
      app:hide()
    end
  end
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

hs.hotkey.bind({ "cmd", "shift" }, "s", interactive_screenshot)
hs.hotkey.bind({ "cmd" }, "h", function() place_in_half("h") end)
hs.hotkey.bind({ "cmd" }, "j", function() place_in_half("j") end)
hs.hotkey.bind({ "cmd" }, "k", function() place_in_half("k") end)
hs.hotkey.bind({ "cmd" }, "l", function() place_in_half("l") end)
hs.hotkey.bind({ "cmd" }, "f", maximize_window)
hs.hotkey.bind({ "cmd" }, "b", restore_window)
hs.hotkey.bind({ "cmd", "shift" }, "h", function() move_to_screen_direction("h") end)
hs.hotkey.bind({ "cmd", "shift" }, "j", function() move_to_screen_direction("j") end)
hs.hotkey.bind({ "cmd", "shift" }, "k", function() move_to_screen_direction("k") end)
hs.hotkey.bind({ "cmd", "shift" }, "l", function() move_to_screen_direction("l") end)
hs.hotkey.bind({ "cmd" }, "d", reveal_desktop)
