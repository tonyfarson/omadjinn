.pragma library

// omadjinn: the maths, with no Hyprland or QML in it, so it can be tested
// with plain node (tests/model.test.js).

var TOL = 6   // px: how close a window must be to a zone to count as "in" it

var DIRS = { left: [-1, 0], right: [1, 0], up: [0, -1], down: [0, 1] }

// CSS shorthand (as Hyprland reports gaps) -> [top, right, bottom, left]
function parseGap(css) {
  var v = String(css === undefined || css === null ? "0" : css).trim().split(/\s+/).map(Number)
  for (var i = 0; i < v.length; i++) if (isNaN(v[i])) v[i] = 0
  if (v.length === 1) return [v[0], v[0], v[0], v[0]]
  if (v.length === 2) return [v[0], v[1], v[0], v[1]]
  if (v.length === 3) return [v[0], v[1], v[2], v[1]]
  return v.slice(0, 4)
}

// Zones in layout coordinates for one monitor. Each zone is the CONTENT box of a
// window: it already leaves room for the gaps (screen edge: gapsOut, edge between
// zones: gapsIn) and for the titlebar drawn above floating windows.
// mon: a Hyprland monitor object. gapsIn/gapsOut: [t, r, b, l]. titlebar: px.
function zonesFor(layoutZones, mon, gapsIn, gapsOut, titlebar) {
  var scale = mon.scale || 1
  var w = mon.width / scale, h = mon.height / scale
  if ((mon.transform || 0) % 2) { var t = w; w = h; h = t }
  // Hyprland reports reserved space as [left, top, right, bottom].
  var rv = mon.reserved || [0, 0, 0, 0]
  var rl = rv[0], rt = rv[1], rr = rv[2], rb = rv[3]
  var ux = mon.x + rl, uy = mon.y + rt
  var uw = w - rl - rr, uh = h - rt - rb
  var e = 0.001
  var out = []
  for (var i = 0; i < layoutZones.length; i++) {
    var z = layoutZones[i], fx = z[0], fy = z[1], fw = z[2], fh = z[3]
    var gl = fx < e ? gapsOut[3] : gapsIn[3]
    var gt = fy < e ? gapsOut[0] : gapsIn[0]
    var gr = fx + fw > 1 - e ? gapsOut[1] : gapsIn[1]
    var gb = fy + fh > 1 - e ? gapsOut[2] : gapsIn[2]
    var x0 = ux + fx * uw + gl, y0 = uy + fy * uh + gt
    var x1 = ux + (fx + fw) * uw - gr, y1 = uy + (fy + fh) * uh - gb
    out.push([Math.round(x0), Math.round(y0 + titlebar), Math.round(x1 - x0), Math.round(y1 - y0 - titlebar)])
  }
  return out
}

function sameBox(a, b) {
  for (var i = 0; i < 4; i++) if (Math.abs(a[i] - b[i]) > TOL) return false
  return true
}

function centre(r) { return [r[0] + r[2] / 2, r[1] + r[3] / 2] }

function overlap(z, r) {
  var ox = Math.min(r[0] + r[2], z[0] + z[2]) - Math.max(r[0], z[0])
  var oy = Math.min(r[1] + r[3], z[1] + z[3]) - Math.max(r[1], z[1])
  return Math.max(ox, 0) * Math.max(oy, 0)
}

// The zone to snap to. win: [x, y, w, h]. Returns { zone, inZone } where zone is
// null when the window is already at the edge of the layout in that direction.
function pickZone(zones, win, dir) {
  var d = DIRS[dir]
  var inZone = null
  for (var i = 0; i < zones.length; i++) if (sameBox(zones[i], win)) { inZone = zones[i]; break }
  var ref = centre(inZone || win)
  var best = null, bestScore = null
  for (var j = 0; j < zones.length; j++) {
    var z = zones[j]
    if (z === inZone) continue
    var c = centre(z)
    var along = (c[0] - ref[0]) * d[0] + (c[1] - ref[1]) * d[1]
    var across = Math.abs((c[0] - ref[0]) * d[1]) + Math.abs((c[1] - ref[1]) * d[0])
    if (along <= TOL) continue
    var score = along + 2 * across
    if (bestScore === null || score < bestScore) { best = z; bestScore = score }
  }
  if (best === null && !inZone) {
    var most = -1
    for (var k = 0; k < zones.length; k++) {
      var o = overlap(zones[k], win)
      if (o > most) { most = o; best = zones[k] }
    }
  }
  return { zone: best, inZone: inZone }
}

// The pre-snap size to remember: a window already in a zone keeps the size it
// had before its first snap; a floating one remembers its size; a tiled one, or
// one found already sitting in a zone with no earlier row, has none (0 0), so the
// drag-out falls back to Omarchy's default float size.
function origSize(prevRow, inZone, floating, win) {
  if (prevRow && inZone) return [prevRow[0], prevRow[1]]
  if (inZone) return [0, 0]   // already in a zone (e.g. an app that reopened there): size unknown
  if (floating) return [win[2], win[3]]
  return [0, 0]
}

function nextLayoutIndex(layouts, currentId, dir) {
  var n = layouts.length
  if (n === 0) return -1
  var idx = -1
  for (var i = 0; i < n; i++) if (layouts[i].id === currentId) { idx = i; break }
  if (dir === "prev") return (idx - 1 + n) % n
  return (idx + 1) % n
}

// A plain-words name for a zone given as fractions [x, y, w, h]: "Left half",
// "Right two thirds", "Top right", "Whole screen". A zone may carry its own name
// instead; this is the fallback for layouts that do not.
var SIZE_WORDS = [
  [1 / 4, "quarter"], [1 / 3, "third"], [1 / 2, "half"],
  [2 / 3, "two thirds"], [3 / 4, "three quarters"]
]

function sizeWord(fraction) {
  for (var i = 0; i < SIZE_WORDS.length; i++)
    if (Math.abs(SIZE_WORDS[i][0] - fraction) < 0.02) return SIZE_WORDS[i][1]
  return Math.round(fraction * 100) + "%"
}

function zoneName(zone) {
  var x = zone[0], y = zone[1], w = zone[2], h = zone[3], EPS = 0.02
  var fullW = w > 1 - EPS, fullH = h > 1 - EPS
  if (fullW && fullH) return "Whole screen"
  var horiz = x < EPS ? "Left" : (x + w > 1 - EPS ? "Right" : "Middle")
  var vert = y < EPS ? "Top" : (y + h > 1 - EPS ? "Bottom" : "Middle")
  if (fullW) return vert + " " + sizeWord(h)
  if (fullH) return horiz + " " + sizeWord(w)
  if (horiz !== "Middle" && vert !== "Middle") return vert + " " + horiz.toLowerCase()
  if (horiz === "Middle" && vert === "Middle") return "Center"
  return horiz === "Middle" ? vert + " middle" : horiz + " middle"
}

// ── Keys ─────────────────────────────────────────────────────────────────────
// Omadjinn registers these with Hyprland itself (hypr/keys.lua), so nobody edits a
// config file. ALT is the anchor: Omarchy keeps SUPER for itself. A user can change
// or turn off any of them with a "keys" entry in config.json, e.g. { "keys": { "menu": "ALT + M", "settings": "" } }.
var KEY_ACTIONS = [
  { id: "snapLeft",   key: "ALT + LEFT",   cmd: "snap left",    label: "Snap window left" },
  { id: "snapRight",  key: "ALT + RIGHT",  cmd: "snap right",   label: "Snap window right" },
  { id: "snapUp",     key: "ALT + UP",     cmd: "snap up",      label: "Snap window up" },
  { id: "snapDown",   key: "ALT + DOWN",   cmd: "snap down",    label: "Snap window down" },
  { id: "menu",       key: "ALT + C",      cmd: "menuFocused",  label: "Menu for the focused window" },
  { id: "layoutPrev", key: "ALT + comma",  cmd: "cycle prev",   label: "Previous layout" },
  { id: "layoutNext", key: "ALT + period", cmd: "cycle next",   label: "Next layout" },
  { id: "settings",   key: "ALT + S",      cmd: "toggle",       label: "Settings" }
]

var MOD_BITS = { SHIFT: 1, CTRL: 4, ALT: 8, SUPER: 64 }
var MOD_ORDER = ["SUPER", "CTRL", "SHIFT", "ALT"]

// "alt+Left" -> { mods: ["ALT"], key: "LEFT", text: "ALT + LEFT", mask: 8 }, or null if it
// is not modifiers plus one plain key name. The text goes into Lua source, so only this safe form passes.
function parseKey(text) {
  var parts = String(text === undefined || text === null ? "" : text).split("+").map(function(p) { return p.trim() })
  if (parts.length < 1 || parts.length > 5) return null
  var key = parts.pop()
  if (!/^[A-Za-z0-9_]{1,24}$/.test(key)) return null
  var mods = [], mask = 0
  for (var i = 0; i < parts.length; i++) {
    var m = parts[i].toUpperCase()
    if (m === "CONTROL") m = "CTRL"
    if (m === "WIN" || m === "META") m = "SUPER"
    if (!(m in MOD_BITS)) return null
    if (mods.indexOf(m) < 0) { mods.push(m); mask |= MOD_BITS[m] }
  }
  mods.sort(function(a, b) { return MOD_ORDER.indexOf(a) - MOD_ORDER.indexOf(b) })
  var keyName = /^[A-Za-z]$/.test(key) ? key.toUpperCase() : key
  return { mods: mods, key: keyName, text: mods.concat([keyName]).join(" + "), mask: mask }
}

// The keys to register: each action's default, or the user's choice from config.keys
// ("" turns it off; something unreadable is skipped). `skip` maps action ids to true to leave out.
function keysFor(config, skip) {
  var chosen = (config && config.keys && typeof config.keys === "object") ? config.keys : {}
  var out = []
  for (var i = 0; i < KEY_ACTIONS.length; i++) {
    var a = KEY_ACTIONS[i]
    if (skip && skip[a.id]) continue
    var want = (a.id in chosen) ? chosen[a.id] : a.key
    if (want === "") continue
    var parsed = parseKey(want)
    if (!parsed) continue
    out.push({ id: a.id, key: parsed.text, cmd: a.cmd, label: a.label })
  }
  return out
}

// What already holds this key in Hyprland's live bind list (`hyprctl -j binds`), or null.
// Binds whose description starts with "Omadjinn: " are ours and do not count; a user's own
// bind for the same key does, even if its description mentions Omadjinn.
function keyConflict(binds, text) {
  var want = parseKey(text)
  if (!want || !Array.isArray(binds)) return null
  for (var i = 0; i < binds.length; i++) {
    var b = binds[i]
    if (String(b.description || "").indexOf("Omadjinn: ") === 0) continue
    if (b.modmask === want.mask && String(b.key || "").toLowerCase() === want.key.toLowerCase())
      return String(b.description || "another binding")
  }
  return null
}

// Why a layout can't be used, or "" when it is fine. A layout needs an id and a list of
// zones; each zone is [x, y, w, h] as fractions of the screen, inside 0 to 1, with a size.
function layoutProblem(layout) {
  if (!layout || typeof layout !== "object") return "not a layout"
  var id = (typeof layout.id === "string" && layout.id !== "") ? layout.id : "(no id)"
  if (id === "(no id)") return id + ": needs an id"
  if (!Array.isArray(layout.zones) || layout.zones.length === 0) return id + ": needs a list of zones"
  var e = 0.001
  for (var i = 0; i < layout.zones.length; i++) {
    var z = layout.zones[i], n = "zone " + (i + 1)
    if (!Array.isArray(z) || z.length !== 4) return id + ": " + n + " needs four numbers [x, y, w, h]"
    for (var j = 0; j < 4; j++) if (typeof z[j] !== "number" || !isFinite(z[j])) return id + ": " + n + " has a value that is not a number"
    if (z[0] < -e || z[1] < -e) return id + ": " + n + " starts off the screen"
    if (z[2] <= 0 || z[3] <= 0) return id + ": " + n + " has no size"
    if (z[0] + z[2] > 1 + e || z[1] + z[3] > 1 + e) return id + ": " + n + " runs past the edge of the screen"
  }
  return ""
}

// Splits a list of layouts into the usable ones and the problems found (one line each).
function checkLayouts(list) {
  var ok = [], problems = [], seen = {}
  for (var i = 0; i < list.length; i++) {
    var p = layoutProblem(list[i])
    if (p === "" && seen[list[i].id]) p = list[i].id + ": the id is used twice"
    if (p === "") { ok.push(list[i]); seen[list[i].id] = true } else problems.push(p)
  }
  return { ok: ok, problems: problems }
}

// ── Split-line editor ────────────────────────────────────────────────────────
// A layout the editor can draw is a tree of splits. A leaf is one zone. A split cuts its
// rectangle in two: dir "v" cuts with a vertical line (a is the left part, b the right),
// dir "h" with a horizontal line (a on top, b below); `at` is where, 0 to 1 across the
// rectangle being cut. A path is a list of 0 (a) and 1 (b) from the root to a node.
// Layouts that no run of straight cuts can make (overlaps, pinwheels) have no tree; they
// stay editable in layouts.json.

var MIN_ZONE = 0.05   // smallest zone side, as a fraction of the screen
var SNAP_STEPS = 12   // split lines snap to twelfths: halves, thirds, quarters and sixths

function leaf() { return { leaf: true } }

function round4(v) { return Math.round(v * 10000) / 10000 }

// The zones [x, y, w, h] of a tree, left to right and top to bottom as the tree is read.
function treeToZones(node, rect) {
  rect = rect || [0, 0, 1, 1]
  if (!node || node.leaf) return [[round4(rect[0]), round4(rect[1]), round4(rect[2]), round4(rect[3])]]
  var a, b
  if (node.dir === "v") {
    var x = rect[0] + node.at * rect[2]
    a = [rect[0], rect[1], x - rect[0], rect[3]]
    b = [x, rect[1], rect[0] + rect[2] - x, rect[3]]
  } else {
    var y = rect[1] + node.at * rect[3]
    a = [rect[0], rect[1], rect[2], y - rect[1]]
    b = [rect[0], y, rect[2], rect[1] + rect[3] - y]
  }
  return treeToZones(node.a, a).concat(treeToZones(node.b, b))
}

function sameZones(p, q) {
  if (p.length !== q.length) return false
  var used = {}
  for (var i = 0; i < p.length; i++) {
    var found = false
    for (var j = 0; j < q.length && !found; j++) {
      if (used[j]) continue
      var ok = true
      for (var k = 0; k < 4; k++) if (Math.abs(p[i][k] - q[j][k]) > 0.002) ok = false
      if (ok) { used[j] = true; found = true }
    }
    if (!found) return false
  }
  return true
}

// The tree for a list of zones, or null when the zones are not made by straight cuts
// across the whole screen (or do not cover it exactly).
function zonesToTree(zones) {
  var e = 0.002
  function build(rects, region) {
    if (rects.length === 1) return leaf()
    var dirs = ["v", "h"]
    for (var d = 0; d < 2; d++) {
      var vert = dirs[d] === "v"
      var lo = vert ? 0 : 1, size = vert ? 2 : 3
      var origin = region[lo], span = region[size]
      var cands = []
      for (var i = 0; i < rects.length; i++) {
        var c = rects[i][lo]
        if (c > origin + e && c < origin + span - e) cands.push(c)
      }
      for (var ci = 0; ci < cands.length; ci++) {
        var cut = cands[ci], first = [], second = [], ok = true
        for (var k = 0; k < rects.length; k++) {
          var r = rects[k]
          if (r[lo] + r[size] <= cut + e) first.push(r)
          else if (r[lo] >= cut - e) second.push(r)
          else { ok = false; break }
        }
        if (!ok || first.length === 0 || second.length === 0) continue
        var regA = region.slice(), regB = region.slice()
        regA[size] = cut - origin
        regB[lo] = cut; regB[size] = origin + span - cut
        var ta = build(first, regA), tb = build(second, regB)
        if (ta && tb) return { dir: dirs[d], at: round4((cut - origin) / span), a: ta, b: tb }
      }
    }
    return null
  }
  if (!Array.isArray(zones) || zones.length === 0) return null
  var tree = build(zones, [0, 0, 1, 1])
  if (!tree) return null
  return sameZones(treeToZones(tree), zones) ? tree : null
}

function nodeAt(tree, path) {
  var n = tree
  for (var i = 0; i < path.length; i++) { if (!n || n.leaf) return null; n = path[i] === 0 ? n.a : n.b }
  return n
}

// The screen rectangle a node covers.
function nodeRect(tree, path) {
  var rect = [0, 0, 1, 1], n = tree
  for (var i = 0; i < path.length; i++) {
    if (!n || n.leaf) return null
    var x, y
    if (n.dir === "v") {
      x = rect[0] + n.at * rect[2]
      rect = path[i] === 0 ? [rect[0], rect[1], x - rect[0], rect[3]] : [x, rect[1], rect[0] + rect[2] - x, rect[3]]
    } else {
      y = rect[1] + n.at * rect[3]
      rect = path[i] === 0 ? [rect[0], rect[1], rect[2], y - rect[1]] : [rect[0], y, rect[2], rect[1] + rect[3] - y]
    }
    n = path[i] === 0 ? n.a : n.b
  }
  return rect
}

function cloneTree(t) { return JSON.parse(JSON.stringify(t)) }

// A copy of the tree with `fn` applied to the node at `path` (fn returns its replacement).
function changeAt(tree, path, fn) {
  var out = cloneTree(tree)
  if (path.length === 0) return fn(out)
  var parent = nodeAt(out, path.slice(0, -1))
  if (!parent || parent.leaf) return out
  var key = path[path.length - 1] === 0 ? "a" : "b"
  parent[key] = fn(parent[key])
  return out
}

// Cut the zone at `path` in two, in the middle. A zone too small to cut is left alone.
function splitZone(tree, path, dir) {
  var r = nodeRect(tree, path), n = nodeAt(tree, path)
  if (!r || !n || !n.leaf) return tree
  if ((dir === "v" ? r[2] : r[3]) < MIN_ZONE * 2 - 0.0001) return tree
  return changeAt(tree, path, function() { return { dir: dir, at: 0.5, a: leaf(), b: leaf() } })
}

// Join everything under the split at `path` back into one zone.
function mergeSplit(tree, path) {
  var n = nodeAt(tree, path)
  if (!n || n.leaf) return tree
  return changeAt(tree, path, leaf)
}

// Move a split so its line sits at `coord` (0 to 1 across the whole screen), snapped to
// twelfths and kept clear of the ends so neither side is thinner than MIN_ZONE.
function moveSplit(tree, path, coord) {
  var n = nodeAt(tree, path), r = nodeRect(tree, path)
  if (!n || n.leaf || !r) return tree
  var lo = n.dir === "v" ? r[0] : r[1], span = n.dir === "v" ? r[2] : r[3]
  var snapped = Math.round(coord * SNAP_STEPS) / SNAP_STEPS
  var abs = Math.max(lo + MIN_ZONE, Math.min(lo + span - MIN_ZONE, snapped))
  if (lo + span - lo < MIN_ZONE * 2) return tree
  return changeAt(tree, path, function(node) { node.at = round4((abs - lo) / span); return node })
}

// Every split line, for drawing and hit tests: its path, direction, and ends in 0 to 1 screen units.
function splitLines(tree) {
  var out = []
  function walk(n, path, rect) {
    if (!n || n.leaf) return
    if (n.dir === "v") {
      var x = rect[0] + n.at * rect[2]
      out.push({ path: path, dir: "v", x0: x, y0: rect[1], x1: x, y1: rect[1] + rect[3] })
      walk(n.a, path.concat([0]), [rect[0], rect[1], x - rect[0], rect[3]])
      walk(n.b, path.concat([1]), [x, rect[1], rect[0] + rect[2] - x, rect[3]])
    } else {
      var y = rect[1] + n.at * rect[3]
      out.push({ path: path, dir: "h", x0: rect[0], y0: y, x1: rect[0] + rect[2], y1: y })
      walk(n.a, path.concat([0]), [rect[0], rect[1], rect[2], y - rect[1]])
      walk(n.b, path.concat([1]), [rect[0], y, rect[2], rect[1] + rect[3] - y])
    }
  }
  walk(tree, [], [0, 0, 1, 1])
  return out
}

// Every zone with its path, for drawing and picking in the editor.
function leafZones(tree) {
  var out = []
  function walk(n, path, rect) {
    if (!n || n.leaf) { out.push({ path: path, rect: rect }); return }
    var x, y
    if (n.dir === "v") {
      x = rect[0] + n.at * rect[2]
      walk(n.a, path.concat([0]), [rect[0], rect[1], x - rect[0], rect[3]])
      walk(n.b, path.concat([1]), [x, rect[1], rect[0] + rect[2] - x, rect[3]])
    } else {
      y = rect[1] + n.at * rect[3]
      walk(n.a, path.concat([0]), [rect[0], rect[1], rect[2], y - rect[1]])
      walk(n.b, path.concat([1]), [rect[0], y, rect[2], rect[1] + rect[3] - y])
    }
  }
  walk(tree, [], [0, 0, 1, 1])
  return out
}
