import { mathjax } from "mathjax-full/js/mathjax.js";
import { liteAdaptor } from "mathjax-full/js/adaptors/liteAdaptor.js";
import { RegisterHTMLHandler } from "mathjax-full/js/handlers/html.js";
import { TeX } from "mathjax-full/js/input/tex.js";
import { SVG } from "mathjax-full/js/output/svg.js";
import "mathjax-full/js/input/tex/ams/AmsConfiguration.js";

const adaptor = liteAdaptor();
RegisterHTMLHandler(adaptor);

const input = new TeX({ packages: ["base", "ams"] });
const output = new SVG({ fontCache: "none" });
const document = mathjax.document("", { InputJax: input, OutputJax: output });

const renderMath = (source, display) =>
  adaptor.outerHTML(document.convert(source, { display }));

export const renderDisplayMath = (source) => renderMath(source, true);
