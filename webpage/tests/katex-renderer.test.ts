import assert from "node:assert/strict";
import test from "node:test";

test("shared renderer emits strict accessible KaTeX markup without SVG", async () => {
  const { renderMath } = await import("../src/lib/katex-renderer.js");
  const inline = renderMath(String.raw`\boldsymbol{\rho}_1`, { displayMode: false });
  const display = renderMath(String.raw`\frac{x}{y}`, { displayMode: true });

  // Both wrapper types must expose KaTeX's visual HTML and accessible MathML outputs.
  for (const markup of [inline, display]) {
    assert.match(markup, /class="katex-html"/);
    assert.match(markup, /<math(?:\s|>)/);
    assert.doesNotMatch(markup, /<svg(?:\s|>)/i);
  }

  assert.doesNotMatch(inline, /class="katex-display"/);
  assert.match(display, /class="katex-display"/);
  assert.throws(() => renderMath(String.raw`\frac{1}{`, { displayMode: false }));
});
