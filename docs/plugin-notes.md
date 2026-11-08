# Omarchy plugin notes (for R10)

Read 2026-11-06 from `docs/omarchy-shell.md` (upstream repo clone), `/usr/share/omarchy/shell/services/PluginShellApi.qml`,
`/usr/share/omarchy/shell/shell.qml`, and the omarchy skill's `plugins.md`. Tier 0/1 unless marked.

## What a plugin is
- Folder `~/.config/omarchy/plugins/<id>/` with `manifest.json` (schemaVersion 1, id, name, version, author, description, kinds, entryPoints) and QML entry points. Add with `omarchy plugin add <git-url>`; validate with `omarchy plugin validate <folder>`.
- Kinds: `bar-widget`, `bar`, `panel` (floating window), `overlay` (fullscreen), `menu`, `service` (headless singleton). A manifest may declare several. A settings page would be a `panel` (or `overlay`); background logic a `service`.
- Panels/overlays/menus expose `open(payloadJson)` and `close()`; saving a file under the plugin folder hot-reloads it.

## What a third-party plugin may do
- It gets a scoped shell facade, not the real shell: it can look up and control only its own service and lifecycle (summon, hide, toggle, isPluginOpen), and `updateEntryInline(id, settings)` for its own settings. `mutateShellConfig` only reaches bar config.
- A clone of a built-in gets no access to that built-in's config section (found the hard way with the dock; only the idle plugin is special-cased).
- The facade is an API boundary, not a sandbox: same QML process.

## Settings
- Settings are inline on the plugin's entry in `shell.json` (`plugins[]`); no separate config object. Third-party enabled means present.
- shell.json hot-reloads on save.

## Rules for UI code (plugins.md)
- `textFormat: Text.PlainText` on text; treat settings, files and command output as untrusted.
- Durations via `Style.duration(ms)`; ease-out only; under 300 ms.
- Strings in `i18n/<lang>.json` read through `Commons.Translations`; English alone is fine to start.
- Build on `qs.Ui` (`KeyboardPanel`, `PopupCard`, `Button`).

## Verified in real third-party plugins (read 2026-11-06)
`bogdart.dock` (kind `panel`, `~/.config/omarchy/plugins/bogdart.dock/Dock.qml`) and `io.github.villainru.panel-resources` (kinds `service` + `bar-widget`):
- **Read shell.json directly.** Since Omarchy 4.0.4 the facade has no `shellConfig`, so bogdart reads `~/.config/omarchy/shell.json` with a `FileView` (`watchChanges: true`) and picks out its own `plugins[]` entry. This is the workaround the dock clone needed.
- **Run commands:** `Process { command: [...] }` and `Quickshell.execDetached([...])` both work from a third-party plugin.
- **Read files:** `FileView { path: ... }` (Quickshell.Io).
- **Drive Hyprland:** `Hyprland.dispatch('hl.dsp.window.move({ workspace = "..." })')`, `hl.dsp.focus({ window = "address:..." })`, `hl.dsp.window.close(...)` (Quickshell.Hyprland). So the plugin can resize and move windows itself, without the Python scripts.
- **Keybinds reach a plugin through IPC:** bogdart declares an `IpcHandler` with a target name; a bind runs `omarchy-shell <target> <function>`. The plugin ships no binds (a plugin can't edit Hyprland config), so its README tells the user to paste them into `bindings.lua`.
- **Settings:** inline on the plugin's `shell.json` entry. panel-resources saves them from its panel with `shell.updateEntryInline(id, entry)`.
- **Repo shape worth copying (panel-resources):** `manifest.json`, `Service.qml`, `Panel.qml`, `Model.js` (logic kept out of QML), `bin/` helper script, `tests/`, `Makefile`, `AGENTS.md`, `CHANGELOG.md`, `README.md`, `LICENSE`.

## Verified by our own skeleton (2026-11-06)
`Panel.qml` + `manifest.json` (kind `panel`, `keepLoaded: true`), linked into `~/.config/omarchy/plugins/` for development:
- Loads and enables (`omarchy plugin enable <id>` works only after a `omarchy-shell shell rescanPlugins` has discovered it).
- Answers IPC: `omarchy-shell omadjinn ping` returns `pong`. This is how keybinds will reach the plugin.
- Writes files two ways from a third-party panel: `FileView.setText()` (signals `onSaved`) and a `Process` running `sh -c "printf ... > file"`. Both worked, so `layouts.json`, `config.json` and a generated binds snippet can be saved by the panel.
- Shows a toast by running `omarchy osd` through `Quickshell.execDetached`.

## Dev loop with `keepLoaded`
- A `keepLoaded: true` plugin stays in memory across rescan, disable/enable and file edits, so new code only loads after `omarchy restart shell`. With `keepLoaded: false` it loads on `omarchy-shell shell summon <id> '{}'` and edits apply after a disable/enable, but its IPC target exists only while loaded. Ship with `true`.

## Verified 2026-11-06 (port of snap and cycle)
- `hyprctl dispatch 'hl.dsp.window.resize/move(...)'` works (same request `Hyprland.dispatch` sends; bogdart uses it in QML).
- A plugin can register a keybind at runtime with `hyprctl eval 'hl.bind(...)'`; it shows in `hyprctl binds`, but **a config reload wipes it**, so a plugin must re-add its binds after every reload.
- The QML port (`Model.js` + `Panel.qml`) lands windows on exactly the same boxes as the Python script (compared with the Comms layout, left and right). `omarchy-shell omadjinn snap <dir>` and `cycle <next|prev>` work; cycle writes the same state file as the script.

## Still to verify
- How the plugin notices a config reload (candidate: `Hyprland.rawEvent`, name `configreloaded`), so it can re-register its binds.
- The `SUPER + LEFT MOUSE` drag-out needs a Lua mouse bind; see whether the plugin can register one with a Lua function.
- Building the settings UI from the `qs.Ui` kit (Toggle, TextField, NumberField, Dropdown, ConfirmDialog, OverlayWindow, PopupCard).

## Built and learned 2026-11-06 (settings popup, bar icon)
- **Shape now:** kinds `service` + `bar-widget`. `Service.qml` holds all state; `BarWidget.qml` (one per monitor) reads it through `bar.shell.serviceFor(pluginId)` and hosts the settings in a `PopupCard` anchored to the icon, so it drops from the bar like Audio or Pomodoro. A panel-kind window was tried first and opens centered on screen instead.
- **Bar icon:** `BarIconButton` with an `iconComponent` (a QML `Shape` from a potrace path); the bar fits its bounds to 12 logical px. Color comes from `bar.barForeground`, so one shape serves every theme.
- **Tinting an SVG:** `Image` plus `MultiEffect` needs `brightness: 1.0` before `colorization`, or a black source stays black.
- **Esc inside a popup:** after a `TextField` finishes editing, hand focus back (`root.forceActiveFocus()`), or Esc never reaches the popup.
- **Restarts:** any change of plugin kind or entry points, and every QML edit to a `keepLoaded` plugin, needs `omarchy restart shell`. A rename showed a stale "File name case mismatch" load error that the second restart cleared.
- **Validate** with the real folder, not the symlink: `omarchy plugin validate <repo path>` (it refuses symlinks inside the plugin folder).
- **Settings files:** `config.json` is rewritten whole on save, so the `_comment` line is lost (known, harmless). The first layout edit copies the bundled layouts to `~/.config/omadjinn/layouts.json`, which then replaces them.
- **Glyph font:** the settings popup draws layout icons in "JetBrainsMono Nerd Font" by name; other users' machines may need a fallback (to do).
- **Tracing artwork:** ChatGPT cannot make a faithful SVG by hand (it typed a crude redraw). Ask for a 1024+ px black-on-transparent PNG, then trace with `potrace` (threshold, trim, `potrace -s`).
