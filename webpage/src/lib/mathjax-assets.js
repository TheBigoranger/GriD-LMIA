import { createReadStream } from "node:fs";
import { cp, mkdir, stat } from "node:fs/promises";
import { dirname, extname, isAbsolute, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const pageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const runtimeRoot = resolve(pageRoot, "node_modules/mathjax");
const fontRoot = resolve(pageRoot, "node_modules/@mathjax/mathjax-modern-font");
const modernBundle = "tex-mml-chtml-mathjax-modern.js";

const contentTypes = new Map([
  [".cjs", "text/javascript; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".map", "application/json; charset=utf-8"],
  [".mjs", "text/javascript; charset=utf-8"],
  [".svg", "image/svg+xml; charset=utf-8"],
  [".ttf", "font/ttf"],
  [".wasm", "application/wasm"],
  [".woff", "font/woff"],
  [".woff2", "font/woff2"],
]);

function safeSource(root, assetPath) {
  if (
    !assetPath ||
    assetPath.includes("\\") ||
    assetPath.includes("\0") ||
    assetPath.split("/").some((part) => !part || part === "." || part === "..")
  ) {
    return null;
  }
  const source = resolve(root, ...assetPath.split("/"));
  const fromRoot = relative(root, source);
  return fromRoot && !isAbsolute(fromRoot) && fromRoot !== ".." && !fromRoot.startsWith(`..${sep}`)
    ? source
    : null;
}

function resolveMathJaxSource(assetPath) {
  if (assetPath === modernBundle) {
    return safeSource(fontRoot, modernBundle);
  }
  const modernPrefix = "mathjax-modern/chtml/";
  if (assetPath.startsWith(modernPrefix)) {
    return safeSource(fontRoot, assetPath.slice("mathjax-modern/".length));
  }
  return safeSource(runtimeRoot, assetPath);
}

function mathJaxPrefix(base) {
  const cleanBase = String(base || "/").replace(/^\/+|\/+$/g, "");
  return `${cleanBase ? `/${cleanBase}` : ""}/mathjax/`;
}

async function copyMathJaxRuntime(target) {
  await cp(runtimeRoot, target, { recursive: true });
  await mkdir(resolve(target, "mathjax-modern"), { recursive: true });
  await cp(resolve(fontRoot, modernBundle), resolve(target, modernBundle));
  await cp(resolve(fontRoot, "chtml"), resolve(target, "mathjax-modern/chtml"), {
    recursive: true,
  });
}

function serveMathJax(prefix) {
  return (request, response, next) => {
    if (request.method !== "GET" && request.method !== "HEAD") {
      next();
      return;
    }

    let pathname;
    try {
      pathname = new URL(request.url || "/", "http://localhost").pathname;
    } catch {
      next();
      return;
    }
    // Vite removes Astro's configured base before integration middleware runs.
    const requestPrefix = pathname.startsWith(prefix)
      ? prefix
      : pathname.startsWith("/mathjax/")
        ? "/mathjax/"
        : null;
    if (!requestPrefix) {
      next();
      return;
    }

    let assetPath;
    try {
      assetPath = decodeURIComponent(pathname.slice(requestPrefix.length));
    } catch {
      response.statusCode = 400;
      response.end("Invalid MathJax asset path");
      return;
    }
    const source = resolveMathJaxSource(assetPath);
    if (!source) {
      response.statusCode = 404;
      response.end("MathJax asset not found");
      return;
    }

    void stat(source)
      .then((details) => {
        if (!details.isFile()) {
          response.statusCode = 404;
          response.end("MathJax asset not found");
          return;
        }
        response.statusCode = 200;
        response.setHeader("Cache-Control", "no-store");
        response.setHeader("Content-Length", String(details.size));
        response.setHeader(
          "Content-Type",
          contentTypes.get(extname(source).toLowerCase()) || "application/octet-stream",
        );
        response.setHeader("X-Content-Type-Options", "nosniff");
        if (request.method === "HEAD") {
          response.end();
          return;
        }
        const stream = createReadStream(source);
        stream.on("error", next);
        stream.pipe(response);
      })
      .catch((error) => {
        if (error?.code === "ENOENT" || error?.code === "ENOTDIR") {
          response.statusCode = 404;
          response.end("MathJax asset not found");
          return;
        }
        next(error);
      });
  };
}

/** Serve MathJax from source in development and copy the same asset tree after builds. */
export function selfHostedMathJax() {
  let assetPrefix = "/mathjax/";
  return {
    name: "pd-lmi-self-hosted-mathjax",
    hooks: {
      "astro:config:done": ({ config }) => {
        assetPrefix = mathJaxPrefix(config.base);
      },
      "astro:server:setup": ({ server }) => {
        server.middlewares.use(serveMathJax(assetPrefix));
      },
      "astro:build:done": async ({ dir }) => {
        const buildRoot = fileURLToPath(dir);
        await copyMathJaxRuntime(resolve(buildRoot, "mathjax"));
      },
    },
  };
}
