import { createServer } from "node:http";
import { access, readFile, readdir, stat } from "node:fs/promises";
import { extname, join, relative, resolve, sep } from "node:path";
import { chromium } from "playwright";

const root = resolve("dist");
const base = "/PD-LMI-package";
const defaultViewports = [320, 390, 700, 768, 1024, 1280, 1440];
const defaultThemes = ["light", "dark"];
const tolerance = 1;
const formulaShiftTolerance = 1;

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

function selectedThemes() {
  const requested = commaSeparated(process.env.GEOMETRY_THEMES);
  if (!requested.length) return defaultThemes;
  if (requested.some((theme) => !defaultThemes.includes(theme))) {
    throw new Error('GEOMETRY_THEMES accepts only "light" and "dark".');
  }
  return [...new Set(requested)];
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

function closeServer(server) {
  return new Promise((resolveClose, rejectClose) => {
    server.close((error) => error ? rejectClose(error) : resolveClose());
  });
}

async function formulaSnapshot(page) {
  return page.evaluate(() => [...document.querySelectorAll(".katex")]
    .filter((formula) => {
      const rect = formula.getBoundingClientRect();
      const style = getComputedStyle(formula);
      return rect.width > 0 &&
        rect.height > 0 &&
        style.display !== "none" &&
        style.visibility !== "hidden";
    })
    .map((formula, index) => {
      const wrapper = formula.closest(".formula-math") ??
        formula.closest(".katex-display")?.parentElement ??
        formula.parentElement ??
        formula;
      const wrapperRect = wrapper.getBoundingClientRect();
      const formulaRect = formula.getBoundingClientRect();
      return {
        index,
        markup: formula.outerHTML,
        rootCount: 1,
        display: Boolean(formula.closest(".katex-display")),
        wrapperRect: {
          left: wrapperRect.left,
          top: wrapperRect.top,
          width: wrapperRect.width,
          height: wrapperRect.height,
        },
        formulaRect: {
          left: formulaRect.left,
          top: formulaRect.top,
          width: formulaRect.width,
          height: formulaRect.height,
        },
      };
    }));
}

function recordHydrationStability(before, after, failures, route, width) {
  const count = Math.max(before.length, after.length);
  for (let index = 0; index < count; index += 1) {
    const initial = before[index];
    const hydrated = after[index];
    if (
      !initial ||
      !hydrated ||
      initial.rootCount !== 1 ||
      hydrated.rootCount !== 1 ||
      initial.display !== hydrated.display ||
      initial.markup !== hydrated.markup
    ) {
      failures.push({
        width,
        route,
        type: "formula-hydration",
        selector: `.katex[data-index="${index}"]`,
        context: JSON.stringify({
          beforeCount: before.length,
          afterCount: after.length,
          initialRootCount: initial?.rootCount ?? 0,
          hydratedRootCount: hydrated?.rootCount ?? 0,
        }),
      });
    }
  }
}

function recordFontStability(before, after, failures, route, width) {
  const relativeRect = ({ formulaRect, wrapperRect } = {}) => formulaRect && wrapperRect
    ? {
        left: formulaRect.left - wrapperRect.left,
        top: formulaRect.top - wrapperRect.top,
        width: formulaRect.width,
        height: formulaRect.height,
      }
    : null;
  const count = Math.max(before.length, after.length);
  for (let index = 0; index < count; index += 1) {
    const initial = relativeRect(before[index]);
    const settled = relativeRect(after[index]);
    if (!initial || !settled) {
      failures.push({
        width,
        route,
        type: "formula-layout-shift",
        selector: `.katex[data-index="${index}"]`,
        context: "Formula geometry was unavailable before or after local font readiness.",
      });
      continue;
    }
    const shift = Math.max(
      Math.abs(settled.left - initial.left),
      Math.abs(settled.top - initial.top),
      Math.abs(settled.width - initial.width),
      Math.abs(settled.height - initial.height),
    );
    if (shift > formulaShiftTolerance) {
      failures.push({
        width,
        route,
        type: "formula-layout-shift",
        selector: `.katex[data-index="${index}"]`,
        actual: Math.round(shift * 100) / 100,
        allowed: formulaShiftTolerance,
        context: JSON.stringify({ before: initial, after: settled }),
      });
    }
  }
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
      const tex = node.querySelector?.('annotation[encoding="application/x-tex"]')?.textContent;
      const aria = node.getAttribute?.("aria-label") ??
        node.closest?.("[aria-label]")?.getAttribute("aria-label");
      const caption = node.querySelector?.("figcaption")?.textContent;
      return normalize(tex || aria || caption || node.textContent || fallback);
    };
    const contentBox = (node) => {
      const rect = node.getBoundingClientRect();
      const style = getComputedStyle(node);
      const scaleX = node.offsetWidth > 0 ? rect.width / node.offsetWidth : 1;
      const insetStart = (
        Number.parseFloat(style.borderInlineStartWidth) +
        Number.parseFloat(style.paddingInlineStart)
      ) * scaleX;
      const insetEnd = (
        Number.parseFloat(style.borderInlineEndWidth) +
        Number.parseFloat(style.paddingInlineEnd)
      ) * scaleX;
      return {
        left: rect.left + insetStart,
        right: rect.right - insetEnd,
        width: Math.max(0, rect.width - insetStart - insetEnd),
      };
    };
    const inlineContainingBlock = (wrapper) => {
      for (
        let candidate = wrapper.parentElement;
        candidate && candidate !== root;
        candidate = candidate.parentElement
      ) {
        const display = getComputedStyle(candidate).display;
        if (display !== "contents" && !display.startsWith("inline")) return candidate;
      }
      return document.body;
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

    for (const formula of document.querySelectorAll(".katex")) {
      const rendered = formula.getBoundingClientRect();
      const style = getComputedStyle(formula);
      if (
        !formula.querySelector(".katex-html") ||
        !formula.querySelector("math") ||
        formula.querySelector("svg") ||
        rendered.width <= 0 ||
        rendered.height <= 0 ||
        style.display === "none" ||
        style.visibility === "hidden" ||
        Number(style.opacity) === 0
      ) {
        failures.push({
          type: "formula-readable",
          selector: describe(formula),
          context: contextFor(formula),
        });
      }
    }

    for (const wrapper of document.querySelectorAll(".formula-math")) {
      const outer = wrapper.getBoundingClientRect();
      if (outer.width <= 0 || outer.height <= 0 || wrapper.closest("pre")) continue;
      const island = wrapper.closest("astro-island");
      if (island?.hasAttribute("ssr")) {
        failures.push({
          type: "formula-hydration",
          selector: describe(wrapper),
          context: contextFor(wrapper),
        });
        continue;
      }
      const roots = [...wrapper.querySelectorAll(".katex")];
      if (roots.length !== 1) {
        failures.push({
          type: "formula-render-count",
          selector: describe(wrapper),
          actual: roots.length,
          allowed: 1,
          context: contextFor(wrapper),
        });
        continue;
      }
      const formula = roots[0];
      const displayRoot = wrapper.querySelector(":scope > .katex-display");
      const expectsDisplay = wrapper.classList.contains("formula-display");
      if (expectsDisplay !== Boolean(displayRoot)) {
        failures.push({
          type: "formula-render-count",
          selector: describe(wrapper),
          actual: displayRoot ? 1 : 0,
          allowed: expectsDisplay ? 1 : 0,
          context: `${contextFor(wrapper)}; display wrapper/root mismatch`,
        });
      }
      const rendered = formula.getBoundingClientRect();
      const style = getComputedStyle(formula);
      const residualSource = [...wrapper.childNodes]
        .filter((node) => node.nodeType === Node.TEXT_NODE)
        .map((node) => node.textContent ?? "")
        .join("")
        .trim();
      if (
        !formula.querySelector(".katex-html") ||
        !formula.querySelector("math") ||
        wrapper.querySelector("svg") ||
        rendered.width <= 0 ||
        rendered.height <= 0 ||
        style.display === "none" ||
        style.visibility === "hidden" ||
        Number(style.opacity) === 0 ||
        residualSource.length > 0
      ) {
        failures.push({
          type: "formula-readable",
          selector: describe(wrapper),
          context: contextFor(wrapper, residualSource),
        });
      }

      const localScroller = wrapper.closest(".elevate-direct-coefficient-scroll");
      const localScrollerStyle = localScroller ? getComputedStyle(localScroller) : null;
      const localScrollActive = Boolean(
        localScroller &&
        localScrollerStyle &&
        ["auto", "scroll"].includes(localScrollerStyle.overflowX) &&
        localScroller.scrollWidth > localScroller.clientWidth + tolerance
      );
      if (localScroller) {
        const scrollerBounds = localScroller.getBoundingClientRect();
        if (
          scrollerBounds.left < -tolerance ||
          scrollerBounds.right > root.clientWidth + tolerance
        ) {
          failures.push({
            type: "local-formula-scroll-bounds",
            selector: describe(localScroller),
            actual: Math.ceil(scrollerBounds.width),
            allowed: root.clientWidth,
            context: contextFor(wrapper),
          });
        }
        if (innerWidth <= 320 && !localScrollActive) {
          failures.push({
            type: "local-formula-scroll-required",
            selector: describe(localScroller),
            actual: localScroller.scrollWidth,
            allowed: localScroller.clientWidth,
            context: contextFor(wrapper),
          });
        }
        if (innerWidth >= 390 && localScrollActive) {
          failures.push({
            type: "local-formula-scroll-unneeded",
            selector: describe(localScroller),
            actual: localScroller.scrollWidth,
            allowed: localScroller.clientWidth,
            context: contextFor(wrapper),
          });
        }
      }
      const available = contentBox(
        expectsDisplay ? wrapper : inlineContainingBlock(wrapper),
      );
      const tex = formula
        .querySelector('annotation[encoding="application/x-tex"]')
        ?.textContent ?? "";
      if (
        wrapper.classList.contains("formula-one-line") &&
        rendered.width <= available.width + tolerance &&
        /\\begin\{(?:aligned|gathered|split)\}/.test(tex)
      ) {
        failures.push({
          type: "formula-unexpected-multiline",
          selector: describe(wrapper),
          actual: Math.ceil(rendered.width),
          allowed: Math.floor(available.width),
          context: contextFor(wrapper, tex),
        });
      }
      if (
        !localScrollActive &&
        (
          rendered.left < available.left - tolerance ||
          rendered.right > available.right + tolerance
        )
      ) {
        failures.push({
          type: "formula-bounds",
          selector: describe(wrapper),
          actual: Math.ceil(rendered.width),
          allowed: Math.floor(available.width),
          context: contextFor(wrapper),
        });
      }
      if (
        !localScrollActive &&
        rendered.width > available.width + tolerance
      ) {
        failures.push({
          type: "formula-width",
          selector: describe(wrapper),
          actual: Math.ceil(rendered.width),
          allowed: Math.floor(available.width),
          context: contextFor(wrapper),
        });
      }
    }

    for (const diagram of document.querySelectorAll(".diagram-frame")) {
      const rect = diagram.getBoundingClientRect();
      const hasLocalHorizontalScroll = (node) => {
        for (
          let current = node.parentElement;
          current && current !== diagram;
          current = current.parentElement
        ) {
          const style = getComputedStyle(current);
          if (
            ["auto", "scroll"].includes(style.overflowX) &&
            current.scrollWidth > current.clientWidth + tolerance
          ) {
            return true;
          }
        }
        return false;
      };
      if (rect.left < -tolerance || rect.right > root.clientWidth + tolerance) {
        failures.push({
          type: "diagram-bounds",
          selector: describe(diagram),
          actual: Math.ceil(rect.width),
          allowed: root.clientWidth,
          context: contextFor(diagram),
        });
      }
      let visibleOverflow = null;
      for (const node of diagram.querySelectorAll("*")) {
        if (node.closest(".katex-mathml") || hasLocalHorizontalScroll(node)) continue;
        const style = getComputedStyle(node);
        if (
          style.display === "none" ||
          style.visibility === "hidden" ||
          Number(style.opacity) === 0
        ) {
          continue;
        }
        const bounds = [...node.getClientRects()].find((fragment) =>
          fragment.width > 0 &&
          fragment.height > 0 &&
          (
            fragment.left < rect.left - tolerance ||
            fragment.right > rect.right + tolerance
          )
        );
        if (bounds) {
          visibleOverflow = { node, bounds };
          break;
        }
      }
      if (visibleOverflow) {
        const overflowBounds = visibleOverflow.bounds;
        const overflowNode = visibleOverflow.node;
        const parentBounds = overflowNode.parentElement?.getBoundingClientRect();
        failures.push({
          type: "diagram-width",
          selector: describe(diagram),
          actual: Math.ceil(overflowBounds.width),
          allowed: Math.floor(rect.width),
          context: `${contextFor(diagram)}; visible overflow: ${describe(overflowNode)} ` +
            JSON.stringify({
              frameLeft: rect.left,
              frameRight: rect.right,
              left: overflowBounds.left,
              right: overflowBounds.right,
              parentLeft: parentBounds?.left,
              parentRight: parentBounds?.right,
            }),
        });
      }
    }

    const storageDestination = "/PD-LMI-package/documents/reference/pdmat/storage-and-elevation/";
    const storageAnchors = new Set(["#pdmat-cells", "#pdmat-coeffs", "#pdmat-lbls", "#pdmat-ncoeff"]);
    for (const link of document.querySelectorAll("a.storage-api-link")) {
      const href = link.getAttribute("href") ?? "";
      const destination = new URL(href, location.href);
      if (
        !href.startsWith(storageDestination) ||
        destination.pathname !== storageDestination ||
        !storageAnchors.has(destination.hash)
      ) {
        failures.push({
          type: "storage-api-link",
          selector: describe(link),
          context: href || "missing href",
        });
      }
    }

    if (
      innerWidth <= 390 &&
      location.pathname.endsWith("/documents/reference/pdmat/constructor/") &&
      document.querySelectorAll(".diagram-frame").length === 0
    ) {
      failures.push({
        type: "narrow-constructor-coverage",
        selector: ".diagram-frame",
        context: "The narrow constructor route must expose its interactive diagram to overflow checks.",
      });
    }

    return { failures };
  }, { tolerance });
}

async function hydrateIslands(page) {
  const islands = page.locator("astro-island");
  const count = await islands.count();
  for (let index = 0; index < count; index += 1) {
    await islands.nth(index).scrollIntoViewIfNeeded();
    await page.waitForFunction(
      (islandIndex) => {
        const island = document.querySelectorAll("astro-island")[islandIndex];
        return Boolean(island && !island.hasAttribute("ssr"));
      },
      index,
      { timeout: 10_000 },
    );
  }
  await page.evaluate(() => {
    window.scrollTo(0, 0);
  });
}

function attachProductionSignals(page, origin, issues, state) {
  page.on("console", (message) => {
    const text = message.text();
    if (message.type() === "error") {
      issues.push({
        type: "console",
        route: state.route,
        width: state.width,
        context: text,
      });
    }
  });
  page.on("pageerror", (error) => {
    issues.push({
      type: "pageerror",
      route: state.route,
      width: state.width,
      context: error.message,
    });
  });
  page.on("request", (request) => {
    const requestUrl = request.url();
    if (/^https?:/i.test(requestUrl) && new URL(requestUrl).origin !== origin) {
      issues.push({
        type: "external-request",
        route: state.route,
        width: state.width,
        context: requestUrl,
      });
    }
  });
  page.on("requestfailed", (request) => {
    if (request.url().startsWith("blob:")) return;
    issues.push({
      type: "request-failed",
      route: state.route,
      width: state.width,
      context: `${request.url()}: ${request.failure()?.errorText ?? "unknown failure"}`,
    });
  });
}

async function settleRootHydration(page) {
  await page.waitForFunction(
    () => document.querySelectorAll("astro-island[ssr]").length === 0,
    null,
    { timeout: 15_000 },
  );
  await page.evaluate(async () => {
    await document.fonts.ready;
    await new Promise((resolveFrame) => {
      requestAnimationFrame(() => requestAnimationFrame(resolveFrame));
    });
  });
}

async function auditRootWalkthroughs(browser, origin, failures) {
  for (const viewport of [
    { width: 1440, height: 900 },
    { width: 390, height: 844 },
  ]) {
    const route = `${base}/`;
    const state = { route, width: viewport.width };
    const issues = [];
    const context = await browser.newContext({ viewport });
    const page = await context.newPage();
    attachProductionSignals(page, origin, issues, state);

    try {
      const response = await page.goto(`${origin}${route}`, { waitUntil: "networkidle" });
      if (!response?.ok()) throw new Error(`root returned ${response?.status() ?? "no response"}`);
      await settleRootHydration(page);

      const hydration = await page.evaluate(() => {
        const visibleInteractiveMath = [...document.querySelectorAll("astro-island .formula-math")]
          .filter((wrapper) => {
            const rect = wrapper.getBoundingClientRect();
            const style = getComputedStyle(wrapper);
            return rect.width > 0 &&
              rect.height > 0 &&
              style.display !== "none" &&
              style.visibility !== "hidden";
          });
        const formulaIssues = visibleInteractiveMath.flatMap((wrapper) => {
          const roots = [...wrapper.querySelectorAll(".katex")];
          const raw = [...wrapper.childNodes]
            .filter((node) => node.nodeType === Node.TEXT_NODE)
            .map((node) => node.textContent ?? "")
            .join("")
            .trim();
          const rendered = roots[0]?.getBoundingClientRect();
          return roots.length === 1 &&
              roots[0]?.querySelector(".katex-html") &&
              roots[0]?.querySelector("math") &&
              !wrapper.querySelector("svg") &&
              rendered &&
              rendered.width > 0 &&
              rendered.height > 0 &&
              raw === "" &&
              !/\\(?:\(|\[)|\\(?:\)|\])|\$\$/.test(raw)
            ? []
            : [{
                className: wrapper.className,
                roots: roots.length,
                raw,
                width: rendered?.width ?? 0,
                height: rendered?.height ?? 0,
              }];
        });
        return {
          formulaCount: visibleInteractiveMath.length,
          formulaIssues,
          pendingIslands: document.querySelectorAll("astro-island[ssr]").length,
          walkthroughs: {
            certificate: document.querySelectorAll("figure.certificate-flow-figure").length,
            grid: document.querySelectorAll("figure.grid-partition-explorer").length,
            storage: document.querySelectorAll(".cell-storage-compact figure.interactive-figure").length,
          },
        };
      });
      if (hydration.pendingIslands !== 0) {
        throw new Error(`${hydration.pendingIslands} root islands still carry ssr`);
      }
      if (Object.values(hydration.walkthroughs).some((count) => count !== 1)) {
        throw new Error(`root walkthrough count mismatch: ${JSON.stringify(hydration.walkthroughs)}`);
      }
      if (hydration.formulaCount === 0 || hydration.formulaIssues.length) {
        throw new Error(`interactive formula hydration failed: ${JSON.stringify(hydration)}`);
      }

      const grid = page.locator("figure.grid-partition-explorer");
      const slider = grid.getByRole("slider").first();
      const output = grid.locator("output").first();
      const previousOutput = (await output.textContent())?.trim() ?? "";
      await slider.fill("0.61");
      await page.waitForFunction(
        (before) => document.querySelector("figure.grid-partition-explorer output")?.textContent?.trim() !== before,
        previousOutput,
        { timeout: 5_000 },
      );
      const currentOutput = (await output.textContent())?.trim() ?? "";
      if (!currentOutput || currentOutput === previousOutput) {
        throw new Error(`slider output did not change from ${JSON.stringify(previousOutput)}`);
      }

      const oneDimensionalCell = grid.getByRole("button", { name: "(2)", exact: true });
      await oneDimensionalCell.click();
      if (await oneDimensionalCell.getAttribute("aria-pressed") !== "true") {
        throw new Error("1D cell (2) did not become selected");
      }

      const twoDimensionalTab = grid.getByRole("tab", { name: "2D", exact: true });
      await twoDimensionalTab.click();
      if (await twoDimensionalTab.getAttribute("aria-selected") !== "true") {
        throw new Error("2D tab did not become selected");
      }
      const twoDimensionalPanel = grid.getByRole("tabpanel");
      if (!await twoDimensionalPanel.isVisible() ||
          await twoDimensionalPanel.getByRole("slider").count() !== 2 ||
          await twoDimensionalPanel.getByRole("button").count() !== 4) {
        throw new Error("2D panel did not expose two knot sliders and four cell controls");
      }

      const storage = page.locator(".cell-storage-compact figure.interactive-figure");
      const storageGroup = storage.getByRole("group", {
        name: "Select one of two hypercubes with arrow keys",
      });
      const storageCellTwo = storageGroup.getByRole("button").nth(1);
      await storageCellTwo.click();
      if (await storageCellTwo.getAttribute("aria-pressed") !== "true") {
        throw new Error("storage c1=2 did not become selected");
      }
      await storage.locator('[aria-label="Nine degree-two coefficient matrices in cell (2, 1)"]')
        .waitFor({ state: "visible", timeout: 5_000 });

      const stageGeometry = await storage.evaluate((figure) => {
        const specs = [
          ["matrix", ".cell-grid-panel"],
          ["coefficients", ".cell-coefficient-flow"],
          ["basis", ".cell-bernstein-readout"],
        ];
        return specs.map(([name, visualSelector]) => {
          const stage = figure.querySelector(`[data-cell-stage="${name}"]`);
          const heading = stage?.querySelector(".cell-stage__heading");
          const visual = stage?.querySelector(visualSelector);
          const stageRect = stage?.getBoundingClientRect();
          const headingRect = heading?.getBoundingClientRect();
          const visualRect = visual?.getBoundingClientRect();
          return {
            name,
            stage: stageRect && {
              left: stageRect.left,
              right: stageRect.right,
              top: stageRect.top,
              bottom: stageRect.bottom,
            },
            heading: headingRect && {
              center: (headingRect.left + headingRect.right) / 2,
              top: headingRect.top,
              bottom: headingRect.bottom,
            },
            visual: visualRect && {
              center: (visualRect.left + visualRect.right) / 2,
              top: visualRect.top,
              bottom: visualRect.bottom,
            },
          };
        });
      });
      for (const pair of stageGeometry) {
        if (!pair.stage || !pair.heading || !pair.visual) {
          throw new Error(`storage stage pair missing: ${JSON.stringify(pair)}`);
        }
        if (Math.abs(pair.heading.center - pair.visual.center) > 2) {
          throw new Error(`storage stage centers diverge: ${JSON.stringify(pair)}`);
        }
        if (pair.visual.top < pair.heading.bottom - 1 || pair.visual.top - pair.heading.bottom > 40) {
          throw new Error(`storage heading is not adjacent to its visual: ${JSON.stringify(pair)}`);
        }
      }

      const certificate = page.getByRole("figure", { name: "Finite certificate selection flow" });
      const certificateStates = [
        { name: "Direct", command: "selected = L;" },
        { name: "Pólya", command: "selected = L.applyPolya(d);" },
        { name: "Putinar", command: "selected = L.applyPutinar();" },
        { name: "SparseFullBox", command: "selected = L.applySparseFullBoxPreorder();" },
        { name: "FullBox", command: "selected = L.applyFullBoxPreorder();" },
      ];
      for (const { name, command } of certificateStates) {
        const tab = certificate.getByRole("tab", { name, exact: true });
        await tab.click();
        if (await tab.getAttribute("aria-selected") !== "true") {
          throw new Error(`${name} tab did not become selected`);
        }
        const certificatePanel = certificate.getByRole("tabpanel");
        await certificatePanel.locator("code").filter({ hasText: command })
          .waitFor({ state: "visible", timeout: 5_000 });
        const formulaState = await certificate.evaluate((figure) => {
          const roots = [...figure.querySelectorAll(".formula-math .katex")];
          const invalid = roots
            .filter((root) =>
              !root.querySelector(".katex-html") ||
              !root.querySelector("math") ||
              root.querySelector("svg"))
            .map((root) =>
              root.querySelector('annotation[encoding="application/x-tex"]')?.textContent ??
              root.textContent?.trim().slice(0, 160) ??
              "");
          return { count: roots.length, invalid };
        });
        if (formulaState.count === 0 || formulaState.invalid.length) {
          throw new Error(
            `certificate-formula-state ${name}: ${JSON.stringify(formulaState)}`,
          );
        }
      }

      if (viewport.width === 390) {
        const storageGeometry = await storage.evaluate((figure) => {
          const tolerance = 1;
          const figureRect = figure.getBoundingClientRect();
          const locallyScrollable = (node) => {
            for (let current = node.parentElement; current && current !== figure; current = current.parentElement) {
              const style = getComputedStyle(current);
              if (
                ["auto", "scroll"].includes(style.overflowX) &&
                current.scrollWidth > current.clientWidth + tolerance
              ) {
                return true;
              }
            }
            return false;
          };
          const descendantsOutside = [...figure.querySelectorAll("*")]
            .filter((node) => {
              if (node.closest(".katex-mathml")) return false;
              const rect = node.getBoundingClientRect();
              return rect.width > 0 &&
                rect.height > 0 &&
                (rect.left < figureRect.left - tolerance || rect.right > figureRect.right + tolerance) &&
                !locallyScrollable(node);
            })
            .slice(0, 10)
            .map((node) => {
              const formula = node.closest(".formula-math");
              const region = node.closest(
                ".cell-stage, .cell-stage-layout, .cell-coeffs, .cell-bernstein-readout",
              );
              const formulaRect = formula?.getBoundingClientRect();
              const regionRect = region?.getBoundingClientRect();
              return {
                className: node.className,
                formulaClassName: formula?.className ?? "",
                tex: formula
                  ?.querySelector('annotation[encoding="application/x-tex"]')
                  ?.textContent,
                formulaLeft: formulaRect?.left,
                formulaRight: formulaRect?.right,
                parentClassName: formula?.parentElement?.className ?? "",
                regionClassName: region?.className ?? "",
                regionColumns: region ? getComputedStyle(region).gridTemplateColumns : "",
                regionLeft: regionRect?.left,
                regionRight: regionRect?.right,
                left: node.getBoundingClientRect().left,
                right: node.getBoundingClientRect().right,
              };
            });
          return {
            clientWidth: figure.clientWidth,
            documentClientWidth: document.documentElement.clientWidth,
            documentScrollWidth: document.documentElement.scrollWidth,
            figureLeft: figureRect.left,
            figureRight: figureRect.right,
            scrollWidth: figure.scrollWidth,
            descendantsOutside,
          };
        });
        if (
          storageGeometry.documentScrollWidth > storageGeometry.documentClientWidth + 1 ||
          storageGeometry.scrollWidth > storageGeometry.clientWidth + 1 ||
          storageGeometry.figureLeft < -1 ||
          storageGeometry.figureRight > storageGeometry.documentClientWidth + 1 ||
          storageGeometry.descendantsOutside.length
        ) {
          throw new Error(`mobile storage clipping/overflow: ${JSON.stringify(storageGeometry)}`);
        }
      }
    } catch (error) {
      issues.push({
        type: "root-production-regression",
        route,
        width: viewport.width,
        context: error instanceof Error ? error.message : String(error),
      });
    } finally {
      await context.close();
    }
    for (const issue of issues) {
      failures.push({
        selector: "root-walkthroughs",
        ...issue,
      });
    }
  }
}

async function auditMobileStorageAnnotations(browser, origin, failures) {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await context.newPage();
  const issues = [];
  const state = { route: "", width: 390 };
  attachProductionSignals(page, origin, issues, state);

  try {
    for (const route of [
      `${base}/documents/math/gridding-and-degree/`,
      `${base}/documents/math/bernstein-polynomial/`,
    ]) {
      state.route = route;
      const response = await page.goto(`${origin}${route}`, { waitUntil: "networkidle" });
      if (!response?.ok()) {
        issues.push({ type: "http", route, width: 390, context: String(response?.status()) });
        continue;
      }
      await page.evaluate(() => document.fonts.ready);
      const annotations = await page.locator(".cell-storage-diagram .control-strip em")
        .evaluateAll((nodes) => nodes.map((node) => ({
          fontSize: Number.parseFloat(getComputedStyle(node).fontSize),
          text: node.textContent?.trim() ?? "",
        })));
      if (!annotations.length || annotations.some(({ fontSize }) => fontSize < 12)) {
        issues.push({
          type: "storage-annotation-font",
          route,
          width: 390,
          context: JSON.stringify(annotations),
        });
      }
    }
  } finally {
    await context.close();
  }
  for (const issue of issues) {
    failures.push({
      selector: ".cell-storage-diagram .control-strip em",
      ...issue,
    });
  }
}

async function auditRhodiffEditor(browser, origin, failures) {
  const route = `${base}/documents/reference/pdvar/rhodiff/`;
  const expectedInitial = [
    "row 1: (-1, -3)",
    "row 2: (-1, 5)",
    "row 3: (2, -3)",
    "row 4: (2, 5)",
  ];
  const expectedFirstCommit = [
    "row 1: (-2, -3)",
    "row 2: (-2, 5)",
    "row 3: (2, -3)",
    "row 4: (2, 5)",
  ];
  const expectedSecondCommit = [
    "row 1: (-4, -3)",
    "row 2: (-4, 5)",
    "row 3: (4, -3)",
    "row 4: (4, 5)",
  ];
  const sameRows = (actual, expected) =>
    actual.length === expected.length &&
    actual.every((row, index) => row === expected[index]);

  for (const viewport of [
    { width: 1440, height: 900 },
    { width: 390, height: 844 },
  ]) {
    const state = { route, width: viewport.width };
    const issues = [];
    const context = await browser.newContext({ viewport });
    const page = await context.newPage();
    attachProductionSignals(page, origin, issues, state);

    try {
      const response = await page.goto(`${origin}${route}`, { waitUntil: "networkidle" });
      if (!response?.ok()) throw new Error(`rhodiff returned ${response?.status() ?? "no response"}`);

      const bounds = page.getByLabel("Rate bounds (one lower upper row per axis)");
      const columns = page.getByLabel("Coefficient columns per cell");
      const figure = page.locator("figure.manual-explorer").filter({ has: bounds });
      const island = page.locator("astro-island").filter({ has: figure });
      await page.waitForFunction(
        () => {
          const candidate = [...document.querySelectorAll("astro-island")]
            .find((item) => item.querySelector("figure.manual-explorer textarea"));
          return Boolean(candidate && !candidate.hasAttribute("ssr"));
        },
        null,
        { timeout: 15_000 },
      );
      if (await island.count() !== 1 ||
          await island.getAttribute("client") !== "load" ||
          await island.getAttribute("ssr") !== null) {
        throw new Error("RateVertexExplorer was not eagerly hydrated with client:load");
      }

      const update = figure.getByRole("button", { name: "Update vertices", exact: true });
      const status = figure.getByRole("status");
      const alert = figure.getByRole("alert");
      const rows = async () => (await figure.locator(".vertex-list code").allTextContents())
        .map((row) => row.trim());

      await bounds.fill("-2 2; -3 5");
      if (await bounds.inputValue() !== "-2 2; -3 5") {
        throw new Error("valid bounds draft did not remain visible before Update");
      }
      if (!sameRows(await rows(), expectedInitial)) {
        throw new Error(`valid draft changed committed rows before Update: ${JSON.stringify(await rows())}`);
      }
      await update.click();
      if (!sameRows(await rows(), expectedFirstCommit)) {
        throw new Error(`first committed row order is wrong: ${JSON.stringify(await rows())}`);
      }
      if ((await status.textContent())?.trim() !== "Updated to 4 rate rows and 4 coefficient columns." ||
          (await alert.textContent())?.trim() ||
          await bounds.getAttribute("aria-invalid") !== "false" ||
          await columns.getAttribute("aria-invalid") !== "false") {
        throw new Error("first valid commit did not expose clean committed status");
      }

      await bounds.fill("-2; -3 5");
      if (await bounds.inputValue() !== "-2; -3 5" ||
          !sameRows(await rows(), expectedFirstCommit)) {
        throw new Error("invalid bounds draft did not preserve its text and last valid rows");
      }
      await update.click();
      if (!sameRows(await rows(), expectedFirstCommit) ||
          (await status.textContent())?.trim() !== "Draft not applied. The last valid rate table remains visible." ||
          (await alert.textContent())?.trim() !== "Each row needs finite lower and upper bounds with lower ≤ upper." ||
          await bounds.getAttribute("aria-invalid") !== "true") {
        throw new Error("invalid bounds did not retain the model with accessible bounds error");
      }

      await bounds.fill("-4 4; -3 5");
      await update.click();
      if (!sameRows(await rows(), expectedSecondCommit) ||
          (await alert.textContent())?.trim() ||
          await bounds.getAttribute("aria-invalid") !== "false") {
        throw new Error(`corrected bounds did not commit and clear the error: ${JSON.stringify(await rows())}`);
      }

      await columns.fill("0");
      if (await columns.inputValue() !== "0" ||
          !sameRows(await rows(), expectedSecondCommit)) {
        throw new Error("invalid columns draft did not remain visible over the last model");
      }
      await update.click();
      if (!sameRows(await rows(), expectedSecondCommit) ||
          (await alert.textContent())?.trim() !== "Coefficient columns must be an integer from 1 to 64." ||
          (await status.textContent())?.trim() !== "Draft not applied. The last valid rate table remains visible." ||
          await columns.getAttribute("aria-invalid") !== "true" ||
          await bounds.getAttribute("aria-invalid") !== "false") {
        throw new Error("invalid columns did not retain the model with a columns-specific error");
      }

      await columns.fill("5");
      await update.click();
      if ((await figure.locator(".explorer-readout strong").textContent())?.trim() !==
            "4 rate rows × 5 coefficient columns" ||
          (await status.textContent())?.trim() !== "Updated to 4 rate rows and 5 coefficient columns." ||
          (await alert.textContent())?.trim() ||
          await columns.getAttribute("aria-invalid") !== "false" ||
          !sameRows(await rows(), expectedSecondCommit)) {
        throw new Error("corrected columns did not commit the shared four-by-five model");
      }

      const geometry = await figure.evaluate((node) => {
        const rect = node.getBoundingClientRect();
        return {
          documentClientWidth: document.documentElement.clientWidth,
          documentScrollWidth: document.documentElement.scrollWidth,
          figureClientWidth: node.clientWidth,
          figureScrollWidth: node.scrollWidth,
          left: rect.left,
          right: rect.right,
        };
      });
      if (
        geometry.documentScrollWidth > geometry.documentClientWidth + 1 ||
        geometry.figureScrollWidth > geometry.figureClientWidth + 1 ||
        geometry.left < -1 ||
        geometry.right > geometry.documentClientWidth + 1
      ) {
        throw new Error(`rhodiff figure/document overflow: ${JSON.stringify(geometry)}`);
      }
    } catch (error) {
      issues.push({
        type: "rhodiff-production-regression",
        route,
        width: viewport.width,
        context: error instanceof Error ? error.message : String(error),
      });
    } finally {
      await context.close();
    }
    for (const issue of issues) {
      failures.push({
        selector: "figure.manual-explorer",
        ...issue,
      });
    }
  }
}

await access(join(root, "index.html"));
const builtFiles = await walk(root);
const builtCss = builtFiles.filter((file) => file.endsWith(".css"));
const katexCss = [];
for (const file of builtCss) {
  if (/\.katex(?:-display)?\b/.test(await readFile(file, "utf8"))) katexCss.push(file);
}
if (!katexCss.length) {
  throw new Error("Built output does not contain the locally bundled KaTeX CSS.");
}
const katexFonts = builtFiles.filter((file) =>
  /\.(?:woff2?|ttf)$/i.test(file) && /katex/i.test(file));
if (!katexFonts.length) {
  throw new Error("Built output does not contain locally bundled KaTeX font assets.");
}
const allRoutes = builtFiles
  .filter((file) => file.endsWith(".html") && !file.endsWith("404.html"))
  .map(routeFor)
  .sort();
const routes = selectRoutes(allRoutes);
const viewports = selectedViewports();
const themes = selectedThemes();

const { server, origin } = await startServer();
let browser = null;
let primaryError;
const failures = [];

try {
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  let currentRoute = "";
  let currentWidth = 0;
  page.on("console", (message) => {
    const text = message.text();
    if (message.type() === "error") {
      failures.push({
        width: currentWidth,
        route: currentRoute,
        type: "console",
        selector: "document",
        context: text,
      });
    }
  });
  page.on("pageerror", (error) => {
    failures.push({
      width: currentWidth,
      route: currentRoute,
      type: "pageerror",
      selector: "document",
      context: error.message,
    });
  });
  page.on("request", (request) => {
    const requestUrl = request.url();
    if (/^https?:/i.test(requestUrl) && new URL(requestUrl).origin !== origin) {
      failures.push({
        width: currentWidth,
        route: currentRoute,
        type: "external-request",
        selector: "document",
        context: requestUrl,
      });
    }
  });
  page.on("requestfailed", (request) => {
    if (request.url().startsWith("blob:")) return;
    failures.push({
      width: currentWidth,
      route: currentRoute,
      type: "request-failed",
      selector: "document",
      context: `${request.url()}: ${request.failure()?.errorText ?? "unknown failure"}`,
    });
  });

  for (const width of viewports) {
    await page.setViewportSize({ width, height: 1000 });
    for (const theme of themes) {
      console.log(`Checking ${routes.length} routes at ${width}px in ${theme} theme...`);
      for (const route of routes) {
        currentRoute = `${route} [${theme}]`;
        currentWidth = width;
        const response = await page.goto(`${origin}${route}`, { waitUntil: "domcontentloaded" });
        if (!response?.ok()) {
          failures.push({
            width,
            route: currentRoute,
            type: "http",
            selector: "document",
            status: response?.status() ?? "no response",
          });
          continue;
        }
        await page.evaluate((activeTheme) => {
          document.documentElement.dataset.theme = activeTheme;
          document.documentElement.style.colorScheme = activeTheme;
        }, theme);
        const beforeFonts = await formulaSnapshot(page);
        const beforeHydration = await formulaSnapshot(page);
        await page.waitForLoadState("networkidle");
        try {
          await hydrateIslands(page);
        } catch (error) {
          failures.push({
            width,
            route: currentRoute,
            type: "island-hydration",
            selector: "astro-island",
            context: error instanceof Error ? error.message : String(error),
          });
        }
        const afterHydration = await formulaSnapshot(page);
        recordHydrationStability(beforeHydration, afterHydration, failures, currentRoute, width);
        await page.evaluate(() => document.fonts.ready);
        await page.evaluate(() => new Promise((resolveFrame) => {
          requestAnimationFrame(() => requestAnimationFrame(resolveFrame));
        }));
        const afterFonts = await formulaSnapshot(page);
        recordFontStability(beforeFonts, afterFonts, failures, currentRoute, width);
        const result = await inspect(page);
        for (const failure of result.failures) {
          failures.push({ width, route: currentRoute, ...failure });
        }
      }
    }
  }
  await auditRootWalkthroughs(browser, origin, failures);
  await auditMobileStorageAnnotations(browser, origin, failures);
  await auditRhodiffEditor(browser, origin, failures);
} catch (error) {
  primaryError = error;
} finally {
  const cleanupErrors = [];
  if (browser) {
    try {
      await browser.close();
    } catch (error) {
      cleanupErrors.push(error);
    }
  }
  try {
    await closeServer(server);
  } catch (error) {
    cleanupErrors.push(error);
  }
  if (primaryError) {
    if (cleanupErrors.length) {
      console.error("Geometry cleanup also failed after the primary error:", ...cleanupErrors);
    }
    throw primaryError;
  }
  if (cleanupErrors.length) {
    throw new AggregateError(cleanupErrors, "Geometry cleanup failed.");
  }
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
    if (
      Number.isFinite(failure.actual) &&
      Number.isFinite(failure.allowed) &&
      failure.allowed > 0
    ) {
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
    if (Number.isFinite(failure.actual) && Number.isFinite(failure.allowed)) {
      if (failure.allowed > 0) {
        group.maxRatio = Math.max(group.maxRatio, failure.actual / failure.allowed);
      }
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
    const hasMeasurements = Number.isFinite(group.minAllowed);
    const ratio = hasMeasurements
      ? `max ${group.maxActual}/${group.minAllowed}` +
        (group.maxRatio ? ` = ${group.maxRatio.toFixed(2)}` : "")
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
  console.log(`Rendered geometry check passed: ${routes.length} routes at ${viewports.join("/")} px in ${themes.join("/")} themes.`);
}
