/** Promote renderer parse messages to fatal build errors before fallback markup is serialized. */
export default function rehypeKatexStrict() {
  return (tree, file) => {
    const parseError = file.messages.find(
      (message) => message.source === "rehype-katex" && message.ruleId === "parseerror",
    );
    if (parseError) throw parseError.cause ?? parseError;
    // Author the same outer layout frame as the Astro and React presenters.
    const span = (className, children, properties = {}) => ({
      type: "element", tagName: "span", properties: { className: [className], ...properties }, children,
    });
    const wrap = (parent) => {
      if (!parent.children) return;
      parent.children = parent.children.map((node) => {
        if (node.type === "element" && node.properties?.className?.includes("katex-display")) {
          return span("formula-math", [span("formula-fit-size", [span("formula-fit-content", [node])])], {
            className: ["formula-math", "formula-display"], dataFormulaFit: "", tabIndex: 0, ariaLabel: "Mathematical formula",
          });
        }
        wrap(node);
        return node;
      });
    };
    wrap(tree);
  };
}
