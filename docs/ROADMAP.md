# Omadjinn roadmap

Ideas for after 1.0, in rough order. Nothing here is promised, and the order can
change. Ideas and bug reports are welcome (links to come when the repo is up).

## Next

- **Layout editor.** Make your own layouts in the settings panel: drag split lines,
  or type a percentage or pixel position, and see the result as you go. Today you
  can already add custom layouts by editing `~/.config/omadjinn/layouts.json`.
- **Layout picture in the toast.** The editor's preview saved as the image the cycle
  toast shows for that layout. Needs a check on whether Omarchy's on-screen display
  accepts a custom image.
- **Pick a layout icon.** Choose a layout's icon from a small set of symbols in the
  panel instead of editing the file. It comes with the editor.

## Later

- **Drag out by the titlebar.** Dragging a snapped window out by its titlebar should
  also restore its size. Today it works only when you grab the window body. This
  depends on whether the titlebar plugin offers a hook.
- **Keybinding help.** A plugin cannot edit Hyprland's config, so Omadjinn will keep
  shipping without default keys. The panel might generate a ready-to-paste
  `bindings.lua` block for the keys you pick, including one per custom layout.
- **Swap.** Snapping into an occupied zone swaps the two windows. A switch, off by default.
- **Reflow.** Changing layout moves each open window to the zone it overlaps most.
  A switch, off by default. Open question: tiled windows too, or floating only?
- **Adopt.** Snap takes the footprint of windows already in the target zone.
  A switch, off by default. The exact behaviour is not decided yet.

## Not planned

- **Dock window-dodge.** The dock is Omarchy's own, and a third-party plugin cannot
  reach its settings. It belongs upstream in Omarchy.
