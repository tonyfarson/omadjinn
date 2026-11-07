-- Omadjinn: a right-click on a floating window's titlebar opens the Omadjinn menu.
--
-- Omadjinn's service loads this file with `hyprctl eval` when the shell starts and
-- after every Hyprland config reload (a reload drops runtime binds). It first sets
-- `omadjinn_menu_enabled` to true or false. Loading it again only changes what differs.
--
-- A right-press on a titlebar is kept from the app, and the menu opens on the release.
-- Every other right-press passes through untouched.

local M = {}

local FLOATING_TAG = "omarchy-floating-workspace" -- windows Omarchy's floating mode gives titlebars
local CLICK_SLOP = 4 -- px the pointer may move between press and release and still count as a click

local function has_tag(window, tag)
  for _, t in ipairs(window.tags or {}) do
    if t == tag or t == tag .. "*" then
      return true
    end
  end
  return false
end

-- The titlebar sits just above the window's reported position.
function M.over_titlebar(window, x, y, bar)
  local left, top = window.at.x, window.at.y
  return x >= left and x < left + window.size.x and y >= top - bar and y < top
end

-- The topmost floating window whose titlebar is under the point, or nil.
-- Hyprland lists windows bottom to top, so the last match is the one on top.
function M.titlebar_target(windows, x, y, bar)
  local hit
  for _, window in ipairs(windows) do
    if window.mapped and window.visible and not window.hidden
        and window.floating and window.fullscreen == 0 and has_tag(window, FLOATING_TAG)
        and M.over_titlebar(window, x, y, bar) then
      hit = window
    end
  end
  return hit
end

local function bar_height()
  local ok, value = pcall(hl.get_config, "plugin.hyprbars.bar_height")
  return (ok and tonumber(value)) or 30
end

local pressed -- the press we claimed, if any

local function on_press()
  local state = _G.omadjinn_rc or {}
  if not state.enabled then
    return { pass_event = true }
  end
  local cursor = hl.get_cursor_pos()
  local window = M.titlebar_target(hl.get_windows(), cursor.x, cursor.y, bar_height())
  pressed = window and { window = window, x = cursor.x, y = cursor.y } or nil
  return { pass_event = pressed == nil }
end

local function on_release()
  local press = pressed
  pressed = nil
  if not press then
    return
  end
  local cursor = hl.get_cursor_pos()
  if math.abs(cursor.x - press.x) > CLICK_SLOP or math.abs(cursor.y - press.y) > CLICK_SLOP then
    return
  end
  -- The address is Hyprland's hex string and the rest are whole numbers, so nothing needs quoting.
  hl.exec_cmd(string.format("omarchy-shell omadjinn menu %s %d %d",
    press.window.address, math.floor(press.x), math.floor(press.y)))
end

function M.register(enabled)
  local state = _G.omadjinn_rc or {}
  _G.omadjinn_rc = state
  state.enabled = enabled
  if not state.bound then
    hl.bind("mouse:273", on_press)
    hl.bind("mouse:273", on_release, { non_consuming = true, release = true, transparent = true, ignore_mods = true })
    state.bound = true
  end
end

if hl and hl.bind then
  M.register(_G.omadjinn_menu_enabled == true)
end

return M
