-- Omadjinn's keys: snap, menu, layouts and settings.
--
-- Omadjinn's service loads this file with `hyprctl eval` when the shell starts, after
-- every Hyprland config reload (a reload drops runtime binds) and when a key setting
-- changes. It first sets `omadjinn_keys` to the list to register, each entry
-- { key, command, description }. Registering again only changes what differs: a key no
-- longer in the list is unbound, and a key whose command changed is bound again.

local M = {}

function M.register(list)
  local state = _G.omadjinn_key_state or { bound = {} }
  _G.omadjinn_key_state = state

  local wanted = {}
  for _, entry in ipairs(list or {}) do
    wanted[entry[1]] = entry
  end

  for key, command in pairs(state.bound) do
    if not wanted[key] or wanted[key][2] ~= command then
      hl.unbind(key)
      state.bound[key] = nil
    end
  end

  for key, entry in pairs(wanted) do
    if not state.bound[key] then
      hl.bind(key, hl.dsp.exec_cmd("omarchy-shell omadjinn " .. entry[2]), { description = entry[3] })
      state.bound[key] = entry[2]
    end
  end
end

if hl and hl.bind then
  M.register(_G.omadjinn_keys)
end

return M
