import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { referenceEntries } from "../src/data/reference-index.js";

const root = path.resolve(import.meta.dirname, "..");
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");
const readOptional = (file) => {
  const target = path.join(root, file);
  return fs.existsSync(target) ? fs.readFileSync(target, "utf8") : "";
};
const sourceRoot = path.join(root, "src");
const allSource = fs.readdirSync(sourceRoot, { recursive: true })
  .filter((file) => /\.(astro|md|mdx|ts|tsx)$/.test(file))
  .map((file) => fs.readFileSync(path.join(sourceRoot, file), "utf8"))
  .join("\n");

const component = (file) => readOptional(`src/components/${file}`);
const page = (file) => readOptional(`src/content/docs/documents/${file}`);
const home = component("HomePortal.astro");
const journey = component("JourneyCurve.astro");
const storage = component("CellStorageDiagram.astro");
const multiply = component("MultiplicationDiagram.astro");
const disclosure = component("ExampleDisclosure.astro");
const rhodiff = component("RhodiffDiagram.astro");
const certificate = component("CertificateSpectrum.astro");
const certificateFlow = component("CertificateFlow.astro");
const certificateFlowTabs = component("CertificateFlow.tsx");
const parameterCurve = component("ParameterCurveDiagram.astro");
const matrixGlyph = component("MatrixGlyphDiagram.astro");
const constraintAssembly = component("ConstraintAssemblyDiagram.astro");
const exportSolve = component("ExportSolveFlow.astro");
const cellExplorer = component("CellStorageExplorer.tsx");
const multiplyExplorer = component("MultiplicationExplorer.tsx");
const evaluateExplorer = component("EvaluateExplorer.tsx");
const diffStorage = component("DifferentiationStorage.astro");
const chooser = component("CertificateChooser.tsx");
const chooserWrapper = component("CertificateChooser.astro");
const rateExplorer = component("RateVertexExplorer.tsx");
const elevationExplorer = component("DegreeElevationExplorer.tsx");
const tensorExplorer = component("TensorTraversalExplorer.tsx");
const certificateNavigation = component("CertificateNavigation.astro");
const header = component("Header.astro");
const referenceCategoryHub = component("ReferenceCategoryHub.astro");
const documentsHub = page("index.mdx");
const generatedReferenceIndex = page("reference-index.mdx");
const referenceGenerator = read("scripts/generate-reference-index.mjs");
const referenceIndex = read("src/data/reference-index.js");

const pdmatCtor = page("reference/pdmat/constructor.mdx");
const pdmatEval = page("reference/pdmat/evaluate.mdx");
const pdmatPlot = page("reference/pdmat/plot.mdx");
const pdmatOps = page("reference/pdmat/matrix-operations.mdx");
const pdmatAlgebra = page("reference/pdmat/algebra.mdx");
const pdmatStructure = page("reference/pdmat/structural-operations.mdx");
const pdmatIndexing = page("reference/pdmat/indexing-and-inspection.mdx");
const pdvarCtor = page("reference/pdvar/constructor.mdx");
const pdvarValue = page("reference/pdvar/value.mdx");
const pdvarTable = page("reference/pdvar/bernsteintable.mdx");
const pdvarCompare = page("reference/pdvar/comparisons.mdx");
const pdvarOps = page("reference/pdvar/matrix-operations.mdx");
const pdvarAlgebra = page("reference/pdvar/algebra.mdx");
const pdvarStructure = page("reference/pdvar/structural-operations.mdx");
const pdvarIndexing = page("reference/pdvar/indexing-and-inspection.mdx");
const pdvarDiff = page("reference/pdvar/rhodiff.mdx");
const pdbaseStorage = page("reference/pdbase/storage-inspection.mdx");
const bernsteinMath = page("math/bernstein-polynomial.mdx");
const griddingMath = page("math/gridding-and-degree.mdx");
const sosMath = page("math/sos-certificates.mdx");
const modelMath = page("math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain.mdx");
const rateInterfaceMath = page("math/modeling-and-analysis/rate-box-and-interface-analysis.mdx");
const coefficientAlgebra = page("math/coordinates-and-bernstein/coefficient-algebra.mdx");
const directPolyaMath = page("math/finite-certificates/direct-and-polya.mdx");
const markovPutinarMath = page("math/finite-certificates/markov-lukacs-and-putinar.mdx");
const sparseFullboxMath = page("math/finite-certificates/sparsefullbox-and-fullbox.mdx");
const detailedMathPages = [
  modelMath,
  rateInterfaceMath,
  coefficientAlgebra,
  directPolyaMath,
  markovPutinarMath,
  sparseFullboxMath,
];
const pdlmiOverview = page("reference/pdlmi/index.mdx");
const pdlmiCtor = page("reference/pdlmi/constructor.mdx");
const pdlmiPolya = page("reference/pdlmi/applypolya.mdx");
const pdlmiPutinar = page("reference/pdlmi/applyputinar.mdx");
const pdlmiSparseFullbox = page("reference/pdlmi/applysparsefullboxpreorder.mdx");
const pdlmiFullbox = page("reference/pdlmi/applyfullboxpreorder.mdx");
const pdlmiYalmip = page("reference/pdlmi/toyalmip.mdx");
const sharedHelpers = page("reference/shared-helpers.md");
const bernsteinUtilities = page("reference/bernstein-utilities.md");
const versionHistory = read("src/data/version-history.js");
const versionData = read("src/data/version.js");

const astroConfig = read("astro.config.mjs");
const packageJson = read("package.json");
const manualCss = read("src/styles/manual.css");
const mathStyleSources = `${manualCss}\n${allSource}`;
const displaySizeRules = mathStyleSources.match(/(?:^|\n)[^\n{}]*(?:\.katex-display|:global\(\.katex-display\))\s*\{[^}]*font-size:[^;}]+[;}]/g) ?? [];
const headerLinks = read("src/data/header-links.ts");
const certData = read("src/data/certificate-data.ts");
const multiplicationInput = read("src/lib/multiplication-input.ts");
const install = read("src/content/docs/install.mdx");
const versionPage = read("src/content/docs/version-history.mdx");
const about = read("src/content/docs/about.mdx");

const stepCount = home.match(/number:\s*"0[1-5]"/g)?.length ?? 0;
const visibleLines = [...home.matchAll(/visibleCode:\s*"([^"]*(?:\\"[^"]*)*)"/g)]
  .map((match) => match[1].split("\\n").length);
// Keep the generated lookup tied to the source-indexed inventory, including
// its family boundaries, so conceptual routes cannot silently change API scope.
const inventoryCounts = referenceEntries.reduce((counts, entry) => {
  counts[entry.group] = (counts[entry.group] ?? 0) + 1;
  return counts;
}, {});
const failures = [];
let checkCount = 0;
const check = (name, condition) => {
  checkCount += 1;
  if (!condition) failures.push(name);
};

check("five-node forward-only journey", (journey.match(/<circle cx=/g)?.length ?? 0) === 5 && ["Model the LPV gain problem", "Reduce rates and grid ", "Pull back and assemble coefficients", "Select a certificate", "Export, solve, recover"].every((label) => journey.includes(label)) && /math: "\\\\boldsymbol\\\\rho"/.test(journey) && /marker-end: url\(#journey-arrow\)/.test(journey) && !/feedback|journey-return|solved matrix/.test(journey));
check("accessible responsive journey SVG", /aria-labelledby="journey-title"[\s\S]*aria-describedby="journey-desc"/.test(journey) && /class="journey-desktop" aria-hidden="true"/.test(journey) && /journey-desktop svg[\s\S]*width: 100%[\s\S]*height: auto/.test(journey));
check("staggered journey cards", /journey-stage-map/.test(journey) && /li:nth-child\(odd\)[\s\S]*align-self: start/.test(journey) && /li:nth-child\(even\)[\s\S]*align-self: end/.test(journey) && /font-size: clamp/.test(journey) && !/<svg[\s\S]*<text/.test(journey) && /journey-leaders/.test(journey));
check("separate vertical enlarged journey", /<ol class="journey-mobile" aria-hidden="true">/.test(journey) && /@media \(max-width: 900px\)[\s\S]*journey-desktop \{ display: none[\s\S]*journey-mobile \{ display: grid/.test(journey));
// The link owns the two-column mobile layout because it is the card's only
// child; placing the columns on the list item collapses the link to 2.25rem.
check("mobile journey cards retain readable link width", /@media \(max-width: 900px\)[\s\S]*\.journey-mobile li\s*\{[^}]*display:\s*block/.test(journey) && /\.journey-mobile a\s*\{[^}]*grid-template-columns:\s*2\.25rem minmax\(0,\s*1fr\)/.test(journey));
check("five welcome stages and required mathematics", stepCount === 5 && ["Model an LPV induced-L2-gain problem", "Reduce the rate box and grid ", "titleMath: \"\\\\boldsymbol\\\\rho\"", "Pull back, differentiate, and assemble coefficients", "Select a finite certificate", "Export, solve, and recover the decision matrix"].every((label) => home.includes(label)) && ["\\\\dot x=A(\\\\boldsymbol\\\\rho)x", "\\\\boldsymbol\\\\nu=\\\\dot{\\\\boldsymbol\\\\rho}", "\\\\mathcal H_{\\\\mathbf c}", "\\\\boldsymbol\\\\alpha=\\\\phi_{\\\\mathbf c}", "S^{(\\\\mathbf c)}", "toYalmip", "optimize", "diagnostics.problem == 0", "value(P)"].every((fragment) => home.includes(fragment)));
check("welcome states the complete bounded-real DPD-LMI", ["P(\\\\boldsymbol\\\\rho)\\\\succ0", "\\\\dot P+\\\\operatorname{He}(PA)", "B^{\\\\mathsf T}P", "-\\\\gamma I", "D^{\\\\mathsf T}", "\\\\prec0"].every((fragment) => home.includes(fragment)));
check("static multiplication evidence", /Bernstein \[4, 2\][\s\S]*Bernstein \[0\.5, 3\][\s\S]*Bernstein \[2, 6\.5, 6\]/.test(multiply));
check("separated cell storage evidence", /physical grid[\s\S]*shared interface[\s\S]*global controls[\s\S]*cell-local leaves/.test(storage) && /LocalValues[\s\S]*i1[\s\S]*i2/.test(storage) && /\[0,0\]/.test(storage));
check("accessible full examples", /<details>[\s\S]*<summary>/.test(disclosure) && visibleLines.length === 4 && visibleLines.every((count) => count <= 2));
check("reference multiplication adoption", [coefficientAlgebra, pdmatAlgebra, pdvarAlgebra].every((source) => /MultiplicationDiagram/.test(source)));
check("reference storage adoption", [pdmatCtor, pdbaseStorage, griddingMath].every((source) => /CellStorageDiagram/.test(source)));
check("parameter curve static adoption", /series[\s\S]*marker[\s\S]*role="img"/.test(parameterCurve) && /ParameterCurveDiagram/.test(pdmatPlot));
check("matrix glyph structural adoption", /before[\s\S]*after[\s\S]*matrix-glyph/.test(matrixGlyph) && [pdmatStructure, pdvarStructure].every((source) => /MatrixGlyphDiagram/.test(source)));
check("pdvar decision evidence adoption", /decision-handles/.test(pdvarCtor) && /value-evidence/.test(pdvarValue) && /coefficient-row-map/.test(pdvarTable));
check("dedicated rhodiff detail reuse", /lower\/upper tensor order[\s\S]*decision degree/.test(rhodiff) && [pdvarDiff, pdvarTable, rateInterfaceMath, coefficientAlgebra].every((source) => /RhodiffDiagram/.test(source)));
check("shared certificate detail navigation", [pdlmiCtor, pdlmiPolya, pdlmiPutinar, pdlmiSparseFullbox, pdlmiFullbox].every((source) => /CertificateNavigation/.test(source) && /showSections=\{false\}/.test(source)) && [[pdlmiCtor, "direct"], [pdlmiPolya, "polya"], [pdlmiPutinar, "putinar"], [pdlmiSparseFullbox, "sparsefullbox"], [pdlmiFullbox, "fullbox"]].every(([source, selected]) => new RegExp(`selected="${selected}"`).test(source)) && [directPolyaMath, markovPutinarMath, sparseFullboxMath].every((source) => /CertificateSpectrum/.test(source)) && ["direct", "polya", "putinar", "sparsefullbox", "fullbox"].every((key) => certData.includes(`key: "${key}"`)));
check("open YALMIP constraint composition", /coefficient-to-constraint[\s\S]*toYalmip[\s\S]*YALMIP constraints/.test(constraintAssembly) && /ConstraintAssemblyDiagram/.test(pdlmiYalmip));

check("official React islands", /@astrojs\/react/.test(packageJson) && /import react from "@astrojs\/react"/.test(astroConfig) && /react\(\)/.test(astroConfig) && /CellStorageExplorer client:load/.test(home) && /client:visible/.test(pdmatEval) && /client:visible/.test(chooserWrapper));
check("accessible mathematical explorers", [rateExplorer, elevationExplorer, tensorExplorer].every((source) => /role="alert"/.test(source) && /aria-live="polite"/.test(source)) && /RateVertexExplorer client:visible/.test(pdvarDiff) && /DegreeElevationExplorer client:visible/.test(coefficientAlgebra) && /TensorTraversalExplorer client:visible/.test(griddingMath) && /CertificateChooser/.test(sosMath));
check("interactive A hypercube storage", /aria-pressed/.test(cellExplorer) && /ArrowLeft[\s\S]*ArrowRight[\s\S]*ArrowUp[\s\S]*ArrowDown/.test(cellExplorer) && /c1: 1[\s\S]*c1: 2/.test(cellExplorer) && /A\.LocalValues/.test(cellExplorer) && /\[3 1; 1 3\]/.test(cellExplorer) && /\[7\/4 1\/8; 1\/8 2\]/.test(cellExplorer));
check("storage selection uses HTML labels and inline TeX values", cellExplorer.includes("<strong>Selected hypercube:</strong>") && cellExplorer.includes("renderInlineMath(`c=(${cell.c1},1)`)") && cellExplorer.includes("<strong>Physical domain:</strong>") && cellExplorer.includes("renderInlineMath(cell.domainTex)") && (cellExplorer.match(/domainTex: "\\\\rho_1\\\\in\[/g)?.length ?? 0) === 2);
check("complete bordered coefficient cells", /\.cell-coeffs\s*>\s*span\s*\{[^}]*border:\s*1px solid var\(--diagram-border\)[^}]*border-block-start:\s*2px solid var\(--sl-color-accent\)[^}]*border-radius:\s*8px/.test(manualCss));
check("bounded mobile storage connector", /@media \(max-width: 700px\)[\s\S]*\.cell-storage-connector\s*\{[^}]*width:\s*auto[^}]*height:\s*3\.2rem[^}]*grid-template-rows:\s*auto 1fr/.test(manualCss) && /\.cell-storage-connector i\s*\{[^}]*width:\s*0[^}]*height:\s*1\.7rem[^}]*border-block-start:\s*0[^}]*border-inline-start:[^}]*transform:\s*none/.test(manualCss) && /\.cell-storage-connector i::after\s*\{[^}]*inset-block-end:\s*0[^}]*border-block-end:\s*2px solid/.test(manualCss) && !/\.cell-storage-connector i\s*\{\s*transform:\s*rotate\(90deg\)/.test(manualCss));
check("interactive multiplication", /parseCoefficients/.test(multiplicationInput) && /useDeferredValue/.test(multiplyExplorer) && /role="alert"/.test(multiplyExplorer) && /BernsteinPlot/.test(multiplyExplorer));
check("independent multiplication errors", /errors\.left/.test(multiplyExplorer) && /errors\.right/.test(multiplyExplorer) && /aria-invalid/.test(multiplyExplorer));
check("bounded multiplication input", /maxMultiplicationCoefficients\s*=\s*256/.test(multiplicationInput) && /Use at most \$\{maxMultiplicationCoefficients\} coefficients per factor/.test(multiplicationInput) && /maxMultiplicationCoefficients/.test(multiplyExplorer));
check("actual multiplication contributions", /bernsteinContributionsAt/.test(multiplyExplorer) && /term\.weight/.test(multiplyExplorer) && /term\.value/.test(multiplyExplorer) && /<details[\s\S]*<summary>Show/.test(multiplyExplorer) && !/sum over i \+ j/.test(multiplyExplorer));
check("interactive cubic evaluate", /1 \+ 3ρ − 6ρ² \+ 4ρ³/.test(evaluateExplorer) && /requestAnimationFrame/.test(evaluateExplorer) && /querySelector\("svg"\)/.test(evaluateExplorer) && /clientXToUnit/.test(evaluateExplorer) && /role="slider"/.test(evaluateExplorer) && /EvaluateExplorer[\s\S]*client:visible/.test(pdmatEval));
check("quadratic-to-linear differentiation detail retained off welcome", /\[0\.8, 2\.2, 1\.4\][\s\S]*\[1\.4, −0\.2, 1\.8\][\s\S]*rhodiff[\s\S]*\[5\.6, −3\.2\][\s\S]*\[−6\.4, 8\]/.test(diffStorage) && !/DifferentiationStorage/.test(home));
check("certificate flow tabs on welcome and interactive reference overview", /CertificateFlow/.test(home) && /CertificateFlow/.test(certificateFlow) && /Positive target/.test(certificateFlowTabs) && /S\^\{\(\\\\mathbf c\)\}\(\\\\boldsymbol\\\\alpha\)\\\\succeq0/.test(certificateFlowTabs) && !/F\^\{\(\\\\mathbf c,v\)\}/.test(certificateFlowTabs) && /role="tablist"/.test(certificateFlowTabs) && /role="tabpanel"/.test(certificateFlowTabs) && /ArrowLeft[\s\S]*ArrowRight[\s\S]*Home[\s\S]*End/.test(certificateFlowTabs) && /Open the \{option\.label\} reference/.test(certificateFlowTabs) && /CertificateChooser/.test(pdlmiOverview) && /useState\(0\)/.test(chooser) && /role="tablist"/.test(chooser) && /selected\.toYalmip\(\)/.test(chooser));
check("Pólya card presents transform before coefficient test and index set", certData.includes('cardFormula: "\\\\widetilde S^{(\\\\mathbf c)}(\\\\boldsymbol\\\\alpha)=S^{(\\\\mathbf c)}(\\\\boldsymbol\\\\alpha)\\\\prod_{s=1}^{\\\\ell}') && certificateFlow.includes('polya: "\\\\begin{gathered}\\\\widetilde C') && certificateFlow.indexOf("\\\\widetilde C") < certificateFlow.indexOf("\\\\mathcal I_{M+d}=") && certificateFlowTabs.indexOf('className="certificate-flow-panel__formula"') < certificateFlowTabs.indexOf('className="certificate-flow-panel__notation"') && certificateFlowTabs.indexOf("option.formula") < certificateFlowTabs.indexOf("option.notation"));
check("equal-height compact certificate tabs and readout", /grid-auto-rows:\s*1fr/.test(manualCss) && /block-size:\s*5rem/.test(manualCss) && /\.certificate-tabs button strong,\s*\.certificate-flow-tabs button strong\s*\{[^}]*overflow-wrap:\s*anywhere[^}]*line-height:\s*1\.15/.test(manualCss) && /certificate-shape-readout p\s*\{[^}]*min-block-size:\s*4\.25rem[^}]*margin:\s*0/.test(manualCss) && !/certificate-default|>Default</.test(chooser) && !/showDefault|default-marker/.test(certificate));
check("shared certificate navigation contract", ["direct", "polya", "putinar", "sparse-full-box", "full-box"].every((anchor) => certData.includes(`anchor: "${anchor}"`)) && ["L", "L.applyPolya(d)", "L.applyPutinar()", "L.applySparseFullBoxPreorder()", "L.applyFullBoxPreorder()"].every((command) => certData.includes(`command: "${command}"`)) && /CertificateNavigation/.test(pdlmiOverview) && /showSections \? `#\$\{item\.anchor\}`/.test(certificateNavigation) && /item\.detailRoute/.test(certificateNavigation) && /aria-current=\{isSelected \? "page"/.test(certificateNavigation));
check("five certificate tabs and sparse endpoint controls", /repeat\(5, minmax\(0, 1fr\)\)/.test(manualCss) && /bandWidth/.test(chooser) && /effectiveSelector/.test(chooser) && /ArrowLeft[\s\S]*ArrowRight[\s\S]*Home[\s\S]*End/.test(chooser) && /width one[\s\S]*Direct/i.test(pdlmiSparseFullbox) && /(?:r|SparseFullBoxOrder) \+ 1[\s\S]*FullBox/i.test(pdlmiSparseFullbox) && ["Direct", "Pólya", "Putinar", "SparseFullBox", "FullBox"].every((label) => exportSolve.includes(`<span>${label}</span>`)));
check("header destinations", /Header: "\.\/src\/components\/Header\.astro"/.test(astroConfig) && ["Manual", "Download", "Examples", "About me"].every((label) => headerLinks.includes(`label: "${label}"`)) && /site-header__brand[\s\S]*site-header__search[\s\S]*site-header__links[\s\S]*site-header__controls/.test(header));
check("responsive header destinations", /<details[^>]*class="site-header__more/.test(header) && /<summary/.test(header) && /@media \(min-width: 72rem\)[\s\S]*site-header__more[\s\S]*display: none/.test(header));
check("global KaTeX formula type scale", displaySizeRules.length === 1 && /font-size:\s*1\.5em/.test(displaySizeRules[0]) && /\.katex\s*\{[^}]*font-size:\s*1em/.test(manualCss));
// One script rule prevents local figure fixes from drifting apart as formulas evolve.
check("single legible KaTeX script scale", /--katex-script-scale:\s*0\.78em/.test(manualCss) && /--katex-script-min:\s*0\.7rem/.test(manualCss) && /\.katex \.msupsub \.mtight\s*\{[^}]*font-size:\s*max\(var\(--katex-script-scale\),\s*var\(--katex-script-min\)\)\s*!important/.test(manualCss) && (mathStyleSources.match(/\.mtight\s*\{/g)?.length ?? 0) === 1);
check("compact storage equations use semantic TeX sizing", /import \{ renderDisplayMath, renderInlineMath \}/.test(cellExplorer) && (cellExplorer.match(/renderDisplayMath\(/g)?.length ?? 0) === 2 && (cellExplorer.match(/\\\\footnotesize/g)?.length ?? 0) === 2 && /"\\\\footnotesize A\(\\\\rho_1,/.test(home) && !/cell-summary__basis \.katex\s*\{/.test(manualCss) && !/cell-bernstein-formula \.katex\s*\{/.test(manualCss) && !/cell-storage-compact \.cell-explorer \.katex\s*\{/.test(manualCss));
check("external plot legends", /plot-legend[\s\S]*<svg/.test(component("BernsteinPlot.tsx")) && /plot-legend[\s\S]*<svg/.test(parameterCurve) && !/<text[^>]*>\{item\.label\}/.test(parameterCurve) && !/<text[^>]*>\{marker\.label\}/.test(parameterCurve) && /<div class="curve-legend"[\s\S]*<\/div>[\s\S]*<svg/.test(multiply) && !/curve-labels/.test(multiply));
check("aligned multiplication header and legend", /multiplication-formulas[\s\S]*grid-template-columns: minmax\(0, 0\.85fr\) minmax\(0, 1\.15fr\)/.test(multiply) && /multiplication-formulas > div[^{]*\{[^}]*margin: 0/.test(multiply) && /curve-legend[\s\S]*grid-template-columns: repeat\(3, minmax\(0, 1fr\)\)[\s\S]*align-items: stretch/.test(multiply) && /curve-copy[\s\S]*height: 100%[\s\S]*min-height: 4\.4rem/.test(multiply) && /@media \(max-width: 560px\)[\s\S]*multiplication-formulas,[\s\S]*curve-legend[\s\S]*grid-template-columns: 1fr/.test(multiply));
check("canonical notation", /\\rho_s\^\{\(j\)\}/.test(griddingMath) && /\\mathbf c=\(c_1,\\ldots,c_\\ell\)/.test(griddingMath) && /C\^\{\(\\mathbf c\)\}\[\\mathbf i\]/.test(coefficientAlgebra) && /B_i\^M/.test(bernsteinMath) && /\\boldsymbol\\nu\(t\)=\\dot\{\\boldsymbol\\rho\}\(t\)/.test(modelMath) && /\\mathcal P/.test(modelMath) && /\\mathcal R/.test(modelMath));
check("canonical axis node counts", [griddingMath, bernsteinMath].every((source) => /k_s/.test(source) && !/N_(?:\d|\\ell|r)/.test(source)));
check("unambiguous tensor and derivative notation", /h_s\^\{\(\\mathbf c\)\}/.test(griddingMath) && /\\phi_\{\\mathbf c\}/.test(griddingMath) && /\\frac\{1\}\{h_s\^\{\(\\mathbf c\)\}\}/.test(rateInterfaceMath) && !/width \$h=/.test(griddingMath));
check("canonical cell-local function notation", !/P_c|Q_c|dP_c/.test(bernsteinMath + coefficientAlgebra) && /P\^\{\(c\)\}/.test(pdvarCtor) && !/P_\{?[0-9i]/.test(pdvarCtor) && /P\^\{\(c\)\}\[i\]/.test(pdvarCtor));
check("dimension-aware Putinar contract", [certData, pdlmiOverview, pdlmiPutinar, pdlmiCtor, sosMath, markovPutinarMath].every((source) => /Markov[–-]Luk[aá]cs/.test(source) && /floor|\\lfloor/.test(source) && /two or more|\\ell\\ge2|\\ell\s*\\ge\s*2/.test(source) && /ceil|\\lceil/.test(source)));
check("cell-indexed DPD-LMI workflow", ["\\\\mathcal H_{\\\\mathbf c}", "\\\\boldsymbol\\\\alpha=\\\\phi_{\\\\mathbf c}", "S^{(\\\\mathbf c)}", "C^{(\\\\mathbf c)}[\\\\mathbf i]", "selected.toYalmip()"].every((fragment) => home.includes(fragment)) && /exact scheduling-rate vertices/.test(home) && !/F\^\{\(\\\\mathbf c,v\)\}|\\\\mathcal V|m\+p/.test(home + certData + certificateFlow));
check("welcome begins from the LPV induced-L2-gain spine", /\\\\dot x=A\(\\\\boldsymbol\\\\rho\)x\+B\(\\\\boldsymbol\\\\rho\)w/.test(home) && /\\\\lVert z\\\\rVert_2<\\\\gamma\\\\lVert w\\\\rVert_2/.test(home) && /x\(t\).*plant state/.test(home) && !/F_i\(\\\\rho\)x_i\(\\\\rho\)/.test(home));
check("new mathematics page contract", detailedMathPages.every((source) => /^---[\s\S]*title:[^\n]+[\s\S]*description:[^\n]+[\s\S]*---/.test(source) && /manual-trail/.test(source) && /^## Limitations$/m.test(source) && /^## Further Reading$/m.test(source) && /^## See Also$/m.test(source) && /\[(?:Previous|Next):/.test(source)));
check("legacy mathematics routes and anchors", [bernsteinMath, griddingMath, sosMath].every((source) => /manual-trail/.test(source) && /^## Limitations$/m.test(source) && /^## Further Reading$/m.test(source) && /^## See Also$/m.test(source)) && /id="polya-type-coefficient-relaxation"/.test(sosMath) && /id="worked-full-box-example-two-parameters-degree-three"/.test(sosMath) && /id="sparse-full-box-tensor-windows"/.test(sosMath) && /id="fixed-order-full-box-preordering"/.test(bernsteinMath));
check("canonical certificate names and symbols", !/Sparse Full Box|Full Box/.test(allSource) && /band-limited Gram support/.test(sparseFullboxMath) && /full-box preordering/.test(sparseFullboxMath) && !/F\^\{\(\\\\mathbf c,v\)\}|\\\\mathcal I_\{m\+p\}|applyPolya\(p\)/.test(certData + certificateFlow + certificateFlowTabs + sosMath + directPolyaMath));
check("source-indexed API inventory remains 178", referenceEntries.length === 178 && inventoryCounts["pdbase-backend"] === 55 && inventoryCounts.pdmat === 56 && inventoryCounts.pdvar === 54 && inventoryCounts.pdlmi === 7 && inventoryCounts["shared-helpers"] === 6);
check("welcome A example is wired to both cells", /grid = \{\[0 0\.5 1\], \[0 1\]\}/.test(home) && /A = pdmat/.test(home) && /A\.LocalValues\{c1\}\{1\}/.test(home));
check("stacked mobile display math", home.includes('number: "01"') && home.includes('number: "05"') && (home.match(/math: \[/g)?.length ?? 0) >= 3 && /\.math-strip\s*\{[^}]*min-width:\s*0/.test(home) && /item\.formula\.map\(renderDisplayMath\)/.test(chooserWrapper) && /option\.mathHtml\.map/.test(chooser) && /key:\s*"putinar"[\s\S]*?formula:\s*\[/.test(certData) && !/key:\s*"putinar"[^\n]*\\qquad/.test(certData));
check("intrinsic certificate KaTeX width", /\.certificate-formula \.katex-display\s*\{[^}]*margin:\s*0 !important[^}]*text-align:\s*start !important/.test(manualCss));
check("generated install and public maintainer identity", /versionInfo\.current/.test(install) && !/v0\.3\.3/.test(install) && /Yicheng Xu/.test(about) && /https:\/\/www\.ethanyxu\.com\//.test(about) && /portfolio-cta/.test(about) && /TheBigoranger/.test(about));
check("positive pdlmi implemented-behavior heading", !/^## Current Boundary\r?$/mi.test(pdlmiOverview) && /^## Implemented Behavior\r?$/mi.test(pdlmiOverview) && !/Reference Page Shape/.test(page("index.md")));
const plotHash = (file) => crypto.createHash("sha256").update(fs.readFileSync(path.join(root, "public/plots", file))).digest("hex").toUpperCase();
check("accepted v0.4.2 plots synchronized", plotHash("pdmat-plot-1d.png") === "C03C2833EDE515301880BC163CEDCD6E64F6937F287E15294FAC2E1A8C11A6B9" && plotHash("pdmat-plot-2d.png") === "109E2D5CEE899EAFC537FB06225EE2FFD6A38A6DA9AE41304157D1041FAD049B" && plotHash("pdmat-plot-2d-matrix.png") === "3832AD479EECB5484FB7F9E0B2A874BD91DF047B2F3579AC6FDEF9EE1A840D54" && ["two-by-one two-parameter", "FaceAlpha=0.62", "eastoutside", "crossingError", "ordering", "handleCount", "     2"].every((fragment) => pdmatPlot.includes(fragment)) && !fs.existsSync(path.join(root, "public/plots/pdmat-plot-3d-slice.png")));
check("three-level mathematics and nested API sidebars", [/label: "Modeling And Analysis"[\s\S]*DPD-LMI And LPV L2-Gain Model[\s\S]*Rate-Box Reduction/, /label: "Coordinates And Bernstein"[\s\S]*Gridding And Local Coordinates[\s\S]*Coefficient Algebra/, /label: "Finite Certificates"[\s\S]*Certificate Map And Selection Guide[\s\S]*Direct And Pólya[\s\S]*Markov–Lukács And Putinar[\s\S]*SparseFullBox And FullBox/, /label: "pdmat"[\s\S]*label: "Matrix Operations"[\s\S]*documents\/reference\/pdmat\/matrix-operations/, /label: "pdvar"[\s\S]*label: "Matrix Operations"[\s\S]*documents\/reference\/pdvar\/matrix-operations/, /label: "pdlmi"[\s\S]*label: "Certificates"[\s\S]*label: "SparseFullBox"[\s\S]*label: "FullBox"/].every((pattern) => pattern.test(astroConfig)));
check("grouped lookup with direct single-symbol links", /ReferenceCategoryHub/.test(documentsHub) && /<table>/.test(referenceCategoryHub) && (referenceCategoryHub.match(/<th scope="col">/g)?.length ?? 0) === 4 && /<th scope="row">\{group\.label\}<\/th>/.test(referenceCategoryHub) && /referenceGroups\.map/.test(referenceCategoryHub) && /referenceEntries\.filter/.test(referenceCategoryHub) && /table-layout:\s*fixed/.test(referenceCategoryHub) && /data-label="Description"/.test(referenceCategoryHub) && /@media \(max-width: 620px\)[\s\S]*tbody tr\s*\{[^}]*display:\s*grid/.test(referenceCategoryHub) && !/overflow-x:\s*auto|tabindex=/.test(referenceCategoryHub) && (generatedReferenceIndex.match(/<details class="reference-index__group"/g)?.length ?? 0) === 5 && ["pdmat", "pdvar", "pdlmi", "pdbase-backend", "shared-helpers"].every((id) => generatedReferenceIndex.includes(`id="${id}"`)) && /referenceGroups\.map\(groupSection\)/.test(referenceGenerator) && /referenceEntries\.filter\(\(entry\) => entry\.group === group\.id\)/.test(referenceGenerator) && /reference-index__direct-symbol/.test(referenceGenerator) && /reference-index__symbols/.test(referenceGenerator) && /singleEntry/.test(referenceGenerator) && /source data lives in `src\/data\/reference-index\.js`/.test(generatedReferenceIndex) && !/<details class="reference-index__group"[^>]*\sopen(?:\s|>)/.test(generatedReferenceIndex) && !/reference-index__jump|jumpNav\(/.test(referenceGenerator + generatedReferenceIndex) && !/<details class="reference-index__family" open>/.test(referenceGenerator + generatedReferenceIndex) && !/\$\{entry\.name\}\s*—\s*\$\{anchor\}/.test(referenceGenerator));
check("aligned reference family rows", /\.reference-index__family-row\s*\{[^}]*align-items:\s*start/.test(manualCss) && /\.reference-index__family-heading\s*\{[^}]*align-items:\s*start/.test(manualCss) && /\.reference-index__family-content\s*\{[^}]*margin-block-start:\s*0/.test(manualCss) && !/\.reference-index__(?:family-row|family-heading|family-content)\s*\{[^}]*(?:^|[;{])\s*(?:block-size|height|transform)\s*:/m.test(manualCss));
check("reference lookup keeps readable mobile columns", /@media \(max-width: 620px\)[\s\S]*\.reference-index__group-summary\s*\{[^}]*grid-template-columns:\s*0\.55rem minmax\(0,\s*1fr\)/.test(manualCss) && /@media \(max-width: 620px\)[\s\S]*\.reference-index__direct-meta\s*\{[^}]*grid-template-columns:\s*minmax\(0,\s*1fr\)/.test(manualCss) && !/\.reference-index\s+summary\s*\{[^}]*display:\s*block/.test(manualCss) && !/\.reference-index__family\s*>\s*summary/.test(manualCss));
check("Bernstein backend utilities nested under pdbase", /label: "pdbase"[\s\S]*items: \[[\s\S]*Bernstein Backend Utilities[\s\S]*documents\/reference\/bernstein-utilities/.test(astroConfig) && !/\{ label: "Bernstein Utilities", slug: "documents\/reference\/bernstein-utilities" \}/.test(astroConfig));
check("split matrix-operation routes", [pdmatAlgebra, pdmatStructure, pdmatIndexing, pdvarAlgebra, pdvarStructure, pdvarIndexing].every((source) => /manual-trail/.test(source)) && ["plus", "mtimes", "transpose", "cat", "subsref", "isequal"].every((name) => pdmatOps.includes(`id="pdmat-${name}"`) && pdvarOps.includes(`id="pdvar-${name}"`)));
check("split operation reference depth", [pdmatAlgebra, pdvarAlgebra].every((source) => /ExampleDisclosure/.test(source) && /MultiplicationDiagram/.test(source) && /MatrixGlyphDiagram/.test(source) && /\\binom/.test(source) && /```text/.test(source)) && [pdmatStructure, pdvarStructure].every((source) => (source.match(/MatrixGlyphDiagram/g)?.length ?? 0) >= 5 && (source.match(/```matlab/g)?.length ?? 0) >= 4 && (source.match(/```text/g)?.length ?? 0) >= 4) && [pdmatIndexing, pdvarIndexing].every((source) => /MatrixGlyphDiagram/.test(source) && /```matlab/.test(source) && /```text/.test(source) && /isequal/.test(source)));
check("six shared helpers and protected pdbase utilities documented", ["cellget", "chk", "combrows", "iszero", "mkgrid", "mknest"].every((name) => sharedHelpers.includes(`id="helper-${name}"`)) && !["berntbl", "mapvals", "matsubs"].some((name) => sharedHelpers.includes(`id="helper-${name}"`)) && ["bernTbl", "mapVals", "matSubs"].every((name) => bernsteinUtilities.includes(name)) && /protected|backend/i.test(bernsteinUtilities));
check("comparison and equality contract", /complete original residual/.test(pdvarCompare) && /inclusive tolerance `1e-10`/.test(pdvarCompare) && /pdlmi:ElementwiseInequality/.test(pdvarCompare) && /column-major/.test(pdvarCompare) && /pdvar-comparison-eq/.test(pdvarCompare) && /ordinary operand compared with a derivative operand/.test(pdvarCompare) && /itself mixes ordinary and derivative row kinds across physical cells/.test(pdvarCompare) && /pdvar:MixedGrid/.test(pdvarCompare) && /pdvar:InvalidSubtraction/.test(pdvarCompare) && /pdlmi:UnsupportedEqualityCertificate/.test(pdvarCompare) && /V == V/.test(pdvarCompare) && /isequal/.test(pdvarCompare));
check("centered GitHub header control", /site-header__controls \{[^}]*border-inline-start:[^}]*padding-inline-start/.test(header) && /site-header__social \{[^}]*display: flex[^}]*width: 2\.25rem[^}]*height: 2\.25rem[^}]*align-items: center[^}]*justify-content: center/.test(header) && /site-header__social :global\(a\)[^}]*width: 2\.25rem[^}]*height: 2\.25rem/.test(header) && !/site-header__social::after/.test(header));
check("centered header search", /\.site-header \{[^}]*position:\s*relative/.test(header) && /site-header__search \{[^}]*position:\s*absolute[^}]*inset-inline-start:\s*50%[^}]*transform:\s*translateX\(-50%\)/.test(header) && /site-header__search :global\(site-search\)\s*\{[^}]*justify-content:\s*center/.test(header) && /site-header__brand \{[^}]*flex:\s*none/.test(header));
check("v1.1.2 documentation and v1.1.0 Release metadata", /current:\s*"v1\.1\.2"/.test(versionData) && /Documentation v1\.1\.2/.test(pdlmiOverview) && (versionHistory.match(/version:\s*"v/g)?.length ?? 0) === 7 && ["v0.1.0", "v0.2.12", "v0.3.6", "v0.4.7", "v1.0.0", "v1.1.0", "v1.1.2"].every((version) => versionHistory.includes(`version: "${version}"`)) && /version:\s*"v1\.1\.2"[\s\S]*status:\s*"current documentation snapshot"/.test(versionHistory) && /version:\s*"v1\.1\.0"[\s\S]*status:\s*"latest GitHub Release"/.test(versionHistory) && /No v1\.1\.2 tag or GitHub Release exists/.test(versionPage) && /Latest GitHub Release \(v1\.1\.0\)/.test(install) && /v1\.1\.0 release gate completed 280 of 280 tests/.test(install) && /version:\s*"v1\.0\.0"[\s\S]*date:\s*"2026-07-19"[\s\S]*6d19619/.test(versionHistory));
check("root-only installer and native transcript output", /only that repository root[\s\S]*does not call `genpath`[\s\S]*Exact-path idempotence/.test(install) && !/fprintf\s*\(/.test(allSource));
check("welcome manual cards removed", !/Manual entrances|manualLinks|manual-entry-list/.test(home) && /Open manual/.test(home));
check("legacy welcome workflow absent", !/WorkflowStepDiagram/.test(home));

if (failures.length > 0) {
  console.error("Visual contract failed:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(`Visual contract passed (${checkCount} checks).`);
