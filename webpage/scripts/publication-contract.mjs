import { createHash } from "node:crypto";
import { readFile, readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { inflateSync } from "node:zlib";

export const expectedPublication = Object.freeze({
  documentationVersion: "v1.4.1",
  latestTaggedRelease: "v1.4.0",
  apiRecordCount: 194,
  manualSha256: "BE919243836777DB5E098225473845FF65C4FC9E4F10574050DCD9DA9B460C92",
  manualPageCount: 178,
});

const fixedArtifacts = [
  "src/data/documentation-contracts.js",
  "src/data/version.js",
  "src/data/version-history.js",
  "src/content/docs/documents/reference-index.mdx",
  "public/plots/pdmat-plot-1d.png",
  "public/plots/pdmat-plot-2d.png",
  "public/plots/pdmat-plot-2d-matrix.png",
];

const fail = (message) => {
  throw new Error(`[publication-contract] ${message}`);
};

export async function sha256File(file) {
  const bytes = await readFile(file);
  return createHash("sha256").update(bytes).digest("hex").toUpperCase();
}

export async function pdfPageCount(file) {
  const bytes = await readFile(file);
  const fragments = [bytes.toString("latin1")];
  const streamMarker = Buffer.from("stream");
  const endMarker = Buffer.from("endstream");
  let cursor = 0;

  while ((cursor = bytes.indexOf(streamMarker, cursor)) >= 0) {
    let start = cursor + streamMarker.length;
    if (bytes[start] === 13) start += 1;
    if (bytes[start] === 10) start += 1;
    const end = bytes.indexOf(endMarker, start);
    if (end < 0) break;
    let payload = bytes.subarray(start, end);
    while (payload.length && (payload.at(-1) === 10 || payload.at(-1) === 13)) {
      payload = payload.subarray(0, -1);
    }
    try {
      fragments.push(inflateSync(payload).toString("latin1"));
    } catch {
      // Other stream encodings carry images, fonts, or visible objects.
    }
    cursor = end + endMarker.length;
  }

  const counts = fragments.flatMap((fragment) => [...fragment.matchAll(
    /\/Type\s*\/Pages\b[\s\S]{0,500}?\/Count\s+(\d+)/g,
  )].map((match) => Number(match[1])));
  if (!counts.length) fail(`Could not read the page tree in ${file}.`);
  return Math.max(...counts);
}

async function artifactPaths(webpageRoot) {
  const graphRoot = path.join(webpageRoot, "src/assets/call-graphs");
  const graphs = (await readdir(graphRoot))
    .filter((name) => name.endsWith(".svg"))
    .sort()
    .map((name) => `src/assets/call-graphs/${name}`);
  return [...fixedArtifacts, ...graphs];
}

function versionFromGenerated(source) {
  const match = source.match(/current:\s*"([^"]+)"/);
  if (!match) fail("Generated version.js has no current version.");
  return match[1];
}

function recordCountFromGenerated(source) {
  const match = source.match(/["']?records["']?\s*:\s*(\d+)/);
  if (!match) fail("Generated documentation contracts have no record summary.");
  return Number(match[1]);
}

export function validateVersionHistorySource(source) {
  const rows = [...source.matchAll(
    /version:\s*"([^"]+)"[\s\S]*?status:\s*"([^"]+)"/g,
  )].map((match) => ({ version: match[1], status: match[2] }));
  const current = rows[0];
  const tagged = rows[1];
  if (current?.version !== expectedPublication.documentationVersion
      || current?.status !== "current documentation snapshot") {
    fail(`Version-history row 1 must be ${expectedPublication.documentationVersion} with current documentation snapshot status.`);
  }
  if (tagged?.version !== expectedPublication.latestTaggedRelease
      || tagged?.status !== "latest tagged GitHub Release") {
    fail(`Version-history row 2 must be ${expectedPublication.latestTaggedRelease} with latest tagged GitHub Release status.`);
  }
  return rows;
}

export async function createPublicationManifest(webpageRoot) {
  const repositoryRoot = path.resolve(webpageRoot, "..");
  const manualPath = path.join(repositoryRoot, "doc/manual.pdf");
  const versionSource = await readFile(path.join(webpageRoot, "src/data/version.js"), "utf8");
  const contractSource = await readFile(path.join(webpageRoot, "src/data/documentation-contracts.js"), "utf8");
  const versionHistorySource = await readFile(path.join(webpageRoot, "src/data/version-history.js"), "utf8");
  const documentationVersion = versionFromGenerated(versionSource);
  const apiRecordCount = recordCountFromGenerated(contractSource);
  validateVersionHistorySource(versionHistorySource);
  const manualSha256 = await sha256File(manualPath);
  const manualPageCount = await pdfPageCount(manualPath);

  if (documentationVersion !== expectedPublication.documentationVersion) {
    fail(`Expected ${expectedPublication.documentationVersion}, found ${documentationVersion}.`);
  }
  if (apiRecordCount !== expectedPublication.apiRecordCount) {
    fail(`Expected ${expectedPublication.apiRecordCount} API records, found ${apiRecordCount}.`);
  }
  if (manualSha256 !== expectedPublication.manualSha256) {
    fail(`Manual SHA-256 mismatch: expected ${expectedPublication.manualSha256}, found ${manualSha256}.`);
  }
  if (manualPageCount !== expectedPublication.manualPageCount) {
    fail(`Manual page-count mismatch: expected ${expectedPublication.manualPageCount}, found ${manualPageCount}.`);
  }

  const artifacts = {};
  for (const relativePath of await artifactPaths(webpageRoot)) {
    artifacts[relativePath] = await sha256File(path.join(webpageRoot, relativePath));
  }

  return {
    schemaVersion: 1,
    documentationVersion,
    latestTaggedRelease: expectedPublication.latestTaggedRelease,
    apiRecordCount,
    manual: {
      repositoryPath: "doc/manual.pdf",
      sha256: manualSha256,
      pageCount: manualPageCount,
    },
    artifacts,
  };
}

export async function writePublicationManifest(webpageRoot) {
  const manifest = await createPublicationManifest(webpageRoot);
  const destination = path.join(webpageRoot, "src/data/publication-manifest.json");
  await writeFile(destination, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
  return manifest;
}

export async function validatePublicationManifest(webpageRoot) {
  const repositoryRoot = path.resolve(webpageRoot, "..");
  const manifestPath = path.join(webpageRoot, "src/data/publication-manifest.json");
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  } catch (error) {
    fail(`Cannot read ${manifestPath}: ${error.message}`);
  }

  for (const [key, expected] of Object.entries({
    schemaVersion: 1,
    documentationVersion: expectedPublication.documentationVersion,
    latestTaggedRelease: expectedPublication.latestTaggedRelease,
    apiRecordCount: expectedPublication.apiRecordCount,
  })) {
    if (manifest[key] !== expected) fail(`Manifest ${key} must equal ${expected}.`);
  }
  if (manifest.manual?.repositoryPath !== "doc/manual.pdf") fail("Manifest manual path must be doc/manual.pdf.");
  if (manifest.manual?.sha256 !== expectedPublication.manualSha256) fail("Manifest manual SHA-256 is stale.");
  if (manifest.manual?.pageCount !== expectedPublication.manualPageCount) fail("Manifest manual page count is stale.");

  const manualPath = path.join(repositoryRoot, manifest.manual.repositoryPath);
  const actualManualHash = await sha256File(manualPath);
  const actualPageCount = await pdfPageCount(manualPath);
  if (actualManualHash !== manifest.manual.sha256) fail(`Manual SHA-256 mismatch: ${actualManualHash}.`);
  if (actualPageCount !== manifest.manual.pageCount) fail(`Manual page-count mismatch: ${actualPageCount}.`);

  const versionHistorySource = await readFile(path.join(webpageRoot, "src/data/version-history.js"), "utf8");
  validateVersionHistorySource(versionHistorySource);

  const requiredArtifacts = await artifactPaths(webpageRoot);
  const manifestArtifacts = Object.keys(manifest.artifacts ?? {}).sort();
  if (JSON.stringify(manifestArtifacts) !== JSON.stringify([...requiredArtifacts].sort())) {
    fail("Manifest artifact list is missing, stale, or contains unexpected paths.");
  }
  for (const relativePath of requiredArtifacts) {
    const actual = await sha256File(path.join(webpageRoot, relativePath));
    if (actual !== manifest.artifacts[relativePath]) fail(`Artifact hash mismatch: ${relativePath}.`);
  }
  return manifest;
}
