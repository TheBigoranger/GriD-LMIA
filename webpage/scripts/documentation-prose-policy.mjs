export const negativePattern = /\b(?:is not|are not|was not|were not|does not|do not|did not|cannot|can't|without|rather than|not|no|never|neither|nor|none|nothing)\b/i;

const sourceIdentifierStarts = new Set([
  "de", "helper", "pdbase", "pdmat", "pdvar", "pdlmi", "rhodiff", "toYalmip",
  "usePolya", "usePutinar", "useSparsePutinar", "useSparseFullBox", "useFullBox",
]);
const userFacingAttributes = new Set([
  "alt", "aria-label", "caption", "label", "placeholder", "summary", "title",
]);
const nonProseDataKeys = new Set([
  "anchor", "button", "class", "className", "command", "exportCommand", "formula",
  "formulaMarkup", "fullCode", "href", "id", "inlineMath", "manual", "math", "number",
  "sourceOfTruth", "tex", "type", "updateRule", "value", "visual",
]);

const boundaryHeadingPattern =
  /^(?:remarks?|implementation remarks?|validation and errors|diagnostics?|limitations?|status|failure interpretation(?: and limits?)?|boundaries and related apis)$/i;
const boundaryContextValues = new Set([
  "remark",
  "remarks",
  "implementation-remark",
  "validation-errors",
  "diagnostics",
  "limitations",
  "status",
  "failure-interpretation",
  "boundaries-related-apis",
]);

function plainHeading(source) {
  return source
    .replace(/<[^>]+>/g, "")
    .replace(/[\x60*_~]/g, "")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .trim();
}

export function isAllowedBoundaryHeading(heading) {
  return boundaryHeadingPattern.test(plainHeading(heading));
}

function cleanMarkdownLine(line) {
  if (/^[\][{}(),;]+$/.test(line.trim())) return "";
  return line
    .replace(/\x60[^\x60]*\x60/g, "CODE")
    .replace(/\$[^$]*\$/g, "MATH")
    .replace(/\{(?:[^{}]|\{[^{}]*\})*\}/g, "")
    .replace(/<[^>]+>/g, "")
    .replace(/&(?:#\d+|#x[0-9a-f]+|[a-z]+);/gi, "")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .trim();
}

function sourceLine(source, offset) {
  return source.slice(0, offset).split(/\r?\n/).length;
}

function decodeLiteral(value) {
  return value
    .replace(/\\n/g, " ")
    .replace(/\\(["'])/g, "$1")
    .replace(/&(?:#\d+|#x[0-9a-f]+|[a-z]+);/gi, " ")
    .trim();
}

function likelyUserCopy(value) {
  const text = decodeLiteral(value);
  if (!/[A-Za-z]/.test(text)) return false;
  if (/^(?:[.#/]?[\w-]+(?:[./][\w-]+)+|[\w-]+:[\w-]+)$/.test(text)) return false;
  if (/\\(?:vect|mathcal|sum|prod|begin|texttt|rho|alpha|qquad|partial)\b/.test(value)) return false;
  if (/\n|[{}]=|=>/.test(value)) return false;
  return /\s/.test(text) || /^[A-Z][A-Za-z-]*$/.test(text);
}

export function hasLowercaseSentenceStart(text, startsSentence = true) {
  const cleaned = text
    .replace(/\x60[^\x60]*\x60/g, "CODE")
    .replace(/\$[^$]*\$/g, "MATH")
    .replace(/<[^>]+>/g, " ")
    .replace(/^\s*(?:[-*+]\s+|>\s*|\|\s*)/, "")
    .trim();
  const candidates = [];
  if (startsSentence) candidates.push(cleaned.match(/^([a-z][A-Za-z-]*)\b/));
  for (const match of cleaned.matchAll(/[.!?]\s+["'([]*([a-z][A-Za-z-]*)\b/g)) candidates.push(match);
  return candidates.some((match) => {
    if (!match) return false;
    const word = match[1];
    return !sourceIdentifierStarts.has(word) && !/^[a-z]+(?:\.[a-z]+)+$/.test(word);
  });
}

export function componentUserVisibleEntries(source, file = "") {
  const entries = [];
  const add = (value, offset, origin, allowedNegative = false) => {
    const text = decodeLiteral(value);
    if (text) entries.push({ text, line: sourceLine(source, offset), origin, allowedNegative });
  };

  const frontmatter = source.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (frontmatter) {
    const frontmatterOffset = frontmatter.index + 4;
    let arrayKey = "";
    let offset = frontmatterOffset;
    for (const line of frontmatter[1].split(/\r?\n/)) {
      const key = line.match(/^\s*([A-Za-z][\w]*):/i)?.[1] ?? "";
      if (/^(?:inlineNoteParts|textParts)$/.test(key)) arrayKey = key;
      const activeKey = key || arrayKey;
      const dataContext = line.match(/data-doc-context=["']([^"']+)["']/i)?.[1] ?? "";
      const allowedNegative = boundaryContextValues.has(dataContext);
      if (!/^\s*import\b/.test(line) && !nonProseDataKeys.has(activeKey)) {
        for (const literal of line.matchAll(/(["'])(.*?)\1/g)) {
          if (likelyUserCopy(literal[2])) add(literal[2], offset + literal.index, `data:${activeKey || "literal"}`, allowedNegative);
        }
      }
      if (arrayKey && /^\s*\],?\s*$/.test(line)) arrayKey = "";
      offset += line.length + 1;
    }
  }

  let body = frontmatter ? source.slice(frontmatter[0].length) : source;
  const bodyOffset = frontmatter ? frontmatter[0].length : 0;
  body = body
    .replace(/<(style|script)\b[^>]*>[\s\S]*?<\/\1>/gi, (block) => " ".repeat(block.length))
    .replace(/<(code|pre)\b[^>]*>[\s\S]*?<\/\1>/gi, (block) => " ".repeat(block.length));

  for (const attribute of body.matchAll(/\b([\w:-]+)=(?:["'])(.*?)(?:["'])/g)) {
    if (userFacingAttributes.has(attribute[1]) && likelyUserCopy(attribute[2])) {
      add(attribute[2], bodyOffset + attribute.index, `attribute:${attribute[1]}`);
    }
  }

  const withoutExpressions = body.replace(/\{(?:[^{}]|\{[^{}]*\})*\}/g, (block) => " ".repeat(block.length));
  const textTag = String.raw`(?:a|b|button|dd|dt|figcaption|h[1-6]|header|label|li|nav|option|p|section|small|span|strong|summary|td|th)`;
  const textNodePattern = new RegExp(`<${textTag}\\b[^>]*>\\s*([^<{][^<]*)<`, "gi");
  const trailingTextPattern = /<\/(?:b|code|strong)>\s*([^<{][^<]*)</gi;
  for (const node of [...withoutExpressions.matchAll(textNodePattern), ...withoutExpressions.matchAll(trailingTextPattern)]) {
    const text = node[1].replace(/\s+/g, " ").trim();
    if (/[A-Za-z]/.test(text)) add(text, bodyOffset + node.index, "jsx-text");
  }

  for (const literal of body.matchAll(/\?\s*(["'])(.*?)\1\s*:\s*(["'])(.*?)\3/g)) {
    if (likelyUserCopy(literal[2])) add(literal[2], bodyOffset + literal.index, "conditional-copy");
    if (likelyUserCopy(literal[4])) add(literal[4], bodyOffset + literal.index, "conditional-copy");
  }

  if (/\.tsx$/.test(file)) {
    const renderedContexts = (name) => {
      const contexts = [];
      const escaped = name.replace(/[.*+?^{}$()|[\]\\]/g, "\\$&");
      const textPattern = new RegExp(
        "<(" + textTag.slice(3, -1) + ")\\b([^>]*)>[^<]*\\{\\s*" +
          escaped + "\\s*\\}[^<]*<\\/\\1>",
        "gi",
      );
      for (const match of source.matchAll(textPattern)) contexts.push(match[2]);
      const attributePattern = new RegExp(
        "\\b(" + [...userFacingAttributes].join("|") + ")=\\{\\s*" + escaped + "\\s*\\}",
        "gi",
      );
      for (const match of source.matchAll(attributePattern)) {
        const openingTag = source.slice(source.lastIndexOf("<", match.index), source.indexOf(">", match.index) + 1);
        contexts.push(openingTag);
      }
      return contexts;
    };
    const contextAllowsNegative = (context) => {
      const marker = context.match(/\bdata-doc-context=["']([^"']+)["']/i)?.[1];
      return (marker && boundaryContextValues.has(marker)) ||
        /\brole=["'](?:alert|status)["']/i.test(context);
    };
    const addRenderedBinding = (name, value, offset, origin) => {
      const contexts = renderedContexts(name);
      if (!contexts.length || !likelyUserCopy(value)) return;
      add(value, offset, origin, contexts.every(contextAllowsNegative));
    };

    for (const binding of source.matchAll(/\bconst\s+([A-Za-z_$][\w$]*)\s*=\s*(["'])(.*?)\2\s*;/g)) {
      addRenderedBinding(binding[1], binding[3], binding.index, "tsx-const:" + binding[1]);
    }
    for (const state of source.matchAll(/\bconst\s*\[\s*([A-Za-z_$][\w$]*)\s*,\s*([A-Za-z_$][\w$]*)\s*\]\s*=\s*useState\(\s*(["'])(.*?)\3\s*\)/g)) {
      addRenderedBinding(state[1], state[4], state.index, "tsx-state:" + state[1]);
      const setterPattern = new RegExp(
        "\\b" + state[2].replace(/[.*+?^{}$()|[\]\\]/g, "\\$&") + "\\(\\s*([\"'])(.*?)\\1\\s*\\)",
        "g",
      );
      for (const setter of source.matchAll(setterPattern)) {
        addRenderedBinding(state[1], setter[2], setter.index, "tsx-setter:" + state[1]);
      }
    }
  }

  if (/astro\.config\.mjs$/.test(file)) {
    for (const label of source.matchAll(/\blabel:\s*(["'])(.*?)\1/g)) add(label[2], label.index, "navigation-label");
  }
  if (/version-history\.js$/.test(file)) {
    for (const field of source.matchAll(/\b(status|summary):\s*(?:\r?\n\s*)?(["'])(.*?)\2/g)) add(field[3], field.index, `version-${field[1]}`);
  }
  return entries;
}

export function markdownProseLines(source) {
  const lines = source.split(/\r?\n/);
  const prose = [];
  const headings = [];
  const asideContexts = [];
  let inFence = false;
  let inDisplayMath = false;
  let inFrontmatter = lines[0]?.trim() === "---";
  let startsSentence = true;

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const trimmed = line.trim();

    if (inFrontmatter) {
      if (index > 0 && trimmed === "---") {
        inFrontmatter = false;
        continue;
      }
      const field = line.match(/^\s*(title|description):\s*(.+?)\s*$/);
      if (field) prose.push({ text: field[2], allowedNegative: false, line: index + 1, startsSentence: true });
      continue;
    }

    if (/^\x60{3}/.test(trimmed)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    if (/^\$\$/.test(trimmed)) {
      if (!trimmed.slice(2).includes("$$")) inDisplayMath = !inDisplayMath;
      continue;
    }
    if (inDisplayMath) {
      if (trimmed.endsWith("$$")) inDisplayMath = false;
      continue;
    }

    const heading = line.match(/^(#{1,6})\s+(.+?)\s*$/);
    if (heading) {
      const level = heading[1].length;
      headings.length = level - 1;
      headings[level - 1] = plainHeading(heading[2]);
      startsSentence = true;
      continue;
    }

    const asideStart = line.match(/<Aside\b[^>]*\btitle=["']([^"']+)["'][^>]*>/i);
    if (asideStart) asideContexts.push(isAllowedBoundaryHeading(asideStart[1].split(":")[0]));
    const allowedNegative =
      asideContexts.some(Boolean) || headings.some((item) => item && isAllowedBoundaryHeading(item));

    if (!/^(?:import|export)\b/.test(trimmed)) {
      const text = cleanMarkdownLine(line);
      if (text) {
        prose.push({ text, allowedNegative, line: index + 1, startsSentence });
        startsSentence = /[.!?]["')\]]?$/.test(text);
      }
    }

    if (/<\/Aside>/.test(line)) asideContexts.pop();
  }

  return prose;
}

export function stripAllowedComponentContexts(source) {
  const explicit = source.replace(
    /<([A-Za-z][\w:.-]*)\b[^>]*\bdata-doc-context=["']([^"']+)["'][^>]*>[\s\S]*?<\/\1>/gi,
    (block, _tag, context) => boundaryContextValues.has(context) ? block.replace(/[^\r\n]/g, " ") : block,
  );
  return explicit.replace(
    /<([A-Za-z][\w:.-]*)\b[^>]*\brole=["'](?:alert|status)["'][^>]*>[\s\S]*?<\/\1>/gi,
    (block) => block.replace(/[^\r\n]/g, " "),
  );
}
