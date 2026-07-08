import { readFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const base = "/DP-LMI-package";
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
  cache.set(file, { html, ids: idsIn(html) });
}

for (const [file, page] of cache) {
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
        targetPage = { html, ids: idsIn(html) };
        cache.set(target, targetPage);
      }
      if (!targetPage.ids.has(anchor)) {
        failures.push(`${file}: missing anchor ${href}`);
      }
    }
  }
}

if (failures.length) {
  console.error([...badBaseLinks, ...failures].join("\n"));
  process.exit(1);
}

if (badBaseLinks.length) {
  console.error(badBaseLinks.join("\n"));
  process.exit(1);
}

console.log(`Checked ${htmlFiles.length} HTML files for ${base} internal links.`);
