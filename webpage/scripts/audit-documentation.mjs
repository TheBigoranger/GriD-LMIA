import { execFileSync } from "node:child_process";
import { readFileSync, readdirSync } from "node:fs";
import { extname, join, relative, resolve } from "node:path";
import { documentationRecords, terminologyTerms } from "../src/data/documentation-contracts.js";
import { referenceEntries } from "../src/data/reference-index.js";

const root = resolve(import.meta.dirname, "..");
const failures = [];

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

const sourceFiles = walk(join(root, "src")).filter((file) => [".md", ".mdx", ".astro", ".tsx", ".ts", ".js"].includes(extname(file)));
for (const file of sourceFiles) {
  if (file.endsWith("documentation-contracts.js") || file.endsWith("katex-options.js")) continue;
  const source = readFileSync(file, "utf8");
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

const negativePattern = /\b(?:is not|are not|was not|were not|does not|do not|did not|cannot|can't|without|rather than|not|no)\b/i;
const bannedPattern = /\b(?:delve|tapestry|myriad|groundbreaking|game-changing|seamless|seamlessly|transformative|intricate|multifaceted|holistic|revolutionary|unlock|unlocks|unlocking)\b/i;
for (const file of sourceFiles.filter((path) => /src[\\/]content[\\/]docs[\\/].*\.(?:md|mdx)$/.test(path))) {
  const prose = markdownProse(readFileSync(file, "utf8"));
  const negative = prose.split(/\r?\n/).filter((line) => negativePattern.test(line));
  const banned = prose.split(/\r?\n/).find((line) => bannedPattern.test(line));
  for (const line of negative) failures.push(`${relative(root, file)} contains negative prose: ${line.trim()}`);
  if (banned) failures.push(`${relative(root, file)} contains promotional prose: ${banned.trim()}`);
  for (const line of prose.split(/\r?\n/).filter((candidate) => candidate.includes(";"))) {
    failures.push(`${relative(root, file)} contains a prose semicolon: ${line.trim()}`);
  }
}
for (const file of sourceFiles.filter((path) => /src[\\/]components[\\/].*\.(?:astro|tsx)$/.test(path))) {
  if (file.endsWith("Term.astro") || file.endsWith("TermText.tsx")) continue;
  const prose = componentProse(readFileSync(file, "utf8"), file);
  const negative = prose.split(/\r?\n/).filter((line) => negativePattern.test(line));
  for (const line of negative) failures.push(`${relative(root, file)} contains negative component prose: ${line.trim()}`);
  if (prose.includes(";")) failures.push(`${relative(root, file)} contains a component-prose semicolon.`);
  for (const term of terminologyTerms.filter((candidate) => candidate.auto_link)) {
    if (new RegExp(`\\b${term.abbreviation.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`).test(prose)) {
      failures.push(`${relative(root, file)} contains raw registered component prose: ${term.abbreviation}.`);
    }
  }
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

console.log("Documentation audit passed: 192 public API records, 8 governed terms, semantic vectors, canonical definitions, affirmative prose, and style checks.");
