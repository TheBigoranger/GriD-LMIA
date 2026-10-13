import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import path from "node:path";
import test from "node:test";
import { parse } from "parse5";

const root = path.resolve(import.meta.dirname, "..");
const dist = path.join(root, "dist");
const read = (file: string) => readFileSync(path.join(dist, file), "utf8");
const normalize = (file: string) => file.replaceAll("\\", "/");

type HtmlNode = {
  attrs?: Array<{ name: string; value: string }>;
  childNodes?: HtmlNode[];
  nodeName: string;
  value?: string;
};

/** Visit a parsed document without depending on browser or server state. */
function descendants(node: HtmlNode): HtmlNode[] {
  const children = node.childNodes ?? [];
  return children.flatMap((child) => [child, ...descendants(child)]);
}

function attr(node: HtmlNode, name: string) {
  return node.attrs?.find((item) => item.name === name)?.value ?? "";
}

function hasClass(node: HtmlNode, name: string) {
  return attr(node, "class").split(/\s+/).includes(name);
}

function textOutsideSourceAnnotations(node: HtmlNode): string {
  if (node.nodeName === "annotation") return "";
  if (node.nodeName === "#text") return node.value ?? "";
  return (node.childNodes ?? []).map(textOutsideSourceAnnotations).join("");
}

test("fresh production output bundles static KaTeX assets and rendered formulas locally", () => {
  assert.ok(existsSync(path.join(dist, "index.html")), "run the production build before testing dist");
  const files = readdirSync(dist, { recursive: true }).map(String);
  const normalizedFiles = files.map(normalize);
  const retiredName = ["math", "jax"].join("");
  const retiredPattern = new RegExp(retiredName, "i");

  assert.ok(
    normalizedFiles.every((file) => !retiredPattern.test(file)),
    "dist must not contain artifacts from the retired renderer",
  );

  const cssFiles = normalizedFiles.filter((file) => file.endsWith(".css"));
  const cssBundles = cssFiles.map((file) => ({ file, source: read(file) }));
  const formulaCss = cssBundles.find(({ source }) => /\.katex(?:-display)?\s*\{/.test(source));
  assert.ok(formulaCss, "dist must contain the bundled KaTeX stylesheet");
  assert.match(formulaCss.source, /font-family:\s*KaTeX_/);
  for (const match of formulaCss.source.matchAll(/url\(([^)]+)\)/g)) {
    const url = match[1].replace(/^["']|["']$/g, "");
    assert.doesNotMatch(url, /^(?:https?:)?\/\//i, `external CSS asset URL: ${url}`);
  }

  const fontFiles = normalizedFiles.filter((file) =>
    /(?:^|\/)KaTeX_[^/]+\.(?:woff2?|ttf)$/.test(file));
  assert.ok(fontFiles.some((file) => file.endsWith(".woff2")), "dist must include local WOFF2 formula fonts");
  assert.ok(fontFiles.length >= 10, `expected a complete local font family, found ${fontFiles.length}`);

  const routes = normalizedFiles.filter((file) => file.endsWith(".html"));
  assert.ok(routes.length > 0, "dist must contain built HTML routes to audit");
  let formulaCount = 0;
  for (const route of routes) {
    const html = read(route);
    assert.doesNotMatch(html, retiredPattern, `${route} must not load the retired renderer`);
    const document = parse(html) as unknown as HtmlNode;
    const nodes = [document, ...descendants(document)];
    const formulas = nodes.filter((node) => hasClass(node, "katex"));
    formulaCount += formulas.length;

    for (const formula of formulas) {
      const nested = descendants(formula);
      assert.ok(nested.some((node) => hasClass(node, "katex-html")), `${route} formula lacks HTML`);
      assert.ok(nested.some((node) => node.nodeName === "math"), `${route} formula lacks MathML`);
      assert.ok(!nested.some((node) => node.nodeName === "svg"), `${route} formula contains SVG`);
      assert.doesNotMatch(
        textOutsideSourceAnnotations(formula),
        /\\(?:[A-Za-z]+|[()[\]])|\${1,2}/,
        `${route} formula contains raw TeX outside its source annotation`,
      );
    }

    for (const wrapper of nodes.filter((node) => hasClass(node, "formula-math"))) {
      assert.equal(
        descendants(wrapper).filter((node) => hasClass(node, "katex")).length,
        1,
        `${route} formula wrapper must contain one rendered root`,
      );
      const raw = (wrapper.childNodes ?? [])
        .filter((node) => node.nodeName === "#text")
        .map((node) => node.value ?? "")
        .join("")
        .trim();
      assert.doesNotMatch(raw, /\\(?:\(|\[)|\${1,2}/, `${route} contains a raw formula placeholder`);
    }

    const assetUrls = nodes.flatMap((node) => {
      if (node.nodeName === "script" && attr(node, "src")) return [attr(node, "src")];
      if (
        node.nodeName === "link"
        && attr(node, "rel").split(/\s+/).includes("stylesheet")
        && attr(node, "href")
      ) {
        return [attr(node, "href")];
      }
      return [];
    });
    for (const url of assetUrls) {
      assert.doesNotMatch(url, /^(?:https?:)?\/\//i, `${route} uses external asset ${url}`);
    }
  }
  assert.ok(formulaCount > 0, "the exhaustive HTML audit must inspect rendered formula roots");

  const executableOutput = normalizedFiles
    .filter((file) => /\.(?:html|js|css)$/.test(file))
    .map((file) => read(file))
    .join("\n");
  assert.doesNotMatch(executableOutput, retiredPattern);
});

test("fresh client bundles exclude the KaTeX renderer and dedicated math chunks", () => {
  assert.ok(existsSync(path.join(dist, "index.html")), "run the production build before testing dist");
  const clientBundles = readdirSync(path.join(dist, "_astro"), { recursive: true })
    .map((file) => normalize(path.join("_astro", String(file))))
    .filter((file) => file.endsWith(".js"));
  const clientRendererPattern =
    /renderToString|KaTeX can only parse string typed expression|katex-error|__renderToHTMLTree|__parse/i;

  assert.ok(clientBundles.length > 0, "dist must contain client bundles to audit");
  const dedicatedChunks = clientBundles.filter((file) =>
    /^_astro\/KaTeXMath\.[^/]+\.js$/i.test(file));
  const rendererBundles = clientBundles.filter((file) =>
    clientRendererPattern.test(read(file)));
  assert.deepEqual(
    { dedicatedChunks, rendererBundles },
    { dedicatedChunks: [], rendererBundles: [] },
    "dist client JavaScript must not contain formula-renderer chunks or parser code",
  );
});
