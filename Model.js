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
