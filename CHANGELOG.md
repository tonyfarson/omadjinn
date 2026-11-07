# Changelog

All notable changes to Omadjinn - Floating Window Controls. Dates are YYYY-MM-DD.

## 1.0.0 - unreleased

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

### Notes
- Omadjinn ships with no keybindings. See "About Keybindings" in the README.
- Known limit: drag-out restore works only when you grab the window body, not its titlebar.
