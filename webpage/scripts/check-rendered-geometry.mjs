import { createServer } from "node:http";
import { access, readFile, readdir, stat } from "node:fs/promises";
import { extname, join, relative, resolve, sep } from "node:path";
import { chromium } from "playwright";

const root = resolve("dist");
const base = "/PD-LMI-package";
const defaultViewports = [390, 768, 1024, 1440];
const tolerance = 1;

function commaSeparated(value) {
  return value?.split(",").map((item) => item.trim()).filter(Boolean) ?? [];
}

function selectedViewports() {
  const requested = commaSeparated(process.env.GEOMETRY_VIEWPORTS);
  if (!requested.length) return defaultViewports;
  const widths = requested.map(Number);
  if (widths.some((width) => !Number.isInteger(width) || width <= 0)) {
    throw new Error("GEOMETRY_VIEWPORTS must be a comma-separated list of positive integer widths.");
  }
  return [...new Set(widths)];
}

function selectRoutes(routes) {
  const requested = commaSeparated(process.env.GEOMETRY_ROUTES);
  if (!requested.length) return routes;

  const matches = (route, filter) => filter.startsWith("/")
    ? route === filter
    : route.endsWith(`/${filter.replace(/^\/+/, "")}`);
  const selected = routes.filter((route) => requested.some((filter) => matches(route, filter)));
  const unmatched = requested.filter((filter) => !routes.some((route) => matches(route, filter)));
  if (unmatched.length) {
    throw new Error(`GEOMETRY_ROUTES did not match: ${unmatched.join(", ")}`);
  }
  return selected;
}

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = await Promise.all(entries.map(async (entry) => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  }));
  return files.flat();
}

function routeFor(file) {
  const rel = relative(root, file).split(sep).join("/");
  if (rel === "index.html") return `${base}/`;
  if (rel.endsWith("/index.html")) return `${base}/${rel.slice(0, -10)}`;
  return `${base}/${rel}`;
}

function contentType(path) {
  return {
    ".css": "text/css; charset=utf-8",
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".pdf": "application/pdf",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
  }[extname(path)] ?? "application/octet-stream";
}

async function resolveRequest(pathname) {
  let local = decodeURIComponent(pathname);
  if (local === base) local = `${base}/`;
  if (!local.startsWith(`${base}/`)) return null;
  local = local.slice(base.length + 1);

  const candidate = resolve(root, local);
  if (!candidate.startsWith(`${root}${sep}`) && candidate !== root) return null;

  try {
    const info = await stat(candidate);
    if (info.isFile()) return candidate;
    if (info.isDirectory()) return join(candidate, "index.html");
  } catch {
    // Extensionless Astro routes are directories in the static build.
    const index = join(candidate, "index.html");
    try {
      await access(index);
      return index;
    } catch {
      return null;
    }
  }
  return null;
}

async function startServer() {
  const server = createServer(async (request, response) => {
    const url = new URL(request.url ?? "/", "http://127.0.0.1");
    const path = await resolveRequest(url.pathname);
    if (!path) {
      response.writeHead(404);
      response.end("Not found");
      return;
    }

    try {
      const body = await readFile(path);
      response.writeHead(200, { "content-type": contentType(path) });
      response.end(body);
    } catch {
      response.writeHead(404);
      response.end("Not found");
    }
  });

  await new Promise((resolveListen) => server.listen(0, "127.0.0.1", resolveListen));
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Unable to start geometry server.");
  return { server, origin: `http://127.0.0.1:${address.port}` };
}

async function inspect(page) {
  return page.evaluate(({ tolerance }) => {
    const failures = [];
    const root = document.documentElement;
    const normalize = (value) => value?.replace(/\s+/g, " ").trim().slice(0, 180) ?? "";
    const describe = (node) => {
      const tag = node.tagName.toLowerCase();
      const id = node.id ? `#${node.id}` : "";
      const classes = [...node.classList].slice(0, 3).map((name) => `.${name}`).join("");
      return `${tag}${id}${classes}`;
    };
    const contextFor = (node, fallback = "") => {
      const aria = node.getAttribute?.("aria-label") ??
        node.closest?.("[aria-label]")?.getAttribute("aria-label");
      const tex = node.querySelector?.('annotation[encoding="application/x-tex"]')?.textContent;
      const caption = node.querySelector?.("figcaption")?.textContent;
      return normalize(aria || tex || caption || node.textContent || fallback);
    };
    if (root.scrollWidth > root.clientWidth + tolerance) {
      failures.push({
        type: "page",
        selector: "html",
        actual: root.scrollWidth,
        allowed: root.clientWidth,
        context: contextFor(document.querySelector("main") ?? document.body, document.title),
      });
    }

    // KaTeX displays are ordinary documentation formulas. Their rendered child,
    // not only the full-width wrapper, must stay inside the wrapper.
    for (const display of document.querySelectorAll(".katex-display")) {
      const formula = display.firstElementChild;
      if (!formula || display.closest("pre")) continue;
      const outer = display.getBoundingClientRect();
      const inner = formula.getBoundingClientRect();
      if (inner.left < outer.left - tolerance || inner.right > outer.right + tolerance) {
        failures.push({
          type: "formula-bounds",
          selector: describe(display),
          actual: Math.ceil(inner.width),
          allowed: Math.floor(outer.width),
          context: contextFor(display),
        });
      }
      if (display.scrollWidth > display.clientWidth + tolerance) {
        failures.push({
          type: "formula-width",
          selector: describe(display),
          actual: display.scrollWidth,
          allowed: display.clientWidth,
          context: contextFor(display),
        });
      }
    }

    for (const diagram of document.querySelectorAll(".diagram-frame")) {
      const rect = diagram.getBoundingClientRect();
      if (rect.left < -tolerance || rect.right > root.clientWidth + tolerance) {
        failures.push({
          type: "diagram-bounds",
          selector: describe(diagram),
          actual: Math.ceil(rect.width),
          allowed: root.clientWidth,
          context: contextFor(diagram),
        });
      }
      if (diagram.scrollWidth > diagram.clientWidth + tolerance) {
        failures.push({
          type: "diagram-width",
          selector: describe(diagram),
          actual: diagram.scrollWidth,
          allowed: diagram.clientWidth,
          context: contextFor(diagram),
        });
      }
    }

    return failures;
  }, { tolerance });
}

await access(join(root, "index.html"));
const allRoutes = (await walk(root))
  .filter((file) => file.endsWith(".html") && !file.endsWith("404.html"))
  .map(routeFor)
  .sort();
const routes = selectRoutes(allRoutes);
const viewports = selectedViewports();

const { server, origin } = await startServer();
const browser = await chromium.launch({ headless: true });
const failures = [];

try {
  const page = await browser.newPage();
  for (const width of viewports) {
    await page.setViewportSize({ width, height: 1000 });
    for (const route of routes) {
      const response = await page.goto(`${origin}${route}`, { waitUntil: "networkidle" });
      if (!response?.ok()) {
        failures.push({
          width,
          route,
          type: "http",
          selector: "document",
          status: response?.status() ?? "no response",
        });
        continue;
      }
      await page.evaluate(() => document.fonts.ready);
      for (const failure of await inspect(page)) {
        failures.push({ width, route, ...failure });
      }
    }
  }
} finally {
  await browser.close();
  await new Promise((resolveClose, rejectClose) => {
    server.close((error) => error ? rejectClose(error) : resolveClose());
  });
}

if (failures.length) {
  console.error(`Rendered geometry check failed with ${failures.length} issue(s):`);
  const viewportSummary = new Map();
  const groups = new Map();

  // Aggregate repeated formulas without losing the route and viewport needed
  // to locate the source expression that should be split.
  for (const failure of failures) {
    const viewport = viewportSummary.get(failure.width) ?? {
      issues: 0,
      routes: new Set(),
      maxRatio: 0,
    };
    viewport.issues += 1;
    viewport.routes.add(failure.route);
    if (failure.actual && failure.allowed) {
      viewport.maxRatio = Math.max(viewport.maxRatio, failure.actual / failure.allowed);
    }
    viewportSummary.set(failure.width, viewport);

    const key = [failure.width, failure.route, failure.type, failure.selector].join("\u0000");
    const group = groups.get(key) ?? {
      width: failure.width,
      route: failure.route,
      type: failure.type,
      selector: failure.selector,
      count: 0,
      maxRatio: 0,
      maxActual: 0,
      minAllowed: Number.POSITIVE_INFINITY,
      status: failure.status,
      contexts: new Set(),
    };
    group.count += 1;
    if (failure.context) group.contexts.add(failure.context);
    if (failure.actual && failure.allowed) {
      group.maxRatio = Math.max(group.maxRatio, failure.actual / failure.allowed);
      group.maxActual = Math.max(group.maxActual, failure.actual);
      group.minAllowed = Math.min(group.minAllowed, failure.allowed);
    }
    groups.set(key, group);
  }

  console.error("Viewport aggregates:");
  for (const [width, summary] of [...viewportSummary].sort((a, b) => a[0] - b[0])) {
    console.error(
      `- ${width}px: ${summary.issues} issue(s), ${summary.routes.size} route(s), ` +
      `max width ratio ${summary.maxRatio ? summary.maxRatio.toFixed(2) : "n/a"}`,
    );
  }

  console.error("Route/type aggregates:");
  const sortedGroups = [...groups.values()].sort((left, right) =>
    left.width - right.width ||
    left.route.localeCompare(right.route) ||
    left.type.localeCompare(right.type));
  for (const group of sortedGroups) {
    const ratio = group.maxRatio
      ? `max ${group.maxActual}/${group.minAllowed} = ${group.maxRatio.toFixed(2)}`
      : `status ${group.status}`;
    console.error(
      `- ${group.width}px ${group.route} [${group.type} ${group.selector}] ` +
      `${group.count} issue(s), ${ratio}` +
      (group.contexts.size
        ? `; contexts: ${[...group.contexts].map((context) => JSON.stringify(context)).join(" | ")}`
        : ""),
    );
  }
  process.exitCode = 1;
} else {
  console.log(`Rendered geometry check passed: ${routes.length} routes at ${viewports.join("/")} px.`);
}
