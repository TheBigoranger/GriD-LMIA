import katex from "katex";

export const renderDisplayMath = (source) =>
  katex.renderToString(source, {
    displayMode: true,
    output: "htmlAndMathml",
    throwOnError: false,
  });

export const renderInlineMath = (source) =>
  katex.renderToString(source, {
    displayMode: false,
    output: "htmlAndMathml",
    throwOnError: false,
  });
