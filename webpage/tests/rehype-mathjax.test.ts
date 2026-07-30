import assert from "node:assert/strict";
import test from "node:test";

import rehypeMathJaxDelimiters from "../src/lib/rehype-mathjax.js";

const transform = (tree: Record<string, unknown>) => {
  const transformer = rehypeMathJaxDelimiters();
  transformer(tree);
  return tree;
};

test("converts remark-math inline and display HAST nodes to raw MathJax delimiters", () => {
  const tree = {
    type: "root",
    children: [{
      type: "element",
      tagName: "p",
      properties: {},
      children: [
        { type: "text", value: "before " },
        {
          type: "element",
          tagName: "code",
          properties: { className: ["math-inline"] },
          children: [{ type: "text", value: "x_i^2" }],
        },
      ],
    }, {
      type: "element",
      tagName: "pre",
      properties: {},
      children: [{
        type: "element",
        tagName: "code",
        properties: { className: ["math-display"] },
        children: [{ type: "text", value: "\\sum_{i=0}^m x_i" }],
      }],
    }],
  };

  transform(tree);
  const inline = tree.children[0].children[1];
  const display = tree.children[1];
  assert.deepEqual(inline.properties.className, ["tex-math", "tex-inline"]);
  assert.equal(inline.children[0].value, "\\(x_i^2\\)");
  assert.equal(display.tagName, "div");
  assert.deepEqual(display.properties.className, ["tex-math", "tex-display"]);
  assert.equal(display.children[0].value, "\\[\\sum_{i=0}^m x_i\\]");
});

test("leaves ordinary dollar text and literal code untouched", () => {
  const tree = {
    type: "root",
    children: [{
      type: "element",
      tagName: "p",
      properties: {},
      children: [{ type: "text", value: "Price $5 and unmatched $x$ stay ordinary text." }],
    }, {
      type: "element",
      tagName: "pre",
      properties: {},
      children: [{
        type: "element",
        tagName: "code",
        properties: {},
        children: [{ type: "text", value: "$x$" }],
      }],
    }],
  };
  const original = structuredClone(tree);

  transform(tree);
  assert.deepEqual(tree, original);
});
