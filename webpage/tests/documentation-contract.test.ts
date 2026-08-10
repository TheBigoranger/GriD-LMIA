import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import { documentationContractSummary, documentationRecords, terminologyTerms } from "../src/data/documentation-contracts.js";
import { referenceEntries } from "../src/data/reference-index.js";
import remarkTerminologyLinks from "../src/lib/remark-terminology-links.js";
import {
  componentUserVisibleEntries,
  hasLowercaseSentenceStart,
  isAllowedBoundaryHeading,
  markdownProseLines,
  stripAllowedComponentContexts,
} from "../scripts/documentation-prose-policy.mjs";

const root = path.resolve(import.meta.dirname, "..");
const read = (file: string) => readFileSync(path.join(root, file), "utf8");

test("projects the accepted shared documentation contracts", () => {
  assert.equal(documentationRecords.length, 192);
  assert.equal(referenceEntries.length, 192);
  assert.equal(terminologyTerms.length, 8);
  assert.deepEqual(documentationContractSummary.ownerCounts, {
    pdbase: 49, pdmat: 55, pdvar: 52, pdlmi: 22, helper: 13, root: 1,
  });
  assert.ok(documentationRecords.every((record) => record.executable_example));
  assert.ok(referenceEntries.every((entry) => entry.href.startsWith("/GriD-LMIA/")));
  const webTargets = documentationRecords.flatMap((record) => [
    record.web_route_or_anchor,
    record.web_example_evidence,
  ]);
  assert.equal(webTargets.length, 384);
  assert.equal(new Set(webTargets).size, 384);
});

test("uses record kind when generating diagnostic IDs", () => {
  const diagnosticIndex = read("src/components/DiagnosticIndex.astro");
  assert.match(diagnosticIndex, /slug\(`\$\{record\.id\}-\$\{record\.kind\}`\)/);
});

test("links Markdown prose terms while preserving excluded AST nodes", () => {
  const tree: any = {
    type: "root",
    children: [
      { type: "paragraph", children: [{ type: "text", value: "LPV and DPD-LMI prose" }] },
      { type: "heading", depth: 2, children: [{ type: "text", value: "LPV heading" }] },
      { type: "inlineCode", value: "LPV" },
      { type: "inlineMath", value: "LPV" },
      { type: "link", url: "/existing", children: [{ type: "text", value: "LPV link" }] },
      { type: "mdxJsxTextElement", name: "Term", attributes: [], children: [{ type: "text", value: "LPV definition" }] },
    ],
  };
  remarkTerminologyLinks()(tree);
  assert.equal(tree.children[0].children.filter((node: any) => node.type === "link").length, 2);
  assert.equal(tree.children[1].children[0].value, "LPV heading");
  assert.equal(tree.children[2].value, "LPV");
  assert.equal(tree.children[3].value, "LPV");
  assert.equal(tree.children[4].children[0].value, "LPV link");
  assert.equal(tree.children[5].children[0].value, "LPV definition");
});

test("defines terms, semantic vectors, and source-time component helpers", () => {
  const config = read("astro.config.mjs");
  const katex = read("src/lib/katex-options.js");
  assert.match(config, /remarkTerminologyLinks/);
  assert.match(katex, /"\\\\vect": "\\\\boldsymbol\{#1\}"/);
  assert.match(read("src/components/Term.astro"), /<dfn id=\{`term-/);
  assert.match(read("src/components/TermText.tsx"), /className="term-link"/);
  assert.match(read("src/components/Term.astro"), /href=\{href\}/);
  assert.match(read("src/components/TermText.tsx"), /href=\{`\/GriD-LMIA\$\{term\.web_definition_anchor\}`\}/);
  assert.match(read("src/lib/remark-terminology-links.js"), /url: `\/GriD-LMIA\$\{term\.web_definition_anchor\}`/);
});

test("mounts the contract inventory on every authoritative owner route", () => {
  const routes = new Map([
    ["pdbase", "src/content/docs/documents/reference/pdbase/index.mdx"],
    ["pdmat", "src/content/docs/documents/reference/pdmat/index.mdx"],
    ["pdvar", "src/content/docs/documents/reference/pdvar/index.mdx"],
    ["pdlmi", "src/content/docs/documents/reference/pdlmi/index.mdx"],
    ["helper", "src/content/docs/documents/reference/helpers/index.mdx"],
    ["root", "src/content/docs/documents/getting-started/installation.mdx"],
  ]);
  for (const [owner, file] of routes) assert.match(read(file), new RegExp(`<ApiInventory owner="${owner}" \\/>`));
});

test("allows negative prose only in explicit documentation boundary contexts", () => {
  const prose = markdownProseLines([
    "---",
    "title: Policy fixture",
    "description: A direct policy fixture.",
    "---",
    "## Overview",
    "The overview does not qualify as a boundary.",
    "## Validation And Errors",
    "The input cannot omit the required grid.",
    "## Failure Interpretation And Limits",
    "A failed certificate does not prove infeasibility.",
  ].join("\n"));

  assert.equal(prose.find((line) => line.text.includes("overview does not"))?.allowedNegative, false);
  assert.equal(prose.find((line) => line.text.includes("input cannot"))?.allowedNegative, true);
  assert.equal(prose.find((line) => line.text.includes("does not prove"))?.allowedNegative, true);
  assert.equal(isAllowedBoundaryHeading("Boundaries And Related APIs"), true);
  assert.equal(isAllowedBoundaryHeading("Overview"), false);
});

test("requires an explicit component context marker for negative boundary copy", () => {
  const source = [
    "<section><p>This copy cannot pass.</p></section>",
    '<section data-doc-context="status"><p>This status cannot pass yet.</p></section>',
  ].join("\n");
  const remaining = stripAllowedComponentContexts(source);

  assert.match(remaining, /This copy cannot pass/);
  assert.doesNotMatch(remaining, /This status cannot pass yet/);
});

test("extracts rendered component controls, attributes, and data-driven copy", () => {
  const source = [
    "---",
    'const cards = [{ title: "Data-driven title", text: "A rendered data sentence." }];',
    "---",
    '<nav aria-label="Primary destinations"><a href="/ignored">Reference link</a></nav>',
    '<button title="Run the calculation">Calculate result</button>',
    '<figcaption>A visible caption.</figcaption>',
    '<pre><code>ignored; code</code></pre>',
  ].join("\n");
  const entries = componentUserVisibleEntries(source, "Fixture.astro").map((entry) => entry.text);

  assert.ok(entries.includes("Data-driven title"));
  assert.ok(entries.includes("A rendered data sentence."));
  assert.ok(entries.includes("Primary destinations"));
  assert.ok(entries.includes("Reference link"));
  assert.ok(entries.includes("Run the calculation"));
  assert.ok(entries.includes("Calculate result"));
  assert.ok(entries.includes("A visible caption."));
  assert.ok(entries.every((entry) => !entry.includes("ignored; code")));
});

test("detects lowercase ordinary sentence starts and preserves identifiers", () => {
  assert.equal(hasLowercaseSentenceStart("The first sentence. the second sentence."), true);
  assert.equal(hasLowercaseSentenceStart("ordinary control label"), true);
  assert.equal(hasLowercaseSentenceStart("`pdlmi` stores the residual."), false);
  assert.equal(hasLowercaseSentenceStart("MATLAB calls remain explicit."), false);
  assert.equal(hasLowercaseSentenceStart("`run.m` selects the example."), false);
});

test("extracts rendered TSX bindings with explicit boundary classification", () => {
  const source = [
    'const ordinaryCopy = "This copy cannot pass.";',
    'const statusCopy = "This status cannot pass yet.";',
    'const implementationOnly = "This implementation does not render.";',
    'const [status, setStatus] = useState("The draft is not applied.");',
    'setStatus("The result is not ready.");',
    "return (",
    '  <section aria-label={ordinaryCopy}>',
    "    <p>{ordinaryCopy}</p>",
    '    <p data-doc-context="status">{statusCopy}</p>',
    '    <p role="status">{status}</p>',
    "  </section>",
    ");",
  ].join("\n");
  const entries = componentUserVisibleEntries(source, "Fixture.tsx");
  const entry = (text: string) => entries.find((candidate) => candidate.text === text);

  assert.equal(entry("This copy cannot pass.")?.allowedNegative, false);
  assert.equal(entry("This status cannot pass yet.")?.allowedNegative, true);
  assert.equal(entry("The draft is not applied.")?.allowedNegative, true);
  assert.equal(entry("The result is not ready.")?.allowedNegative, true);
  assert.equal(entry("This implementation does not render."), undefined);
});
