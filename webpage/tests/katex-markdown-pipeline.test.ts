import assert from "node:assert/strict";
import test from "node:test";
import rehypeKatex from "rehype-katex";
import rehypeStringify from "rehype-stringify";
import remarkMath from "remark-math";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import { unified } from "unified";

import { katexOptions } from "../src/lib/katex-options.js";
import rehypeKatexStrict from "../src/lib/rehype-katex-strict.js";

/** Exercise the same parser and renderer stages configured by Astro. */
const renderMarkdown = (markdown: string) => unified()
  .use(remarkParse)
  .use(remarkMath)
  .use(remarkRehype)
  .use(rehypeKatex, katexOptions)
  .use(rehypeKatexStrict)
  .use(rehypeStringify)
  .process(markdown);

test("renders inline and display Markdown math to strict HTML and MathML", async () => {
  const html = String(await renderMarkdown([
    "Inline $x_i^2$.",
    "",
    "$$",
    "\\sum_{i=0}^{m} x_i",
    "$$",
  ].join("\n")));

  assert.match(html, /<p>Inline <span class="katex">/);
  assert.match(html, /<span class="katex-display"><span class="katex">/);
  assert.equal((html.match(/class="katex-html"/g) ?? []).length, 2);
  assert.equal((html.match(/<math(?:\s|>)/g) ?? []).length, 2);
  assert.doesNotMatch(html, /(?:^|>)\s*\${1,2}|\\\(|\\\[|<svg(?:\s|>)/i);
});

test("strict Markdown rendering rejects malformed TeX", async () => {
  await assert.rejects(
    renderMarkdown("Broken $\\thisCommandDoesNotExist{x}$."),
    /KaTeX parse error|ParseError|Undefined control sequence/i,
  );
});

test("leaves ordinary dollar text and literal code untouched", async () => {
  const html = String(await renderMarkdown([
    "Price $5 stays ordinary.",
    "",
    "`$x$`",
    "",
    "```tex",
    "$x$",
    "```",
  ].join("\n")));

  assert.match(html, /Price \$5 stays ordinary\./);
  assert.match(html, /<code>\$x\$<\/code>/);
  assert.match(html, /<code class="language-tex">\$x\$/);
  assert.doesNotMatch(html, /class="katex(?:-display)?"/);
});
