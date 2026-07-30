import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import test from "node:test";

const root = path.resolve(import.meta.dirname, "..");
const read = (file: string) => readFileSync(path.join(root, file), "utf8");

test("formula styles use stable fluid wrappers without changing KaTeX metrics", () => {
  const astro = read("src/components/KaTeXMath.astro");
  const react = read("src/components/RenderedMath.tsx");
  const manualCss = read("src/styles/manual.css");
  const home = read("src/components/HomePortal.astro");
  const welcomeCss = home.match(/<style>\s*([\s\S]*?)<\/style>/)?.[1] ?? "";
  const retiredSelectorPattern = new RegExp(
    `${["m", "jx"].join("")}|${["math", "jax"].join("")}|\\.tex-`,
    "i",
  );

  for (const [name, source] of [["Astro", astro], ["React", react]] as const) {
    assert.match(source, /\bformula-math\b/, `${name} wrapper must expose formula-math`);
    assert.match(
      source,
      /display\s*\?\s*["']formula-display["']\s*:\s*["']formula-inline["']/,
      `${name} wrapper must distinguish formula-display from formula-inline`,
    );
    assert.doesNotMatch(source, /\btex-(?:math|inline|display)\b/, `${name} wrapper must not emit tex-* classes`);
  }

  assert.doesNotMatch(
    manualCss,
    retiredSelectorPattern,
    "manual.css must not retain retired-renderer or legacy tex-* selectors",
  );
  assert.match(manualCss, /\.formula-math\b/, "manual.css must style the stable formula wrapper");
  assert.match(manualCss, /\.formula-display\b/, "manual.css must style display formula wrappers");
  assert.match(manualCss, /\.katex\b/, "manual.css must integrate the KaTeX root");
  assert.match(manualCss, /\.katex-display\b/, "manual.css must integrate KaTeX displays");

  // Custom CSS may target only KaTeX's public roots, never internal glyph/layout classes.
  const katexClasses = [...manualCss.matchAll(/\.katex(?:-[\w-]+)?\b/g)]
    .map((match) => match[0]);
  assert.deepEqual(
    new Set(katexClasses),
    new Set([".katex", ".katex-display"]),
    "custom styles must not target KaTeX internals",
  );

  const cssRules = [...`${manualCss}\n${welcomeCss}`.matchAll(/([^{}]+)\{([^{}]*)\}/g)]
    .map((match) => ({ selector: match[1].trim(), body: match[2] }));
  for (const { selector, body } of cssRules.filter(({ selector }) => /\.katex\b/.test(selector))) {
    assert.doesNotMatch(
      body,
      /(?:font-size|transform|zoom)\s*:/i,
      `${selector} must preserve KaTeX script, fraction, and accent metrics`,
    );
  }

  const formulaScrollers = cssRules
    .filter(({ selector, body }) =>
      /formula-|katex|math-strip|elevate-direct-coefficient-scroll/.test(selector)
      && /overflow(?:-x|-inline)?\s*:\s*(?:auto|scroll)/i.test(body))
    .map(({ selector }) => selector);
  assert.deepEqual(
    formulaScrollers,
    [".elevate-direct-coefficient-scroll"],
    "only the direct elevation coefficient formula may scroll horizontally",
  );

  const welcomeFormulaRules = cssRules
    .filter(({ selector }) => /\.math-strip(?:--stacked|__row)?\b/.test(selector))
    .map(({ selector, body }) => `${selector}{${body}}`)
    .join("\n");
  assert.match(
    welcomeFormulaRules,
    /inline-size\s*:\s*(?:min|max|clamp)\([^;]*(?:%|vw|rem)/i,
    "Welcome Step 01 must size against available width",
  );
  assert.match(
    welcomeFormulaRules,
    /font-size\s*:\s*clamp\(/i,
    "Welcome Step 01 must scale formula size fluidly",
  );
  assert.match(
    welcomeFormulaRules,
    /display\s*:\s*(?:grid|flex)/i,
    "Welcome Step 01 multiline grouping must use a fluid layout container",
  );
});
