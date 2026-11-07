# Requirements (R) and features (F)

Ideas go here unless Tony says "let's do this now".

## R (core)
- R1 Layouts: halves, quadrants, comms (1/3 + 2/3), 1/4 + 1/2 + 1/4, and custom ones from a file. Each layout has a user-editable `name` and an `icon` (Nerd Font glyph) in `layouts/default.json`; the toast shows both. Done.
- R2 A key cycles layouts; an `omarchy osd` toast names the active one. Done.
- R6 Default keys (Tony, this build): snap = ALT+arrows (4 directions); cycle layouts = SUPER+ALT+LEFT/RIGHT. Overwrites stock SUPER+ALT+arrows (move window to group) and steals ALT+arrows from apps (browser back/forward etc). Done.
- R7 Users can change every keybind in the plugin settings, and assign a unique bind to each custom layout. Risk: a plugin can't edit Hyprland config, so settings need a way to generate/apply the binds (stage 2 question).
- R8 Dragging a snapped window out with SUPER+LEFT MOUSE resizes it to Omarchy's default floating size (about 64% x 68% of the screen, capped at 1100 x 760). Changed 2026-11-06 (Tony): the first version restored the pre-snap size, which proved brittle (Electron apps reopen in their zone, so the "original" size was often the snapped size). `lua/drag.lua`; the rows in `~/.local/state/omadjinn/snapped` now only mark a window as snapped. Same titlebar limit as R11.
- R11 Dragging a snapped window out restores its size however it is grabbed, including by its titlebar. Today `SUPER + LEFT MOUSE` restores only when the press reaches our bind; a press with the pointer on the titlebar does not (Tony, 2026-11-06). Until fixed, the README says to grab the window body. Not started; check whether the titlebar plugin offers a hook.
- R9 Optional behaviours are switches in `~/.config/omadjinn/config.json`, read at run time (no reload). All off by default. Stage 2 puts a settings page on the same file.

- R10 Stage 2: package omadjinn as an Omarchy shell plugin with a settings page. It is the home for R7 (keybinds, per-layout binds), R9 (feature switches), layout editing (names, icons, zones) and F2-F4. Open: what a third-party plugin may store, show and run (see docs/plugin-notes.md once read).

- R12 Layout creator/editor (Tony, 2026-11-06; Phase 2 step 3): users make their own layouts in the settings window. A layout is a set of vertical and horizontal split lines; the cells they cut are the zones (saved as fractions, as now). Lines are dragged, added and removed in a graphical preview, or set by typing a percentage or pixel position, and the preview follows the numbers. Edge-to-edge lines cannot make L-shaped zones; free-form zones are a later option.
- R13 The editor preview looks exactly like the layout image in the cycle toast, so the picture drawn in the editor can be saved and used as that layout's toast image (Tony, 2026-11-06). Open: how the OSD takes a custom image (today `omarchy osd -i` takes an icon name or glyph); check before promising.

## F (optional features, each a switch, all off by default)
- `dragRestore` (R8) is a switch too: off by default, on in Tony's config. Safety net: any error in the restore falls through to a plain drag (`last-error` file).
- F2 `swap`: snapping into an occupied zone swaps the two windows. (Was R3. By hand it already works: focus a window, ALT+arrow it, then move the other.)
- F3 `reflow`: changing layout moves each open window to the zone it overlaps most. (Was R4.) Open: tiled windows too, or floating only?
- F4 `adopt`: snap takes the footprint of windows already in the target zone. (Was R5.) Behaviour not defined yet.
- Binds for these are assignable in `bindings.lua`; a switch that is off makes the key do nothing extra.

- F5 Genie in the settings popup header corner (Tony, 2026-11-06): the carpet genie (`assets/genie-watermark.svg`, 21 KB) in the theme text color, 72 px, with the divider stopping short of it. Done. A faded full-card watermark was tried and dropped.

## Out of scope
- F1 Dock window-dodge: abandoned in this project (Tony, 2026-11-06). The dock is Omarchy's own, and a cloned dock plugin loses access to shell.json (third-party plugins get a scoped shell API), so it belongs upstream as a built-in dock option. Likewise a running-app dot on the dock (not requested).
