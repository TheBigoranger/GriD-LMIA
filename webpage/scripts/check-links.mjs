import { readFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { documentationRecords } from "../src/data/documentation-contracts.js";

const base = "/GriD-LMIA";
const here = dirname(fileURLToPath(import.meta.url));
const dist = resolve(here, "../dist");
const htmlFiles = [];
const failures = [];
const badBaseLinks = [];

async function walk(dir) {
  for (const item of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, item.name);
    if (item.isDirectory()) {
      await walk(full);
    } else if (extname(item.name) === ".html") {
      htmlFiles.push(full);
    }
  }
}

function htmlPath(urlPath) {
  const clean = urlPath.replace(/\/$/, "");
  if (clean === "") return join(dist, "index.html");
  return join(dist, clean, "index.html");
}

function assetPath(urlPath) {
  const clean = urlPath.replace(/^\//, "");
  return join(dist, clean);
}

function isPageRoute(urlPath) {
  const last = urlPath.split("/").pop() ?? "";
  return !last.includes(".");
}

function idsIn(html) {
  const ids = new Set();
  const idRe = /\sid="([^"]+)"/g;
  const nameRe = /\sname="([^"]+)"/g;
  for (const re of [idRe, nameRe]) {
    let match;
    while ((match = re.exec(html))) ids.add(match[1]);
  }
  return ids;
}

function idCountsIn(html) {
  const counts = new Map();
  const re = /\sid="([^"]+)"/g;
  let match;
  while ((match = re.exec(html))) {
    counts.set(match[1], (counts.get(match[1]) ?? 0) + 1);
  }
  return counts;
}

function hrefsIn(html) {
  const hrefs = [];
  const re = /href="([^"]+)"/g;
  let match;
  while ((match = re.exec(html))) hrefs.push(match[1]);
  return hrefs;
}

function isLocalRootLink(href) {
  return href.startsWith("/") && !href.startsWith(base) && !href.startsWith("//");
}

if (!existsSync(dist)) {
  throw new Error("webpage/dist does not exist. Run npm --prefix webpage run build first.");
}

await walk(dist);

const cache = new Map();
for (const file of htmlFiles) {
  const html = await readFile(file, "utf8");
  cache.set(file, { html, ids: idsIn(html), idCounts: idCountsIn(html) });
}

for (const [file, page] of cache) {
  for (const [id, count] of page.idCounts) {
    if (count > 1) failures.push(`${file}: duplicate id ${id} appears ${count} times`);
  }
  for (const href of hrefsIn(page.html)) {
    if (isLocalRootLink(href)) {
      badBaseLinks.push(`${file}: root link missing ${base} base path: ${href}`);
      continue;
    }

    if (!href.startsWith(base)) continue;
    const [urlPath, anchor] = href.slice(base.length).split("#");
    if (!isPageRoute(urlPath)) {
      const targetAsset = assetPath(urlPath);
      if (!existsSync(targetAsset)) failures.push(`${file}: missing asset ${href}`);
      continue;
    }

    const target = htmlPath(urlPath);
    if (!existsSync(target)) {
      failures.push(`${file}: missing page ${href}`);
      continue;
    }

    if (anchor) {
      let targetPage = cache.get(target);
      if (!targetPage) {
        const html = await readFile(target, "utf8");
        targetPage = { html, ids: idsIn(html), idCounts: idCountsIn(html) };
        cache.set(target, targetPage);
      }
      if (!targetPage.ids.has(anchor)) {
        failures.push(`${file}: missing anchor ${href}`);
      }
    }
  }
}

const declaredTargets = documentationRecords.flatMap((record) => [
  [record.web_route_or_anchor, `${record.id}.web_route_or_anchor`],
  [record.web_example_evidence, `${record.id}.web_example_evidence`],
]);
const uniqueDeclaredTargets = new Map();
for (const [target, owner] of declaredTargets) {
  const owners = uniqueDeclaredTargets.get(target) ?? [];
  owners.push(owner);
  uniqueDeclaredTargets.set(target, owners);
}
for (const [target, owners] of uniqueDeclaredTargets) {
  if (owners.length > 1) {
    failures.push(`duplicate declared API target ${target}: ${owners.join(", ")}`);
    continue;
  }
  const [urlPath, anchor] = target.split("#");
  const targetFile = htmlPath(urlPath);
  const targetPage = cache.get(targetFile);
  const renderedCount = targetPage?.idCounts.get(anchor) ?? 0;
  if (renderedCount !== 1) {
    failures.push(`${owners[0]} target ${target} renders ${renderedCount} times; expected exactly once`);
  }
}
if (declaredTargets.length !== 384 || uniqueDeclaredTargets.size !== 384) {
  failures.push(`expected 384 unique declared API targets, found ${uniqueDeclaredTargets.size}`);
}

if (failures.length) {
  console.error([...badBaseLinks, ...failures].join("\n"));
  process.exit(1);
}

if (badBaseLinks.length) {
  console.error(badBaseLinks.join("\n"));
  process.exit(1);
}

console.log(`Checked ${htmlFiles.length} HTML files, unique IDs, and 384 API/example targets for ${base} internal links.`);
