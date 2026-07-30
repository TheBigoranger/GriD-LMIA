import katex from "katex";
import { katexOptions } from "./katex-options.js";

/** Render one formula to KaTeX HTML and MathML while preserving strict failures. */
export function renderMath(tex, { displayMode = false } = {}) {
  return katex.renderToString(tex, {
    ...katexOptions,
    displayMode,
  });
}
