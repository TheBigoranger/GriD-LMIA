import { mkdir, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { referenceEntries, referenceGroups } from "../src/data/reference-index.js";

const here = dirname(fileURLToPath(import.meta.url));
const outFile = resolve(here, "../src/content/docs/documents/reference-index.mdx");
const legacyOutFile = resolve(here, "../src/content/docs/documents/reference-index.md");

const escapeHtml = (value) => value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const routeOf = (href) => href.split("#", 1)[0];
const anchorOf = (href) => href.includes("#") ? href.slice(href.indexOf("#") + 1) : "";
const titleCase = (value) => value
  .replace(/[-_]/g, " ")
  .replace(/\b\w/g, (character) => character.toUpperCase());

function familyLabel(route, entries) {
  const overview = entries.find((entry) => !anchorOf(entry.href) && entry.href === route);
  if (overview) return overview.name;
  return titleCase(route.split("/").filter(Boolean).at(-1) ?? "Reference page");
}

function symbolList(entries) {
  return entries.map((entry) => {
    const anchor = anchorOf(entry.href);
    const label = anchor ? `${entry.name} — ${anchor}` : entry.name;
    return `<li><a href="${entry.href}"><code>${escapeHtml(label)}</code></a><span>${escapeHtml(entry.type)}</span></li>`;
  }).join("\n");
}

function group(definition) {
  const entries = referenceEntries.filter((item) => item.group === definition.id);
  const families = new Map();
  for (const entry of entries) {
    const route = routeOf(entry.href);
    if (!families.has(route)) families.set(route, []);
    families.get(route).push(entry);
  }

  const familyMarkup = [...families].map(([route, familyEntries]) => `
<details class="reference-index__family" open>
<summary>${escapeHtml(familyLabel(route, familyEntries))}<span>${familyEntries.length} symbol${familyEntries.length === 1 ? "" : "s"}</span></summary>
<a class="reference-index__page" href="${route}">Open reference page</a>
<details class="reference-index__symbols">
<summary>Symbols and anchors</summary>
<ul>
${symbolList(familyEntries)}
</ul>
</details>
</details>`).join("\n");

  return `<details class="reference-index__group" open>
<summary>${escapeHtml(definition.label)}<span>${escapeHtml(definition.description)}</span></summary>
${familyMarkup}
</details>`;
}

const body = `---
title: Reference Lookup
description: Generated three-level lookup for implemented PD-LMI classes, pages, and symbols.
---

This generated menu follows the manual navigation: module or class, reference-page family, then each symbol or anchor. Modules and page families start expanded; symbol lists remain collapsed until needed. The source data lives in \`src/data/reference-index.js\`; regenerate this page with \`npm --prefix webpage run generate:index\`.

<nav class="reference-index" aria-label="PD-LMI reference lookup">
${referenceGroups.map(group).join("\n")}
</nav>
`;

await mkdir(dirname(outFile), { recursive: true });
await rm(legacyOutFile, { force: true });
await writeFile(outFile, body, "utf8");
console.log(`Generated ${outFile}`);
