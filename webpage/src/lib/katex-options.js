/** Shared strict renderer boundary for Markdown and component-generated formulas. */
export const katexOptions = Object.freeze({
  output: "htmlAndMathml",
  throwOnError: true,
  strict: "error",
  trust: false,
});
