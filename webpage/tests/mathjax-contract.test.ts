import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import path from "node:path";
import test from "node:test";
import vm from "node:vm";

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

test("uses only self-hosted MathJax 4 CommonHTML with mathjax-modern", () => {
  const packageJson = read("package.json");
  const packageLock = read("package-lock.json");
  const config = read("astro.config.mjs");
  const assetPlugin = read("src/lib/mathjax-assets.js");

  assert.match(packageJson, /"mathjax":\s*"\^4\./);
  assert.match(packageJson, /"@mathjax\/mathjax-modern-font":\s*"\^4\./);
  const lockRoot = JSON.parse(packageLock).packages[""]?.dependencies ?? {};
  assert.ok(!("katex" in lockRoot));
  assert.ok(!("rehype-katex" in lockRoot));
  assert.doesNotMatch(packageJson, /(?:rehype-katex|"katex")/i);
  assert.doesNotMatch(allSource, /\bkatex\b|render(?:Display|Inline)Math|--formula-size|formulaScale/i);
  assert.match(config, /src:\s*`\$\{mathJaxRoot\}\/tex-mml-chtml-mathjax-modern\.js`/);
  assert.match(config, /font:\s*"mathjax-modern"/);
  assert.match(config, /scale:\s*1\.0/);
  assert.match(config, /displayOverflow:\s*"linebreak"/);
  assert.match(config, /linebreaks:\s*\{[\s\S]*inline:\s*true[\s\S]*width:\s*"100%"/);
  assert.match(config, /enableMenu:\s*true/);
  assert.match(config, /enableEnrichment:\s*true/);
  assert.match(config, /enableComplexity:\s*true/);
  assert.doesNotMatch(config, /enableAssistiveMml/);
  assert.match(assetPlugin, /node_modules\/@mathjax\/mathjax-modern-font/);
  assert.match(assetPlugin, /tex-mml-chtml-mathjax-modern\.js/);
  assert.match(assetPlugin, /mathjax-modern\/chtml/);
  assert.doesNotMatch(
    config + assetPlugin,
    /(?:cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|unpkg\.com|esm\.sh|mathjax\.org\/mathjax\/latest)/i,
  );
});

test("ships the complete local MathJax runtime and modern CHTML font payload", () => {
  const packageRoot = path.join(root, "node_modules/@mathjax/mathjax-modern-font");
  assert.ok(existsSync(path.join(packageRoot, "tex-mml-chtml-mathjax-modern.js")));
  assert.ok(existsSync(path.join(packageRoot, "chtml/woff2/mjx-mm-i.woff2")));
  assert.ok(existsSync(path.join(packageRoot, "chtml/woff2/mjx-mm-s4.woff2")));
  assert.ok(existsSync(path.join(packageRoot, "chtml/woff2/mjx-mm-sy.woff2")));
});

test("the current production build contains lazy MathJax runtime dependencies", () => {
  const dist = path.join(root, "dist");
  if (!existsSync(dist)) return;

  assert.ok(existsSync(path.join(dist, "mathjax/sre/speech-worker.js")));
  assert.ok(existsSync(path.join(dist, "mathjax/input/tex/extensions/boldsymbol.js")));
  assert.ok(existsSync(path.join(dist, "mathjax/mathjax-modern/chtml/woff2/mjx-mm-i.woff2")));
});

test("all 25 binomials use two explicit braced arguments", () => {
  const { count, failures } = unbracedBinomials();
  assert.equal(count, 25, `expected the audited 25 binomials, found ${count}`);
  assert.deepEqual(failures, []);
});

test("does not override TeX script, fraction, binomial, or display metrics", () => {
  const css = read("src/styles/manual.css");
  const metricCommands =
    /\\(?:displaystyle|textstyle|scriptstyle|scriptscriptstyle|tiny|scriptsize|footnotesize|small|large|Large|LARGE|huge|Huge)\b/;
  const mathMetricRule =
    /(?:mjx-|mjx-container|\.tex-(?:display|inline|math))[^{]*\{[^}]*(?:font-size|font-family|transform|zoom|--mjx|--math-scale)\s*:/gis;

  assert.doesNotMatch(allSource, metricCommands);
  assert.doesNotMatch(css, mathMetricRule);
  assert.doesNotMatch(css, /(?:\.tex-display|mjx-container)[^{]*\{[^}]*1\.5em/si);
});

test("dynamic React math serializes clear, TeX replacement, and typesetting", () => {
  const config = read("astro.config.mjs");
  const helper = read("src/components/MathJaxMath.tsx");
  const clear = config.indexOf("typesetClear(elements)");
  const update = config.indexOf("update?.()");
  const typeset = config.indexOf("typesetPromise(elements)");

  assert.match(config, /pdLmiTypeset\s*=\s*\(elements,\s*update\)/);
  assert.ok(clear >= 0, "the shared queue must clear the supplied elements");
  assert.ok(update > clear, "the queued update callback must run after typesetClear");
  assert.ok(typeset > update, "typesetPromise must run after the queued TeX update");
  assert.match(
    helper,
    /pdLmiTypeset\?\.\(\[element\],\s*\(\)\s*=>\s*\{?[\s\S]*?element\.textContent/,
  );
  assert.doesNotMatch(helper, /dangerouslySetInnerHTML|render(?:Display|Inline)Math/);
});

test("the React wrapper stays internal while public formula wrappers are consumed", () => {
  const helper = read("src/components/MathJaxMath.tsx");
  const reactConsumers = sourceEntries
    .filter(({ source }) => /from\s+["'][^"']*MathJaxMath\.tsx["']/.test(source));

  assert.match(helper, /function MathJaxMath\s*\(/);
  assert.doesNotMatch(helper, /export\s+(?:default\s+)?function\s+MathJaxMath\b/);
  assert.match(helper, /export const DisplayMath\s*=/);
  assert.match(helper, /export const InlineMath\s*=/);
  assert.ok(reactConsumers.length >= 4, "the public wrappers must remain used by React islands");
  for (const { file, source } of reactConsumers) {
    assert.match(source, /import\s*\{[^}]*\b(?:DisplayMath|InlineMath)\b[^}]*\}\s*from/);
    assert.doesNotMatch(
      source,
      /import\s*(?:MathJaxMath|\{[^}]*\bMathJaxMath\b)/,
      `${file} must consume DisplayMath or InlineMath instead of the internal component`,
    );
  }
});

test("the global queue recovers after a rejected MathJax typeset task", async () => {
  const config = read("astro.config.mjs");
  const helperStart = config.indexOf("window.pdLmiMathQueue = Promise.resolve();");
  const helperEnd = config.indexOf("const typesetStaticMath", helperStart);
  assert.ok(helperStart >= 0 && helperEnd > helperStart, "the global helper must remain extractable");

  const order: string[] = [];
  const errors: unknown[][] = [];
  let typesetCount = 0;
  const context = vm.createContext({
    console: {
      error: (...args: unknown[]) => errors.push(args),
    },
    Promise,
    window: {
      MathJax: {
        typesetClear: (elements: unknown[]) => order.push(`clear:${String(elements[0])}`),
        typesetPromise: async (elements: unknown[]) => {
          typesetCount += 1;
          order.push(`typeset:${String(elements[0])}`);
          if (typesetCount === 1) throw new Error("first task failed");
        },
      },
    },
  });
  vm.runInContext(config.slice(helperStart, helperEnd), context);
  const runtime = context.window as {
    pdLmiMathQueue: Promise<unknown>;
    pdLmiTypeset: (elements: unknown[], update: () => void) => Promise<unknown>;
  };

  await assert.doesNotReject(runtime.pdLmiTypeset(["first"], () => order.push("update:first")));
  await assert.doesNotReject(runtime.pdLmiTypeset(["second"], () => order.push("update:second")));
  await assert.doesNotReject(runtime.pdLmiMathQueue);
  assert.deepEqual(order, [
    "clear:first",
    "update:first",
    "typeset:first",
    "clear:second",
    "update:second",
    "typeset:second",
  ]);
  assert.equal(errors.length, 1);
  assert.equal(errors[0][0], "MathJax typesetting failed:");
  assert.match(String(errors[0][1]), /first task failed/);
});

test("late-hydrated React math uses durable readiness before startup and event fallbacks", () => {
  const config = read("astro.config.mjs");
  const helper = read("src/components/MathJaxMath.tsx");
  const durableReady = helper.indexOf('document.documentElement.dataset.mathjaxReady === "true"');
  const startup = helper.indexOf("window.MathJax?.startup?.promise");
  const startupFallback = helper.indexOf("else if (startup)");
  const eventFallback = helper.indexOf('document.addEventListener("mathjax:ready"');
  const cleanup = helper.indexOf("return () =>");

  assert.match(config, /document\.documentElement\.dataset\.mathjaxReady\s*=\s*"true"/);
  assert.match(config, /document\.dispatchEvent\(new CustomEvent\("mathjax:ready"\)\)/);
  assert.ok(durableReady >= 0, "late islands must first consult the durable ready dataset");
  assert.ok(startup >= 0 && startup < durableReady, "the startup promise must be captured before readiness branching");
  assert.ok(startupFallback > durableReady, "startup.promise must be the second readiness path");
  assert.ok(eventFallback > startupFallback, "the one-shot ready event must be the final fallback");
  assert.match(helper, /startup\.then\(typeset\)/);
  assert.match(helper, /document\.addEventListener\("mathjax:ready",\s*typeset,\s*\{\s*once:\s*true\s*\}\)/);
  assert.ok(cleanup > eventFallback, "effect cleanup must follow all readiness paths");
  assert.match(
    helper.slice(cleanup),
    /removeEventListener\("mathjax:ready",\s*typeset\)[\s\S]*pdLmiTypeset\?\.\(\[element\],[\s\S]*element\.textContent\s*=\s*""/,
  );
});

test("the Markdown pipeline relies on remark-math HAST classes, not a dollar scanner", () => {
  const plugin = read("src/lib/rehype-mathjax.js");
  assert.doesNotMatch(
    plugin,
    /splitInlineMath|nextSingleDollar|isEscaped|source\[index\]\s*===\s*["']\$["']/,
  );
  assert.match(plugin, /math-inline/);
  assert.match(plugin, /math-display/);
});

test("commits the clean-session bernsteinTable transcripts byte for byte", () => {
  const page = read("src/content/docs/documents/reference/pdvar/bernsteintable.mdx")
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
  const page = read("src/content/docs/documents/reference/pdvar/bernsteintable.mdx");
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

test("preserves both pdvar bernsteinTable example anchors", () => {
  const source = read("src/content/docs/documents/reference/pdvar/bernsteintable.mdx");
  assert.match(
    source,
    /<span id="example"><\/span>\s*## Exact two-dimensional storage example/,
  );

  const built = path.join(
    root,
    "dist/documents/reference/pdvar/bernsteintable/index.html",
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

test("development MathJax middleware is BASE_URL-aware and path-safe", () => {
  const assets = read("src/lib/mathjax-assets.js");

  assert.match(assets, /"astro:config:done":\s*\(\{\s*config\s*\}\)\s*=>/);
  assert.match(assets, /assetPrefix\s*=\s*mathJaxPrefix\(config\.base\)/);
  assert.match(assets, /pathname\.startsWith\("\/mathjax\/"\)/);
  assert.match(assets, /decodeURIComponent/);
  assert.ok(assets.includes('assetPath.includes("\\0")'));
  assert.match(assets, /part === "\.\."|part === "\."/);
  assert.match(assets, /details\.isFile\(\)/);
  assert.equal(existsSync(path.join(root, "public/mathjax")), false);
});

test("only the root walkthroughs opt into eager React hydration", () => {
  const home = read("src/components/HomePortal.astro");
  const certificateWrapper = read("src/components/CertificateFlow.astro");
  const certificateConcept = read("src/content/docs/documents/math/sos-certificates.mdx");

  assert.match(home, /<GridPartitionExplorer client:load\s*\/>/);
  assert.match(home, /<CellStorageExplorer client:load\b/);
  assert.match(home, /<CertificateFlow compact eager\s*\/>/);
  assert.match(
    certificateWrapper,
    /eager\s*\?\s*<CertificateFlow compact=\{compact\} options=\{options\} client:load\s*\/>\s*:\s*<CertificateFlow compact=\{compact\} options=\{options\} client:visible\s*\/>/,
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

test("browser test resources install cleanup guards before fallible follow-up work", () => {
  const geometry = read("scripts/check-rendered-geometry.mjs");
  const devSmoke = read("tests/mathjax-dev-server.test.ts");

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

  const spawnAt = devSmoke.indexOf("const child = spawn(");
  const guardAt = devSmoke.indexOf("\n  try {", spawnAt);
  const awaitStartAt = devSmoke.indexOf("const started = await launcherExit", spawnAt);
  const pidAssertAt = devSmoke.indexOf("assert.ok(managedPid", spawnAt);
  assert.ok(spawnAt >= 0 && guardAt > spawnAt);
  assert.ok(awaitStartAt > guardAt, "launcher completion must be protected by managed cleanup");
  assert.ok(pidAssertAt > guardAt, "PID parsing assertions must be protected by managed cleanup");
  assert.match(
    devSmoke.slice(guardAt),
    /finally \{[\s\S]*await astroControl\("stop"\);[\s\S]*await astroControl\("status"\);[\s\S]*if \(managedPid\)[\s\S]*throw primaryError;[\s\S]*AggregateError/,
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
