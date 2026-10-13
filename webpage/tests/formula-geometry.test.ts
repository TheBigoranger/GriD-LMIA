import assert from "node:assert/strict";
import test from "node:test";
import { chromium } from "playwright";
import { intrinsicFormulaRect } from "../scripts/formula-geometry.mjs";

test("measured outer transforms normalize fit shifts but retain intrinsic font drift", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.setContent('<div style="padding:17px"><span id="content" style="display:inline-block;transform-origin:left top"><span id="formula" style="font:20px monospace">R = P Q</span></span></div>');
    const snapshot = () => page.evaluate(() => {
      const content = document.querySelector('#content')!;
      const formula = document.querySelector('#formula')!;
      const matrix = new DOMMatrixReadOnly(getComputedStyle(content).transform);
      const rect = (node: Element) => {
        const bounds = node.getBoundingClientRect();
        return { left: bounds.left, top: bounds.top, width: bounds.width, height: bounds.height };
      };
      return {
        formulaRect: rect(formula), wrapperRect: rect(content),
        scale: { x: Math.hypot(matrix.a, matrix.b), y: Math.hypot(matrix.c, matrix.d) },
      };
    });
    const before = await snapshot();
    const native = intrinsicFormulaRect(before)!;
    for (const scale of [.85, .869, .983, 1]) {
      await page.locator('#content').evaluate((node, scale) => { (node as HTMLElement).style.transform = `scale(${scale})`; }, scale);
      const after = await snapshot();
      const actual = intrinsicFormulaRect(after)!;
      assert.ok(Math.abs(after.scale.x - scale) < 1e-6);
      for (const key of ['left', 'top', 'width', 'height'] as const) {
        assert.ok(Math.abs(actual[key] - native[key]) < 1);
      }
    }
    await page.locator('#formula').evaluate(node => { (node as HTMLElement).style.fontSize = '24px'; });
    const drift = intrinsicFormulaRect(await snapshot())!;
    assert.ok(Math.abs(drift.width - native.width) > 1, 'native glyph changes remain detectable');
    assert.equal(intrinsicFormulaRect({ ...before, scale: { x: NaN, y: 1 } }), null);
  } finally { await browser.close(); }
});
