import { copyFile, mkdir, rm, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const webpageDirectory = path.resolve(scriptDirectory, "..");
const source = path.resolve(webpageDirectory, "..", "doc", "manual.pdf");
const destination = path.resolve(webpageDirectory, "public", "manual.pdf");
const plotNames = ["pdmat-plot-1d.png", "pdmat-plot-2d.png", "pdmat-plot-2d-matrix.png"];
const obsoletePlotNames = ["pdmat-plot-3d-slice.png"];

const fail = (message) => {
  console.error(`[copy-manual] ${message}`);
  process.exitCode = 1;
};

let sourceStat;
try {
  sourceStat = await stat(source);
} catch (error) {
  fail(`Cannot read source PDF at ${source}: ${error.message}`);
}

if (sourceStat && !sourceStat.isFile()) {
  fail(`Source PDF is not a regular file: ${source}`);
}

if (process.exitCode !== 1) {
  try {
    await mkdir(path.dirname(destination), { recursive: true });
    await copyFile(source, destination);
    console.log(`[copy-manual] Copied ${source} to ${destination}`);
    for (const plotName of plotNames) {
      const plotSource = path.resolve(webpageDirectory, "..", "doc", "matlab-figures", plotName);
      const plotDestination = path.resolve(webpageDirectory, "public", "plots", plotName);
      await mkdir(path.dirname(plotDestination), { recursive: true });
      await copyFile(plotSource, plotDestination);
      console.log(`[copy-manual] Copied ${plotSource} to ${plotDestination}`);
    }
    for (const plotName of obsoletePlotNames) {
      const obsoleteDestination = path.resolve(webpageDirectory, "public", "plots", plotName);
      await rm(obsoleteDestination, { force: true });
      console.log(`[copy-manual] Removed obsolete ${obsoleteDestination}`);
    }
  } catch (error) {
    fail(`Could not copy the manual to ${destination}: ${error.message}`);
  }
}
