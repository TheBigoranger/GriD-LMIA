import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const terminologyPath = resolve(here, "../../../doc/support/terminology.json");
const { terms } = JSON.parse(readFileSync(terminologyPath, "utf8"));
const linkedTerms = terms.filter((term) => term.auto_link);
const expression = new RegExp(
  `\\b(${linkedTerms
    .map((term) => term.abbreviation.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
    .sort((left, right) => right.length - left.length)
    .join("|")})\\b`,
  "g",
);
const byAbbreviation = new Map(linkedTerms.map((term) => [term.abbreviation, term]));

const excludedTypes = new Set([
  "heading", "link", "linkReference", "definition", "code", "inlineCode",
  "math", "inlineMath", "html", "yaml", "toml", "mdxFlowExpression",
  "mdxTextExpression", "mdxJsxFlowElement", "mdxJsxTextElement",
]);

function visit(node, excluded = false) {
  const nextExcluded = excluded || excludedTypes.has(node.type);
  if (!nextExcluded && Array.isArray(node.children)) {
    const children = [];
    for (const child of node.children) {
      if (child.type !== "text") {
        visit(child, false);
        children.push(child);
        continue;
      }
      let cursor = 0;
      for (const match of child.value.matchAll(expression)) {
        if (match.index > cursor) children.push({ type: "text", value: child.value.slice(cursor, match.index) });
        const term = byAbbreviation.get(match[0]);
        children.push({
          type: "link",
          url: `/GriD-LMIA${term.web_definition_anchor}`,
          title: term.expansion,
          children: [{ type: "text", value: match[0] }],
          data: { hProperties: { className: ["term-link"], "data-term": term.id } },
        });
        cursor = match.index + match[0].length;
      }
      if (cursor === 0) children.push(child);
      else if (cursor < child.value.length) children.push({ type: "text", value: child.value.slice(cursor) });
    }
    node.children = children;
    return;
  }
  if (Array.isArray(node.children)) for (const child of node.children) visit(child, nextExcluded);
}

export default function remarkTerminologyLinks() {
  return (tree) => visit(tree);
}
