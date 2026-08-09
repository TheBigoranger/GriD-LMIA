import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import path from "node:path";
import test from "node:test";

const root = path.resolve(import.meta.dirname, "..");
const read = (file: string) => readFileSync(path.join(root, file), "utf8");
const sourceFiles = readdirSync(path.join(root, "src"), { recursive: true })
  .filter((file) => /\.(astro|css|js|md|mdx|ts|tsx)$/.test(String(file)))
  .map(String);
const sourceEntries = sourceFiles.map((file) => ({
  file: `src/${file.replaceAll("\\", "/")}`,
  source: read(`src/${file}`),
}));
const allSource = sourceEntries.map(({ source }) => source).join("\n");

function lineNumber(source: string, offset: number) {
  return source.slice(0, offset).split("\n").length;
}

function closingBrace(source: string, start: number) {
  let depth = 0;
  for (let index = start; index < source.length; index += 1) {
    if (source[index] === "{") depth += 1;
    if (source[index] === "}") {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return -1;
}

function unbracedBinomials() {
  const failures: string[] = [];
  let count = 0;

  for (const { file, source } of sourceEntries) {
    for (const match of source.matchAll(/\\binom\b/g)) {
      count += 1;
      const offset = match.index ?? 0;
      let cursor = offset + match[0].length;
      while (/\s/.test(source[cursor] ?? "")) cursor += 1;
      if (source[cursor] !== "{") {
        failures.push(`${file}:${lineNumber(source, offset)} first argument is not braced`);
        continue;
      }
      cursor = closingBrace(source, cursor) + 1;
      while (/\s/.test(source[cursor] ?? "")) cursor += 1;
      if (source[cursor] !== "{") {
        failures.push(`${file}:${lineNumber(source, offset)} second argument is not braced`);
      }
    }
  }
  return { count, failures };
}

test("uses build-time KaTeX with local CSS and no client fallback", () => {
  const packageJson = JSON.parse(read("package.json"));
  const packageLock = JSON.parse(read("package-lock.json"));
  const config = read("astro.config.mjs");
  const dependencies = packageJson.dependencies ?? {};
  const lockRoot = packageLock.packages[""]?.dependencies ?? {};
  const retiredRenderer = new RegExp(["math", "jax"].join(""), "i");

  // Direct dependencies make the renderer and both build plugins explicit, reproducible inputs.
  for (const dependency of ["katex", "remark-math", "rehype-katex"]) {
    assert.ok(
      Object.hasOwn(dependencies, dependency),
      `package.json must declare "${dependency}" as a direct dependency`,
    );
    assert.ok(
      Object.hasOwn(lockRoot, dependency),
      `package-lock.json must lock "${dependency}" as a direct dependency`,
    );
  }

  assert.match(config, /import\s+remarkMath\s+from\s+["']remark-math["']/);
  assert.match(config, /import\s+rehypeKatex\s+from\s+["']rehype-katex["']/);
  assert.match(config, /remarkPlugins:\s*\[[^\]]*\bremarkMath\b[^\]]*\]/s);
  assert.match(config, /rehypePlugins:\s*\[[^\]]*\brehypeKatex\b[^\]]*\]/s);
  assert.match(config, /["']katex\/dist\/katex\.min\.css["']/);
  assert.doesNotMatch(config, /https?:\/\/[^"'`\s]*katex/i);

  // A clean renderer boundary forbids dependency, plugin, and injected runtime fallbacks.
  assert.deepEqual(
    Object.keys(dependencies).filter((dependency) => retiredRenderer.test(dependency)),
    [],
  );
  assert.deepEqual(
    Object.keys(lockRoot).filter((dependency) => retiredRenderer.test(dependency)),
    [],
  );
  assert.doesNotMatch(config, retiredRenderer);
});

test("ships local CSS and font payloads without formula SVG assets", () => {
  const packageRoot = path.join(root, "node_modules/katex/dist");
  const stylesheet = readFileSync(path.join(packageRoot, "katex.min.css"), "utf8");

  assert.ok(existsSync(path.join(packageRoot, "fonts/KaTeX_Main-Regular.woff2")));
  assert.ok(existsSync(path.join(packageRoot, "fonts/KaTeX_Math-Italic.woff2")));
  assert.ok(existsSync(path.join(packageRoot, "fonts/KaTeX_AMS-Regular.woff2")));
  assert.match(stylesheet, /url\(fonts\/KaTeX_Main-Regular\.woff2\)/);
  assert.doesNotMatch(stylesheet, /url\([^)]*https?:|<svg/i);
});

test("preserves intrinsic fraction, script, and accent metrics", () => {
  const options = read("src/lib/katex-options.js");
  const css = read("src/styles/manual.css");

  assert.match(options, /output:\s*"htmlAndMathml"/);
  assert.match(options, /throwOnError:\s*true/);
  assert.match(options, /strict:\s*"error"/);
  assert.doesNotMatch(
    css,
    /\.katex(?:-[\w-]+)?[^{]*\{[^}]*(?:font-size|font-family|transform|zoom)\s*:/gis,
  );
});

test("authors the Welcome DPD-LMI as one unbroken centered display", () => {
  const homePortal = read("src/components/HomePortal.astro");
  const firstStep = homePortal.slice(
    homePortal.indexOf('number: "01"'),
    homePortal.indexOf('number: "02"'),
  );
  const css = read("src/styles/manual.css");

  assert.match(
    firstStep,
    /math:\s*"\\\\mathcal F\(\\\\vect\\\\rho,\\\\dot\{\\\\vect\\\\rho\};y\)=F_0\+\\\\sum_\{k=1\}\^\{N\}F_ky_k\+\\\\sum_\{k=1\}\^\{N\}\\\\sum_\{s=1\}\^\{\\\\ell\}\\\\dot\\\\rho_sT_\{k,s\}\\\\frac\{\\\\partial y_k\}\{\\\\partial\\\\rho_s\}\\\\preceq0\."/,
  );
  assert.match(firstStep, /All coefficient functions in the residual are evaluated at/);
  assert.match(firstStep, /oneLine:\s*true/);
  assert.doesNotMatch(firstStep, /\\begin\{(?:aligned|gathered|split)\}|\\\\\\\\/);
  assert.doesNotMatch(
    css,
    /\.katex(?:-[\w-]+)?[^{]*\{[^}]*(?:font-size|transform|zoom)\s*:/gis,
  );
});

test("Welcome stages 02 and 03 keep semantic formulas paired through responsive reflow", () => {
  const home = read("src/components/HomePortal.astro");
  const explorer = read("src/components/CellStorageExplorer.tsx");
  const secondStep = home.slice(home.indexOf('number: "02"'), home.indexOf('number: "03"'));
  const thirdStep = home.slice(home.indexOf('number: "03"'), home.indexOf('number: "04"'));

  assert.match(secondStep, /annotatedMath:\s*\[/);
  assert.match(secondStep, /label:\s*\["axis-",\s*\{\s*tex:\s*"s"\s*\},\s*" physical nodes"\]/);
  assert.match(secondStep, /label:[^\n]*physical cell selected by[^\n]*vect c/);
  assert.doesNotMatch(secondStep, /\\underbrace|\\begin\{(?:aligned|gathered|split)\}/);
  assert.equal((home.match(/class="math-square-underbracket"/g) ?? []).length, 1);
  assert.match(home, /math-square-underbracket__expression[\s\S]*math-square-underbracket__rule[\s\S]*math-square-underbracket__label/);
  assert.match(home, /\.math-square-underbracket__rule\s*\{[^}]*border-block-end:\s*1\.5px solid currentColor/s);
  assert.doesNotMatch(home, /\.math-square-underbracket__expression::(?:before|after)/);
  assert.match(home, /\.math-strip--underbrackets\s*\{[^}]*grid-template-columns:\s*repeat\(2,\s*max-content\)/s);
  assert.match(home, /@media \(max-width: 700px\)[\s\S]*\.math-strip--underbrackets\s*\{[^}]*grid-template-columns:\s*minmax\(0,\s*1fr\)/);

  assert.doesNotMatch(thirdStep, /storageMath:[^\n]*\\begin\{gathered\}/);
  for (const stage of ["matrix", "coefficients", "basis"]) {
    assert.match(explorer, new RegExp(`data-cell-stage="${stage}"`));
  }
  assert.match(explorer, /Known matrix and cell selector[\s\S]*cell-grid-panel/);
  assert.match(explorer, /Selected cell and coefficient lattice[\s\S]*cell-coeffs/);
  assert.match(explorer, /Bernstein basis and final representation[\s\S]*cell-bernstein-readout/);
  assert.match(explorer, /ArrowLeft[\s\S]*ArrowRight[\s\S]*ArrowUp[\s\S]*ArrowDown/);
  assert.match(explorer, /A\.LocalValues[\s\S]*cell\.coefficients\.map/);
});

test("only explicitly indivisible one-line formulas opt into local scrolling", () => {
  const elevate = read("src/content/docs/documents/reference/pdmat/elevate.mdx");
  const solverSmoke = read("src/content/docs/examples/solver-smoke.md");
  const css = read("src/styles/manual.css");
  const geometry = read("scripts/check-rendered-geometry.mjs");

  assert.equal(
    (allSource.match(/className="elevate-direct-coefficient-scroll"/g) ?? []).length,
    1,
  );
  assert.equal((solverSmoke.match(/className="solver-one-line"/g) ?? []).length, 3);
  assert.match(
    elevate,
    /<div className="elevate-direct-coefficient-scroll">[\s\S]*\\hat C\^\{\(\\vect c\)\}\[\\vect k\][\s\S]*\\binom\{m_s\}\{i_s\}\\binom\{M_s-m_s\}\{k_s-i_s\}[\s\S]*<\/div>/,
  );
  assert.match(
    css,
    /\.elevate-direct-coefficient-scroll\s*\{[^}]*max-width:\s*100%[^}]*overflow-x:\s*auto[^}]*\}/s,
  );
  assert.match(
    css,
    /\.solver-one-line\s*\{[^}]*max-width:\s*100%[^}]*overflow-x:\s*auto[^}]*\}/s,
  );
  assert.doesNotMatch(
    allSource,
    /(?:\.formula-display|\.math-strip(?:__row)?)\s*\{[^}]*overflow-x:\s*(?:auto|scroll)/si,
  );
  assert.match(
    geometry,
    /closest\(\s*"\.elevate-direct-coefficient-scroll, \.solver-one-line",\s*\)/s,
  );
  assert.match(
    geometry,
    /\["auto",\s*"scroll"\]\.includes\(localScrollerStyle\.overflowX\)[\s\S]*localScroller\.scrollWidth\s*>\s*localScroller\.clientWidth/,
  );
  assert.match(geometry, /type:\s*"local-formula-scroll-bounds"/);
  assert.match(geometry, /type:\s*"local-formula-scroll-required"/);
  assert.match(geometry, /type:\s*"local-formula-scroll-unneeded"/);
});

test("elevation kernel shorthand stays consistent with the direct coefficient rule", () => {
  const elevate = read("src/content/docs/documents/reference/pdmat/elevate.mdx");

  assert.match(elevate, /Let \$\\vect d:=\\vect M-\\vect m\$/);
  assert.match(
    elevate,
    /\\mathcal E_\{\\vect d\}\[\\vect j\]:=\\prod_\{s=1\}\^\{\\ell\}\\binom\{d_s\}\{j_s\},\\qquad\\vect j\\in\\prod_s\\\{0,\\ldots,d_s\\\}/,
  );
  assert.equal(
    (elevate.match(/\\mathcal E_\{\\vect d\}\[\\vect j\]/g) ?? []).length,
    2,
  );
  assert.match(
    elevate,
    /\\ast_\{\\ell\}[\s\S]*\\mathcal E_\{\\vect d\}\[\\vect j\]/,
  );
  assert.doesNotMatch(elevate, /\\mathcal E_\{\\vect M-\\vect m\}/);
  assert.match(
    elevate,
    /<div className="elevate-direct-coefficient-scroll">[\s\S]*\\binom\{m_s\}\{i_s\}\\binom\{M_s-m_s\}\{k_s-i_s\}[\s\S]*\\binom\{M_s\}\{k_s\}[\s\S]*<\/div>/,
  );
});

test("the shared renderer owns strict HTML and MathML output", () => {
  const renderer = read("src/lib/katex-renderer.js");
  const options = read("src/lib/katex-options.js");

  assert.match(renderer, /katex\.renderToString\(tex,/);
  assert.match(renderer, /\.\.\.katexOptions/);
  assert.match(renderer, /displayMode/);
  assert.match(options, /output:\s*"htmlAndMathml"/);
  assert.match(options, /trust:\s*false/);
});

test("the current production build contains local formula CSS and fonts", () => {
  const dist = path.join(root, "dist");
  if (!existsSync(dist)) return;

  const files = readdirSync(dist, { recursive: true }).map(String);
  assert.ok(files.some((file) => /KaTeX_Main-Regular\.[^.]+\.woff2$/.test(file)));
  const css = files
    .filter((file) => file.endsWith(".css"))
    .map((file) => readFileSync(path.join(dist, file), "utf8"))
    .join("\n");
  assert.match(css, /\.katex(?:-display)?\s*\{/);
  assert.doesNotMatch(css, /url\((?:["'])?(?:https?:)?\/\//i);
});

test("all 28 binomials use two explicit braced arguments", () => {
  const { count, failures } = unbracedBinomials();
  assert.equal(count, 28, `expected the audited 28 binomials, found ${count}`);
  assert.deepEqual(failures, []);
});

test("does not override TeX script, fraction, binomial, or display metrics", () => {
  const css = read("src/styles/manual.css");
  const metricCommands =
    /\\(?:displaystyle|textstyle|scriptstyle|scriptscriptstyle|tiny|scriptsize|footnotesize|small|large|Large|LARGE|huge|Huge)\b/;
  const mathMetricRule =
    /\.katex(?:-[\w-]+)?[^{]*\{[^}]*(?:font-size|font-family|transform|zoom)\s*:/gis;

  assert.doesNotMatch(allSource, metricCommands);
  assert.doesNotMatch(css, mathMetricRule);
  assert.doesNotMatch(css, /\.katex(?:-display)?[^{]*\{[^}]*1\.5em/si);
});

test("every component wrapper isolates formula internals from Starlight content flow", () => {
  const astro = read("src/components/KaTeXMath.astro");
  const react = read("src/components/RenderedMath.tsx");
  const missing: string[] = [];

  for (const [name, source] of [
    ["Astro", astro],
    ["React", react],
  ] as const) {
    const classes = source.match(/const classes\s*=\s*`([^`]+)`/)?.[1] ?? "";
    if (!/\bformula-math\b/.test(classes) || !/\bnot-content\b/.test(classes)) {
      missing.push(`${name} formula wrapper`);
    }
  }

  assert.deepEqual(missing, []);
});

test("React formulas consume trusted build-time markup without a document typesetting pass", () => {
  const helper = read("src/components/RenderedMath.tsx");

  assert.match(helper, /\bmarkup:\s*string\b/);
  assert.match(helper, /dangerouslySetInnerHTML=\{\{\s*__html:\s*markup\s*\}\}/);
  assert.doesNotMatch(helper, /\brenderMath\s*\(|\brenderToString\s*\(|katex-renderer/i);
  assert.doesNotMatch(helper, /\btex\s*:\s*string\b/);
  assert.doesNotMatch(helper, /\buseEffect\b|\buseRef\b|textContent|document\.|window\./);
});

test("the React wrapper stays internal while public formula wrappers are consumed", () => {
  const helper = read("src/components/RenderedMath.tsx");
  const reactConsumers = sourceEntries
    .filter(({ source }) => /from\s+["'][^"']*RenderedMath\.tsx["']/.test(source));

  assert.match(helper, /function RenderedMath\s*\(/);
  assert.doesNotMatch(helper, /export\s+(?:default\s+)?function\s+RenderedMath\b/);
  assert.match(helper, /export const DisplayMath\s*=/);
  assert.match(helper, /export const InlineMath\s*=/);
  assert.ok(reactConsumers.length >= 4, "the public wrappers must remain used by React islands");
  for (const { file, source } of reactConsumers) {
    assert.match(source, /import\s*\{[^}]*\b(?:DisplayMath|InlineMath)\b[^}]*\}\s*from/);
    assert.doesNotMatch(
      source,
      /import\s*(?:RenderedMath|\{[^}]*\bRenderedMath\b)/,
      `${file} must consume DisplayMath or InlineMath instead of the internal component`,
    );
  }
});

test("strict rendering throws on malformed TeX and never emits formula SVG", async () => {
  const { renderMath } = await import("../src/lib/katex-renderer.js");
  const markup = renderMath(String.raw`\frac{x}{y}`, { displayMode: true });

  assert.match(markup, /class="katex-html"/);
  assert.match(markup, /<math(?:\s|>)/);
  assert.doesNotMatch(markup, /<svg(?:\s|>)/i);
  assert.throws(() => renderMath(String.raw`\frac{1}{`));
});

test("late-hydrated React formulas need no readiness or queue fallback", () => {
  const config = read("astro.config.mjs");
  const helper = read("src/components/RenderedMath.tsx");
  const deferredRuntime = /documentElement\.dataset|addEventListener|dispatchEvent|\bqueue\b|typeset|startup/i;

  assert.doesNotMatch(config, deferredRuntime);
  assert.doesNotMatch(helper, deferredRuntime);
  assert.match(helper, /\bmarkup:\s*string\b/);
  assert.match(helper, /dangerouslySetInnerHTML=\{\{\s*__html:\s*markup\s*\}\}/);
  assert.doesNotMatch(helper, /\brenderMath\s*\(|\brenderToString\s*\(|katex-renderer/i);
});

test("the Markdown pipeline uses standard plugins rather than a dollar scanner", () => {
  const config = read("astro.config.mjs");
  assert.doesNotMatch(
    config,
    /splitInlineMath|nextSingleDollar|isEscaped|source\[index\]\s*===\s*["']\$["']/,
  );
  assert.match(config, /remarkPlugins:\s*\[\s*remarkTerminologyLinks\s*,\s*remarkMath\s*\]/);
  assert.match(
    config,
    /rehypePlugins:\s*\[\s*\[\s*rehypeKatex,\s*katexOptions\s*\]\s*,\s*rehypeKatexStrict\s*\]/,
  );
});

test("commits the clean-session bernTable transcripts byte for byte", () => {
  const page = read("src/content/docs/documents/reference/pdvar/berntable.mdx")
    .replaceAll("\r\n", "\n");
  const localValues = [
    "ans =",
    "",
    "  1×4 cell array",
    "",
    "    {1×1 sdpvar}    {1×1 sdpvar}    {1×1 sdpvar}    {1×1 sdpvar}",
  ].join("\n");
  const table = [
    "T =",
    "",
    "  4×7 table",
    "",
    "    TermIndex    CellSubscript    CoeffSubscript    LocalIndex              Basis              IsPhysicalNode          Value",
    "    _________    _____________    ______________    __________    _________________________    ______________    _________________",
    "",
    "        1           {[2 1]}          {[2 1]}         {[0 0]}      \"(1-alpha1) * (1-alpha2)\"        true          {[\"internal(4)\"]}",
    "        2           {[2 1]}          {[2 2]}         {[0 1]}      \"(1-alpha1) * alpha2\"            true          {[\"internal(5)\"]}",
    "        3           {[2 1]}          {[3 1]}         {[1 0]}      \"alpha1 * (1-alpha2)\"            true          {[\"internal(7)\"]}",
    "        4           {[2 1]}          {[3 2]}         {[1 1]}      \"alpha1 * alpha2\"                true          {[\"internal(8)\"]}",
  ].join("\n");
  const rateRows = [
    "ans =",
    "  2×3 table",
    "",
    "    RateVertexIndex    RateVertex    LocalIndex",
    "    _______________    __________    __________",
    "",
    "           1             {[-1]}         {[0]}",
    "           2             {[ 2]}         {[0]}",
  ].join("\n");

  for (const transcript of [localValues, table, rateRows]) {
    assert.ok(
      page.includes(`\`\`\`text\n${transcript}\n\`\`\``),
      `transcript differs from clean MATLAB output:\n${transcript}`,
    );
  }
});

test("documents the exact four-slot LocalValues-to-table-row order", () => {
  const page = read("src/content/docs/documents/reference/pdvar/berntable.mdx");
  const mappings = [
    ["1", "row 1", "[0 0]"],
    ["2", "row 2", "[0 1]"],
    ["3", "row 3", "[1 0]"],
    ["4", "row 4", "[1 1]"],
  ];
  for (const [slot, row, label] of mappings) {
    assert.match(
      page,
      new RegExp(`LocalValues[^\\n]*&#123;${slot}&#125;[^\\n]*${row.replace(" ", "\\s+")}[^\\n]*${label.replaceAll("[", "\\[").replaceAll("]", "\\]")}`),
    );
  }
  assert.doesNotMatch(page, /RhodiffDiagram/);
});

test("preserves both pdvar bernTable example anchors", () => {
  const source = read("src/content/docs/documents/reference/pdvar/berntable.mdx");
  assert.match(
    source,
    /<span id="example"><\/span>\s*## Exact two-dimensional storage example/,
  );

  const built = path.join(
    root,
    "dist/documents/reference/pdvar/berntable/index.html",
  );
  if (!existsSync(built)) return;
  const html = readFileSync(built, "utf8");
  assert.match(html, /<span id="example"><\/span>/);
  assert.match(
    html,
    /<h2 id="exact-two-dimensional-storage-example">Exact two-dimensional storage example<\/h2>/,
  );
});

test("CellStorageDiagram API links use the BASE_URL pdmat storage route", () => {
  const component = read("src/components/CellStorageDiagram.astro");
  const expectedAnchors = new Set([
    "pdmat-cells",
    "pdmat-coeffs",
    "pdmat-lbls",
    "pdmat-ncoeff",
  ]);
  const links = [...component.matchAll(/href=\{`\$\{pdmatStorage\}#(pdmat-[a-z]+)`\}/g)]
    .map((match) => match[1]);

  assert.ok(
    component.includes('import.meta.env.BASE_URL.replace(/\\/?$/, "/")'),
    "the link prefix must normalize Astro's BASE_URL",
  );
  assert.match(
    component,
    /const pdmatStorage\s*=\s*`\$\{base\}documents\/reference\/pdmat\/storage-and-elevation\/`/,
  );
  assert.ok(links.length > 0, "the diagram must expose linked pdmat accessors");
  assert.deepEqual(new Set(links), expectedAnchors);
  assert.doesNotMatch(component, /href=(?:"|')#pdmat-/);

});

test("static math assets use the normal build graph without development middleware", () => {
  const config = read("astro.config.mjs");
  const packageJson = JSON.parse(read("package.json"));
  const retiredRenderer = ["math", "jax"].join("");
  const retiredPattern = new RegExp(retiredRenderer, "i");

  assert.equal(typeof packageJson.dependencies?.katex, "string");
  assert.match(config, /customCss:\s*\[[^\]]*["']katex\/dist\/katex\.min\.css["']/s);
  assert.doesNotMatch(config, /astro:server:setup|configureServer|createServer/);
  assert.doesNotMatch(config, retiredPattern);
  assert.equal(existsSync(path.join(root, "public", "katex")), false);
});

test("only the root walkthroughs opt into eager React hydration", () => {
  const home = read("src/components/HomePortal.astro");
  const certificateWrapper = read("src/components/CertificateFlow.astro");
  const certificateConcept = read("src/content/docs/documents/math/sos-certificates.mdx");

  assert.match(home, /<GridPartitionExplorer client:load mathMarkup=\{gridPartitionMathMarkup\}\s*\/>/);
  assert.match(home, /<CellStorageExplorer client:load\b/);
  assert.match(home, /<CertificateFlow compact eager\s*\/>/);
  assert.match(
    certificateWrapper,
    /eager\s*\?\s*<CertificateFlow compact=\{compact\} options=\{options\} residualMarkup=\{residualMarkup\} client:load\s*\/>\s*:\s*<CertificateFlow compact=\{compact\} options=\{options\} residualMarkup=\{residualMarkup\} client:visible\s*\/>/,
  );
  assert.match(certificateConcept, /<CertificateFlow\s*\/>/);
  assert.doesNotMatch(certificateConcept, /<CertificateFlow\b[^>]*\beager\b/);

  for (const { file, source } of sourceEntries) {
    if (file === "src/components/HomePortal.astro" || file === "src/components/CertificateFlow.astro") {
      continue;
    }
    assert.doesNotMatch(
      source,
      /<CertificateFlow\b[^>]*\beager\b/,
      `${file} must retain lazy CertificateFlow hydration`,
    );
  }
});

test("browser geometry resources install cleanup guards before fallible follow-up work", () => {
  const geometry = read("scripts/check-rendered-geometry.mjs");

  assert.match(
    geometry,
    /const \{ server, origin \} = await startServer\(\);\s*let browser = null;\s*let primaryError;\s*const failures = \[\];\s*try \{\s*browser = await chromium\.launch/,
  );
  assert.match(
    geometry,
    /finally \{\s*const cleanupErrors = \[\];[\s\S]*if \(browser\) \{\s*try \{\s*await browser\.close\(\);[\s\S]*\}\s*try \{\s*await closeServer\(server\);/,
  );
  assert.match(
    geometry,
    /if \(primaryError\)[\s\S]*throw primaryError;[\s\S]*throw new AggregateError\(cleanupErrors, "Geometry cleanup failed\."\)/,
  );
});

test("the rhodiff editor alone is eager and preserves accessible draft/commit state", () => {
  const page = read("src/content/docs/documents/reference/pdvar/rhodiff.mdx");
  const explorer = read("src/components/RateVertexExplorer.tsx");
  const lazyPeers = [
    read("src/content/docs/documents/reference/pdmat/elevate.mdx"),
    read("src/content/docs/documents/reference/pdmat/evaluate.mdx"),
    read("src/content/docs/documents/reference/pdmat/algebra.mdx"),
    read("src/content/docs/documents/math/gridding-and-degree.mdx"),
  ];

  assert.match(page, /<RateVertexExplorer client:load\s*\/>/);
  assert.match(explorer, /boundsDraft[\s\S]*columnsDraft[\s\S]*model/);
  assert.match(
    explorer,
    /Draft changed\. Select Update vertices to validate and apply it\./,
  );
  assert.match(
    explorer,
    /Updated to \$\{next\.vertices\.length\} rate rows and \$\{next\.coefficientColumns\} coefficient columns\./,
  );
  assert.match(
    explorer,
    /Draft not applied\. The last valid rate table remains visible\./,
  );
  assert.match(explorer, /aria-invalid=\{errorField === "bounds"\}/);
  assert.match(explorer, /aria-invalid=\{errorField === "columns"\}/);
  assert.match(explorer, /aria-describedby=\{`\$\{id\}-status \$\{id\}-error`\}/);
  assert.match(explorer, /role="status"/);
  assert.match(explorer, /role="alert"/);
  assert.match(explorer, /className="explorer-readout" aria-live="polite"/);
  assert.match(explorer, /model\.vertices\.map/);
  assert.ok(lazyPeers.every((source) => /client:visible/.test(source)));

  for (const { file, source } of sourceEntries) {
    if (file === "src/content/docs/documents/reference/pdvar/rhodiff.mdx") continue;
    assert.doesNotMatch(
      source,
      /<RateVertexExplorer\b[^>]*client:load/,
      `${file} must not duplicate eager rhodiff-editor hydration`,
    );
  }
});
