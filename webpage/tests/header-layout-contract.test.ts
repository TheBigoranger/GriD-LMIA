import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import test from "node:test";

const root = path.resolve(import.meta.dirname, "..");
const read = (relative: string) => readFileSync(path.join(root, relative), "utf8");

test("allocates header regions without absolute search placement", () => {
  const header = read("src/components/Header.astro");
  assert.match(header, /\.site-header \{[^}]*display:\s*grid/);
  assert.match(header, /grid-template-columns:\s*max-content minmax\(9rem, 28rem\) max-content/);
  assert.match(header, /site-header__search \{[^}]*width:\s*100%[^}]*min-width:\s*0/);
  assert.doesNotMatch(header, /site-header__search \{[^}]*(?:position:\s*absolute|transform:)/);
});

test("measures header-region overlap at the reported 1280 by 900 viewport", () => {
  const geometry = read("scripts/check-rendered-geometry.mjs");
  assert.match(geometry, /async function auditHeaderLayout/);
  assert.match(geometry, /width:\s*1280,\s*height:\s*900/);
  assert.match(geometry, /type:\s*"header-region-overlap"/);
  assert.match(geometry, /\.site-header__brand[\s\S]*\.site-header__search[\s\S]*\.site-header__end/);
  assert.match(geometry, /await auditHeaderLayout\(browser, origin, failures\)/);
});
