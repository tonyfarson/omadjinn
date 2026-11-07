-- omadjinn: drag a snapped window out and it goes back to Omarchy's default
-- floating size. Returns the function to bind to SUPER + LEFT MOUSE.
--
-- State: ~/.local/state/omadjinn/snapped, one line per snapped window,
-- written by bin/omadjinn-snap:
--   <address> <orig-w> <orig-h> <snap-x> <snap-y> <snap-w> <snap-h>
-- The row only marks the window as snapped and holds the box it was snapped to.
-- orig-w/h are no longer used (a remembered size proved brittle: Electron apps
-- reopen in their zone, so the "original" size was often the snapped size).
--
-- Off unless ~/.config/omadjinn/config.json has "dragRestore": true (read on
-- every press, no reload needed). Any error in the restore step is swallowed and
-- the press falls through to a plain drag, so the worst outcome is Omarchy's own
-- behaviour; the last error is kept in ~/.local/state/omadjinn/last-error.
--
-- Runs inside Hyprland, so it never calls hyprctl (that would block the
-- compositor on itself).

local TOL = 6        -- px: how close a window must be to its snapped box
local TITLEBAR = 40  -- px above the window that still counts as grabbing it

local state_path = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))
  .. "/omadjinn/snapped"

local function read_state()
  local rows = {}
  local f = io.open(state_path, "r")
  if not f then return rows end
  for line in f:lines() do
    local a, ow, oh, sx, sy, sw, sh =
      line:match("^(%S+) (%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+)$")
    if a then
      rows[#rows + 1] = { addr = a, ow = tonumber(ow), oh = tonumber(oh),
        sx = tonumber(sx), sy = tonumber(sy), sw = tonumber(sw), sh = tonumber(sh) }
    end
  end
  f:close()
  return rows
end

local function write_state(rows)
  local f = io.open(state_path, "w")
  if not f then return end
  for _, r in ipairs(rows) do
    f:write(string.format("%s %d %d %d %d %d %d\n", r.addr, r.ow, r.oh, r.sx, r.sy, r.sw, r.sh))
  end
  f:close()
end

local function coord(t, a, b)
  if not t then return nil end
  return t[a] or t[b]
end

-- The window the press lands on: of the floating windows on the active workspace
-- whose box (titlebar included) holds the pointer, the most recently focused one,
-- which is the one on top. Only that window may be restored; a snapped window
-- that merely sits underneath it must be left alone.
local function window_under(c)
  local active = hl.get_active_window()
  local ws = active and active.workspace and active.workspace.id or nil
  local top = nil
  for _, w in ipairs(hl.get_windows()) do
    if w.mapped and not w.hidden and w.floating and (ws == nil or w.workspace.id == ws) then
      local wx, wy = coord(w.at, "x", 1), coord(w.at, "y", 2)
      local ww, wh = coord(w.size, "x", 1), coord(w.size, "y", 2)
      if wx and c.x >= wx and c.x <= wx + ww and c.y >= wy - TITLEBAR and c.y <= wy + wh then
        if not top or w.focus_history_id < top.focus_history_id then top = w end
      end
    end
  end
  return top
end

-- The bind runs twice per click: once on press, once on release. Only the press
-- may restore a window; on the release the pointer sits wherever the window was
-- dropped, possibly over another snapped window, which must be left alone.
-- A release that never arrives is forgotten after PRESS_TIMEOUT seconds.
local PRESS_TIMEOUT = 60
local pressed_at = nil

local config_path = os.getenv("HOME") .. "/.config/omadjinn/config.json"

local function enabled()
  local f = io.open(config_path, "r")
  if not f then return false end
  local text = f:read("a") or ""
  f:close()
  return text:match('"dragRestore"%s*:%s*true') ~= nil
end

local function remember_error(err)
  local f = io.open(state_path:gsub("snapped$", "last-error"), "w")
  if f then f:write(os.date("%H:%M:%S ") .. tostring(err) .. "\n"); f:close() end
end

-- Restore the window the press lands on, if omadjinn snapped it.
local function restore(c)
  local rows = read_state()
  local top = window_under(c)

  -- Forget windows that have closed, so the file does not collect dead rows.
  local alive = {}
  for _, w in ipairs(hl.get_windows()) do alive[w.address] = true end
  local kept = {}
  for _, r in ipairs(rows) do
    if alive[r.addr] then kept[#kept + 1] = r end
  end
  if #kept ~= #rows then
    rows = kept
    write_state(rows)
  end

  for i, r in ipairs(rows) do
    for _, w in ipairs(hl.get_windows()) do
      if w.address == r.addr and w.floating then
        local wx, wy = coord(w.at, "x", 1), coord(w.at, "y", 2)
        local ww, wh = coord(w.size, "x", 1), coord(w.size, "y", 2)
        local still_snapped = wx and math.abs(wx - r.sx) <= TOL and math.abs(wy - r.sy) <= TOL
          and math.abs(ww - r.sw) <= TOL and math.abs(wh - r.sh) <= TOL
        local under_cursor = c.x >= wx and c.x <= wx + ww and c.y >= wy - TITLEBAR and c.y <= wy + wh
        if still_snapped and under_cursor and top and w.address == top.address then
          local m = w.monitor
          local mw = math.floor(m.width / m.scale)
          local mh = math.floor(m.height / m.scale)
          -- Omarchy's default floating size (default/hypr/workspace-modes.lua, place()).
          local nw, nh = math.min(1100, math.floor(mw * 0.64)), math.min(760, math.floor(mh * 0.68))
          -- Keep the cursor at the same relative spot across the window, and the
          -- same distance below its top edge (the titlebar included).
          local nx = math.floor(c.x - nw * (c.x - wx) / ww)
          local off = math.max(-30, math.min(c.y - wy, nh - 10))
          local ny = math.floor(c.y - off)
          hl.dispatch(hl.dsp.window.resize({ x = nw, y = nh, relative = false, window = w }))
          hl.dispatch(hl.dsp.window.move({ x = nx, y = ny, relative = false, window = w }))
          table.remove(rows, i)
          write_state(rows)
          return
        end
      end
    end
  end
end

-- opts (for testing): { cursor = {x=, y=}, no_drag = true }
return function(opts)
  opts = (type(opts) == "table") and opts or {}
  local testing = opts.cursor ~= nil or opts.no_drag

  if not testing then
    if pressed_at and os.time() - pressed_at < PRESS_TIMEOUT then
      pressed_at = nil           -- the release: just end the drag
      hl.dispatch(hl.dsp.window.drag())
      return
    end
    pressed_at = os.time()       -- the press: restore if wanted, then drag
  end

  local ok_on, on = pcall(enabled)
  if ok_on and on then
    local ok, err = pcall(function() restore(opts.cursor or hl.get_cursor_pos()) end)
    if not ok then pcall(remember_error, err) end
  end

  if not opts.no_drag then hl.dispatch(hl.dsp.window.drag()) end
end
