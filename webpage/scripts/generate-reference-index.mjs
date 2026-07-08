import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { referenceEntries } from "../src/data/reference-index.js";

const here = dirname(fileURLToPath(import.meta.url));
const outFile = resolve(here, "../src/content/docs/documents/reference-index.md");

function row(entry) {
  return `| [\`${entry.name}\`](${entry.href}) | ${entry.type} | ${entry.task} |`;
}

const body = `---
title: Reference Lookup Table
description: Generated lookup table for implemented DP-LMI classes and methods.
---

This generated page lists implemented public classes and methods that are documented in the online manual. The source data lives in \`src/data/reference-index.js\`; regenerate this page with \`npm --prefix webpage run generate:index\`.

| Name | Type | Lookup Task |
| :--- | :--- | :--- |
${referenceEntries.map(row).join("\n")}
`;

await mkdir(dirname(outFile), { recursive: true });
await writeFile(outFile, body, "utf8");
console.log(`Generated ${outFile}`);
