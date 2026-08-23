import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  validatePublicationManifest,
  writePublicationManifest,
} from "./publication-contract.mjs";

const webpageRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const modeArgument = process.argv.find((argument) => argument.startsWith("--mode="));
const explicitMode = modeArgument?.slice("--mode=".length);
const environmentMode = process.env.GRID_LMIA_DOC_BUILD_MODE;
if (explicitMode && environmentMode && explicitMode !== environmentMode) {
  throw new Error("[prepare-build] CLI and GRID_LMIA_DOC_BUILD_MODE select different modes.");
}
const mode = explicitMode ?? environmentMode ?? "source";

if (!new Set(["source", "publish"]).has(mode)) {
  throw new Error("[prepare-build] Select source or publish build mode.");
}

const run = (script, ...args) => execFileSync(
  process.execPath,
  [path.join(webpageRoot, "scripts", script), ...args],
  { cwd: webpageRoot, stdio: "inherit" },
);

if (mode === "source") {
  run("sync-documentation-contracts.mjs");
  run("sync-version.mjs");
  run("generate-reference-index.mjs");
  run("generate-call-graphs.mjs");
  run("copy-manual.mjs");
  const manifest = await writePublicationManifest(webpageRoot);
  console.log(`[prepare-build] Source mode generated ${manifest.apiRecordCount} records and ${manifest.documentationVersion}.`);
} else {
  const manifest = await validatePublicationManifest(webpageRoot);
  run("copy-manual.mjs");
  console.log(`[prepare-build] Publish mode validated ${manifest.documentationVersion}, ${manifest.manual.pageCount} pages, and committed generated assets.`);
}
