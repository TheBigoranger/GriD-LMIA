import { createServer } from "node:http";
import { access, readFile, readdir, stat } from "node:fs/promises";
import { extname, join, relative, resolve, sep } from "node:path";
import { chromium } from "playwright";

const root = resolve("dist");
const base = "/PD-LMI-package";
const defaultViewports = [320, 390, 700, 768, 1024, 1440];
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

function closeServer(server) {
  return new Promise((resolveClose, rejectClose) => {
    server.close((error) => error ? rejectClose(error) : resolveClose());
  });
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

    for (const wrapper of document.querySelectorAll(".tex-math")) {
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
      const directContainers = [...wrapper.querySelectorAll(":scope > mjx-container")];
      if (directContainers.length !== 1) {
        failures.push({
          type: "formula-render-count",
          selector: describe(wrapper),
          actual: directContainers.length,
          allowed: 1,
          context: contextFor(wrapper),
        });
        continue;
      }
      const container = directContainers[0];
      const inner = container.querySelector("mjx-math");
      const rendered = (inner ?? container).getBoundingClientRect();
      const style = getComputedStyle(container);
      const residualSource = [...wrapper.childNodes]
        .filter((node) => node.nodeType === Node.TEXT_NODE)
        .map((node) => node.textContent ?? "")
        .join("")
        .trim();
      if (
        !inner ||
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
    }

    // MathJax may split a display into several CHTML lines. Every rendered line,
    // not merely the full-width container, must remain inside its TeX wrapper.
    for (const display of document.querySelectorAll('.tex-display > mjx-container[display="true"]')) {
      if (display.closest("pre")) continue;
      const wrapper = display.parentElement;
      const outer = wrapper?.getBoundingClientRect();
      if (!wrapper || !outer || outer.width <= 0 || outer.height <= 0) continue;
      const lines = [...display.querySelectorAll("mjx-line")];
      const renderedParts = lines.length ? lines : [display.querySelector("mjx-math") ?? display];

      for (const part of renderedParts) {
        const inner = part.getBoundingClientRect();
        if (inner.left < outer.left - tolerance || inner.right > outer.right + tolerance) {
          failures.push({
            type: "formula-bounds",
            selector: describe(wrapper),
            actual: Math.ceil(inner.width),
            allowed: Math.floor(outer.width),
            context: contextFor(wrapper),
          });
        }
      }
      if (wrapper.scrollWidth > wrapper.clientWidth + tolerance) {
        failures.push({
          type: "formula-width",
          selector: describe(wrapper),
          actual: wrapper.scrollWidth,
          allowed: wrapper.clientWidth,
          context: contextFor(wrapper),
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
  await page.evaluate(async () => {
    await window.pdLmiMathQueue;
    window.scrollTo(0, 0);
  });
}

function attachProductionSignals(page, origin, issues, state) {
  page.on("console", (message) => {
    const text = message.text();
    const invalidMathJaxOption = message.type() === "warning" &&
      /mathjax/i.test(text) &&
      /invalid option/i.test(text);
    if (message.type() === "error" || invalidMathJaxOption) {
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
    if (/^https?:/i.test(requestUrl) && !requestUrl.startsWith(origin)) {
      issues.push({
        type: /mathjax/i.test(requestUrl) ? "external-mathjax" : "external-request",
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
    () => document.documentElement.dataset.mathjaxReady === "true",
    null,
    { timeout: 15_000 },
  );
  await page.waitForFunction(
    () => document.querySelectorAll("astro-island[ssr]").length === 0,
    null,
    { timeout: 15_000 },
  );
  await page.evaluate(async () => {
    await window.pdLmiMathQueue;
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
        const visibleInteractiveMath = [...document.querySelectorAll("astro-island .tex-math")]
          .filter((wrapper) => {
            const rect = wrapper.getBoundingClientRect();
            const style = getComputedStyle(wrapper);
            return rect.width > 0 &&
              rect.height > 0 &&
              style.display !== "none" &&
              style.visibility !== "hidden";
          });
        const formulaIssues = visibleInteractiveMath.flatMap((wrapper) => {
          const containers = [...wrapper.querySelectorAll(":scope > mjx-container")];
          const raw = [...wrapper.childNodes]
            .filter((node) => node.nodeType === Node.TEXT_NODE)
            .map((node) => node.textContent ?? "")
            .join("")
            .trim();
          const rendered = containers[0]?.querySelector("mjx-math")?.getBoundingClientRect();
          return containers.length === 1 &&
              rendered &&
              rendered.width > 0 &&
              rendered.height > 0 &&
              raw === "" &&
              !/\\(?:\(|\[)|\\(?:\)|\])|\$\$/.test(raw)
            ? []
            : [{
                className: wrapper.className,
                containers: containers.length,
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

      const certificate = page.getByRole("figure", { name: "Finite certificate selection flow" });
      const polya = certificate.getByRole("tab", { name: "Pólya", exact: true });
      await polya.click();
      if (await polya.getAttribute("aria-selected") !== "true") {
        throw new Error("Pólya tab did not become selected");
      }
      const certificatePanel = certificate.getByRole("tabpanel");
      await certificatePanel.locator("code").filter({ hasText: "selected = L.applyPolya(d);" })
        .waitFor({ state: "visible", timeout: 5_000 });

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
              const rect = node.getBoundingClientRect();
              return rect.width > 0 &&
                rect.height > 0 &&
                (rect.left < figureRect.left - tolerance || rect.right > figureRect.right + tolerance) &&
                !locallyScrollable(node);
            })
            .slice(0, 10)
            .map((node) => ({
              className: node.className,
              left: node.getBoundingClientRect().left,
              right: node.getBoundingClientRect().right,
            }));
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
      await page.waitForFunction(
        () => document.documentElement.dataset.mathjaxReady === "true",
        null,
        { timeout: 15_000 },
      );
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
      await page.waitForFunction(
        () => document.documentElement.dataset.mathjaxReady === "true",
        null,
        { timeout: 15_000 },
      );

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
await access(join(root, "mathjax/sre/speech-worker.js"));
await access(join(root, "mathjax/input/tex/extensions/boldsymbol.js"));
await access(join(root, "mathjax/mathjax-modern/chtml/woff2/mjx-mm-i.woff2"));
const allRoutes = (await walk(root))
  .filter((file) => file.endsWith(".html") && !file.endsWith("404.html"))
  .map(routeFor)
  .sort();
const routes = selectRoutes(allRoutes);
const viewports = selectedViewports();

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
    const invalidMathJaxOption = message.type() === "warning" &&
      /mathjax/i.test(text) &&
      /invalid option/i.test(text);
    if (message.type() === "error" || invalidMathJaxOption) {
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
    if (/^https?:/i.test(requestUrl) && !requestUrl.startsWith(origin)) {
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
    console.log(`Checking ${routes.length} routes at ${width}px...`);
    await page.setViewportSize({ width, height: 1000 });
    for (const route of routes) {
      currentRoute = route;
      currentWidth = width;
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
      try {
        await page.waitForFunction(
          () => document.documentElement.dataset.mathjaxReady === "true",
          null,
          { timeout: 15_000 },
        );
      } catch {
        failures.push({
          width,
          route,
          type: "mathjax-readiness",
          selector: "html",
          context: "documentElement.dataset.mathjaxReady did not become true",
        });
        continue;
      }
      try {
        await hydrateIslands(page);
      } catch (error) {
        failures.push({
          width,
          route,
          type: "island-hydration",
          selector: "astro-island",
          context: error instanceof Error ? error.message : String(error),
        });
      }
      await page.evaluate(() => document.fonts.ready);
      await page.evaluate(() => new Promise((resolveFrame) => {
        requestAnimationFrame(() => requestAnimationFrame(resolveFrame));
      }));
      const result = await inspect(page);
      for (const failure of result.failures) {
        failures.push({ width, route, ...failure });
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
