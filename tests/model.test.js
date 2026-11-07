// Run with: node tests/model.test.js   (Model.js is a QML library; load it as text.)
const fs = require("fs"), assert = require("assert")
const M = {}; new Function("exports", fs.readFileSync(__dirname + "/../Model.js", "utf8").replace(".pragma library", "") + "\nObject.assign(exports,{parseGap,zonesFor,pickZone,origSize,nextLayoutIndex})")(M)

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
