import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import { documentationContractSummary, documentationRecords, terminologyTerms } from "../src/data/documentation-contracts.js";
import { referenceEntries } from "../src/data/reference-index.js";
import remarkTerminologyLinks from "../src/lib/remark-terminology-links.js";

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
