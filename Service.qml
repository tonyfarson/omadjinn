import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Model.js" as Model

// omadjinn engine: snap, cycle, config and layouts live here, one
// instance per shell. The bar icon and its settings popup (BarWidget.qml) read
// this state through shell.serviceFor and call back into it.
// The plugin shows no toast of its own except the layout name when the layout
// is cycled.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/omadjinn"
  readonly property string userLayoutsPath: home + "/.config/omadjinn/layouts.json"
  readonly property string bundledLayoutsPath: Qt.resolvedUrl("layouts/default.json").toString().replace("file://", "")

  // ── Layouts ────────────────────────────────────────────────────────────────
  property var userLayouts: []
  property var bundledLayouts: []
  readonly property var layouts: userLayouts.length > 0 ? userLayouts : bundledLayouts
  property string currentId: ""

  function parseLayouts(text) {
    try { var d = JSON.parse(text); return Array.isArray(d.layouts) ? d.layouts : [] } catch (e) { return [] }
  }

  FileView {
    id: userLayoutsFile
    path: root.userLayoutsPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.userLayouts = root.parseLayouts(text())
    onLoadFailed: root.userLayouts = []
  }

  FileView {
    path: root.bundledLayoutsPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.bundledLayouts = root.parseLayouts(text())
  }

  // The current layout is remembered across restarts in the same place the
  // scripts use, so the two stay in step while both exist.
  FileView {
    id: currentFile
    path: root.stateDir + "/current"
    printErrors: false
    onLoaded: root.currentId = text().trim()
  }

  Process {
    command: ["mkdir", "-p", root.stateDir]
    running: true
  }

  function layoutById(id) {
    for (var i = 0; i < layouts.length; i++) if (layouts[i].id === id) return layouts[i]
    return layouts.length > 0 ? layouts[0] : null
  }

  // ── Cycle ──────────────────────────────────────────────────────────────────
  function cycle(direction) {
    if (layouts.length === 0) return "no layouts"
    var idx = Model.nextLayoutIndex(layouts, currentId, direction === "prev" ? "prev" : "next")
    var layout = layouts[idx]
    currentId = layout.id
    currentFile.setText(layout.id + "\n")
    var args = ["omarchy", "osd"]
    if (layout.icon) args = args.concat(["-i", String(layout.icon)])
    args = args.concat(["-m", String(layout.name || layout.id), "-d", "1500"])
    Quickshell.execDetached(args)
    return layout.id
  }

  // ── Snap ───────────────────────────────────────────────────────────────────
  // One snap reads the window, its monitor, the live gaps and the titlebar
  // height from Hyprland, then moves the window through Hyprland's dispatch.
  Component {
    id: cmdComponent
    Process {
      id: proc
      property var done: null
      stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
          if (proc.done) proc.done(text)
          proc.destroy(2000)
        }
      }
    }
  }

  function run(command, done) {
    var p = cmdComponent.createObject(root, { command: command, done: done })
    p.running = true
  }

  function json(text) {
    try { return JSON.parse(text) } catch (e) { return null }
  }

  // Everything one snap needs besides the window: its monitor, the live gaps and
  // the titlebar height, all read from Hyprland. Calls done(mon, gIn, gOut, titlebar).
  function withContext(win, done) {
    run(["hyprctl", "-j", "monitors"], function(t2) {
      var mons = root.json(t2) || [], mon = null
      for (var i = 0; i < mons.length; i++) if (mons[i].id === win.monitor) mon = mons[i]
      if (!mon) return
      run(["hyprctl", "-j", "getoption", "general:gaps_in"], function(t3) {
        var gIn = Model.parseGap((root.json(t3) || {}).css)
        run(["hyprctl", "-j", "getoption", "general:gaps_out"], function(t4) {
          var gOut = Model.parseGap((root.json(t4) || {}).css)
          run(["hyprctl", "plugin", "list"], function(t5) {
            if (t5.indexOf("hyprbars") < 0) { done(mon, gIn, gOut, 0); return }
            run(["hyprctl", "-j", "getoption", "plugin:hyprbars:bar_height"], function(t6) {
              done(mon, gIn, gOut, Number((root.json(t6) || {}).int) || 0)
            })
          })
        })
      })
    })
  }

  function snap(direction) {
    if (!(direction in Model.DIRS)) return "direction must be left, right, up or down"
    if (layouts.length === 0) return "no layouts"
    run(["hyprctl", "-j", "activewindow"], function(t1) {
      var win = root.json(t1)
      if (!win || !win.address || win.fullscreen) return
      // Tiled and scrolling windows are left alone unless the snapTiled switch is on.
      if (!win.floating && root.config.features.snapTiled !== true) return
      root.withContext(win, function(mon, gIn, gOut, titlebar) {
        root.snapNow(win, mon, gIn, gOut, titlebar, direction)
      })
    })
    return "ok"
  }

  // Put the window with this address into zone number `index` of the current layout
  // (used by the right-click menu).
  function snapToZone(address, index) {
    if (layouts.length === 0) return "no layouts"
    run(["hyprctl", "-j", "clients"], function(t1) {
      var all = root.json(t1) || [], win = null
      for (var i = 0; i < all.length; i++) if (all[i].address === address) win = all[i]
      if (!win || win.fullscreen) return
      root.withContext(win, function(mon, gIn, gOut, titlebar) {
        var layout = root.layoutById(root.currentId)
        if (!layout) return
        var zones = Model.zonesFor(layout.zones, mon, gIn, gOut, titlebar)
        if (index < 0 || index >= zones.length) return
        var geo = [win.at[0], win.at[1], win.size[0], win.size[1]]
        root.placeIn(win, zones[index], geo, Model.pickZone(zones, geo, "left").inZone)
      })
    })
    return "ok"
  }

  function snapNow(win, mon, gIn, gOut, titlebar, direction) {
    var layout = layoutById(currentId)
    if (!layout) return
    var zones = Model.zonesFor(layout.zones, mon, gIn, gOut, titlebar)
    var geo = [win.at[0], win.at[1], win.size[0], win.size[1]]
    var pick = Model.pickZone(zones, geo, direction)
    if (!pick.zone) {
      // At the layout edge. If the window sits in a zone with no row (an app
      // that reopened there), record it so a drag-out has a size to restore.
      if (pick.inZone && !rows[win.address]) remember(win, pick.inZone, geo, pick.inZone)
      return
    }
    placeIn(win, pick.zone, geo, pick.inZone)
  }

  // Remember the pre-snap size, float the window if needed, then size and move it into the zone.
  function placeIn(win, z, geo, inZone) {
    remember(win, z, geo, inZone)
    var target = "address:" + win.address
    if (!win.floating) Hyprland.dispatch("hl.dsp.window.float({ action = 'enable', window = '" + target + "' })")
    Hyprland.dispatch("hl.dsp.window.resize({ x = " + z[2] + ", y = " + z[3] + ", relative = false, window = '" + target + "' })")
    Hyprland.dispatch("hl.dsp.window.move({ x = " + z[0] + ", y = " + z[1] + ", relative = false, window = '" + target + "' })")
    // Bring it to the front. A snap that comes from a click we swallowed (the menu)
    // never focused or raised the window, so ask Hyprland to do both.
    Hyprland.dispatch("hl.dsp.focus({ window = '" + target + "' })")
    Hyprland.dispatch("hl.dsp.window.alter_zorder({ window = '" + target + "', mode = 'top' })")
  }

  // ── Remember the pre-snap size (for the drag-out restore) ──────────────────
  // Same file and format the Python script writes:
  //   <address> <orig-w> <orig-h> <snap-x> <snap-y> <snap-w> <snap-h>
  property var rows: ({})

  FileView {
    id: snappedFile
    path: root.stateDir + "/snapped"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var map = ({})
      var lines = text().split("\n")
      for (var i = 0; i < lines.length; i++) {
        var f = lines[i].trim().split(/\s+/)
        if (f.length === 7) map[f[0]] = f.slice(1).map(Number)
      }
      root.rows = map
    }
  }

  function remember(win, zone, geo, inZone) {
    var prev = rows[win.address] || null
    var next = ({})
    for (var k in rows) next[k] = rows[k]
    next[win.address] = Model.origSize(prev, inZone, win.floating, geo).concat(zone)
    rows = next
    var out = ""
    for (var a in next) out += a + " " + next[a].join(" ") + "\n"
    snappedFile.setText(out)
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  // ~/.config/omadjinn/config.json holds the feature switches. The panel
  // reads and writes it; the Lua drag-out reads it directly on every press.
  readonly property string configPath: home + "/.config/omadjinn/config.json"
  property var config: ({ features: {} })
  property bool settingsOpen: false

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        if (!parsed.features || typeof parsed.features !== "object") parsed.features = ({})
        root.config = parsed
      } catch (e) { root.config = ({ features: {} }) }
    }
    onLoadFailed: root.config = ({ features: {} })
  }

  Process {
    command: ["mkdir", "-p", root.home + "/.config/omadjinn"]
    running: true
  }

  function setFeature(key, value) {
    var next = JSON.parse(JSON.stringify(config))
    if (!next.features) next.features = ({})
    next.features[key] = value
    config = next
    configFile.setText(JSON.stringify(next, null, 2) + "\n")
  }

  // Layout edits go to ~/.config/omadjinn/layouts.json. The first edit copies
  // the bundled layouts there; from then on that file is the one in use.
  function saveLayouts(list) {
    userLayoutsFile.setText(JSON.stringify({ layouts: list }, null, 2) + "\n")
    userLayouts = list
  }

  // Opens layouts.json in the default text editor. The first time, the bundled layouts
  // are copied there so the file exists.
  function openLayoutsFile() {
    if (userLayouts.length === 0) saveLayouts(JSON.parse(JSON.stringify(layouts)))
    openFileTimer.start()
  }

  Timer {
    id: openFileTimer
    interval: 400
    onTriggered: Quickshell.execDetached(["xdg-open", root.userLayoutsPath])
  }

  function renameLayout(id, name) {
    var list = JSON.parse(JSON.stringify(layouts))
    for (var i = 0; i < list.length; i++) if (list[i].id === id) list[i].name = name
    saveLayouts(list)
  }

  // ── Right-click menu ───────────────────────────────────────────────────────
  // hypr/right-click.lua catches a right-click on a titlebar and calls the `menu`
  // IPC below. The service hands Hyprland that file when the shell starts and after
  // every config reload, which drops runtime binds.
  readonly property bool menuEnabled: config.features.rightClickMenu === true
  readonly property string menuHook: Qt.resolvedUrl("hypr/right-click.lua").toString().replace("file://", "")
  onMenuEnabledChanged: { loadMenuHook(); loadKeys() }

  function loadMenuHook() {
    // The path goes into Lua source, so it must be exactly the safe form checked here.
    if (!/^[A-Za-z0-9_\/.\-]+$/.test(menuHook)) {
      console.warn("omadjinn: refusing to load the right-click hook from", menuHook)
      return
    }
    run(["hyprctl", "eval", "omadjinn_menu_enabled = " + menuEnabled + " dofile(\"" + menuHook + "\")"], function(out) {
      if (out.trim() !== "ok") console.warn("omadjinn: hyprctl eval said:", out.trim())
    })
  }

  // ── Keys ───────────────────────────────────────────────────────────────────
  // hypr/keys.lua binds the default keys (see Model.KEY_ACTIONS) or the user's own from
  // config.json. A key something else already holds is left to it. Calls that arrive
  // while one is running fold into one more run afterwards.
  readonly property string keysHook: Qt.resolvedUrl("hypr/keys.lua").toString().replace("file://", "")
  property bool keysBusy: false
  property bool keysAgain: false
  property var blockedKeys: ({})
  // While the panel records a new bind, our own binds are lifted so Hyprland does not
  // swallow the keys being pressed.
  property bool keysSuspended: false
  onKeysSuspendedChanged: loadKeys()

  // Saves one action's key to config.json "keys". The default key (or an empty string
  // to switch the action off) is stored only when it differs from the default.
  // Drops every key override, so all binds are the defaults again.
  function restoreKeys() {
    var next = JSON.parse(JSON.stringify(config))
    delete next.keys
    config = next
    configFile.setText(JSON.stringify(next, null, 2) + "\n")
  }

  function setKey(id, text) {
    var next = JSON.parse(JSON.stringify(config))
    if (!next.keys) next.keys = ({})
    var def = ""
    for (var i = 0; i < Model.KEY_ACTIONS.length; i++) if (Model.KEY_ACTIONS[i].id === id) def = Model.KEY_ACTIONS[i].key
    if (text === def) delete next.keys[id]; else next.keys[id] = text
    if (Object.keys(next.keys).length === 0) delete next.keys
    config = next
    configFile.setText(JSON.stringify(next, null, 2) + "\n")
  }

  function loadKeys() {
    if (keysBusy) { keysAgain = true; return }
    keysBusy = true
    keysAgain = false
    run(["hyprctl", "-j", "binds"], function(text) {
      var binds = root.json(text)
      var wanted = root.keysSuspended ? [] : Model.keysFor(root.config, { menu: !root.menuEnabled })
      var list = [], blocked = ({})
      for (var i = 0; i < wanted.length; i++) {
        var holder = Model.keyConflict(binds, wanted[i].key)
        if (holder) blocked[wanted[i].id] = holder
        else list.push("{\"" + wanted[i].key + "\",\"" + wanted[i].cmd + "\",\"Omadjinn: " + wanted[i].label + "\"}")
      }
      root.blockedKeys = blocked
      // The path goes into Lua source, so it must be exactly the safe form checked here.
      if (!/^[A-Za-z0-9_\/.\-]+$/.test(root.keysHook)) {
        console.warn("omadjinn: refusing to load the keys from", root.keysHook)
        root.keysBusy = false
        return
      }
      run(["hyprctl", "eval", "omadjinn_keys = { " + list.join(", ") + " } dofile(\"" + root.keysHook + "\")"], function(out) {
        if (out.trim() !== "ok") console.warn("omadjinn: hyprctl eval said:", out.trim())
        root.keysBusy = false
        if (root.keysAgain) root.loadKeys()
      })
    })
  }

  onConfigChanged: loadKeys()

  Component.onCompleted: { loadMenuHook(); loadKeys() }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && String(event.name) === "configreloaded") { root.loadMenuHook(); root.loadKeys() }
    }
  }

  // Hand the clicked window and cursor position to the menu overlay (Menu.qml).
  function openMenu(address, x, y) {
    if (!menuEnabled || !shell) return "disabled"
    shell.summon(manifest.id, JSON.stringify({ address: address, x: Number(x), y: Number(y) }))
    return "ok"
  }

  // The same menu for the focused window, for a key: it opens just inside the
  // window's top-left corner.
  function openMenuFocused() {
    if (!menuEnabled) return "disabled"
    run(["hyprctl", "-j", "activewindow"], function(t) {
      var win = root.json(t)
      if (!win || !win.address || win.fullscreen) return
      if (!win.floating && config.features.snapTiled !== true) return
      root.openMenu(win.address, win.at[0] + 16, win.at[1] + 12)
    })
    return "ok"
  }

  // ── IPC: how keybinds (yours, in bindings.lua) reach the plugin ───────────────────────────
  // omarchy-shell omadjinn snap left|right|up|down
  // omarchy-shell omadjinn cycle next|prev
  IpcHandler {
    target: "omadjinn"

    function ping(): string { return "pong" }
    function snap(direction: string): string { return root.snap(direction) }
    function cycle(direction: string): string { return root.cycle(direction) }
    function current(): string { return root.currentId }
    function open(): string { root.settingsOpen = true; return "open" }
    function close(): string { root.settingsOpen = false; return "closed" }
    function toggle(): string { root.settingsOpen = !root.settingsOpen; return root.settingsOpen ? "open" : "closed" }
    function menu(address: string, x: string, y: string): string { return root.openMenu(address, x, y) }
    function menuFocused(): string { return root.openMenuFocused() }
  }
}
