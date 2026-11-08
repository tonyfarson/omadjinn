#!/usr/bin/env node
// Pre-merge gate: our own version of the marketplace checks, run on the working tree.
// Needs a clone of omacom/omarchy-plugin-marketplace (Node 24+). Point MARKETPLACE_CLONE at it
// (default ~/Projects/github/omarchy-plugin-marketplace). Not a security audit.
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, relative } from "node:path";
import { pathToFileURL } from "node:url";

const root = new URL("..", import.meta.url).pathname;
const clone = process.env.MARKETPLACE_CLONE || join(homedir(), "Projects/github/omarchy-plugin-marketplace");
const results = [];
const add = (level, name, detail = "") => results.push({ level, name, detail });
const read = (p) => readFileSync(join(root, p), "utf8");

// --- 1. Marketplace structure (SUBMISSION.md "Check the repository")
const manifest = JSON.parse(read("manifest.json"));
for (const f of ["manifest.json", "README.md", "LICENSE"]) {
  existsSync(join(root, f)) ? add("ok", `root file ${f}`) : add("fail", `root file ${f} missing`);
}
/^[a-z0-9]+(\.[a-z0-9-]+)+$/.test(manifest.id) && !manifest.id.startsWith("omarchy.")
  ? add("ok", `plugin id ${manifest.id}`) : add("fail", "plugin id invalid or in omarchy.*", manifest.id);
for (const [kind, file] of Object.entries(manifest.entryPoints || {})) {
  existsSync(join(root, file)) ? add("ok", `entry point ${kind}: ${file}`) : add("fail", `entry point missing: ${file}`);
}
const readme = read("README.md");
/install/i.test(readme) ? add("ok", "README mentions install") : add("fail", "README has no install instructions");
/(remov|uninstall)/i.test(readme) ? add("ok", "README mentions removal") : add("fail", "README has no removal instructions");
const topChange = (read("CHANGELOG.md").match(/^## \[?v?(\d+\.\d+\.\d+)/m) || [])[1];
topChange === manifest.version
  ? add("ok", `CHANGELOG top entry matches manifest ${manifest.version}`)
  : add("fail", "CHANGELOG top entry does not match manifest version", `${topChange} vs ${manifest.version}`);

// --- 2. The marketplace's own security baseline, run on the working tree
const scanner = join(clone, "scripts/security-baseline-scanner.mjs");
if (!existsSync(scanner)) {
  add("fail", "marketplace clone not found; cannot run its baseline", clone);
} else {
  const { buildSecurityBaseline, isSecurityScanPath } = await import(pathToFileURL(scanner));
  const tracked = execFileSync("git", ["ls-files"], { cwd: root, encoding: "utf8" }).split("\n").filter(Boolean);
  const files = tracked.filter((p) => isSecurityScanPath(p)).map((p) => ({
    path: p, content: read(p),
    mode: (statSync(join(root, p)).mode & 0o111) ? "100755" : "100644",
  }));
  const head = execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim();
  const b = buildSecurityBaseline({
    repository: "tonyfarson/omadjinn", repoUrl: "https://github.com/tonyfarson/omadjinn",
    commitSha: head, files,
  });
  const caps = b.capabilities.map((c) => c.id || c).join(", ") || "none";
  const finds = b.findings.map((f) => f.id || f).join(", ") || "none";
  b.outcome === "passed"
    ? add("ok", `marketplace baseline: passed (${files.length} files scanned)`)
    : add(b.outcome === "needs-fixes" ? "fail" : "warn", `marketplace baseline: ${b.outcome}`, `findings: ${finds}; capabilities: ${caps}`);
  if (execFileSync("git", ["status", "--porcelain"], { cwd: root, encoding: "utf8" }).trim())
    add("warn", "working tree has uncommitted changes; the scan covers the files as they are now, the marketplace scans the commit");
}

// --- 3. Our own checks (not in the marketplace docs; best practice and our rules)
const qml = readdirSync(root).filter((f) => f.endsWith(".qml"));
// 3a. Text inputs: each must only exist while its UI is open. List every one for a human to confirm.
for (const f of qml) {
  read(f).split("\n").forEach((line, i) => {
    if (/^\s*(TextField|TextInput|TextArea)\s*\{/.test(line)) {
      const loaded = /Loader|sourceComponent/.test(read(f)) || f === "ZoneEditor.qml";
      add("review", `text input ${f}:${i + 1}`, loaded
        ? "confirm it lives inside a Loader that is active only while its UI is open"
        : "confirm it cannot exist while its panel is closed (a foreign clipboard offer can fill it)");
    }
  });
}
// 3b. Clipboard or process execution surface
for (const f of qml) {
  read(f).split("\n").forEach((line, i) => {
    if (/Clipboard|wl-paste|wl-copy|Process\s*\{|execDetached/.test(line))
      add("review", `clipboard/process use ${f}:${i + 1}`, line.trim());
  });
}
// 3c. Prime directive 2: no hard-coded colours in UI code
for (const f of qml) {
  read(f).split("\n").forEach((line, i) => {
    if (/#[0-9a-fA-F]{3,8}\b|color:\s*"(white|black|red|green|blue|gold|yellow)"/.test(line))
      add("fail", `hard-coded colour ${f}:${i + 1}`, line.trim());
  });
}
// 3d. Private details in public files
for (const f of execFileSync("git", ["ls-files"], { cwd: root, encoding: "utf8" }).split("\n").filter(Boolean)) {
  if (/\.(png|svg|jpg|webp)$/.test(f)) continue;
  read(f).split("\n").forEach((line, i) => {
    if (/\bkijo\b|\bnamahage\b|\/home\/tony/i.test(line)) add("warn", `private host/path in public file ${f}:${i + 1}`, line.trim().slice(0, 100));
  });
}

// --- Report
const order = { fail: 0, warn: 1, review: 2, ok: 3 };
for (const r of results.sort((a, b) => order[a.level] - order[b.level]))
  console.log(`${r.level.toUpperCase().padEnd(6)} ${r.name}${r.detail ? "  - " + r.detail : ""}`);
const fails = results.filter((r) => r.level === "fail").length;
const reviews = results.filter((r) => r.level === "review" || r.level === "warn").length;
console.log(`\n${fails} fail, ${reviews} to review by hand. ${fails ? "GATE: BLOCKED" : "GATE: no automatic blocker; confirm the review items"}`);
process.exit(fails ? 1 : 0);
