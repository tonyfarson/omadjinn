// Run with: node tests/model.test.js   (Model.js is a QML library; load it as text.)
const fs = require("fs"), assert = require("assert")
const M = {}; new Function("exports", fs.readFileSync(__dirname + "/../Model.js", "utf8").replace(".pragma library", "") + "\nObject.assign(exports,{parseGap,zonesFor,pickZone,origSize,nextLayoutIndex,zoneName,KEY_ACTIONS,parseKey,keysFor,keyConflict})")(M)

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
assert(defaults.every(d => d.key.startsWith("ALT + ")))
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
console.log("model.test.js: keys ok")
