import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import test from "node:test";

const root = path.resolve(import.meta.dirname, "..");
const read = (file: string) => readFileSync(path.join(root, file), "utf8");

test("acceptance scripts verify static local KaTeX rendering at every target width", () => {
  const visual = read("scripts/check-visual-contract.mjs");
  const geometry = read("scripts/check-rendered-geometry.mjs");
  const legacyMath = new RegExp(
    `${["math", "jax"].join("")}|${["m", "jx"].join("")}|\\.tex-(?:math|inline|display)\\b`,
    "i",
  );

  assert.doesNotMatch(visual, legacyMath, "visual acceptance must not reference retired math code");
  assert.doesNotMatch(geometry, legacyMath, "geometry acceptance must not reference retired math code");

  for (const file of [
    "KaTeXMath.astro",
    "RenderedMath.tsx",
    "katex-renderer.js",
    "katex-options.js",
    "package.json",
    "package-lock.json",
    "astro.config.mjs",
  ]) {
    assert.match(visual, new RegExp(file.replaceAll(".", "\\.")), `visual acceptance must inspect ${file}`);
  }
  assert.match(visual, /katex\/dist\/katex\.min\.css/, "visual acceptance must require local KaTeX CSS");
  assert.match(
    visual,
    /katex[\s\S]{0,300}(?:https?|external)|(?:https?|external)[\s\S]{0,300}katex/i,
    "visual acceptance must reject external KaTeX URLs",
  );
  assert.match(visual, /katex-html/, "visual acceptance must require KaTeX HTML output");
  assert.match(visual, /htmlAndMathml|<math/i, "visual acceptance must require MathML output");
  assert.match(
    visual,
    /formula[\s\S]{0,200}<svg|<svg[\s\S]{0,200}formula/i,
    "visual acceptance must reject SVG formula output",
  );
  for (const token of ["renderMath", "set:html", "dangerouslySetInnerHTML", "useEffect"]) {
    assert.match(visual, new RegExp(token), `visual acceptance must inspect synchronous SSR token ${token}`);
  }
  assert.match(
    visual,
    /(?:ready|readiness|queue)/i,
    "visual acceptance must reject deferred readiness or queue machinery",
  );

  // Both source and browser acceptance retain the same fluid viewport coverage.
  const widthMatrix = /320\s*,\s*390\s*,\s*700\s*,\s*768\s*,\s*1024\s*,\s*1280\s*,\s*1440/;
  assert.match(visual, widthMatrix, "visual acceptance must preserve the seven-width matrix");
  assert.match(geometry, widthMatrix, "geometry acceptance must preserve the seven-width matrix");
  assert.match(geometry, /defaultThemes\s*=\s*\["light",\s*"dark"\]/);

  for (const selector of [".formula-math", ".katex", ".katex-display"]) {
    assert.ok(geometry.includes(selector), `geometry acceptance must query ${selector}`);
  }
  for (const diagnostic of [
    "formula-render-count",
    "formula-readable",
    "formula-bounds",
    "formula-width",
    "formula-hydration",
    "formula-unexpected-multiline",
  ]) {
    assert.ok(geometry.includes(diagnostic), `geometry acceptance must retain ${diagnostic}`);
  }
  assert.match(
    geometry,
    /querySelectorAll\([^)]*\.katex[^)]*\)[\s\S]{0,500}(?:length\s*!==\s*1|length\s*===\s*1)/,
    "each formula wrapper must contain exactly one rendered KaTeX root",
  );
  assert.match(geometry, /document\.fonts\.ready/, "geometry acceptance must wait for local fonts");
  assert.ok(
    geometry.includes("formula-layout-shift"),
    "geometry acceptance must compare pre-font and post-font formula rectangles",
  );
  assert.ok(
    (geometry.match(/getBoundingClientRect\(\)/g) ?? []).length >= 2,
    "geometry acceptance must capture formula rectangles on both sides of font readiness",
  );
  assert.match(
    geometry,
    /page\.on\(["']request["'][\s\S]{0,500}(?:startsWith\(origin\)|new URL\([^)]*\)\.origin)/,
    "geometry acceptance must enforce same-origin requests",
  );
  assert.match(
    geometry,
    /katex[\s\S]{0,500}(?:\.css|css)|(?:\.css|css)[\s\S]{0,500}katex/i,
    "geometry acceptance must assert a built local KaTeX stylesheet",
  );
  assert.match(
    geometry,
    /katex[\s\S]{0,500}(?:woff2?|font)|(?:woff2?|font)[\s\S]{0,500}katex/i,
    "geometry acceptance must assert built local KaTeX fonts",
  );

  assert.ok(
    geometry.includes(".elevate-direct-coefficient-scroll, .solver-one-line"),
    "geometry acceptance must retain the two narrowly scoped formula scrollers",
  );
  assert.match(
    geometry,
    /const certificateStates\s*=\s*\[[\s\S]*Direct[\s\S]*Pólya[\s\S]*Putinar[\s\S]*SparseFullBox[\s\S]*FullBox/,
    "geometry acceptance must exercise every certificate tab state",
  );
  assert.match(
    geometry,
    /querySelector\(["']svg["']\)[\s\S]*certificate-formula-state/,
    "every hydrated certificate state must reject formula SVG",
  );
  for (const diagnostic of [
    "local-formula-scroll-bounds",
    "local-formula-scroll-required",
    "local-formula-scroll-unneeded",
  ]) {
    assert.ok(geometry.includes(diagnostic), `geometry acceptance must retain ${diagnostic}`);
  }
});

test("geometry captures a pre-font formula snapshot before network idle and font readiness", () => {
  const geometry = read("scripts/check-rendered-geometry.mjs");
  const routeLoopAt = geometry.lastIndexOf("for (const width of viewports)");
  const routeLoopEnd = geometry.indexOf("await auditRootWalkthroughs", routeLoopAt);
  assert.ok(routeLoopAt >= 0 && routeLoopEnd > routeLoopAt, "main route audit loop must remain present");
  const routeLoop = geometry.slice(routeLoopAt, routeLoopEnd);

  assert.match(
    routeLoop,
    /page\.goto\([^;]+waitUntil:\s*["']domcontentloaded["']/,
    "route navigation must expose formula geometry before network idle and font readiness",
  );
  const beforeFontsAt = routeLoop.indexOf("const beforeFonts = await formulaSnapshot(page)");
  const networkIdleAt = routeLoop.indexOf('page.waitForLoadState("networkidle")');
  const fontReadyAt = routeLoop.indexOf("document.fonts.ready");
  assert.ok(beforeFontsAt >= 0, "the route audit must capture a pre-font formula snapshot");
  assert.ok(networkIdleAt > beforeFontsAt, "network idle must occur after the pre-font snapshot");
  assert.ok(fontReadyAt > beforeFontsAt, "font readiness must occur after the pre-font snapshot");
});

test("font stability ignores unrelated document-flow movement", () => {
  const geometry = read("scripts/check-rendered-geometry.mjs");
  const comparisonStart = geometry.indexOf("function recordFontStability");
  const comparisonEnd = geometry.indexOf("async function inspect", comparisonStart);
  const comparison = geometry.slice(comparisonStart, comparisonEnd);

  assert.match(
    comparison,
    /formulaRect\.left\s*-\s*wrapperRect\.left/,
    "font stability must compare the formula position within its wrapper",
  );
  assert.match(
    comparison,
    /formulaRect\.top\s*-\s*wrapperRect\.top/,
    "font stability must not treat an image-driven document shift as a formula shift",
  );
});

test("geometry audits every KaTeX root while retaining custom wrapper contracts", () => {
  const geometry = read("scripts/check-rendered-geometry.mjs");
  const snapshotStart = geometry.indexOf("async function formulaSnapshot(page)");
  const snapshotEnd = geometry.indexOf("function recordHydrationStability", snapshotStart);
  const snapshot = geometry.slice(snapshotStart, snapshotEnd);
  assert.match(
    snapshot,
    /document\.querySelectorAll\(["']\.katex["']\)/,
    "formula snapshots must include unwrapped Markdown roots",
  );

  const inspectStart = geometry.indexOf("async function inspect(page)");
  const inspectEnd = geometry.indexOf("async function hydrateIslands", inspectStart);
  const inspect = geometry.slice(inspectStart, inspectEnd);
  const allRootsAt = inspect.search(
    /for\s*\(\s*const\s+formula\s+of\s+document\.querySelectorAll\(["']\.katex["']\)\s*\)/,
  );
  assert.ok(allRootsAt >= 0, "geometry inspection must iterate every KaTeX root directly");
  const wrapperAt = inspect.indexOf("document.querySelectorAll(\".formula-math\")", allRootsAt);
  const rootAudit = inspect.slice(allRootsAt, wrapperAt >= 0 ? wrapperAt : undefined);
  assert.match(rootAudit, /querySelector\(["']\.katex-html["']\)/, "every root must expose HTML output");
  assert.match(rootAudit, /querySelector\(["']math["']\)/, "every root must expose MathML output");
  assert.match(rootAudit, /querySelector\(["']svg["']\)/, "every root must be checked for forbidden SVG");
  assert.match(rootAudit, /getBoundingClientRect\(\)/, "every root must receive a bounds check");
  assert.match(
    rootAudit,
    /(?:display|visibility|opacity)/,
    "every root must receive a readability check",
  );

  assert.match(
    inspect,
    /for\s*\(\s*const\s+wrapper\s+of\s+document\.querySelectorAll\(["']\.formula-math["']\)\s*\)/,
    "custom formula wrapper checks must remain",
  );
  assert.match(
    inspect,
    /wrapper\.querySelectorAll\(["']\.katex["']\)[\s\S]{0,300}(?:length\s*!==\s*1|length\s*===\s*1)/,
    "custom wrappers must still contain exactly one rendered root",
  );
});
