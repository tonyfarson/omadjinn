# Changelog

All notable changes to Omadjinn - Floating Window Controls. Dates are YYYY-MM-DD.

## Unreleased (1.1.1)

### Fixed
- Right-clicking a page could open the Omadjinn menu instead of the app's own menu. A window on a hidden workspace
  (such as the scratchpad) still had an invisible title bar that caught clicks. Only windows on a workspace you can
  see count now (issue #2).

## 1.1.0 - 2026-11-07

### Added
- Default keys, registered by the plugin at runtime (no `bindings.lua` edit): `ALT + arrows` snap,
  `ALT + comma` / `period` cycle layouts, `ALT + C` the menu, `ALT + S` the settings. A key that something
  else already holds is left alone. Change or switch off any key in the new **Keybinds** page (Edit records the
  new keys, with conflict checks) or in `config.json`; Restore defaults puts them back.
- Stacking: `ALT + SHIFT + arrows` snap and stack on top of what is in the zone. Each zone remembers the order windows
  joined, and `ALT + grave` / `ALT + SHIFT + grave` step through the stack.
- Swap switch (off by default): a plain snap into a taken zone trades places with the top window there.
- Layout editor: **New layout** and **Edit zones** open a picture of the screen; split a zone, drag a line (it snaps to
  twelfths), merge a line, Save. Layouts you make appear on the Layouts page and in the cycle.
- Delete any layout, built-in ones included, with a **Restore layout?** bar to undo until you leave the page.
  **Restore defaults** (two clicks) brings the built-ins back and keeps your file as a timestamped backup.
- A glyph picker for each layout; the toast, the Layouts page and the right-click menu show the same glyph.
- Layouts with bad zones (no id, off-screen, no size, duplicates) are left out, and the Layouts page says why.
- Settings panel redesign: a fixed frame the height of the tallest page, with page buttons (General, Keybinds,
  Layouts, About), links for suggestions, bugs and coffee, the version in the footer, and a scroll bar that shows
  only when a page overflows.

### Changed
- The About page is shorter, and the Restart button is gone.
- The "Known limit" on titlebar drags is now documented as intended: `SUPER + LEFT MOUSE` restores the default
  floating size, and dragging by the titlebar is Hyprland's own drag.

### Notes
- Window gaps are Omarchy's (`SUPER + SHIFT + BACKSPACE`); Omadjinn follows the live gaps.

## 1.0.0 - 2026-11-07

First release.

### Added
- Snap a floating window into a zone of the current layout, in four directions.
- Cycle between layouts, with a toast that names the active one.
- Bundled layouts: halves ("Split"), stacked, quadrants, comms (1/3 + 2/3), and
  wide middle (1/4 + 1/2 + 1/4). Add your own in `~/.config/omadjinn/layouts.json`.
- Settings popup from a bar icon: feature switches, layout renaming, and a quick start.
- Optional feature switches, all off by default:
  - `dragRestore`: dragging a snapped window out with SUPER + LEFT MOUSE resizes it to
    Omarchy's default floating size.
  - `snapTiled`: snapping also floats tiled and scrolling windows.
- The popup follows the system font and theme colors, and closes with Esc or a click outside.
- Right-click menu, a switch that is off by default: right-click a floating window's titlebar to pick
  a zone of the current layout or change the layout. Keyboard control (arrows, Enter, number keys,
  Esc), theme colors only, and a `menuFocused` command to open it on the focused window from a key.
- Snapping now focuses the window and raises it to the top.

### Notes
- 1.0.0 shipped with no keybindings; see Unreleased for the defaults.
- Two ways to drag, on purpose: `SUPER + LEFT MOUSE` restores Omarchy's default floating size; dragging by the titlebar is Hyprland's own drag and keeps the snapped size.
