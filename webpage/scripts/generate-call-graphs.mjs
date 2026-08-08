import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = path.resolve(import.meta.dirname, "..");
const sourceDir = path.join(root, "src", "diagrams", "call-graphs");
const outputDir = path.join(root, "src", "assets", "call-graphs");
const configFile = path.join(root, "scripts", "mermaid-config.json");
const puppeteerConfigFile = path.join(root, "scripts", "puppeteer-config.json");
const executable = path.join(root, "node_modules", "@mermaid-js", "mermaid-cli", "src", "cli.js");
const sources = fs.readdirSync(sourceDir).filter((file) => file.endsWith(".mmd")).sort();
const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "grid-lmia-mermaid-"));

fs.mkdirSync(outputDir, { recursive: true });

try {
  // A source file is authoritative. Only its top-level direction changes:
  // LR for desktop and TB for mobile. Temporary variants never enter source.
  for (const sourceName of sources) {
    const family = path.basename(sourceName, ".mmd");
    const source = fs.readFileSync(path.join(sourceDir, sourceName), "utf8");
    for (const [layout, direction] of [["desktop", "LR"], ["mobile", "TB"]]) {
      const input = path.join(tempDir, `${family}-${layout}.mmd`);
      fs.writeFileSync(input, source.replace(/^flowchart\s+(?:LR|TB)/, `flowchart ${direction}`));
      for (const theme of ["light", "dark"]) {
        const output = path.join(outputDir, `${family}-${layout}-${theme}.svg`);
        const result = spawnSync(process.execPath, [executable,
          "-i", input,
          "-o", output,
          "--configFile", configFile,
          "--puppeteerConfigFile", puppeteerConfigFile,
          "--theme", theme === "dark" ? "dark" : "neutral",
          "--backgroundColor", "transparent",
          "--quiet",
        ], { cwd: root, encoding: "utf8" });
        if (result.status !== 0) {
          throw new Error(`Mermaid failed for ${family}/${layout}/${theme}: ${result.error?.message || result.stderr || result.stdout || `exit ${result.status}`}`);
        }
      }
    }
  }
} finally {
  // Keep build-time variants isolated even when Mermaid fails midway.
  fs.rmSync(tempDir, { recursive: true, force: true });
}

console.log(`Generated ${sources.length * 4} deterministic call-graph SVGs.`);
