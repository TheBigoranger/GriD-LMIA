import { execFileSync } from "node:child_process";
import { readFileSync, readdirSync } from "node:fs";
import { extname, join, relative, resolve } from "node:path";
import { documentationRecords, terminologyTerms } from "../src/data/documentation-contracts.js";
import { referenceEntries } from "../src/data/reference-index.js";
import { certificateSources } from "../src/data/certificate-data.ts";
import {
  componentUserVisibleEntries,
  hasLowercaseSentenceStart,
  markdownProseLines,
  negativePattern,
  stripAllowedComponentContexts,
} from "./documentation-prose-policy.mjs";

const root = resolve(import.meta.dirname, "..");
const failures = [];
// Assemble the forbidden token so the validator does not reproduce it verbatim.
const calligraphicCommand = String.raw`\math` + "cal";
const completeLabelName = "I";
const bannedIndexSetPattern = new RegExp(
  `${calligraphicCommand}\\s*(?:${completeLabelName}|\\{${completeLabelName}\\})(?:_|\\b)`,
);

function walk(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

function markdownProse(source) {
  return source
    .replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "")
    .replace(/```[\s\S]*?```/g, "")
    .replace(/^import\s+[\s\S]*?;\s*(?:\r?\n|$)/gm, "")
    .replace(/^export\s+(?:const|let|var|function|class|default|\{)[\s\S]*?;\s*(?:\r?\n|$)/gm, "")
    .replace(/\$\$[\s\S]*?\$\$/g, "")
    .replace(/`[^`\r\n]*`/g, "")
    .replace(/\$[^$\r\n]+\$/g, "")
    .replace(/^#{1,6} .*$/gm, "")
    .replace(/<style>[\s\S]*?<\/style>/g, "")
    .replace(/\{(?:[^{}]|\{[^{}]*\})*\}/g, "")
    .replace(/<[^>]+>/g, "")
    .replace(/&(?:#\d+|#x[0-9a-f]+|[a-z]+);/gi, "")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1");
}

function stripJsxExpressions(source) {
  let output = "";
  let depth = 0;
  let quote = "";
  let escaped = false;
  for (const character of source) {
    if (depth === 0) {
      if (character === "{") depth = 1;
      else output += character;
      continue;
    }
    if (escaped) {
      escaped = false;
      continue;
    }
    if (quote) {
      if (character === "\\") escaped = true;
      else if (character === quote) quote = "";
      continue;
    }
    if (character === '"' || character === "'" || character === "`") quote = character;
    else if (character === "{") depth += 1;
    else if (character === "}") depth -= 1;
  }
  return output;
}

function componentProse(source, file) {
  let body = source.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "");
  if (file.endsWith(".tsx")) {
    const returnIndex = body.lastIndexOf("return (");
    body = returnIndex >= 0 ? body.slice(returnIndex + "return (".length) : "";
  }
  body = body
    .replace(/<(style|script)\b[^>]*>[\s\S]*?<\/\1>/gi, "")
    .replace(/<(h[1-6]|nav|a|button|code|pre|TermText)\b[^>]*>[\s\S]*?<\/\1>/gi, "");
  body = stripJsxExpressions(body);
  return [...body.matchAll(/>([^<{][^<]*)</g)]
    .map((match) => match[1])
    .join("\n");
}

execFileSync(process.execPath, [join(root, "scripts/sync-documentation-contracts.mjs"), "--check"], { stdio: "inherit" });

if (documentationRecords.length !== 192) failures.push(`Expected 192 public API records, found ${documentationRecords.length}.`);
if (referenceEntries.length !== 192) failures.push(`Expected 192 reference entries, found ${referenceEntries.length}.`);
if (terminologyTerms.length !== 8) failures.push(`Expected 8 governed terms, found ${terminologyTerms.length}.`);
if (documentationRecords.some((record) => /protected|private/i.test(record.kind))) failures.push("Protected or private symbols entered the public inventory.");
if (documentationRecords.some((record) => !record.executable_example)) failures.push("Every public record must carry executable example evidence.");

const declaredWebTargets = documentationRecords.flatMap((record) => [
  [record.web_route_or_anchor, `${record.id}.web_route_or_anchor`],
  [record.web_example_evidence, `${record.id}.web_example_evidence`],
]);
const declaredTargetOwners = new Map();
for (const [target, owner] of declaredWebTargets) {
  const owners = declaredTargetOwners.get(target) ?? [];
  owners.push(owner);
  declaredTargetOwners.set(target, owners);
}
const duplicateDeclaredTargets = [...declaredTargetOwners]
  .filter(([, owners]) => owners.length > 1)
  .map(([target, owners]) => `${target} (${owners.join(", ")})`);
if (declaredWebTargets.length !== 384 || declaredTargetOwners.size !== 384) {
  failures.push(
    `Expected 384 unique API and example targets, found ${declaredTargetOwners.size}: ${duplicateDeclaredTargets.join(" | ")}`,
  );
}

// Resolve inventory evidence against authored routes, not only against JSON shape.
const docsRoot = join(root, "src/content/docs");
const routeSources = new Map(
  walk(docsRoot)
    .filter((file) => [".md", ".mdx"].includes(extname(file)))
    .map((file) => {
      const relativePath = relative(docsRoot, file).replace(/\\/g, "/");
      const stem = relativePath.slice(0, -extname(file).length);
      const route = stem === "index"
        ? "/"
        : stem.endsWith("/index")
          ? `/${stem.slice(0, -"/index".length)}/`
          : `/${stem}/`;
      return [route, readFileSync(file, "utf8")];
    }),
);
const apiInventorySource = readFileSync(join(root, "src/components/ApiInventory.astro"), "utf8");
const dynamicInventoryContract = apiInventorySource.includes("id={anchor}")
  && apiInventorySource.includes("id={exampleAnchor}")
  && apiInventorySource.includes("record.web_route_or_anchor.split")
  && apiInventorySource.includes("record.web_example_evidence.split");
for (const record of documentationRecords) {
  for (const field of ["web_route_or_anchor", "web_example_evidence"]) {
    const [route, anchor] = record[field].split("#");
    const source = routeSources.get(route);
    const dynamicOwnerInventory = dynamicInventoryContract
      && source?.includes(`<ApiInventory owner="${record.owner}" />`);
    if (!source) failures.push(`${record.id} points ${field} to missing route ${route}.`);
    else if (!anchor || (!source.includes(`id="${anchor}"`) && !dynamicOwnerInventory)) {
      failures.push(`${record.id} points ${field} to missing anchor ${record[field]}.`);
    }
  }
}

const sourceFiles = walk(join(root, "src")).filter((file) => [".md", ".mdx", ".astro", ".tsx", ".ts", ".js"].includes(extname(file)));
for (const file of sourceFiles) {
  if (file.endsWith("documentation-contracts.js") || file.endsWith("katex-options.js")) continue;
  const source = readFileSync(file, "utf8");
  if (bannedIndexSetPattern.test(source)) {
    failures.push(`${relative(root, file)} uses the banned named complete-label set.`);
  }
  const legacy = source.match(/\\(?:mathbf|boldsymbol)\b/g);
  if (legacy) failures.push(`${relative(root, file)} uses legacy vector commands: ${[...new Set(legacy)].join(", ")}.`);
}

const canonicalDefinitions = new Map([
  ["grid-lmia", "src/components/HomePortal.astro"],
  ["lmi", "src/content/docs/documents/math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain.mdx"],
  ["pd-lmi", "src/content/docs/documents/math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain.mdx"],
  ["dpd-lmi", "src/content/docs/documents/math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain.mdx"],
  ["lpv", "src/content/docs/documents/math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain.mdx"],
  ["psd", "src/content/docs/documents/math/sos-certificates.mdx"],
  ["sos", "src/content/docs/documents/math/sos-certificates.mdx"],
  ["sdp", "src/content/docs/documents/math/sos-certificates.mdx"],
]);
for (const term of terminologyTerms) {
  const file = canonicalDefinitions.get(term.id);
  const source = file ? readFileSync(join(root, file), "utf8") : "";
  if (!source.includes(`<Term id="${term.id}" definition />`)) failures.push(`Missing canonical definition for ${term.id}.`);
}

const bannedPattern = /\b(?:delve|tapestry|myriad|groundbreaking|game-changing|seamless|seamlessly|transformative|intricate|multifaceted|holistic|revolutionary|unlock|unlocks|unlocking)\b/i;
for (const file of sourceFiles.filter((path) => /src[\\/]content[\\/]docs[\\/].*\.(?:md|mdx)$/.test(path))) {
  const prose = markdownProseLines(readFileSync(file, "utf8"));
  for (const entry of prose) {
    if (negativePattern.test(entry.text) && !entry.allowedNegative) {
      failures.push(`${relative(root, file)}:${entry.line} contains negative prose outside an allowed boundary context: ${entry.text}`);
    }
    if (bannedPattern.test(entry.text)) {
      failures.push(`${relative(root, file)}:${entry.line} contains promotional prose: ${entry.text}`);
    }
    if (entry.text.includes(";")) {
      failures.push(`${relative(root, file)}:${entry.line} contains a prose semicolon: ${entry.text}`);
    }
    const generatedReferenceIdentifier = file.endsWith("reference-index.mdx");
    if (!generatedReferenceIdentifier && hasLowercaseSentenceStart(entry.text, entry.startsSentence)) {
      failures.push(`${relative(root, file)}:${entry.line} contains a lowercase ordinary sentence start: ${entry.text}`);
    }
  }
}
for (const file of sourceFiles.filter((path) => /src[\\/]components[\\/].*\.(?:astro|tsx)$/.test(path))) {
  if (file.endsWith("Term.astro") || file.endsWith("TermText.tsx")) continue;
  const source = readFileSync(file, "utf8");
  const entries = componentUserVisibleEntries(source, relative(root, file));
  const negativeEntries = componentUserVisibleEntries(stripAllowedComponentContexts(source), relative(root, file));
  for (const entry of entries) {
    if (/\b(?:const|export|function|interface|return)\b|=>|^\s*\{/.test(entry.text)) continue;
    const label = `${relative(root, file)}:${entry.line} ${entry.origin}`;
    if (bannedPattern.test(entry.text)) failures.push(`${label} contains promotional component prose: ${entry.text}`);
    if (entry.text.includes(";")) failures.push(`${label} contains a component-prose semicolon: ${entry.text}`);
    const dataSentence = entry.origin.startsWith("data:") && !/data:(?:inlineNoteParts|textParts)/.test(entry.origin) && /[.!?][\"')\]]?$/.test(entry.text);
    if (hasLowercaseSentenceStart(entry.text, dataSentence)) failures.push(`${label} contains a lowercase ordinary sentence start: ${entry.text}`);
  }
  for (const entry of negativeEntries) {
    if (/\b(?:const|export|function|interface|return)\b|=>|^\s*\{/.test(entry.text)) continue;
    if (negativePattern.test(entry.text)) failures.push(`${relative(root, file)}:${entry.line} ${entry.origin} contains negative component prose: ${entry.text}`);
  }
  const prose = componentProse(source, file);
  for (const term of terminologyTerms.filter((candidate) => candidate.auto_link)) {
    if (new RegExp(`\\b${term.abbreviation.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`).test(prose)) {
      failures.push(`${relative(root, file)} contains raw registered component prose: ${term.abbreviation}.`);
    }
  }
}

for (const relativeFile of ["astro.config.mjs", "src/data/version-history.js"]) {
  const file = join(root, relativeFile);
  for (const entry of componentUserVisibleEntries(readFileSync(file, "utf8"), relativeFile)) {
    const label = `${relativeFile}:${entry.line} ${entry.origin}`;
    if (negativePattern.test(entry.text)) failures.push(`${label} contains negative user-visible data copy: ${entry.text}`);
    if (bannedPattern.test(entry.text)) failures.push(`${label} contains promotional user-visible data copy: ${entry.text}`);
    if (entry.text.includes(";")) failures.push(`${label} contains a user-visible data semicolon: ${entry.text}`);
    if (entry.origin === "version-summary" && hasLowercaseSentenceStart(entry.text)) failures.push(`${label} contains a lowercase user-visible sentence start: ${entry.text}`);
  }
}

for (const certificate of certificateSources) {
  for (const field of ["description", "constraintCount"]) {
    const prose = certificate[field];
    const label = "src/data/certificate-data.ts " + certificate.key + "." + field;
    if (negativePattern.test(prose)) failures.push(label + " contains negative component prose.");
    if (bannedPattern.test(prose)) failures.push(label + " contains promotional component prose.");
    if (prose.includes(";")) failures.push(label + " contains a component-prose semicolon.");
    if (hasLowercaseSentenceStart(prose)) failures.push(label + " contains a lowercase ordinary sentence start.");
  }
  const boundaryLabel = "src/data/certificate-data.ts " + certificate.key + ".boundaryNote";
  if (bannedPattern.test(certificate.boundaryNote)) failures.push(boundaryLabel + " contains promotional component prose.");
  if (certificate.boundaryNote.includes(";")) failures.push(boundaryLabel + " contains a component-prose semicolon.");
  if (hasLowercaseSentenceStart(certificate.boundaryNote)) failures.push(boundaryLabel + " contains a lowercase ordinary sentence start.");
}

const headingPattern = /^#{1,6} .*\b(?:not|no|without|cannot|rather than)\b.*$/gim;
for (const file of sourceFiles.filter((path) => /\.(?:md|mdx)$/.test(path))) {
  const headings = readFileSync(file, "utf8").match(headingPattern) ?? [];
  if (headings.length) failures.push(`${relative(root, file)} contains negative headings: ${headings.join(" | ")}`);
}

if (failures.length) {
  console.error(`Documentation audit failed with ${failures.length} finding(s):`);
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log("Documentation audit passed: 192 public API records, 8 governed terms, semantic vectors, canonical definitions, contextual boundary prose, and style checks.");
