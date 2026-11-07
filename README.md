<p align="center"><img src="assets/banner.svg" alt="Omadjinn - Floating Window Controls" width="100%"></p>

Omadjinn (oh-MAHD-jin) is a window snapping tool for floating workspaces on Omarchy 4.5 and later: named
layouts (halves, quadrants, comms 1/3 + 2/3, 1/4 + 1/2 + 1/4, and your own), keys to snap a window into a
zone, stack windows in a zone, swap them, and cycle layouts, a layout editor you drag lines in, and an on-screen
toast (`omarchy osd`) naming the active layout.

## About Keybindings

Omadjinn registers its own keys when the shell starts, so there is nothing to paste into your Hyprland
config. They show up in Omarchy's keybindings menu with an "Omadjinn:" description.

| Keys | What they do |
| --- | --- |
| `ALT + arrows` | Snap the window into the zone in that direction |
| `ALT + SHIFT + arrows` | Snap and stack: the window lands on top of whatever is in the zone, even with swap on |
| `ALT + grave` / `ALT + SHIFT + grave` | Step through the stack in the zone (`grave` is the backtick key): the top window goes to the bottom, or the bottom one comes up |
| `ALT + comma` / `ALT + period` | Previous and next layout |
| `ALT + C` | Menu for the focused window (needs the right-click menu switched on) |
| `ALT + S` | Open the settings |

A key that something else already holds is left to that other binding, so your own binds always win.
Change any key from the **Keybinds** page (click Edit, then press
the new keys; the page says so if the combination is taken), or put them in `~/.config/omadjinn/config.json` under `"keys"`; an empty string switches a key off.
"Restore defaults" on that page puts them all back.

You can still bind the commands yourself in `~/.config/hypr/bindings.lua`, for example:

```lua
o.bind("SUPER + ALT + LEFT", "Snap window left", "omarchy-shell omadjinn snap left")
```

Commands: `snap left|right|up|down`, `stack left|right|up|down`, `stackCycle next|prev`,
`cycle next|prev`, `menuFocused` and `toggle` (opens the settings). Check that a key is free first
(`omarchy menu keybindings --print`).

Status: an Omarchy shell plugin, working on Omarchy 4.5. Built: snap, stack and swap, layout cycling, the layout
editor with custom layouts, drag-out restore, a right-click menu, a bar icon, and a settings panel with four pages
(General, Keybinds, Layouts, About). Planned: see the roadmap below.

## Install

Requires Omarchy 4.5 or later. There is nothing else to install. If Omarchy's window
titlebars (hyprbars) are on, Omadjinn leaves room for them in each zone.

```
omarchy plugin add https://github.com/tonyfarson/omadjinn --enable
```

The genie icon is added to the bar for you. The keys work straight away (see About Keybindings);
settings open from the bar icon or `ALT + S`.

Optional, for drag-out restore: turn on the `dragRestore` switch in the settings, and
add this block to `~/.config/hypr/bindings.lua`:

```lua
hl.unbind("SUPER + mouse:272")
o.bind("SUPER + mouse:272", "Move window (restores pre-snap size)",
  dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.tonyfarson.omadjinn/lua/drag.lua"), { mouse = true })
```

## Remove

```
omarchy plugin remove io.github.tonyfarson.omadjinn
```

Removing the plugin leaves your own files alone. To clean up fully, delete
`~/.config/omadjinn` (settings and your layouts) and `~/.local/state/omadjinn`, and take
out any Omadjinn binds you added to `~/.config/hypr/bindings.lua`.

## Use

- **Snap** (`ALT + arrows`) puts the focused window in the current layout's zone in that direction.
  Only floating windows are snapped, unless the `snapTiled` switch is on (then a tiled or scrolling window is floated first).
- **Stack and swap.** Snapping into a zone that already holds a window puts yours on top, and the stack
  remembers the order windows joined. With the **swap** switch on, a plain snap instead trades places with the
  top window there, which goes to the spot yours came from. `ALT + SHIFT + arrows` always stacks. Step through a
  stack with `ALT + grave`. A window that leaves the zone drops out of the stack and the one beneath shows.
- **Cycle** (`ALT + comma` / `period`) changes layout; a toast names the active one.
- **Settings** open from the genie icon in the bar. The General page has the feature switches, Keybinds lists
  every key with an Edit button, Layouts manages your layouts, and About has the basics.
- **Layouts page.**
  - Each layout shows its glyph (the same one the toast and the menu use) and its name. Click Edit to rename
    it, pick another glyph, or open its zones in the editor.
  - **New layout** and **Edit zones** open the zone editor: click a zone and split it, drag a line to move it
    (lines snap to twelfths: halves, thirds, quarters, sixths), click a line and merge it away, then Save. A new
    layout is saved as "Custom 1" and so on.
  - The trash button deletes a layout, built-in ones included. The row turns into a **Restore layout?** bar until
    you leave the page. The last layout cannot be deleted.
  - **Restore defaults** (click twice) puts the built-in layouts back and keeps your file as
    `~/.config/omadjinn/layouts.backup-<date>-<time>.json`.
  - Prefer a text editor? **Open the JSON** opens `~/.config/omadjinn/layouts.json`. A zone is
    `[x, y, w, h]` as fractions of the screen, 0 to 1. A layout with a bad zone is left out and the page says why.
- **Right-click menu** (off until you turn on "Right-click menu on titlebars" in the settings):
  right-click a floating window's titlebar and a small menu opens at the pointer. It lists the zones of
  the current layout. Click a zone, press its number, or use the arrow keys and Enter, and the window snaps there and
  comes to the front. The last row shows the layout, with arrows to change it. `Esc` or a click outside closes
  the menu. It follows your Omarchy theme. It needs Omarchy's floating workspace, which draws the titlebars.

## Layout

- `manifest.json` plugin manifest: a service, a bar widget and the right-click menu overlay
- `Service.qml` the engine: layouts, snap, stack, swap, keys, config files
- `BarWidget.qml` the bar icon and the popup; `SettingsPanel.qml` its frame, with one file per page (`GeneralPage.qml`, `KeysPage.qml`, `LayoutsPage.qml`, `AboutPage.qml`) and `ZoneEditor.qml`
- `Menu.qml` the right-click menu; `GenieIcon.qml` the icon shape
- `Model.js` the zone math, key parsing and layout checks (tested by `tests/model.test.js`)
- `lua/drag.lua` the drag-out restore, run inside Hyprland; `hypr/` the key and right-click hooks
- `layouts/default.json` bundled layouts; your copy is `~/.config/omadjinn/layouts.json`
- `assets/` genie artwork (SVG, traced with potrace)
- `bin/` the first-stage scripts, no longer bound, kept for reference
- `docs/requirements.md` requirements (R) and features (F); `docs/plugin-notes.md` what we learned about Omarchy plugins

Source and issues: https://github.com/tonyfarson/omadjinn. MIT license.

## Known limits

- **Who is on top is a guess.** Hyprland does not expose stacking order, so Omadjinn takes the most recently
  focused window in a zone as the top one (used by swap). A window raised without being focused could fool it.
- **Two ways to drag a snapped window, on purpose.** `SUPER + LEFT MOUSE` (off unless the `dragRestore` switch is on
  and the block above is in your `bindings.lua`) moves the window and resizes it to Omarchy's default floating
  size (about 64% x 68% of the screen, capped at 1100 x 760). Dragging by the titlebar is Hyprland's own drag, so
  the window keeps its snapped size. The restore is wrapped so that any error falls through to a plain drag; the
  last error is kept in `~/.local/state/omadjinn/last-error`.
- A window is recognized as snapped only if you snapped it with the plugin (it leaves a marker row). One that merely sits in a zone is not.
- The zone editor draws layouts made by straight cuts across the screen. A layout with overlapping zones, gaps,
  or a pinwheel shape can't be drawn there; edit it in `layouts.json`.
- Once `~/.config/omadjinn/layouts.json` exists it replaces the built-in layouts completely. Restore defaults brings them back.
- While you record a new key on the Keybinds page, Omadjinn's own keys are lifted so Hyprland doesn't swallow the key you press. They return when you finish, cancel or close the panel.
- The toast takes one text glyph as its icon, so layouts are shown there by glyph rather than by a drawing of their zones.
- Window gaps are Omarchy's: toggle them with `SUPER + SHIFT + BACKSPACE`. Zones follow whatever gaps are set.

Planned features: see [docs/ROADMAP.md](docs/ROADMAP.md).

## Built with AI

Omadjinn is designed and tested by Tony Farson, and built with the help of [Claude Code](https://claude.com/claude-code), an AI coding assistant from Anthropic.
