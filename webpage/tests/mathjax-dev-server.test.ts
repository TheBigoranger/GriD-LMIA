import assert from "node:assert/strict";
import { execFile, spawn } from "node:child_process";
import { createServer, request } from "node:http";
import path from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import { chromium } from "playwright";

const root = path.resolve(import.meta.dirname, "..");
const base = "/PD-LMI-package";
const astroCli = path.join(root, "node_modules/astro/bin/astro.mjs");
const execFileAsync = promisify(execFile);

async function reservePort() {
  const server = createServer();
  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const address = server.address();
  assert.ok(address && typeof address !== "string");
  const port = address.port;
  await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  return port;
}

async function waitForServer(origin: string, output: () => string) {
  const deadline = Date.now() + 30_000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`${origin}${base}/`);
      if (response.ok) return;
    } catch {
      // The isolated listener is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`Astro dev did not become ready.\n${output()}`);
}

async function astroControl(command: "status" | "stop") {
  return execFileAsync(process.execPath, [astroCli, "dev", command], {
    cwd: root,
    env: { ...process.env, NO_COLOR: "1" },
    windowsHide: true,
  });
}

function rawRequest(origin: string, requestPath: string, method = "GET") {
  return new Promise<{ body: Buffer; headers: Record<string, string | string[] | undefined>; status: number }>(
    (resolve, reject) => {
      const target = new URL(origin);
      const outgoing = request({
        host: target.hostname,
        port: target.port,
        method,
        path: requestPath,
      }, (response) => {
        const chunks: Buffer[] = [];
        response.on("data", (chunk) => chunks.push(Buffer.from(chunk)));
        response.on("end", () => resolve({
          body: Buffer.concat(chunks),
          headers: response.headers,
          status: response.statusCode ?? 0,
        }));
      });
      outgoing.once("error", reject);
      outgoing.end();
    },
  );
}

test("real Astro dev serves the local MathJax graph safely and renders formulas", {
  timeout: 60_000,
}, async () => {
  const port = await reservePort();
  const origin = `http://127.0.0.1:${port}`;
  const before = await astroControl("status");
  assert.match(`${before.stdout}${before.stderr}`, /No dev server is running/);
  const child = spawn(
    process.execPath,
    [
      astroCli,
      "dev",
      "--background",
      "--host",
      "127.0.0.1",
      "--port",
      String(port),
    ],
    {
      cwd: root,
      env: { ...process.env, NO_COLOR: "1" },
      stdio: ["ignore", "pipe", "pipe"],
      windowsHide: true,
    },
  );
  let stdout = "";
  let stderr = "";
  let managedPid: number | undefined;
  let primaryError: unknown;
  child.stdout?.on("data", (chunk) => { stdout = `${stdout}${chunk}`.slice(-20_000); });
  child.stderr?.on("data", (chunk) => { stderr = `${stderr}${chunk}`.slice(-20_000); });
  const output = () => `${stdout}\n${stderr}`;
  const launcherExit = new Promise<{ code: number | null; signal: NodeJS.Signals | null }>(
    (resolve, reject) => {
      child.once("error", reject);
      child.once("exit", (code, signal) => resolve({ code, signal }));
    },
  );

  try {
    const started = await launcherExit;
    assert.deepEqual(started, { code: 0, signal: null }, output());
    const parsedPid = Number(/\(pid (\d+)\)/.exec(output())?.[1]);
    if (Number.isInteger(parsedPid) && parsedPid > 0) managedPid = parsedPid;
    assert.ok(managedPid, `missing managed dev PID\n${output()}`);
    await waitForServer(origin, output);

    const assets = [
      [`${base}/mathjax/tex-mml-chtml-mathjax-modern.js`, /^text\/javascript\b/i, 10_000],
      [`${base}/mathjax/sre/speech-worker.js`, /^text\/javascript\b/i, 1_000],
      [`${base}/mathjax/input/tex/extensions/boldsymbol.js`, /^text\/javascript\b/i, 100],
      [`${base}/mathjax/mathjax-modern/chtml/woff2/mjx-mm-i.woff2`, /^font\/woff2\b/i, 1_000],
      ["/mathjax/tex-mml-chtml-mathjax-modern.js", /^text\/javascript\b/i, 10_000],
    ] as const;
    for (const [requestPath, contentType, minimumBytes] of assets) {
      const response = await rawRequest(origin, requestPath);
      assert.equal(response.status, 200, `${requestPath} returned ${response.status}\n${output()}`);
      assert.match(String(response.headers["content-type"]), contentType, requestPath);
      assert.ok(response.body.length >= minimumBytes, `${requestPath} returned only ${response.body.length} bytes`);
      assert.equal(response.headers["x-content-type-options"], "nosniff");
    }

    const head = await rawRequest(
      origin,
      `${base}/mathjax/mathjax-modern/chtml/woff2/mjx-mm-i.woff2`,
      "HEAD",
    );
    assert.equal(head.status, 200);
    assert.equal(head.body.length, 0);
    assert.match(String(head.headers["content-type"]), /^font\/woff2\b/i);

    for (const invalidPath of [
      `${base}/mathjax/%2e%2e%2fpackage.json`,
      `${base}/mathjax/%5cpackage.json`,
      `${base}/mathjax/%00.js`,
      `${base}/mathjax/input/`,
    ]) {
      const response = await rawRequest(origin, invalidPath);
      assert.equal(response.status, 404, `${invalidPath} unexpectedly returned ${response.status}`);
      assert.doesNotMatch(response.body.toString("utf8"), /"name"\s*:\s*"pd-lmi-webpage"/);
    }

    const browser = await chromium.launch({ headless: true });
    try {
      const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
      const externalRequests: string[] = [];
      const consoleErrors: string[] = [];
      const failedRequests: string[] = [];
      page.on("request", (pending) => {
        if (/^https?:/i.test(pending.url()) && !pending.url().startsWith(origin)) {
          externalRequests.push(pending.url());
        }
      });
      page.on("console", (message) => {
        if (message.type() === "error") consoleErrors.push(message.text());
      });
      page.on("requestfailed", (pending) => {
        failedRequests.push(`${pending.url()}: ${pending.failure()?.errorText ?? "unknown"}`);
      });

      const response = await page.goto(
        `${origin}${base}/documents/math/notation/`,
        { waitUntil: "networkidle" },
      );
      assert.ok(response?.ok(), `formula page returned ${response?.status()}`);
      await page.waitForFunction(
        () => document.documentElement.dataset.mathjaxReady === "true",
        null,
        { timeout: 15_000 },
      );
      const formulas = await page.locator(".tex-math").count();
      assert.ok(formulas > 0, "the representative page must contain formulas");
      await page.waitForFunction(
        () => [...document.querySelectorAll(".tex-math")]
          .filter((wrapper) => {
            const rect = wrapper.getBoundingClientRect();
            return rect.width > 0 && rect.height > 0;
          })
          .every((wrapper) => wrapper.querySelectorAll(":scope > mjx-container").length === 1),
        null,
        { timeout: 15_000 },
      );
      assert.deepEqual(externalRequests, []);
      assert.deepEqual(consoleErrors, []);
      assert.deepEqual(failedRequests, []);
    } finally {
      await browser.close();
    }
  } catch (error) {
    primaryError = error;
  } finally {
    const cleanupErrors: unknown[] = [];
    if (child.exitCode === null && child.pid) {
      child.kill();
      try {
        await Promise.race([
          launcherExit.catch(() => ({ code: child.exitCode, signal: child.signalCode })),
          new Promise<never>((_, reject) => setTimeout(
            () => reject(new Error(`Astro dev launcher ${child.pid} did not stop`)),
            10_000,
          )),
        ]);
      } catch (error) {
        cleanupErrors.push(error);
      }
    }
    try {
      await astroControl("stop");
    } catch (error) {
      cleanupErrors.push(error);
    }
    try {
      const after = await astroControl("status");
      assert.match(`${after.stdout}${after.stderr}`, /No dev server is running/);
    } catch (error) {
      cleanupErrors.push(error);
    }
    if (managedPid) {
      let alive = true;
      try {
        process.kill(managedPid, 0);
      } catch {
        alive = false;
      }
      if (alive) cleanupErrors.push(new Error(`Astro dev process ${managedPid} remains alive`));
    }
    if (primaryError) {
      if (cleanupErrors.length) {
        console.error("Astro dev cleanup also failed after the primary error:", ...cleanupErrors);
      }
      throw primaryError;
    }
    if (cleanupErrors.length) {
      throw new AggregateError(cleanupErrors, "Astro dev cleanup failed.");
    }
  }
});
