import { mkdir, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { referenceEntries, referenceGroups } from "../src/data/reference-index.js";

const here = dirname(fileURLToPath(import.meta.url));
const outFile = resolve(here, "../src/content/docs/documents/reference-index.mdx");
const legacyOutFile = resolve(here, "../src/content/docs/documents/reference-index.md");

const escapeHtml = (value) => value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const positivePunctuation = (value) => value.replace(
  /;\s*([a-z])/g,
  (_, character) => `. ${character.toUpperCase()}`,
);
const wrapCompounds = (value) => escapeHtml(positivePunctuation(value)).replace(
  /\b[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+\b/g,
  '<span class="reference-index__compound">$&</span>',
);

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
  return entries.map((entry) => `<li>
<div><a href="${entry.href}"><code>${escapeHtml(entry.name)}</code></a><span>${escapeHtml(entry.type)}</span></div>
<p>${wrapCompounds(entry.task)}</p>
</li>`).join("\n");
}

function family(route, familyEntries) {
  const singleEntry = familyEntries.length === 1 ? familyEntries[0] : undefined;
  const count = `${familyEntries.length} symbol${familyEntries.length === 1 ? "" : "s"}`;
  const primaryLink = singleEntry
    ? `<a class="reference-index__direct-symbol" href="${singleEntry.href}"><code>${escapeHtml(singleEntry.name)}</code></a>`
    : `<a class="reference-index__page" href="${route}">${escapeHtml(familyLabel(route, familyEntries))}</a>`;
  const content = singleEntry
    ? `<div class="reference-index__direct-meta">
<span>${escapeHtml(singleEntry.type)}</span>
<p>${wrapCompounds(singleEntry.task)}</p>
</div>`
    : `<details class="reference-index__symbols">
<summary>Show direct symbol links</summary>
<ul>
${symbolList(familyEntries)}
</ul>
</details>`;

  return `<div class="reference-index__family-row">
<div class="reference-index__family-heading">
${primaryLink}
<span>${count}</span>
</div>
<div class="reference-index__family-content">
${content}
</div>
</div>`;
}

function familiesOf(entries) {
  const families = new Map();
  for (const entry of entries) {
    const route = routeOf(entry.href);
    if (!families.has(route)) families.set(route, []);
    families.get(route).push(entry);
  }
  return [...families];
}

function groupSection(group) {
  const entries = referenceEntries.filter((entry) => entry.group === group.id);
  return `<details class="reference-index__group" id="${group.id}">
<summary class="reference-index__group-summary">
<span class="reference-index__group-copy"><strong>${escapeHtml(group.label)}</strong><span>${wrapCompounds(group.description)}</span></span>
<span>${entries.length} indexed entries</span>
</summary>
<div class="reference-index__families">
${familiesOf(entries).map(([route, familyEntries]) => family(route, familyEntries)).join("\n")}
</div>
</details>`;
}

const body = `---
title: Reference Lookup
description: Generated lookup for implemented GriD-LMIA reference pages and symbols.
---

<p>${wrapCompounds("This generated lookup groups every reference-page family by its package role. A one-symbol family links directly to that symbol; multi-symbol families keep their direct symbol and anchor links in one compact disclosure. The source data lives in ")}<code>src/data/reference-index.js</code>${wrapCompounds("; regenerate this page with ")}<code>{"npm --prefix webpage run generate:index"}</code>.</p>

<div class="reference-index">
${referenceGroups.map(groupSection).join("\n")}
</div>
`;

await mkdir(dirname(outFile), { recursive: true });
await rm(legacyOutFile, { force: true });
await writeFile(outFile, body, "utf8");
console.log(`Generated ${outFile}`);
