import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { referenceEntries, referenceGroups } from "../src/data/reference-index.js";

const here = dirname(fileURLToPath(import.meta.url));
const outFile = resolve(here, "../src/content/docs/documents/reference-index.md");

function row(entry) {
  return `| [\`${entry.name}\`](${entry.href}) | ${entry.type} | ${entry.task} |`;
}

const group = (definition) => {
  const entries = referenceEntries.filter((item) => item.group === definition.id);
  return `## ${definition.label}\n\n${definition.description}\n\n| Name | Type | Lookup Task |\n| :--- | :--- | :--- |\n${entries.map(row).join("\n")}`;
};

const body = `---
title: Reference Lookup Table
description: Generated lookup table for implemented PD-LMI classes and methods.
---

This generated page groups implemented public classes, methods, backend utilities, and shared helpers. The source data lives in \`src/data/reference-index.js\`; regenerate this page with \`npm --prefix webpage run generate:index\`.

${referenceGroups.map(group).join("\n\n")}
`;

await mkdir(dirname(outFile), { recursive: true });
await writeFile(outFile, body, "utf8");
console.log(`Generated ${outFile}`);
