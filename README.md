# Omadjinn - Floating Window Controls

Window snapping for floating workspaces on Omarchy 4.5 and later: named layouts
(halves, quadrants, comms 1/3 + 2/3, 1/4 + 1/2 + 1/4, custom), commands to snap
a window into a zone and to cycle layouts (you choose the keys), and an on-screen
toast (`omarchy osd`) naming the active layout.

## About Keybindings

Omadjinn ships **no keybindings**. Every key combination on a desktop is already
spoken for by something, and a plugin cannot edit Hyprland's config, so the keys are
yours to choose. Paste the lines you want into `~/.config/hypr/bindings.lua` and
change the keys to suit:

```lua
o.bind("ALT + LEFT",  "Snap window left",  "omarchy-shell omadjinn snap left")
o.bind("ALT + RIGHT", "Snap window right", "omarchy-shell omadjinn snap right")
o.bind("ALT + UP",    "Snap window up",    "omarchy-shell omadjinn snap up")
o.bind("ALT + DOWN",  "Snap window down",  "omarchy-shell omadjinn snap down")
o.bind("SUPER + ALT + RIGHT", "Next window layout",     "omarchy-shell omadjinn cycle next")
o.bind("SUPER + ALT + LEFT",  "Previous window layout", "omarchy-shell omadjinn cycle prev")
o.bind("SUPER + ALT + UP",    "Omadjinn settings",      "omarchy-shell omadjinn toggle")
```

Those keys are only an example. Check that a key is free first (`omarchy menu keybindings --print`).
Some are taken: stock Omarchy uses `SUPER + ALT + arrows` to move a window into a group, and
`ALT + arrows` are back and forward in browsers.

Status (2026-11-06): an Omarchy shell plugin, working on Omarchy 4.5. Built: snap,
cycle, drag-out restore, a bar icon, and a settings popup with feature switches,
layout renaming and a quick start. Not built yet: see the roadmap below.

## Use

- Snap (`snap left|right|up|down`) puts the focused window in the current layout's zone in that direction.
  Only floating windows are snapped, unless the `snapTiled` switch is on (then a tiled or scrolling window is floated first).
- Cycle (`cycle next|prev`) changes layout; a toast names the active one.
- A click on the genie icon in the bar opens the settings popup (`toggle` does the same from a key).
- Bind the keys yourself (see About Keybindings).
- Install: link this folder into `~/.config/omarchy/plugins/`, run
  `omarchy-shell shell rescanPlugins`, `omarchy plugin enable io.github.tonyfarson.omadjinn`,
  add the plugin id to `bar.layout` in `~/.config/omarchy/shell.json`, then `omarchy restart shell`.
  `SUPER + LEFT MOUSE` drag-out also needs the block in `~/.config/hypr/bindings.lua` that loads `lua/drag.lua`.

## Layout

- `manifest.json` plugin manifest: a service plus a bar widget
- `Service.qml` the engine: layouts, snap, cycle, config files
- `BarWidget.qml` the bar icon and the settings popup; `SettingsPanel.qml` its content; `GenieIcon.qml` the icon shape
- `Model.js` the zone math (tested by `tests/model.test.js`)
- `lua/drag.lua` the drag-out restore, run inside Hyprland
- `layouts/default.json` bundled layouts; your copy is `~/.config/omadjinn/layouts.json`
- `assets/` genie artwork (SVG, traced with potrace)
- `bin/` the first-stage scripts, no longer bound, kept for reference
- `docs/requirements.md` requirements (R) and features (F); `docs/plugin-notes.md` what we learned about Omarchy plugins

Source and issues: https://github.com/tonyfarson/omadjinn. MIT license.

## Known limits

- Dragging a snapped window out with `SUPER + LEFT MOUSE` (off unless `"dragRestore": true` in `~/.config/omadjinn/config.json`; see `config.example.json`) resizes it to Omarchy's default floating size (about 64% x 68% of the screen, capped at 1100 x 760). It works only when the press lands on the window body; with the pointer on the titlebar the window moves but keeps its snapped size (R11 in `docs/requirements.md`).
- A window is recognized as snapped only if you snapped it with the plugin (it leaves a marker row). One that merely sits in a zone is not.
- "Which window is on top" is a guess: of the floating windows under the pointer, the most recently focused one. Hyprland does not expose stacking order. A window raised without being focused could fool it.
- The restore is wrapped so that any error falls through to a plain drag; the last error is kept in `~/.local/state/omadjinn/last-error`.

Planned features: see [docs/ROADMAP.md](docs/ROADMAP.md).
