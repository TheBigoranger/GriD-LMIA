import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const root = path.resolve(import.meta.dirname, "..");
const read = (relative: string) => fs.readFileSync(path.join(root, relative), "utf8");

const families = [
  "constructors",
  "alignment",
  "multiplication",
  "elevation",
  "differentiation",
  "certificates",
];

test("call graphs are generated from six trusted Mermaid sources", () => {
  const pkg = JSON.parse(read("package.json"));
  const generator = read("scripts/generate-call-graphs.mjs");
  const puppeteer = JSON.parse(read("scripts/puppeteer-config.json"));
  assert.equal(pkg.devDependencies["@mermaid-js/mermaid-cli"], "11.15.0");
  assert.match(pkg.scripts.prebuild, /generate-call-graphs\.mjs/);
  assert.match(generator, /--puppeteerConfigFile/);
  assert.deepEqual(puppeteer.args, ["--no-sandbox", "--disable-setuid-sandbox"]);

  for (const family of families) {
    assert.equal(fs.existsSync(path.join(root, "src/diagrams/call-graphs", `${family}.mmd`)), true);
    for (const layout of ["desktop", "mobile"])
      for (const theme of ["light", "dark"])
        assert.equal(
          fs.existsSync(path.join(root, "src/assets/call-graphs", `${family}-${layout}-${theme}.svg`)),
          true,
        );
  }
});

test("call graph component selects responsive theme assets without client Mermaid", () => {
  const component = read("src/components/CallGraph.astro");
  assert.match(component, /<picture/);
  assert.match(component, /prefers-color-scheme/);
  assert.match(component, /data-theme/);
  assert.match(component, /call-graph__links/);
  assert.doesNotMatch(component, /mermaid\.initialize|client:/);
  assert.match(component, /rawAssets/);
  assert.match(component, /viewBox=/);
  assert.match(component, /--call-graph-ratio/);
  assert.doesNotMatch(component, /<img[^>]+(?:width|height)=/);
  assert.doesNotMatch(component, /width="1200"|height="320"|width="520"|height="980"/);
});
