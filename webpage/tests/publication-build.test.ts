import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import {
  expectedPublication,
  pdfPageCount,
  sha256ArtifactBytes,
  sha256File,
  validatePublicationManifest,
  validateVersionHistorySource,
} from "../scripts/publication-contract.mjs";

const webpageRoot = path.resolve(import.meta.dirname, "..");
const repositoryRoot = path.resolve(webpageRoot, "..");
const read = (file: string) => readFileSync(path.join(webpageRoot, file), "utf8");

test("pins the accepted printable manual identity", async () => {
  const manual = path.join(repositoryRoot, "doc/manual.pdf");
  assert.equal(await sha256File(manual), expectedPublication.manualSha256);
  assert.equal(await pdfPageCount(manual), expectedPublication.manualPageCount);
  assert.deepEqual(expectedPublication, {
    documentationVersion: "v1.5.0",
    latestTaggedRelease: "v1.5.0",
    apiRecordCount: 197,
    manualSha256: "86E50D7110108128A2D7386A35532315E5D93591B754FD7FD7F81F544774101F",
    manualPageCount: 184,
  });
});

test("keeps publish mode independent from unpublished documentation sources", () => {
  const prepare = read("scripts/prepare-build.mjs");
  const copyManual = read("scripts/copy-manual.mjs");
  const terminology = read("src/lib/remark-terminology-links.js");

  assert.match(prepare, /GRID_LMIA_DOC_BUILD_MODE/);
  assert.match(prepare, /validatePublicationManifest/);
  assert.doesNotMatch(copyManual, /matlab-figures/);
  assert.match(terminology, /documentation-contracts\.js/);
  assert.doesNotMatch(terminology, /doc\/support/);
});

test("validates the committed publication manifest", async () => {
  const manifest = await validatePublicationManifest(webpageRoot);
  assert.equal(manifest.documentationVersion, "v1.5.0");
  assert.equal(manifest.apiRecordCount, 197);
  assert.equal(manifest.manual.pageCount, 184);
});

test("normalizes generated text line endings without normalizing binary artifacts", () => {
  const lf = Buffer.from("export const value = 1;\n");
  const crlf = Buffer.from("export const value = 1;\r\n");
  assert.equal(sha256ArtifactBytes(lf, ".js"), sha256ArtifactBytes(crlf, ".js"));
  assert.notEqual(sha256ArtifactBytes(lf, ".png"), sha256ArtifactBytes(crlf, ".png"));
});

test("rejects stale visible version-history roles", () => {
  const staleCurrent = `export const versionHistory = [
    { version: "v1.4.0", status: "current documentation snapshot" },
    { version: "v1.4.0", status: "latest tagged GitHub Release" },
  ];`;
  const staleTag = `export const versionHistory = [
    { version: "v1.5.0", status: "current documentation snapshot" },
    { version: "v1.3.8", status: "latest tagged GitHub Release" },
  ];`;

  assert.throws(() => validateVersionHistorySource(staleCurrent), /row 1 must be v1\.5\.0/);
  assert.throws(() => validateVersionHistorySource(staleTag), /tagged entry must be v1\.5\.0/);
});
