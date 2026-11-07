# Omadjinn roadmap

Ideas for after the next release, in rough order. Nothing here is promised, and the order can
change. Ideas and bug reports are welcome: https://github.com/tonyfarson/omadjinn/issues

## Next

- **Workspace overview.** One command shows every window in the workspace at once. Cycle
  with the arrow keys, press Enter, and that window comes to the front with focus. It would
  end the hunt for windows stacked in one zone (`SUPER + arrows` can focus a hidden window,
  and `ALT + TAB` cycles blindly). Open questions: whether Quickshell can draw real window
  thumbnails, or whether a labelled box with the app icon is the first version; and whether
  a marketplace plugin already does this. First step: a small feasibility check.

## Later

- **Reflow.** Changing layout moves each open window to the zone it overlaps most.
  A switch, off by default. Open question: tiled windows too, or floating only?
- **Adopt.** Snap takes the footprint of windows already in the target zone.
  A switch, off by default. The exact behaviour is not decided yet.
- **Right-click on the window border.** Open the menu from the border as well as the titlebar.
  Waits until someone asks for it.

## Not planned

- **Dock window-dodge.** The dock is Omarchy's own, and a third-party plugin cannot
  reach its settings. It belongs upstream in Omarchy.
