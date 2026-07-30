const classNames = (node) => node.properties?.className ?? [];
const textValue = (node) => node.children?.map((child) => child.value ?? "").join("") ?? "";

/** Convert only official remark-math HAST nodes to raw MathJax delimiters. */
export default function rehypeMathJaxDelimiters() {
  return (tree) => {
    const visit = (node) => {
      if (!node?.children) return;
      if (classNames(node).includes("tex-math")) return;

      for (let childIndex = 0; childIndex < node.children.length; childIndex += 1) {
        const child = node.children[childIndex];
        if (child.tagName === "code" && classNames(child).includes("math-inline")) {
          node.children[childIndex] = {
            type: "element",
            tagName: "span",
            properties: { className: ["tex-math", "tex-inline"] },
            children: [{ type: "text", value: `\\(${textValue(child)}\\)` }],
          };
          continue;
        }

        if (
          child.tagName === "pre" &&
          child.children?.length === 1 &&
          child.children[0].tagName === "code" &&
          classNames(child.children[0]).includes("math-display")
        ) {
          node.children[childIndex] = {
            type: "element",
            tagName: "div",
            properties: { className: ["tex-math", "tex-display"] },
            children: [{ type: "text", value: `\\[${textValue(child.children[0])}\\]` }],
          };
          continue;
        }
        visit(child);
      }
    };

    visit(tree);
  };
}
