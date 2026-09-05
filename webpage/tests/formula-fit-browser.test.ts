import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { chromium } from "playwright";
import { installFormulaFit } from "../src/lib/formula-fit.ts";
import { renderMath } from "../src/lib/katex-renderer.js";

test("whole-formula layout preserves scripts, clamps and recovers after resize and markup changes", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    const css = readFileSync(new URL("../src/styles/manual.css", import.meta.url), "utf8");
    const katexCss = readFileSync(new URL("../node_modules/katex/dist/katex.min.css", import.meta.url), "utf8");
    const tex = String.raw`R^{(c)}[k]=\sum_{i+j=k}\Omega(i,j)P^{(c)}[i]Q^{(c)}[j]+x_i^{y_j}`;
    const markup = renderMath(tex, { displayMode: true });
    await page.setContent(`<style>${katexCss}\n${css}</style><div id="host" style="width:1000px"><div class="formula-math formula-display" data-formula-fit tabindex="0"><span class="formula-fit-size"><span class="formula-fit-content">${markup}</span></span></div></div>`);
    await page.addScriptTag({ content: `window.disposeFit = (${installFormulaFit.toString()})(document);` });
    const inspect = () => page.evaluate(() => {
      const frame = document.querySelector<HTMLElement>("[data-formula-fit]")!;
      const content = frame.querySelector<HTMLElement>(".formula-fit-content")!;
      const formula = frame.querySelector<HTMLElement>(".katex")!;
      const base = parseFloat(getComputedStyle(formula).fontSize);
      const ratios = [...formula.querySelectorAll(".msupsub .sizing")].map((node) => parseFloat(getComputedStyle(node).fontSize) / base);
      return { scale: Number(frame.dataset.formulaScale), natural: content.offsetWidth, available: frame.clientWidth, scroll: frame.scrollWidth, tabIndex: frame.tabIndex, html: formula.outerHTML, ratios, height: frame.querySelector(".formula-fit-size")!.getBoundingClientRect().height, actualHeight: content.getBoundingClientRect().height };
    });
    await page.waitForFunction(() => document.querySelector("[data-formula-fitted]"));
    const original = await inspect();
    assert.equal(original.scale, 1);
    assert.ok(original.ratios.some((ratio) => Math.abs(ratio - .7) < .02));
    assert.ok(original.ratios.some((ratio) => Math.abs(ratio - .5) < .02));
    for (const width of [320, 390, 700, 768, 1024, 1280, 1440, 150, 1000]) {
      await page.locator("#host").evaluate((host, width) => { (host as HTMLElement).style.width = `${width}px`; }, width);
      await page.waitForFunction(() => {
        const frame = document.querySelector<HTMLElement>("[data-formula-fit]")!;
        const natural = frame.querySelector<HTMLElement>(".formula-fit-content")!.offsetWidth;
        return Math.abs(Number(frame.dataset.formulaScale) - Math.max(.85, Math.min(1, frame.clientWidth / natural))) < .001;
      });
      const state = await inspect();
      assert.equal(state.html, original.html, "layout must not mutate HTML or MathML");
      assert.deepEqual(state.ratios, original.ratios, "nested scripts retain native proportions");
      assert.ok(Math.abs(state.height - state.actualHeight) < 1);
      if (state.natural * .85 > width + 1) {
        assert.equal(state.scale, .85);
        assert.equal(state.tabIndex, 0);
        await page.locator("[data-formula-fit]").focus();
        await page.keyboard.press("ArrowRight");
        await page.waitForFunction(() => document.querySelector("[data-formula-fit]")!.scrollLeft > 0);
      } else assert.ok(state.scroll <= width + 1);
    }
    const longer = renderMath(Array(10).fill(tex).join("+"), { displayMode: true });
    await page.locator(".formula-fit-content").evaluate((node, html) => { node.innerHTML = html; }, longer);
    await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve()))));
    const changed = await inspect();
    assert.ok(changed.natural > original.natural * 2, JSON.stringify(changed));
    assert.equal(changed.scale, Math.max(.85, Math.min(1, changed.available / changed.natural)));
    await page.evaluate(() => { (window as unknown as {disposeFit: () => void}).disposeFit(); });
  } finally { await browser.close(); }
});
