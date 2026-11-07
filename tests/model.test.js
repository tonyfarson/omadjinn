// Run with: node tests/model.test.js   (Model.js is a QML library; load it as text.)
const fs = require("fs"), assert = require("assert")
const M = {}; new Function("exports", fs.readFileSync(__dirname + "/../Model.js", "utf8").replace(".pragma library", "") + "\nObject.assign(exports,{parseGap,zonesFor,pickZone,origSize,nextLayoutIndex,zoneName,KEY_ACTIONS,parseKey,keysFor,keyConflict,layoutProblem,checkLayouts,treeToZones,zonesToTree,splitZone,mergeSplit,moveSplit,splitLines,nodeRect,nodeAt,leafZones,occupants})")(M)

// kijo's monitor: 3840x2160 at scale 1.5, bar reserves 30 at the top.
const mon = { x: -1280, y: -1440, width: 3840, height: 2160, scale: 1.5, reserved: [0, 30, 0, 0] }
const halves = [[0, 0, 0.5, 1], [0.5, 0, 0.5, 1]]

assert.deepStrictEqual(M.parseGap("5 5 5 5"), [5, 5, 5, 5])
assert.deepStrictEqual(M.parseGap("10"), [10, 10, 10, 10])
assert.deepStrictEqual(M.parseGap("1 2"), [1, 2, 1, 2])

// gaps off, titlebar 30: the zone starts under the bar and its titlebar.
let z = M.zonesFor(halves, mon, [0, 0, 0, 0], [0, 0, 0, 0], 30)
assert.deepStrictEqual(z[0], [-1280, -1380, 1280, 1380])
assert.deepStrictEqual(z[1], [0, -1380, 1280, 1380])

// gaps on (5 in / 10 out): 10 at the screen edges, 5 each side between zones.
z = M.zonesFor(halves, mon, [5, 5, 5, 5], [10, 10, 10, 10], 30)
assert.deepStrictEqual(z[0], [-1270, -1370, 1265, 1360])
assert.deepStrictEqual(z[1], [5, -1370, 1265, 1360])

// snapping right from the left zone lands in the right zone; at the edge: nothing.
assert.deepStrictEqual(M.pickZone(z, z[0], "right").zone, z[1])
assert.strictEqual(M.pickZone(z, z[1], "right").zone, null)
// a loose window takes the nearest zone in that direction, else the most overlapped.
assert.deepStrictEqual(M.pickZone(z, [-600, -900, 800, 600], "right").zone, z[1])
assert.deepStrictEqual(M.pickZone(z, [200, -900, 800, 600], "right").zone, z[1])

// pre-snap size: kept across re-snaps; tiled has none.
assert.deepStrictEqual(M.origSize([700, 500], z[0], true, z[0]), [700, 500])
assert.deepStrictEqual(M.origSize(null, z[0], true, z[0]), [0, 0])  // already in a zone, no row: unknown
assert.deepStrictEqual(M.origSize(null, null, true, [0, 0, 800, 600]), [800, 600])
assert.deepStrictEqual(M.origSize(null, null, false, [0, 0, 800, 600]), [0, 0])

const L = [{ id: "a" }, { id: "b" }, { id: "c" }]
assert.strictEqual(M.nextLayoutIndex(L, "a", "next"), 1)
assert.strictEqual(M.nextLayoutIndex(L, "c", "next"), 0)
assert.strictEqual(M.nextLayoutIndex(L, "a", "prev"), 2)
assert.strictEqual(M.nextLayoutIndex(L, "", "next"), 0)
console.log("model.test.js: ok")

// ── zone names
assert.strictEqual(M.zoneName([0, 0, 0.5, 1]), "Left half")
assert.strictEqual(M.zoneName([0.5, 0.5, 0.5, 0.5]), "Bottom right")
assert.strictEqual(M.zoneName([0, 0, 1, 1]), "Whole screen")
assert.strictEqual(M.zoneName([0.25, 0.25, 0.5, 0.5]), "Center")

// ── keys
const k = M.parseKey
assert.deepStrictEqual([k("alt + c").text, k("alt + c").mask], ["ALT + C", 8])
assert.strictEqual(k("Super+Ctrl+shift+left").text, "SUPER + CTRL + SHIFT + LEFT" .replace("LEFT", "left"))
assert.strictEqual(k("control + alt + x").mask, 12)
assert.strictEqual(k("ALT + comma").text, "ALT + comma")
for (const bad of ["", "ALT +", "ALT + C; os.exit()", 'ALT + "C"', "FOO + C", "ALT + a b", "A+B+C+D+E+F+G"]) assert.strictEqual(k(bad), null, bad)

// defaults: one key per action, no two the same, all valid and all on ALT
const defaults = M.keysFor({})
assert.strictEqual(defaults.length, M.KEY_ACTIONS.length)
assert.strictEqual(new Set(defaults.map(d => d.key)).size, defaults.length)
assert(defaults.every(d => d.key.split(" + ").includes("ALT")))
assert.strictEqual(defaults.find(d => d.id === "menu").key, "ALT + C")
// a user's choice replaces the default; "" turns it off; junk is skipped; skip leaves one out
const custom = M.keysFor({ keys: { menu: "super + m", settings: "", snapUp: "ALT + 1; boom" } }, { layoutNext: true })
assert.strictEqual(custom.find(d => d.id === "menu").key, "SUPER + M")
assert(!custom.some(d => ["settings", "snapUp", "layoutNext"].includes(d.id)))

// conflicts: another bind on the same modifiers and key; our own binds do not count
const binds = [
  { modmask: 8, key: "C", description: "Some app" },
  { modmask: 64, key: "C", description: "Universal copy" },
  { modmask: 8, key: "LEFT", description: "Omadjinn: Snap window left" },
  { modmask: 0, key: "mouse:273", description: "" },
]
assert.strictEqual(M.keyConflict(binds, "alt + c"), "Some app")
assert.strictEqual(M.keyConflict(binds, "SUPER + C"), "Universal copy")
assert.strictEqual(M.keyConflict(binds, "ALT + LEFT"), null)
assert.strictEqual(M.keyConflict(binds, "ALT + S"), null)
assert.strictEqual(M.keyConflict(null, "ALT + S"), null)
// a user's own bind that merely mentions Omadjinn still counts as a conflict
assert.strictEqual(M.keyConflict([{ modmask: 8, key: "C", description: "Omadjinn menu for the focused window" }], "ALT + C"), "Omadjinn menu for the focused window")
console.log("model.test.js: keys ok")

// layout checks
const good = { id: "thirds", zones: [[0, 0, 0.3333, 1], [0.3333, 0, 0.3333, 1], [0.6667, 0, 0.3333, 1]] }
assert.strictEqual(M.layoutProblem(good), "")
assert.match(M.layoutProblem({ zones: [[0, 0, 1, 1]] }), /needs an id/)
assert.match(M.layoutProblem({ id: "a" }), /list of zones/)
assert.match(M.layoutProblem({ id: "a", zones: [] }), /list of zones/)
assert.match(M.layoutProblem({ id: "a", zones: [[0, 0]] }), /four numbers/)
assert.match(M.layoutProblem({ id: "a", zones: [[0, 0, "x", 1]] }), /not a number/)
assert.match(M.layoutProblem({ id: "a", zones: [[-0.5, 0, 0.5, 1]] }), /off the screen/)
assert.match(M.layoutProblem({ id: "a", zones: [[0, 0, 0, 1]] }), /no size/)
assert.match(M.layoutProblem({ id: "a", zones: [[0, 0, 2, 1]] }), /past the edge/)
assert.match(M.layoutProblem(null), /not a layout/)
const checked = M.checkLayouts([good, { id: "bad", zones: [] }, good])
assert.strictEqual(checked.ok.length, 1)
assert.strictEqual(checked.problems.length, 2)
console.log("model.test.js: layouts ok")

// split-line editor
const shipped = JSON.parse(fs.readFileSync(__dirname + "/../layouts/default.json", "utf8")).layouts
for (const l of shipped) {
  const tree = M.zonesToTree(l.zones)
  assert.ok(tree, l.id + " has a tree")
  const back = M.treeToZones(tree)
  assert.strictEqual(back.length, l.zones.length, l.id)
  assert.strictEqual(M.layoutProblem({ id: l.id, zones: back }), "", l.id)
}
assert.strictEqual(M.zonesToTree([[0, 0, 0.7, 1], [0.5, 0, 0.5, 1]]), null)        // overlap
assert.strictEqual(M.zonesToTree([[0, 0, 0.5, 1]]), null)                           // does not cover the screen
assert.strictEqual(M.zonesToTree([[0, 0, 0.5, 0.5], [0.5, 0, 0.5, 0.5], [0, 0.5, 1, 0.5]]) !== null, true)
// pinwheel: no straight cut across the whole screen
assert.strictEqual(M.zonesToTree([[0, 0, 0.6, 0.4], [0.6, 0, 0.4, 0.6], [0.4, 0.6, 0.6, 0.4], [0, 0.4, 0.4, 0.6]]), null)
let t = { leaf: true }
t = M.splitZone(t, [], "v")
assert.deepStrictEqual(M.treeToZones(t), [[0, 0, 0.5, 1], [0.5, 0, 0.5, 1]])
t = M.splitZone(t, [1], "h")
assert.deepStrictEqual(M.treeToZones(t), [[0, 0, 0.5, 1], [0.5, 0, 0.5, 0.5], [0.5, 0.5, 0.5, 0.5]])
t = M.moveSplit(t, [], 0.3)                                // snaps to 4/12
assert.strictEqual(M.nodeAt(t, []).at, 0.3333)
t = M.moveSplit(t, [], 0.99)                               // kept off the end
assert.ok(M.nodeAt(t, []).at <= 0.95 + 1e-9)
t = M.moveSplit(t, [1], 0.5)                               // inner line, across the whole screen coordinate
assert.strictEqual(M.splitLines(t).length, 2)
t = M.mergeSplit(t, [1])
assert.strictEqual(M.treeToZones(t).length, 2)
// a zone too small to cut stays as it is
let tiny = { dir: "v", at: 0.05, a: { leaf: true }, b: { leaf: true } }
assert.strictEqual(M.splitZone(tiny, [0], "v"), tiny)
console.log("model.test.js: editor ok")
assert.strictEqual(M.leafZones(M.zonesToTree(shipped[2].zones)).length, shipped[2].zones.length)
console.log("model.test.js: leafZones ok")

// occupants
const zoneBox = [0, 40, 960, 500]
const win = (a, at, size, extra) => Object.assign({ address: a, mapped: true, hidden: false, floating: true, workspace: { id: 1 }, at, size, focusHistoryID: 0 }, extra || {})
const cl = [
  win("a", [0, 40], [960, 500], { focusHistoryID: 3 }),
  win("b", [2, 41], [958, 500], { focusHistoryID: 1 }),
  win("c", [960, 40], [960, 500]),                       // another zone
  win("d", [0, 40], [960, 500], { floating: false }),    // tiled
  win("e", [0, 40], [960, 500], { workspace: { id: 2 } }),
  win("f", [0, 40], [960, 500], { hidden: true }),
  win("self", [0, 40], [960, 500], { focusHistoryID: 0 })
]
assert.deepStrictEqual(M.occupants(cl, zoneBox, "self", 1).map(c => c.address), ["b", "a"])
assert.deepStrictEqual(M.occupants([], zoneBox, "self", 1), [])
assert.deepStrictEqual(M.occupants(null, zoneBox, "self", 1), [])
console.log("model.test.js: occupants ok")
