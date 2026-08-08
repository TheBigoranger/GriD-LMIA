import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import path from "node:path";
import test from "node:test";

import { certificateSources } from "../src/data/certificate-data.ts";
import { renderMath } from "../src/lib/katex-renderer.js";

const root = path.resolve(import.meta.dirname, "..");
const components = path.join(root, "src/components");
const read = (file: string) => readFileSync(path.join(components, file), "utf8");

test("Astro renders formulas at build time and React islands never load the renderer", () => {
  const retiredRenderer = ["math", "jax"].join("");
  const retiredComponent = ["Math", "Jax", "Math"].join("");
  const retiredPattern = new RegExp(retiredRenderer, "i");
  const astroPath = path.join(components, "KaTeXMath.astro");
  const reactPresenterPath = path.join(components, "RenderedMath.tsx");
  assert.ok(existsSync(astroPath), "the Astro KaTeXMath wrapper must exist");
  assert.ok(existsSync(reactPresenterPath), "the pure React markup presenter must exist");
  assert.equal(
    existsSync(path.join(components, "KaTeXMath.tsx")),
    false,
    "the React source tree must not retain a client formula-renderer entry point",
  );

  const astro = read("KaTeXMath.astro");
  assert.match(
    astro,
    /import\s*\{\s*renderMath\s*\}\s*from\s*["']\.\.\/lib\/katex-renderer\.js["']/,
    "the Astro wrapper must import the build-time renderMath function",
  );
  assert.match(
    astro,
    /\brenderMath\(\s*tex\s*,\s*\{\s*displayMode:\s*display\s*,?\s*\}\s*\)/s,
    "the Astro wrapper must render the current TeX and display mode at build time",
  );
  assert.match(
    astro,
    /\bset:html=\{\w+\}/,
    "the Astro wrapper must emit trusted shared-renderer markup",
  );

  // Preserve the established default Astro consumer interface.
  for (const file of ["HomePortal.astro", "JourneyCurve.astro"]) {
    const source = read(file);
    assert.match(
      source,
      /import\s+KaTeXMath\s+from\s+["']\.\/KaTeXMath\.astro["']/,
      `${file} must import the Astro KaTeX wrapper`,
    );
    assert.match(source, /<KaTeXMath\b/, `${file} must render formulas through KaTeXMath`);
  }

  const reactFiles = readdirSync(components, { recursive: true })
    .map(String)
    .filter((file) => file.endsWith(".tsx"));
  const clientRendererPattern =
    /from\s*["'](?:katex(?:\/[^"']*)?|[^"']*katex-renderer(?:\.js)?)[\"']|\brenderMath\s*\(|\brenderToString\s*\(/i;
  assert.ok(reactFiles.length > 0, "the React island audit must inspect at least one component");
  const rendererOffenders = reactFiles.filter((file) => clientRendererPattern.test(read(file)));
  assert.deepEqual(
    rendererOffenders,
    [],
    "React islands must not import or execute a TeX renderer",
  );

  assert.equal(
    existsSync(path.join(components, `${retiredComponent}.astro`)),
    false,
    "the retired Astro wrapper must be removed",
  );
  assert.equal(
    existsSync(path.join(components, `${retiredComponent}.tsx`)),
    false,
    "the retired React wrapper must be removed",
  );

  const componentFiles = readdirSync(components, { recursive: true })
    .map(String)
    .filter((file) => /\.(astro|tsx?)$/.test(file));
  for (const file of componentFiles) {
    assert.doesNotMatch(
      read(file),
      retiredPattern,
      `${file.replaceAll("\\", "/")} must not reference the retired renderer`,
    );
  }
});

test("every interactive certificate state renders without formula SVG", () => {
  const flow = read("CertificateFlow.astro");
  const formulaSources = certificateSources.flatMap((source) => [
    ...source.formula,
    source.cardFormula,
  ]);

  for (const tex of formulaSources) {
    assert.doesNotMatch(
      renderMath(tex, { displayMode: true }),
      /<svg(?:\s|>)/i,
      `certificate formula must use HTML/CSS-compatible accents: ${tex}`,
    );
  }
  assert.doesNotMatch(
    flow,
    /\\widetilde\b/,
    "the compact certificate flow must not use KaTeX's SVG-producing wide tilde",
  );
});
