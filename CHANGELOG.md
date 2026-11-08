# Changelog

All notable changes to Omadjinn - Floating Window Controls. Dates are YYYY-MM-DD.

## 1.1.3 - 2026-11-07

### Fixed
- Closing the settings panel, or leaving the Layouts page, now also closes the zone editor and any layout name you
  were editing. Before, an editor left open stayed alive inside the closed panel, and so did its name field. No text
  input is left in the shell behind a closed panel now. Unsaved edits are dropped, as Cancel would.

## 1.1.2 - 2026-11-07

### Fixed
- The settings panel no longer leaves a text input in the shell while it is idle. The new-layout name field and the
  layout name fields used to exist as soon as the Layouts page had been shown, and stayed after the panel closed. They
  are now created only while you are typing in them. This came out of the marketplace review of 1.1.1.
- The bar icon's default colour follows the theme instead of a fixed white.

### Changed
- On the Layouts page, layout names show as plain text until you click Edit. The editor below the list still shows
  greyed out until New layout or Edit zones opens it; it looks the same as before.

## 1.1.1 - 2026-11-07

### Added
- Saving a new layout now asks for a name and an icon in the zone editor (issue #1), so there is no need to click Edit afterwards.
  An empty name still becomes "Custom N".

### Fixed
- Right-clicking a page could open the Omadjinn menu instead of the app's own menu. A window on a hidden workspace
  (such as the scratchpad) still had an invisible title bar that caught clicks. Only windows on a workspace you can
  see count now (issue #2).

## 1.1.0 - 2026-11-07

### Added
- Right-click menu (off by default): right-click a floating window's titlebar to pick a zone of the current
  layout or change the layout. Keyboard control (arrows, Enter, number keys, Esc), theme colors only, and a
  `menuFocused` command to open it on the focused window from a key.
- Snapping now focuses the window and raises it to the top.
- Default keys, registered by the plugin at runtime (no `bindings.lua` edit): `ALT + arrows` snap,
  `ALT + comma` / `period` cycle layouts, `ALT + C` the menu (when the right-click menu is switched on),
  `ALT + S` the settings. A key that something else already holds is left alone. Change or switch off any key in the new **Keybinds** page (Edit records the
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
- An About page with a few words from the developer and links to learn more.

### Changed
- The "Known limit" on titlebar drags is now documented as intended: `SUPER + LEFT MOUSE` restores the default
  floating size, and dragging by the titlebar is Hyprland's own drag.

### Notes
- Window gaps are Omarchy's (`SUPER + SHIFT + BACKSPACE`); Omadjinn follows the live gaps.

## 1.0.0 - 2026-11-06

First release.

### Added
- Snap a floating window into a zone of the current layout, in four directions.
- Cycle between layouts, with a toast that names the active one.
- Bundled layouts: halves ("Split"), stacked, quadrants, comms (1/3 + 2/3), and
  wide middle (1/4 + 1/2 + 1/4). Add your own in `~/.config/omadjinn/layouts.json`.
- Settings popup from a bar icon: feature switches, layout renaming, and a quick start with links to
  suggestions, bug reports and the README. The genie sits in the header corner, in the theme text color.
- Optional feature switches, all off by default:
  - `dragRestore`: dragging a snapped window out with SUPER + LEFT MOUSE resizes it to
    Omarchy's default floating size.
  - `snapTiled`: snapping also floats tiled and scrolling windows.
- The popup follows the system font and theme colors, and closes with Esc or a click outside.
- A Buy Me a Coffee funding link on the repository.

### Notes
- Omadjinn shipped with no keybindings. Default keys came in 1.1.0.
- Known limit: drag-out restore works only when you grab the window body, not its titlebar.
