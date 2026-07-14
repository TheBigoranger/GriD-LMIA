import { copyFile, mkdir, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const webpageDirectory = path.resolve(scriptDirectory, "..");
const source = path.resolve(webpageDirectory, "..", "doc", "manual.pdf");
const destination = path.resolve(webpageDirectory, "public", "manual.pdf");

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
  } catch (error) {
    fail(`Could not copy the manual to ${destination}: ${error.message}`);
  }
}
