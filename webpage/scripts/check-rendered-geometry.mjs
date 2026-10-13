import { createServer } from "node:http";
import { access, readFile, readdir, stat } from "node:fs/promises";
import { extname, join, relative, resolve, sep } from "node:path";
import { chromium } from "playwright";
import { intrinsicFormulaRect } from "./formula-geometry.mjs";

const root = resolve("dist");
const base = "/GriD-LMIA";
const defaultViewports = [320, 390, 700, 768, 1024, 1280, 1440];
const defaultThemes = ["light", "dark"];
const tolerance = 1;
const formulaShiftTolerance = 1;
const welcomeCitation = "Yicheng Xu and Faryar Jabbari, “GriD-LMIA: A Gridding-Based Assembler for Solving Differentiable Parameter-Dependent Linear Matrix Inequalities,” arXiv:2608.03175, 2026.";
const welcomeBibtex = `@article{xu2026gridlmia,
  title         = {GriD-LMIA: A Gridding-Based Assembler for Solving Differentiable Parameter-Dependent Linear Matrix Inequalities},
  author        = {Xu, Yicheng and Jabbari, Faryar},
  year          = {2026},
  eprint        = {2608.03175},
  archivePrefix = {arXiv}
}`;

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
      const content = formula.closest(".formula-fit-content");
      const nativeOrigin = content ?? wrapper;
      const transform = content ? new DOMMatrixReadOnly(getComputedStyle(content).transform) : new DOMMatrixReadOnly();
      const wrapperRect = nativeOrigin.getBoundingClientRect();
      const formulaRect = formula.getBoundingClientRect();
      return {
        index,
        markup: formula.outerHTML,
        scale: { x: Math.hypot(transform.a, transform.b), y: Math.hypot(transform.c, transform.d) },
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
  const count = Math.max(before.length, after.length);
  for (let index = 0; index < count; index += 1) {
    const initial = intrinsicFormulaRect(before[index]);
    const settled = intrinsicFormulaRect(after[index]);
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
      const overflowNode = [...document.body.querySelectorAll("*")]
        .map((node) => ({ node, rect: node.getBoundingClientRect() }))
        .filter(({ rect }) =>
          rect.width > 0 &&
          rect.height > 0 &&
          (rect.left < -tolerance || rect.right > root.clientWidth + tolerance))
        .sort((left, right) => right.rect.right - left.rect.right)[0];
      failures.push({
        type: "page",
        selector: overflowNode ? describe(overflowNode.node) : "html",
        actual: root.scrollWidth,
        allowed: root.clientWidth,
        context: overflowNode
          ? `${contextFor(overflowNode.node)} ${JSON.stringify({
            left: overflowNode.rect.left,
            right: overflowNode.rect.right,
            width: overflowNode.rect.width,
          })}`
          : contextFor(document.querySelector("main") ?? document.body, document.title),
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
      const displayRoot = wrapper.querySelector(":scope > .formula-fit-size > .formula-fit-content > .katex-display");
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
      if (expectsDisplay) {
        const content = wrapper.querySelector(".formula-fit-content");
        const frameStyle = getComputedStyle(wrapper);
        const availableWidth = wrapper.clientWidth - parseFloat(frameStyle.paddingLeft) - parseFloat(frameStyle.paddingRight);
        const naturalWidth = content?.offsetWidth ?? 0;
        const scale = Number(wrapper.dataset.formulaScale);
        const expectedScale = Math.max(.85, Math.min(1, availableWidth / naturalWidth));
        if (!naturalWidth || !Number.isFinite(scale) || !wrapper.hasAttribute("data-formula-fitted") || Math.abs(scale - expectedScale) > .002) {
          failures.push({ type: "formula-fit-scale", selector: describe(wrapper), actual: scale, allowed: expectedScale });
        }
        if (naturalWidth * .85 > availableWidth + tolerance && wrapper.tabIndex !== 0) {
          failures.push({ type: "formula-scroll-keyboard", selector: describe(wrapper) });
        }
        const slot = wrapper.querySelector(".formula-fit-size")?.getBoundingClientRect();
        if (slot && naturalWidth <= availableWidth && Math.abs((slot.left + slot.right) / 2 - (wrapper.getBoundingClientRect().left + wrapper.getBoundingClientRect().right) / 2) > tolerance) {
          failures.push({ type: "formula-fit-centering", selector: describe(wrapper) });
        }
        const baseSize = parseFloat(style.fontSize);
        const scripts = [...formula.querySelectorAll(".msupsub .sizing")];
        if (scripts.some((node) => parseFloat(getComputedStyle(node).fontSize) >= baseSize)) {
          failures.push({ type: "formula-script-proportion", selector: describe(wrapper) });
        }
      }
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

      const localScroller = wrapper.closest(
        "[data-formula-fit], .elevate-formula-one-line, .solver-one-line, .cell-formula-one-line, .welcome-target",
      );
      const localScrollerStyle = localScroller ? getComputedStyle(localScroller) : null;
      const localNeedsScroll = Boolean(
        localScroller && localScroller.scrollWidth > localScroller.clientWidth + tolerance
      );
      const localScrollActive = Boolean(
        localScroller &&
        localScrollerStyle &&
        localScrollerStyle.overflowX === "auto" &&
        localNeedsScroll
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
        // Browser scroll width is the rendered-content contract for indivisible displays.
        if (localNeedsScroll && !localScrollActive) {
          failures.push({
            type: "local-formula-scroll-required",
            selector: describe(localScroller),
            actual: localScroller.scrollWidth,
            allowed: localScroller.clientWidth,
            context: contextFor(wrapper),
          });
        }
        if (localScrollerStyle?.overflowX === "scroll" && !localNeedsScroll) {
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

    for (const label of document.querySelectorAll(".curve-axis-labels span")) {
      const bounds = label.getBoundingClientRect();
      if (bounds.width && parseFloat(getComputedStyle(label).fontSize) < 12) {
        failures.push({ type: "multiplication-axis-label-size", selector: describe(label), actual: parseFloat(getComputedStyle(label).fontSize), allowed: 12 });
      }
    }

    // Unicode labels use font-native script glyphs, not KaTeX style nodes.
    const scriptGlyphs = "₀₁₂₃₄₅₆₇₈₉⁰¹²³⁴⁵⁶⁷⁸⁹";
    const glyphCanvas = document.createElement("canvas").getContext("2d");
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      const text = walker.currentNode;
      const parent = text.parentElement;
      if (!parent || parent.closest(".katex, pre, code, script, style") || !/[₀-₉⁰¹²³⁴⁵⁶⁷⁸⁹]/.test(text.textContent ?? "")) continue;
      const font = getComputedStyle(parent);
      if (font.display === "none" || !parent.getBoundingClientRect().width || !glyphCanvas) continue;
      glyphCanvas.font = `${font.fontStyle} ${font.fontWeight} ${font.fontSize} ${font.fontFamily}`;
      for (const glyph of text.textContent ?? "") {
        const index = scriptGlyphs.indexOf(glyph);
        if (index < 0) continue;
        const script = glyphCanvas.measureText(glyph);
        const base = glyphCanvas.measureText(String(index % 10));
        const ratio = (script.actualBoundingBoxAscent + script.actualBoundingBoxDescent) / (base.actualBoundingBoxAscent + base.actualBoundingBoxDescent);
        if (!(ratio > 0 && ratio < .9)) failures.push({ type: "unicode-script-proportion", selector: describe(parent), actual: ratio, context: text.textContent });
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

    const storageDestination = "/GriD-LMIA/documents/reference/pdmat/storage-and-elevation/";
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

    if (location.pathname.endsWith("/documents/math/bernstein-polynomial/")) {
      const figures = [...document.querySelectorAll(".bernstein-concept, .cell-storage-diagram")];
      if (
        figures.length !== 3 ||
        figures.some((figure) => {
          const body = figure.querySelector(".diagram-frame__body");
          return !body || body.children.length === 0 || body.getBoundingClientRect().height <= 32;
        })
      ) {
        failures.push({
          type: "bernstein-empty-figure",
          selector: ".bernstein-concept, .cell-storage-diagram",
          actual: figures.length,
          allowed: 3,
          context: figures.map((figure) => ({
            className: figure.className,
            children: figure.querySelector(".diagram-frame__body")?.children.length ?? 0,
            height: figure.querySelector(".diagram-frame__body")?.getBoundingClientRect().height ?? 0,
          })),
        });
      }
    }

    if (location.pathname.endsWith("/examples/solver-smoke/")) {
      const firstPlant = [...document.querySelectorAll(".solver-one-line")]
        .find((formula) => formula.querySelector(
          'annotation[encoding="application/x-tex"]',
        )?.textContent?.includes("A(\\rho)=(1-\\rho)"));
      const tex = firstPlant
        ?.querySelector('annotation[encoding="application/x-tex"]')
        ?.textContent ?? "";
      if (!firstPlant || /\\begin\{(?:aligned|gathered|split)\}/.test(tex)) {
        failures.push({
          type: "solver-plant-one-line",
          selector: ".solver-one-line",
          context: tex || "first A(rho) display not found",
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

async function auditWelcomeRoot(browser, origin, failures) {
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

      const welcome = await page.locator(".welcome").evaluate((section) => {
        const rect = section.getBoundingClientRect();
        const workflow = section.querySelector(".welcome-workflow");
        const target = section.querySelector(".welcome-target");
        const targetFormula = target?.querySelector(":scope > .formula-display > .formula-fit-size > .formula-fit-content > .katex-display");
        const targetTex = targetFormula
          ?.querySelector('annotation[encoding="application/x-tex"]')
          ?.textContent ?? "";
        const targetStyle = target ? getComputedStyle(target) : null;
        const targetNeedsScroll = Boolean(
          target && target.scrollWidth > target.clientWidth + 1
        );
        const diagramMath = [...section.querySelectorAll(".workflow-visual .diagram-math")]
          .map((node) => node.textContent?.trim() ?? "");
        const workflowColumns = workflow
          ? getComputedStyle(workflow).gridTemplateColumns.split(" ").filter(Boolean).length
          : 0;
        const info = section.querySelector(".welcome-info");
        const infoStream = section.querySelector(".welcome-info__stream");
        const infoLinks = [...section.querySelectorAll(".welcome-info a")]
          .map((link) => new URL(link.href).pathname);
        const infoOrder = [...section.querySelectorAll(".welcome-info__item h3")]
          .map((heading) => heading.textContent?.trim() ?? "");
        const citationCodes = [...section.querySelectorAll(".citation-code")]
          .map((code) => {
            const codeRect = code.getBoundingClientRect();
            const itemRect = code.closest(".welcome-info__item")?.getBoundingClientRect();
            const labelId = code.getAttribute("aria-labelledby") ?? "";
            return {
              overflowX: getComputedStyle(code).overflowX,
              needsScroll: code.scrollWidth > code.clientWidth + 1,
              tabIndex: code.tabIndex,
              labelId,
              labelText: labelId ? document.getElementById(labelId)?.textContent?.trim() ?? "" : "",
              text: code.textContent ?? "",
              contained: Boolean(
                itemRect &&
                codeRect.left >= itemRect.left - 1 &&
                codeRect.right <= itemRect.right + 1
              ),
            };
          });
        const text = section.textContent ?? "";
        return {
          actionCount: section.querySelectorAll(".welcome-actions a").length,
          workflowCount: section.querySelectorAll(".welcome-workflow a").length,
          workflowColumns,
          infoCount: info ? 1 : 0,
          infoHeadingCount: info?.querySelectorAll("h2").length ?? 0,
          infoItemCount: info?.querySelectorAll(".welcome-info__item").length ?? 0,
          infoSeparatorCount: info?.querySelectorAll(".welcome-info__separator").length ?? 0,
          infoDisplay: infoStream ? getComputedStyle(infoStream).display : "",
          infoDirection: infoStream ? getComputedStyle(infoStream).flexDirection : "",
          infoOrder,
          infoLinks,
          citationCodes,
          islandCount: section.querySelectorAll("astro-island").length,
          targetCount: section.querySelectorAll(".welcome-target").length,
          targetDisplayCount: section.querySelectorAll(".welcome-target > .formula-display > .formula-fit-size > .formula-fit-content > .katex-display").length,
          targetMathCount: section.querySelectorAll(".welcome-target math[display='block']").length,
          targetTex,
          targetNeedsScroll,
          targetScrollActive: targetStyle?.overflowX === "auto" && targetNeedsScroll,
          modelShorthand: diagramMath[0] ?? "",
          gridShorthand: diagramMath[1] ?? "",
          sigmaCount: (text.match(/Σ/g) ?? []).length,
          hasMu: /[μµ]/.test(text),
          left: rect.left,
          right: rect.right,
          clientWidth: document.documentElement.clientWidth,
          scrollWidth: document.documentElement.scrollWidth,
        };
      });

      const citationKeyboard = [];
      const citationLocators = page.locator(".citation-code");
      for (let index = 0; index < await citationLocators.count(); index += 1) {
        const code = citationLocators.nth(index);
        const needsScroll = await code.evaluate(
          (node) => node.scrollWidth > node.clientWidth + 1,
        );
        let moved = false;
        if (needsScroll) {
          await code.evaluate((node) => { node.scrollLeft = 0; });
          await code.focus();
          for (let press = 0; press < 4; press += 1) {
            await page.keyboard.press("ArrowRight");
          }
          await page.waitForTimeout(50);
          moved = await code.evaluate((node) => node.scrollLeft > 0);
        }
        citationKeyboard.push({ needsScroll, moved });
      }
      welcome.citationKeyboard = citationKeyboard;

      const expectedColumns = viewport.width <= 620 ? 1 : 5;
      if (
        welcome.actionCount !== 4 ||
        welcome.workflowCount !== 5 ||
        welcome.workflowColumns !== expectedColumns ||
        welcome.infoCount !== 1 ||
        welcome.infoHeadingCount !== 1 ||
        welcome.infoItemCount !== 3 ||
        welcome.infoSeparatorCount !== 2 ||
        welcome.infoDisplay !== "flex" ||
        welcome.infoDirection !== "column" ||
        JSON.stringify(welcome.infoOrder) !== JSON.stringify([
          "Author and maintainer",
          "Latest in v1.5.0",
          "Cite GriD-LMIA",
        ]) ||
        !["about", "version-history", "citing"].every((route) =>
          welcome.infoLinks.some((path) => path.endsWith(`/${route}/`))
        ) ||
        welcome.citationCodes.length !== 2 ||
        welcome.citationCodes.some((code) => code.overflowX !== "auto" || code.tabIndex !== 0 || !code.contained) ||
        welcome.citationCodes[0]?.labelId !== "citation-plain-label" ||
        welcome.citationCodes[0]?.labelText !== "Plain text" ||
        welcome.citationCodes[0]?.text !== welcomeCitation ||
        welcome.citationCodes[1]?.labelId !== "citation-bibtex-label" ||
        welcome.citationCodes[1]?.labelText !== "BibTeX" ||
        welcome.citationCodes[1]?.text !== welcomeBibtex ||
        welcome.citationKeyboard.some((code) => code.needsScroll && !code.moved) ||
        welcome.islandCount !== 0 ||
        welcome.targetCount !== 1 ||
        welcome.targetDisplayCount !== 1 ||
        welcome.targetMathCount !== 1 ||
        !welcome.targetTex.includes("\\dot\\rho_s F_{k,s}(\\vect\\rho)") ||
        !welcome.targetTex.includes("\\forall(\\vect\\rho,\\dot{\\vect\\rho})\\in\\mathcal P\\times\\mathcal R.") ||
        (welcome.targetNeedsScroll && !welcome.targetScrollActive) ||
        (viewport.width === 1440 && welcome.targetNeedsScroll) ||
        welcome.modelShorthand !== "𝓕 ≼ 0" ||
        welcome.gridShorthand !== "ρ ∈ 𝒫" ||
        welcome.sigmaCount !== 1 ||
        welcome.hasMu ||
        welcome.left < -1 ||
        welcome.right > welcome.clientWidth + 1 ||
        welcome.scrollWidth > welcome.clientWidth + 1
      ) {
        throw new Error(`welcome root contract mismatch: ${JSON.stringify(welcome)}`);
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
        selector: "welcome-root",
        ...issue,
      });
    }
  }
}

async function auditDetailedWalkthroughs(browser, origin, failures) {
  const viewport = { width: 1440, height: 900 };
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  const issues = [];
  const state = { route: "", width: viewport.width };
  attachProductionSignals(page, origin, issues, state);

  try {
    state.route = `${base}/documents/math/sos-certificates/`;
    let response = await page.goto(`${origin}${state.route}`, { waitUntil: "networkidle" });
    if (!response?.ok()) throw new Error(`certificate detail returned ${response?.status() ?? "no response"}`);
    const certificate = page.getByRole("figure", { name: "Finite certificate selection flow" });
    await certificate.scrollIntoViewIfNeeded();
    await certificate.locator("astro-island").waitFor({ state: "attached", timeout: 5_000 }).catch(() => {});
    await page.waitForFunction(() =>
      !document.querySelector("figure.certificate-flow-figure astro-island[ssr]"), null, { timeout: 15_000 });

    const certificateStates = [
      { name: "Direct", command: "selected = L;" },
      { name: "Pólya", command: "selected = L.usePolya(d);" },
      { name: "Putinar", command: "selected = L.usePutinar();" },
      { name: "SparsePutinar", command: "selected = L.useSpPut();" },
      { name: "SparseFullBox", command: "selected = L.useSpBox();" },
      { name: "FullBox", command: "selected = L.useFullBox();" },
    ];
    for (const { name, command } of certificateStates) {
      const tab = certificate.getByRole("tab", { name: new RegExp(`^${name}\\b`) });
      await tab.click();
      if (await tab.getAttribute("aria-selected") !== "true") {
        throw new Error(`${name} certificate tab did not become selected`);
      }
      await certificate.getByRole("tabpanel").locator("code").filter({ hasText: command })
        .waitFor({ state: "visible", timeout: 5_000 });
      const formulaState = await certificate.evaluate((figure) => {
        const roots = [...figure.querySelectorAll(".formula-math .katex")];
        return {
          count: roots.length,
          invalid: roots.filter((root) =>
            !root.querySelector(".katex-html") ||
            !root.querySelector("math") ||
            root.querySelector("svg")).length,
        };
      });
      if (formulaState.count === 0 || formulaState.invalid !== 0) {
        throw new Error(`certificate-formula-state ${name}: ${JSON.stringify(formulaState)}`);
      }
    }

    state.route = `${base}/documents/math/gridding-and-degree/`;
    response = await page.goto(`${origin}${state.route}`, { waitUntil: "networkidle" });
    if (!response?.ok()) throw new Error(`grid detail returned ${response?.status() ?? "no response"}`);
    const grid = page.locator("figure.grid-partition-explorer");
    await grid.scrollIntoViewIfNeeded();
    await page.waitForFunction(() =>
      !document.querySelector("figure.grid-partition-explorer astro-island[ssr]"), null, { timeout: 15_000 });
    const slider = grid.getByRole("slider").first();
    const output = grid.locator("output").first();
    const previousOutput = (await output.textContent())?.trim() ?? "";
    await slider.fill("0.61");
    await page.waitForFunction(
      (before) => document.querySelector("figure.grid-partition-explorer output")?.textContent?.trim() !== before,
      previousOutput,
      { timeout: 5_000 },
    );

    state.route = `${base}/documents/math/coordinates-and-bernstein/coefficient-algebra/`;
    response = await page.goto(`${origin}${state.route}`, { waitUntil: "networkidle" });
    if (!response?.ok()) throw new Error(`storage detail returned ${response?.status() ?? "no response"}`);
    const storage = page.locator(".cell-storage-detail figure.interactive-figure");
    await storage.scrollIntoViewIfNeeded();
    await page.waitForFunction(() =>
      !document.querySelector(".cell-storage-detail astro-island[ssr]"), null, { timeout: 15_000 });
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
    const alignment = await storage.evaluate((figure) => {
      const stageLayout = figure.querySelector(".cell-stage-layout");
      const basisReadout = figure.querySelector(".cell-stage--basis .cell-bernstein-readout");
      const basisGroup = basisReadout?.querySelector(".cell-bernstein-formula-group");
      const readoutRect = basisReadout?.getBoundingClientRect();
      const groupRect = basisGroup?.getBoundingClientRect();
      return {
        stageColumnCount: stageLayout
          ? getComputedStyle(stageLayout).gridTemplateColumns.split(" ").filter(Boolean).length
          : 0,
        activeFormulaScrollers: [...figure.querySelectorAll(".cell-formula-one-line")]
          .filter((scroller) => scroller.scrollWidth > scroller.clientWidth + 1).length,
        basisOffset: readoutRect && groupRect
          ? Math.abs(
            (groupRect.top + groupRect.bottom) / 2 -
            (readoutRect.top + readoutRect.bottom) / 2
          )
          : Number.POSITIVE_INFINITY,
      };
    });
    if (
      alignment.stageColumnCount !== 1 ||
      alignment.activeFormulaScrollers !== 0 ||
      alignment.basisOffset > 2
    ) {
      throw new Error(`storage basis alignment regression: ${JSON.stringify(alignment)}`);
    }
  } catch (error) {
    issues.push({
      type: "detail-walkthrough-regression",
      route: state.route,
      width: state.width,
      context: error instanceof Error ? error.message : String(error),
    });
  } finally {
    await context.close();
  }

  for (const issue of issues) {
    failures.push({ selector: "detail-walkthroughs", ...issue });
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

async function auditHeaderLayout(browser, origin, failures) {
  const route = `${base}/`;
  const viewport = { width: 1280, height: 900 };
  for (const theme of defaultThemes) {
    const context = await browser.newContext({ viewport });
    const page = await context.newPage();
    try {
      const response = await page.goto(`${origin}${route}`, { waitUntil: "networkidle" });
      if (!response?.ok()) throw new Error(`header route returned ${response?.status() ?? "no response"}`);
      await page.evaluate((activeTheme) => {
        document.documentElement.dataset.theme = activeTheme;
        document.documentElement.style.colorScheme = activeTheme;
      }, theme);
      await page.evaluate(() => document.fonts.ready);
      const result = await page.evaluate(() => {
        const selectors = [
          ".site-header__brand",
          ".site-header__search",
          ".site-header__end",
        ];
        const regions = selectors.map((selector) => {
          const node = document.querySelector(selector);
          if (!node) return { selector, missing: true };
          const style = getComputedStyle(node);
          const rect = node.getBoundingClientRect();
          return {
            selector,
            visible: style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0,
            left: rect.left,
            right: rect.right,
            top: rect.top,
            bottom: rect.bottom,
          };
        });
        const visible = regions.filter((region) => region.visible);
        const overlaps = [];
        for (let left = 0; left < visible.length; left += 1) {
          for (let right = left + 1; right < visible.length; right += 1) {
            const first = visible[left];
            const second = visible[right];
            if (first.left < second.right && first.right > second.left &&
                first.top < second.bottom && first.bottom > second.top) {
              overlaps.push([first.selector, second.selector]);
            }
          }
        }
        return { regions, overlaps };
      });
      if (result.regions.some((region) => region.missing) || result.overlaps.length) {
        failures.push({
          width: viewport.width,
          route: `${route} [${theme}]`,
          type: "header-region-overlap",
          selector: ".site-header",
          context: JSON.stringify(result),
        });
      }
    } finally {
      await context.close();
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
const requiredSparseRoutes = [
  `${base}/citing/`,
  `${base}/documents/math/finite-certificates/sparseputinar/`,
  `${base}/documents/reference/pdlmi/usespput/`,
];
if (!requiredSparseRoutes.every((route) => allRoutes.includes(route))) {
  throw new Error(`Built output is missing a required SparsePutinar or citing route: ${requiredSparseRoutes.filter((route) => !allRoutes.includes(route)).join(", ")}`);
}
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
        if (route === `${base}/`) {
          const wordmark = await page.locator("#welcome-title").evaluate((node) => {
            // A text range exposes hyphen wrapping that the paragraph's block rectangle hides.
            const range = document.createRange();
            range.selectNodeContents(node);
            const textRects = [...range.getClientRects()].filter((rect) => rect.width > 0 && rect.height > 0);
            const lineTops = textRects.reduce((tops, rect) => {
              if (!tops.some((top) => Math.abs(top - rect.top) <= 1)) tops.push(rect.top);
              return tops;
            }, []);
            const nodeRect = node.getBoundingClientRect();
            const textLeft = Math.min(...textRects.map((rect) => rect.left));
            const textRight = Math.max(...textRects.map((rect) => rect.right));
            return {
              lineCount: lineTops.length,
              textRectCount: textRects.length,
              textLeft,
              textRight,
              nodeLeft: nodeRect.left,
              nodeRight: nodeRect.right,
              nodeClientWidth: node.clientWidth,
              nodeScrollWidth: node.scrollWidth,
              rootClientWidth: document.documentElement.clientWidth,
              rootScrollWidth: document.documentElement.scrollWidth,
            };
          });
          const allowedLineCount = width <= 620 ? 2 : 1;
          if (wordmark.lineCount > allowedLineCount) {
            failures.push({
              width,
              route: currentRoute,
              type: "home-wordmark-line",
              selector: "#welcome-title",
              actual: wordmark.lineCount,
              allowed: allowedLineCount,
              context: JSON.stringify(wordmark),
            });
          }
          if (
            wordmark.textLeft < wordmark.nodeLeft - tolerance ||
            wordmark.textRight > wordmark.nodeRight + tolerance ||
            wordmark.nodeScrollWidth > wordmark.nodeClientWidth + tolerance ||
            wordmark.rootScrollWidth > wordmark.rootClientWidth + tolerance
          ) {
            failures.push({
              width,
              route: currentRoute,
              type: "home-wordmark-bounds",
              selector: "#welcome-title",
              actual: Math.max(wordmark.textRight, wordmark.nodeScrollWidth, wordmark.rootScrollWidth),
              allowed: Math.max(wordmark.nodeRight, wordmark.nodeClientWidth, wordmark.rootClientWidth),
              context: JSON.stringify(wordmark),
            });
          }
        }
        if (
          width === 320 &&
          route.endsWith("/documents/reference/pdvar/constructor/")
        ) {
          const transcript = page.locator(".expressive-code pre").filter({
            hasText: "CellSubscript",
          }).first();
          await transcript.evaluate((node) => {
            node.scrollLeft = 0;
          });
          await transcript.focus();
          await page.keyboard.press("ArrowRight");
          await page.waitForTimeout(100);
          const scrollState = await transcript.evaluate((node) => ({
            focused: document.activeElement === node,
            overflowX: getComputedStyle(node).overflowX,
            rootClientWidth: document.documentElement.clientWidth,
            rootScrollWidth: document.documentElement.scrollWidth,
            scrollLeft: node.scrollLeft,
            scrollerClientWidth: node.clientWidth,
            scrollerScrollWidth: node.scrollWidth,
          }));
          if (
            !scrollState.focused ||
            !["auto", "scroll"].includes(scrollState.overflowX) ||
            scrollState.scrollerScrollWidth <= scrollState.scrollerClientWidth ||
            scrollState.scrollLeft <= 0 ||
            scrollState.rootScrollWidth !== scrollState.rootClientWidth
          ) {
            failures.push({
              width,
              route: currentRoute,
              type: "constructor-transcript-scroll",
              selector: ".expressive-code pre",
              actual: scrollState.scrollerScrollWidth,
              allowed: scrollState.scrollerClientWidth,
              context: JSON.stringify(scrollState),
            });
          }
        }
      }
    }
  }
  await auditWelcomeRoot(browser, origin, failures);
  await auditDetailedWalkthroughs(browser, origin, failures);
  await auditMobileStorageAnnotations(browser, origin, failures);
  await auditRhodiffEditor(browser, origin, failures);
  await auditHeaderLayout(browser, origin, failures);
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
