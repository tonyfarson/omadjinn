-- Run with: lua tests/right-click.test.lua
-- Tests the titlebar hit-testing in hypr/right-click.lua. Outside Hyprland the file
-- registers no binds, so it loads as a plain module.
local here = arg[0]:match("^(.*)/tests/[^/]*$") or "."
local M = dofile(here .. "/hypr/right-click.lua")

local function window(over)
  local w = {
    address = "0x1", mapped = true, visible = true, hidden = false, floating = true, fullscreen = 0,
    tags = { "omarchy-floating-workspace" },
    at = { x = 100, y = 200 }, size = { x = 400, y = 300 },
  }
  for k, v in pairs(over or {}) do w[k] = v end
  return w
end

local BAR = 30

-- The titlebar is the BAR pixels just above the window's top edge, across its width.
local w = window()
assert(M.over_titlebar(w, 100, 170, BAR), "top-left corner of the bar")
assert(M.over_titlebar(w, 499, 199, BAR), "bottom-right corner of the bar")
assert(not M.over_titlebar(w, 100, 169, BAR), "just above the bar")
assert(not M.over_titlebar(w, 100, 200, BAR), "the window body")
assert(not M.over_titlebar(w, 500, 185, BAR), "just right of the bar")
assert(not M.over_titlebar(w, 99, 185, BAR), "just left of the bar")

-- Only floating-workspace windows that are shown count.
assert(M.titlebar_target({ w }, 300, 185, BAR) == w)
assert(M.titlebar_target({ window({ floating = false }) }, 300, 185, BAR) == nil, "tiled")
assert(M.titlebar_target({ window({ tags = {} }) }, 300, 185, BAR) == nil, "no floating tag")
assert(M.titlebar_target({ window({ tags = { "omarchy-floating-workspace*" } }) }, 300, 185, BAR) ~= nil, "starred tag")
assert(M.titlebar_target({ window({ hidden = true }) }, 300, 185, BAR) == nil, "hidden")
assert(M.titlebar_target({ window({ visible = false }) }, 300, 185, BAR) == nil, "not visible")
assert(M.titlebar_target({ window({ mapped = false }) }, 300, 185, BAR) == nil, "not mapped")
assert(M.titlebar_target({ window({ fullscreen = 2 }) }, 300, 185, BAR) == nil, "fullscreen")

-- Hyprland lists windows bottom to top, so with overlap the last one wins.
local below, above = window({ address = "0xA" }), window({ address = "0xB", at = { x = 150, y = 200 } })
assert(M.titlebar_target({ below, above }, 300, 185, BAR) == above, "topmost wins")
assert(M.titlebar_target({ above, below }, 300, 185, BAR) == below, "order decides, not position")

-- The bar height matters: a click 20 px up is on a 30 px bar but not on a 10 px one.
assert(M.titlebar_target({ w }, 300, 180, 30) == w)
assert(M.titlebar_target({ w }, 300, 180, 10) == nil)

print("right-click.test.lua: ok")
