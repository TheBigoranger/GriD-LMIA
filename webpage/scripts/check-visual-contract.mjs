import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { referenceEntries } from "../src/data/reference-index.js";
import { renderMath } from "../src/lib/katex-renderer.js";

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
const firstHomeStep = home.match(/number: "01",[\s\S]*?(?=\n\s*\{\s*\n\s*number: "02")/)?.[0] ?? "";
const secondHomeStep = home.match(/number: "02",[\s\S]*?(?=\n\s*\{\s*\n\s*number: "03")/)?.[0] ?? "";
const thirdHomeStep = home.match(/number: "03",[\s\S]*?(?=\n\s*\{\s*\n\s*number: "04")/)?.[0] ?? "";
const fourthHomeStep = home.match(/number: "04",[\s\S]*?(?=\n\s*\{\s*\n\s*number: "05")/)?.[0] ?? "";
const fifthHomeStep = home.match(/number: "05",[\s\S]*?(?=\n\s*\];)/)?.[0] ?? "";
const journey = component("JourneyCurve.astro");
const gridExplorer = component("GridPartitionExplorer.tsx");
const gridPartition = read("src/lib/grid-partition.ts");
const storage = component("CellStorageDiagram.astro");
const multiply = component("MultiplicationDiagram.astro");
const disclosure = component("ExampleDisclosure.astro");
const rhodiff = component("RhodiffDiagram.astro");
const certificate = component("CertificateSpectrum.astro");
const certificateFlow = component("CertificateFlow.astro");
const sparseFlowNotation = certificateFlow.match(/sparsefullbox:\s*"[^"\n]*"/)?.[0] ?? "";
const certificateFlowTabs = component("CertificateFlow.tsx");
const parameterCurve = component("ParameterCurveDiagram.astro");
const matrixGlyph = component("MatrixGlyphDiagram.astro");
const constraintAssembly = component("ConstraintAssemblyDiagram.astro");
const exportSolve = component("ExportSolveFlow.astro");
const cellExplorer = component("CellStorageExplorer.tsx");
const cellBasisExplorer = component("CellBernsteinExpressionExplorer.tsx");
const cellBasisWrapper = component("CellBernsteinExpressionExplorer.astro");
const cellBernstein = read("src/lib/cell-bernstein.ts");
const multiplyExplorer = component("MultiplicationExplorer.tsx");
const additionExplorer = component("AdditionExplorer.tsx");
const evaluateExplorer = component("EvaluateExplorer.tsx");
const diffStorage = component("DifferentiationStorage.astro");
const chooser = component("CertificateChooser.tsx");
const chooserWrapper = component("CertificateChooser.astro");
const rateExplorer = component("RateVertexExplorer.tsx");
const elevationExplorer = component("DegreeElevationExplorer.tsx");
const elevationPlanExplorer = component("ElevationPlanExplorer.tsx");
const productPlanExplorer = component("ProductPlanExplorer.tsx");
const gramPlanExplorer = component("GramAssemblyExplorer.tsx");
const assemblyPlans = read("src/lib/assembly-plans.ts");
const additionInput = read("src/lib/addition-input.ts");
const tensorExplorer = component("TensorTraversalExplorer.tsx");
const certificateNavigation = component("CertificateNavigation.astro");
const header = component("Header.astro");
const referenceCategoryHub = component("ReferenceCategoryHub.astro");
const diagnosticIndex = component("DiagnosticIndex.astro");
const documentsHub = page("index.mdx");
const generatedReferenceIndex = page("reference-index.mdx");
const referenceGenerator = read("scripts/generate-reference-index.mjs");
const referenceIndex = read("src/data/reference-index.js");

const pdmatCtor = page("reference/pdmat/constructor.mdx");
const pdmatStorage = page("reference/pdmat/storage-and-elevation.mdx");
const pdmatEval = page("reference/pdmat/evaluate.mdx");
const pdmatPlot = page("reference/pdmat/plot.mdx");
const pdmatElevate = page("reference/pdmat/elevate.mdx");
const pdmatOps = page("reference/pdmat/matrix-operations.mdx");
const pdmatAlgebra = page("reference/pdmat/algebra.mdx");
const pdmatStructure = page("reference/pdmat/structural-operations.mdx");
const pdmatIndexing = page("reference/pdmat/indexing-and-inspection.mdx");
const pdvarCtor = page("reference/pdvar/constructor.mdx");
const pdvarStorage = page("reference/pdvar/storage-and-evaluation.mdx");
const pdvarValue = page("reference/pdvar/value.mdx");
const pdvarTable = page("reference/pdvar/berntable.mdx");
const pdvarCompare = page("reference/pdvar/comparisons.mdx");
const pdvarOps = page("reference/pdvar/matrix-operations.mdx");
const pdvarAlgebra = page("reference/pdvar/algebra.mdx");
const pdvarStructure = page("reference/pdvar/structural-operations.mdx");
const pdvarIndexing = page("reference/pdvar/indexing-and-inspection.mdx");
const pdvarDiff = page("reference/pdvar/rhodiff.mdx");
const pdbaseStorage = page("reference/pdbase/storage-inspection.mdx");
const bernsteinMath = page("math/bernstein-polynomial.mdx");
const notationMath = page("math/notation.mdx");
const griddingMath = page("math/gridding-and-degree.mdx");
const sosMath = page("math/sos-certificates.mdx");
const modelMath = page("math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain.mdx");
const rateInterfaceMath = page("math/modeling-and-analysis/rate-box-and-interface-analysis.mdx");
const coefficientAlgebra = page("math/coordinates-and-bernstein/coefficient-algebra.mdx");
const directPolyaMath = page("math/finite-certificates/direct-and-polya.mdx");
const markovPutinarMath = page("math/finite-certificates/markov-lukacs-and-putinar.mdx");
const sparsePutinarMath = page("math/finite-certificates/sparseputinar.mdx");
const sparseFullboxMath = page("math/finite-certificates/sparsefullbox-and-fullbox.mdx");
const detailedMathPages = [
  modelMath,
  rateInterfaceMath,
  coefficientAlgebra,
  directPolyaMath,
  markovPutinarMath,
  sparsePutinarMath,
  sparseFullboxMath,
];
const pdlmiOverview = page("reference/pdlmi/index.mdx");
const pdlmiCtor = page("reference/pdlmi/constructor.mdx");
const pdlmiPolya = page("reference/pdlmi/usepolya.mdx");
const pdlmiPutinar = page("reference/pdlmi/useputinar.mdx");
const pdlmiSparsePutinar = page("reference/pdlmi/usespput.mdx");
const pdlmiSparseFullbox = page("reference/pdlmi/usespbox.mdx");
const pdlmiFullbox = page("reference/pdlmi/usefullbox.mdx");
const pdlmiYalmip = page("reference/pdlmi/toyalmip.mdx");
const sharedHelpers = page("reference/shared-helpers.md");
const bernsteinUtilities = page("reference/bernstein-utilities.md");
const versionHistory = read("src/data/version-history.js");
const versionData = read("src/data/version.js");

const astroConfig = read("astro.config.mjs");
const packageJson = read("package.json");
const packageLock = read("package-lock.json");
const manualCss = read("src/styles/manual.css");
const katexReact = component("RenderedMath.tsx");
const katexAstro = component("KaTeXMath.astro");
const katexRenderer = read("src/lib/katex-renderer.js");
const katexOptions = read("src/lib/katex-options.js");
const geometryCheck = read("scripts/check-rendered-geometry.mjs");
const certificateSelection = read("src/content/docs/examples/certificate-selection.md");
const solverSmoke = read("src/content/docs/examples/solver-smoke.md");
const mathStyleSources = `${manualCss}\n${allSource}`;
const mathMetricRules = manualCss.match(/\.katex(?:-display)?\b[^{]*\{[^}]*(?:font-size|transform|zoom)\s*:/gis) ?? [];
const renderedFormula = renderMath(String.raw`\frac{x}{y}`, { displayMode: true });
const packageData = JSON.parse(packageJson);
const lockData = JSON.parse(packageLock);
const directDependencies = packageData.dependencies ?? {};
const lockedDependencies = lockData.packages?.[""]?.dependencies ?? {};
const katexCssImport = "katex/dist/katex.min.css";
const acceptanceViewports = [320, 390, 700, 768, 1024, 1280, 1440];
const headerLinks = read("src/data/header-links.ts");
const certData = read("src/data/certificate-data.ts");
const multiplicationInput = read("src/lib/multiplication-input.ts");
const install = read("src/content/docs/install.mdx");
const versionPage = read("src/content/docs/version-history.mdx");
const about = read("src/content/docs/about.mdx");
const sparseFullboxUserFacing = [
  certData,
  certificateFlow,
  chooser,
  documentsHub,
  bernsteinMath,
  sosMath,
  sparseFullboxMath,
  pdlmiOverview,
  pdlmiCtor,
  pdlmiSparseFullbox,
  versionHistory,
].join("\n").replace(/<span id="[^"]*"><\/span>/g, "");

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
const expectedCertificateKeys = ["direct", "polya", "putinar", "sparseputinar", "sparsefullbox", "fullbox"];
const expectedCertificateAnchors = ["direct", "polya", "putinar", "sparse-putinar", "sparse-full-box", "full-box"];
const expectedCertificateLabels = ["Direct", "Pólya", "Putinar", "SparsePutinar", "SparseFullBox", "FullBox"];
const expectedCertificateCommands = ["L", "L.usePolya(d)", "L.usePutinar()", "L.useSpPut()", "L.useSpBox()", "L.useFullBox()"];
const exactSequence = (actual, expected) => JSON.stringify(actual) === JSON.stringify(expected);
const certificateKeys = [...certData.matchAll(/\bkey: "([^"]+)"/g)].map((match) => match[1]);
// The interface union contains an anchor annotation before the six data rows.
const certificateAnchors = [...certData.matchAll(/\banchor: "([^"]+)"/g)].map((match) => match[1]).slice(-6);
const certificateLabels = [...certData.matchAll(/\blabel: "([^"]+)"/g)].map((match) => match[1]);
const certificateCommands = [...certData.matchAll(/\bcommand: "([^"]+)"/g)].map((match) => match[1]);

check("GriD-LMIA brand, expansion, repository, and base path stay synchronized", /title:\s*"GriD-LMIA Manual"/.test(astroConfig) && /base:\s*"\/GriD-LMIA"/.test(astroConfig) && /https:\/\/github\.com\/TheBigoranger\/GriD-LMIA/.test(astroConfig) && /<p class="home-wordmark">GriD-LMIA<\/p>/.test(home) && /<Term id="grid-lmia" definition\s*\/>/.test(home) && /aria-label="GriD-LMIA Manual home">GriD-LMIA<\/a>/.test(header) && packageData.name === "grid-lmia-webpage" && lockData.name === "grid-lmia-webpage" && packageData.version === "0.0.1" && lockData.version === "0.0.1");
check("five-node forward-only journey", (journey.match(/<circle cx=/g)?.length ?? 0) === 5 && ["Model the general DPD-LMI", "Partition the parameter box", "Fix a cell and use Bernstein", "Select a finite certificate", "Export, solve, validate"].every((label) => journey.includes(label)) && /general continuum <Term id="dpd-lmi"\s*\/>/.test(journey) && /exact partition of an axis-aligned parameter box/.test(journey) && /local Bernstein representation/.test(journey) && /status validation/.test(journey) && /#general-dpd-lmi-template/.test(journey) && /marker-end: url\(#journey-arrow\)/.test(journey) && !/feedback|journey-return|solved matrix|LPV induced-L2-gain model|Reduce rates and grid|Pull back and assemble coefficients/.test(journey));
check("accessible responsive journey SVG", /aria-labelledby="journey-title"[\s\S]*aria-describedby="journey-desc"/.test(journey) && /class="journey-desktop" aria-hidden="true"/.test(journey) && /journey-desktop svg[\s\S]*width: 100%[\s\S]*height: auto/.test(journey));
check("staggered journey cards", /journey-stage-map/.test(journey) && /li:nth-child\(odd\)[\s\S]*align-self: start/.test(journey) && /li:nth-child\(even\)[\s\S]*align-self: end/.test(journey) && /font-size: clamp/.test(journey) && !/<svg[\s\S]*<text/.test(journey) && /journey-leaders/.test(journey));
check("separate vertical enlarged journey", /<ol class="journey-mobile" aria-hidden="true">/.test(journey) && /@media \(max-width: 900px\)[\s\S]*journey-desktop \{ display: none[\s\S]*journey-mobile \{ display: grid/.test(journey));
// The link owns the two-column mobile layout because it is the card's only
// child; placing the columns on the list item collapses the link to 2.25rem.
check("mobile journey cards retain readable link width", /@media \(max-width: 900px\)[\s\S]*\.journey-mobile li\s*\{[^}]*display:\s*block/.test(journey) && /\.journey-mobile a\s*\{[^}]*grid-template-columns:\s*2\.25rem minmax\(0,\s*1fr\)/.test(journey));
check("five welcome stages and required mathematics", stepCount === 5 && ["Model the general DPD-LMI problem", "Partition the supported parameter box", "Fix one cell and use the Bernstein basis", "Select a finite certificate for the positive target", "Assemble the panorama, solve, and validate status"].every((label) => home.includes(label)) && ["\\\\vect\\\\rho\\\\in\\\\mathcal P", "\\\\dot{\\\\vect\\\\rho}\\\\in\\\\mathcal R", "\\\\vect y:\\\\mathcal P\\\\to\\\\mathbb R^N", "\\\\mathcal F(\\\\vect\\\\rho,\\\\dot{\\\\vect\\\\rho};\\\\vect y)", "\\\\dot\\\\rho_sT_{k,s}", "\\\\mathcal P=\\\\prod", "\\\\mathcal R=\\\\prod", "\\\\mathcal G_s=\\\\{", "\\\\mathcal H_{\\\\vect c}=\\\\prod", "\\\\vect\\\\alpha=\\\\phi_{\\\\vect c}^{-1}", "B_{\\\\vect i}^{\\\\vect m}", "S^{(\\\\vect c)}", "toYalmip", "optimize", "sol.problem == 0", "value(P)"].every((fragment) => home.includes(fragment)));
check("welcome states one natural general DPD-LMI and one L2 link", /inlineNoteParts:[\s\S]*decision function, assumed locally Lipschitz continuous[\s\S]*All coefficient functions in the residual are evaluated at/.test(firstHomeStep) && /\\\\mathcal F\(\\\\vect\\\\rho,\\\\dot\{\\\\vect\\\\rho\};\\\\vect y\)[\s\S]*F_0[\s\S]*F_ky_k[\s\S]*T_\{k,s\}[\s\S]*\\\\frac\{\\\\partial y_k\}\{\\\\partial\\\\rho_s\}[\s\S]*\\\\preceq0/.test(firstHomeStep) && !/\\\\mathcal F_\{\\\\mathrm\{(?:alg|rate)\}\}/.test(firstHomeStep) && !/\btextHtml:/.test(firstHomeStep) && /manualLabel: "Open the induced-L₂-gain specialization ↗"/.test(firstHomeStep) && (firstHomeStep.match(/dpd-lmi-and-lpv-l2-gain/g)?.length ?? 0) === 1 && (firstHomeStep.match(/\binlineMath:/g)?.length ?? 0) === 1 && (firstHomeStep.match(/\bmath:/g)?.length ?? 0) === 1 && /step\.visual === "export"[\s\S]*step\.inlineMath[\s\S]*step\.inlineNoteParts/.test(home));
check("welcome stage 01 names parameter and rate domains", /inlineMath:\s*"\\\\vect\\\\rho\\\\in\\\\mathcal P,\\\\qquad\\\\dot\{\\\\vect\\\\rho\}\\\\in\\\\mathcal R,\\\\qquad\\\\vect y:\\\\mathcal P\\\\to\\\\mathbb R\^N\."/.test(firstHomeStep) && /supported parameter domain[\s\S]*supported scheduling-rate domain/.test(firstHomeStep));
check("welcome uses a visible full-panel aurora mesh without a grid", /:global\(\.content-panel:has\(\.home-portal\)\)\s*\{[^}]*position:\s*relative[^}]*overflow:\s*clip/.test(home) && /:global\(\.content-panel:has\(\.home-portal\)\)::before\s*\{[\s\S]*radial-gradient[\s\S]*radial-gradient[\s\S]*radial-gradient[\s\S]*linear-gradient\(118deg/.test(home) && !/home-portal::before|home-grid|42px 42px/.test(home) && /--home-canvas:\s*#edf4ff/.test(manualCss) && /--home-aurora-blue:\s*rgb\(37 99 235 \/ 0\.3\)/.test(manualCss) && /--home-aurora-teal:\s*rgb\(13 148 136 \/ 0\.24\)/.test(manualCss) && /--home-aurora-violet:\s*rgb\(99 102 241 \/ 0\.18\)/.test(manualCss));
check("welcome keeps paired square-underbracket annotations intact", /tensor grid partitions/.test(secondHomeStep) && /exactly/.test(secondHomeStep) && /Approximation comes only from restricting the decision-function space/.test(secondHomeStep) && /Affine rate-vertex reduction remains exact/.test(secondHomeStep) && /visual: "grid"/.test(secondHomeStep) && /annotatedMath:[\s\S]*tex: "\\\\mathcal G_s=[\s\S]*label: \["axis-"[\s\S]*tex: "\\\\mathcal H_\{\\\\vect c\}=[\s\S]*label: \["physical cell selected by "/.test(secondHomeStep) && !/mathLabels|\\underbrace/.test(secondHomeStep) && /math-strip--parameter-boxes[\s\S]*step\.textParts[\s\S]*math-strip--underbrackets[\s\S]*math-square-underbracket__expression[\s\S]*math-square-underbracket__rule[\s\S]*math-square-underbracket__label/.test(home) && /GridPartitionExplorer client:load/.test(home));
check("welcome annotation and stage margins are reset", /\.math-square-underbracket\s*>\s*\*\s*\{\s*margin-block:\s*0/.test(home) && /cell-stage-layout\s*>\s*\.cell-stage\),[\s\S]*cell-stage\s*>\s*\*\)\s*\{\s*margin-block:\s*0/.test(home));
check("React-island mathematics uses trusted TeX markup and remains upright", /gridPartitionMathMarkup\s*=\s*\{[\s\S]*renderMath\(`\\\\mathcal G_[\s\S]*renderMath\(`\\\\mathcal H_/.test(home) && /<GridPartitionExplorer client:load mathMarkup=\{gridPartitionMathMarkup\}/.test(home) && /import\s*\{\s*InlineMath\s*\}\s*from\s*"\.\/RenderedMath\.tsx"/.test(gridExplorer) && /<InlineMath markup=\{mathMarkup\.gridPrefixes\[axis\]\}/.test(gridExplorer) && /<InlineMath markup=\{mathMarkup\.cellPrefixes\[/.test(gridExplorer) && !/structured-math__cal">[GH]</.test(gridExplorer) && /\.structured-math\s*\{[^}]*font-style:\s*normal/.test(manualCss) && /\.structured-math \*,[\s\S]*\.structured-math-matrix\s*\{[^}]*font-style:\s*normal/.test(manualCss));
check("welcome storage labels attach to nodes without corner overlap and final expression centers", /cell-axis-ticks--y\s*>\s*\.formula-inline:nth-child\(1\)[^}]*inset-block-start:\s*0/.test(home) && /nth-child\(2\)[^}]*inset-block-start:\s*50%/.test(home) && /nth-child\(3\)[^}]*inset-block-start:\s*100%/.test(home) && /cell-axis-ticks--x\)[^}]*align-self:\s*start[^}]*transform:\s*translateY\(0\.15rem\)/.test(home) && /cell-stage--basis \.cell-bernstein-readout\)[^}]*align-content:\s*center/.test(home));
check("accessible fitted nonuniform grid explorer", /role="tablist"/.test(gridExplorer) && /ArrowLeft[\s\S]*ArrowRight[\s\S]*Home[\s\S]*End/.test(gridExplorer) && /1: \[0\.35\][\s\S]*2: \[0\.4, 0\.25\][\s\S]*3: \[0\.3, 0\.55, 0\.75\]/.test(gridExplorer) && /type="range"/.test(gridExplorer) && /<GridDefinition knots=\{activeKnots\} mathMarkup=\{mathMarkup\}/.test(gridExplorer) && /<CellDefinition bounds=\{bounds\} cell=\{activeCell\} mathMarkup=\{mathMarkup\}/.test(gridExplorer) && /role="math"/.test(gridExplorer) && gridExplorer.includes("labelCell(cell)") && /partition-cube__cell[\s\S]*partition-cube__axis/.test(gridExplorer) && /aria-live="polite"/.test(gridExplorer) && /onPointerDown[\s\S]*onPointerMove[\s\S]*onPointerUp/.test(gridExplorer) && /Rotate left[\s\S]*Rotate right[\s\S]*Tilt up[\s\S]*Tilt down[\s\S]*Reset view/.test(gridExplorer) && /enumerateCells[\s\S]*getCellBounds[\s\S]*projectPoint[\s\S]*fitProjection[\s\S]*mapProjection/.test(gridExplorer) && /KNOT_MIN = 0\.1[\s\S]*KNOT_MAX = 0\.9[\s\S]*PITCH_LIMIT = 70[\s\S]*fitProjection[\s\S]*mapProjection/.test(gridPartition));
check("static multiplication evidence", /Bernstein \[4, 2\][\s\S]*Bernstein \[0\.5, 3\][\s\S]*Bernstein \[2, 6\.5, 6\]/.test(multiply));
check("separated cell storage evidence", /physical grid[\s\S]*shared interface[\s\S]*global controls[\s\S]*cell-wise leaves/.test(storage) && /LocalValues[\s\S]*i1[\s\S]*i2/.test(storage) && /\[0,0\]/.test(storage));
check("accessible full examples", /<details>[\s\S]*<summary>/.test(disclosure) && visibleLines.length === 0 && (home.match(/fullCode:/g)?.length ?? 0) === 4);
check("reference multiplication adoption", /ProductPlanExplorer/.test(coefficientAlgebra) && /MultiplicationDiagram/.test(pdmatAlgebra) && !/MultiplicationDiagram/.test(pdvarAlgebra) && /numerical multiplication explorer/.test(pdvarAlgebra));
check("reference storage adoption", [pdmatStorage, pdbaseStorage, griddingMath].every((source) => /CellStorageDiagram/.test(source)) && !/CellStorageDiagram/.test(pdmatCtor));
check("pdmat storage documents entry-level coefficient access", /coeffs\(A\(rowIndex,columnIndex\),cellSubscript\)/.test(pdmatStorage) && /same[\s\S]*local-label order as `A\.lbls\(\)`/.test(pdmatStorage));
check(
  "constructor separates global, cell-wise, and coefficient-level Bernstein expressions",
  /## Bernstein Basis Expression/.test(pdmatCtor) &&
    /CellBernsteinExpressionExplorer\.astro/.test(pdmatCtor) &&
    /CellBernsteinExpressionExplorer mathMarkup=\{mathMarkup\} client:visible/.test(cellBasisWrapper) &&
    /globalLhs:\s*renderMath\(`A\(\\\\vect\\\\rho\)=`\)/.test(cellBasisWrapper) &&
    /globalMatrix:\s*renderMath\(`\\\\begin\{bmatrix\}[\s\S]*1\+\\\\rho_1\+\\\\rho_2[\s\S]*\\\\rho_1\\\\rho_2[\s\S]*2\+\\\\rho_1\^2[\s\S]*\\\\end\{bmatrix\},`\)/.test(cellBasisWrapper) &&
    /globalDomain:\s*renderMath\(`\\\\vect\\\\rho\\\\in\[0,1\]\^2\.`\)/.test(cellBasisWrapper) &&
    /representationLhs:\s*renderMath\(`A\^\{\(\$\{cell\.c1\},1\)\}[\s\S]*=`\)/.test(cellBasisWrapper) &&
    /representationSum:\s*renderMath\(`\\\\sum_\{\\\\vect i/.test(cellBasisWrapper) &&
    /basisDefinition:\s*renderMath\(`B_\{\\\\vect i\}\^\{2\}[\s\S]*B_\{i_1\}\^\{2\}/.test(cellBasisWrapper) &&
    /cell-basis-expression__global-formula formula-one-line[\s\S]*InlineMath markup=\{mathMarkup\.globalLhs\}[\s\S]*InlineMath markup=\{mathMarkup\.globalMatrix\}[\s\S]*InlineMath markup=\{mathMarkup\.globalDomain\}/.test(cellBasisExplorer) &&
    /cell-basis-expression__formula formula-one-line[\s\S]*InlineMath markup=\{cellMath\.representationLhs\}[\s\S]*InlineMath markup=\{cellMath\.representationSum\}[\s\S]*InlineMath markup=\{cellMath\.basisDefinition\}/.test(cellBasisExplorer) &&
    /documentedMatrixAt[\s\S]*1 \+ rho1 \+ rho2[\s\S]*rho1 \* rho2[\s\S]*2 \+ rho1 \*\* 2/.test(cellBernstein) &&
    /role="tablist"/.test(cellBasisExplorer) &&
    /type="range"/.test(cellBasisExplorer) &&
    /cell-basis-term-grid/.test(cellBasisExplorer) &&
    /buildCellBernsteinModel/.test(cellBasisExplorer) &&
    /bernsteinBasisWeights/.test(cellBernstein),
);
check("local-coordinate axes frame and orient the tensor basis grid", /cell-basis-coordinate-frame[\s\S]*cell-basis-axis--vertical[\s\S]*cell-basis-term-grid[\s\S]*cell-basis-axis--horizontal/.test(cellBasisExplorer) && /orderCellBernsteinTermsForAxes\(model\.terms\)/.test(cellBasisExplorer) && /right\.j - left\.j \|\| left\.i - right\.i/.test(cellBernstein) && /\.cell-basis-axis--vertical input\s*\{[^}]*direction:\s*rtl[^}]*writing-mode:\s*vertical-lr/.test(manualCss) && /\.cell-basis-axis--horizontal\s*\{[^}]*grid-column:\s*2[^}]*grid-row:\s*3/.test(manualCss) && /@media \(max-width: 700px\)[\s\S]*\.cell-basis-coordinate-frame\s*\{[^}]*grid-template-columns:\s*4rem minmax\(0,\s*1fr\)/.test(manualCss));
check("pdmat elevate has a dedicated route and sidebar chapter", /label: "Storage", slug: "documents\/reference\/pdmat\/storage-and-elevation"/.test(astroConfig) && /label: "elevate", slug: "documents\/reference\/pdmat\/elevate"/.test(astroConfig) && /id="pdmat-elevate"/.test(pdmatElevate) && /id="pdmat-elevate"/.test(pdmatElevate) && /DegreeElevationExplorer client:visible/.test(pdmatElevate) && !/DegreeElevationExplorer|id="pdmat-elevate"|id="pdmat-elevate"/.test(page("reference/pdmat/storage-and-elevation.mdx")));
check("pdmat storage diagram links geometry to absolute BASE_URL public accessors", /import\.meta\.env\.BASE_URL/.test(storage) && /pdmatStorage\s*=\s*`\$\{base\}documents\/reference\/pdmat\/storage-and-elevation\/`/.test(storage) && /href=\{`\$\{pdmatStorage\}#pdmat-cells`\}[\s\S]*href=\{`\$\{pdmatStorage\}#pdmat-coeffs`\}[\s\S]*href=\{`\$\{pdmatStorage\}#pdmat-lbls`\}[\s\S]*href=\{`\$\{pdmatStorage\}#pdmat-ncoeff`\}/.test(storage) && !/href=["']#pdmat-/.test(storage) && /cells\(A\)[\s\S]*coeffs\(A,cellSubscript\)[\s\S]*lbls\(A\)[\s\S]*ncell[^]*ncoeff[^]*npar/.test(pdmatStorage));
check("pdmat elevate preserves both bases and direct normalized convolution", /## What degree elevation does/.test(pdmatElevate) && /B_\{\\vect i\}\^\{\\vect m\}[\s\S]*B_\{\\vect k\}\^\{\\vect M\}/.test(pdmatElevate) && /<div className="elevate-direct-coefficient-scroll">[\s\S]*class="formula-block formula-one-line"[\s\S]*\\binom\{m_s\}\{i_s\}\\binom\{M_s-m_s\}\{k_s-i_s\}[\s\S]*\\binom\{M_s\}\{k_s\}[\s\S]*<\/div>/.test(pdmatElevate) && !/<div className="elevate-direct-coefficient-scroll">[\s\S]*\\begin\{aligned\}[\s\S]*<\/div>/.test(pdmatElevate) && /Let \$\\vect d:=\\vect M-\\vect m\$/.test(pdmatElevate) && /\\mathcal E_\{\\vect d\}\[\\vect j\]:=\\prod_\{s=1\}\^\{\\ell\}\\binom\{d_s\}\{j_s\},\\qquad\\vect j\\in\\prod_\{s=1\}\^\{\\ell\}\\\{0,\\ldots,d_s\\\}/.test(pdmatElevate) && (pdmatElevate.match(/\\mathcal E_\{\\vect d\}\[\\vect j\]/g)?.length ?? 0) === 2 && /\\ast_\{\\ell\}[\s\S]*\\mathcal E_\{\\vect d\}\[\\vect j\]/.test(pdmatElevate) && /\\prod_\{s=1\}\^\{\\ell\}\\\{0,\\ldots,m_s\\\}/.test(pdmatElevate) && /\\prod_\{s=1\}\^\{\\ell\}\\\{0,\\ldots,M_s\\\}/.test(pdmatElevate) && /\\left\\\{\\left\(\\prod[\s\S]*\\right\\\}_\{\\vect k\}=[\s\S]*\\right\\\}_\{\\vect i\}\\ast_\{\\ell\}\\left\\\{\\mathcal E/.test(pdmatElevate) && !/\\mathcal E_\{\\vect M-\\vect m\}|\\mathcal U|w_\{\\vect i,\\vect k\}|\\widehat C|\\widetilde a/.test(pdmatElevate) && /### One-dimensional coefficient rule and example[\s\S]*\\tilde a_\{i_1\}[\s\S]*A = pdmat/.test(pdmatElevate) && /Implementation remark: copy, do not reconstruct/.test(pdmatElevate) && /out = obj[\s\S]*out\.Degree[\s\S]*out\.LocalValues[\s\S]*FunctionHandle[\s\S]*rate-row ordering[\s\S]*YALMIP variables/.test(pdmatElevate) && pdmatElevate.includes("`ncoeff(A)` increases") && /exact representation change on a fixed grid and fixed polynomial/.test(pdmatElevate));
check("pdvar preserves symbolic elevation and evaluation contracts", pdvarStorage.includes("\\operatorname{Aff}(\\texttt{sdpvar})") && (pdvarStorage.match(/id="pdvar-elevate"/g)?.length ?? 0) === 1 && /same underlying YALMIP[\s\S]*preserves the existing[\s\S]*decision field/.test(pdvarStorage) && /id="pdvar-evaluate"/.test(pdvarStorage) && !/elevatedTree\s*=/.test(pdvarStorage) && !/client:visible|interactive-figure/.test(pdvarCtor + pdvarStorage));
check("top-level sidebar omits the retired v1.1.2 performance entry", !/v1\.1\.2 Performance|performance-v1-1-2/.test(astroConfig));
check("physical-grid nodes share the lower track boundary", /<div class="track-nodes" aria-hidden="true">[\s\S]*node--start[\s\S]*node--middle[\s\S]*node--end/.test(storage) && /\.track-nodes\s*\{[^}]*position:\s*absolute[^}]*inset:\s*0/.test(storage) && /\.node\s*\{[^}]*inset-block-start:\s*100%[^}]*margin:\s*0/.test(storage));
check("degree-elevation explorer starts from the documented cubic row", /const initialCoefficients\s*=\s*"1 2 6 2"/.test(elevationExplorer) && /buildElevation\(initialCoefficients,\s*2\)/.test(elevationExplorer) && /useState\(initialCoefficients\)/.test(elevationExplorer));
check("parameter curve static adoption", /series[\s\S]*marker[\s\S]*role="img"/.test(parameterCurve) && /ParameterCurveDiagram/.test(pdmatPlot));
check("matrix glyph structural adoption", /before[\s\S]*after[\s\S]*matrix-glyph/.test(matrixGlyph) && [pdmatStructure, pdvarStructure].every((source) => /MatrixGlyphDiagram/.test(source)));
check("pdvar decision evidence adoption", /X\^\{\(\\vect c\)\}\[\\vect i\]/.test(pdvarCtor) && /YALMIP decision/.test(pdvarCtor) && /value-evidence/.test(pdvarValue) && /coefficient-row-map/.test(pdvarTable));
check("pdvar bernTable preserves legacy and heading anchors", /<span id="example"><\/span>\s*## Exact two-dimensional storage example/.test(pdvarTable));
check("dedicated rhodiff detail reuse", /lower\/upper Cartesian-product order[\s\S]*direction-wise decision degree/.test(rhodiff) && [pdvarDiff, rateInterfaceMath, coefficientAlgebra].every((source) => /RhodiffDiagram/.test(source)) && !/RhodiffDiagram/.test(pdvarTable));
check("SparsePutinar card and reference keep parity, tensor windows, accumulation, and graph-chordal boundary", /key: "sparseputinar"/.test(certData) && /useSpPut\(\)/.test(certData) && /tensor windows/.test(certData) && [pdlmiSparsePutinar, sparsePutinarMath].every((source) => source.includes("parity-specific Markov–Lukács") && source.includes("singleton") && (source.includes("tensor-window") || source.includes("tensor windows")) && source.includes("coefficient identit") && source.includes("Zheng") && source.includes("graph")) && /Tensor-window side b/.test(chooser) && /cliqueSize/.test(chooser));
check("SparseFullBox card and references use sliding tensor windows", /sliding tensor windows/.test(sparseFullboxMath) && /sliding tensor-window/.test(pdlmiSparseFullbox) && /overlapping windows/.test(certData) && /tensor-label window/.test(sparseFlowNotation) && [sparseFullboxMath, pdlmiSparseFullbox, certData, sparseFlowNotation].every((source) => !/block[- ]band/i.test(source)) && certData.includes("Q_{J,\\\\vect u}") && sparseFlowNotation.includes("Q_{J,\\\\vect u}"));
check("certificate spectrum uses uniform 3x2, 2x3, and one-column layouts", /grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\)/.test(certificate) && /max-width:\s*760px[\s\S]*repeat\(2,\s*minmax\(0,\s*1fr\)\)/.test(certificate) && /max-width:\s*390px[\s\S]*grid-template-columns:\s*1fr/.test(certificate) && /strong\s*\{[^}]*min-width:\s*0[^}]*overflow-wrap:\s*anywhere[^}]*line-height:\s*1\.15/.test(certificate) && !/strong\s*\{[^}]*(?:transform|margin)/.test(certificate));
check("shared certificate detail navigation", [pdlmiCtor, pdlmiPolya, pdlmiPutinar, pdlmiSparsePutinar, pdlmiSparseFullbox, pdlmiFullbox].every((source) => /CertificateNavigation/.test(source) && /showSections=\{false\}/.test(source)) && [[pdlmiCtor, "direct"], [pdlmiPolya, "polya"], [pdlmiPutinar, "putinar"], [pdlmiSparsePutinar, "sparseputinar"], [pdlmiSparseFullbox, "sparsefullbox"], [pdlmiFullbox, "fullbox"]].every(([source, selected]) => new RegExp(`selected="${selected}"`).test(source)) && [directPolyaMath, markovPutinarMath, sparsePutinarMath, sparseFullboxMath].every((source) => /CertificateSpectrum/.test(source)) && ["direct", "polya", "putinar", "sparseputinar", "sparsefullbox", "fullbox"].every((key) => certData.includes(`key: "${key}"`)));
check("open YALMIP constraint composition", /coefficient-to-constraint[\s\S]*toYalmip[\s\S]*YALMIP constraints/.test(constraintAssembly) && /ConstraintAssemblyDiagram/.test(pdlmiYalmip));

check("root-only eager React walkthroughs and lazy detail islands", /@astrojs\/react/.test(packageJson) && /import react from "@astrojs\/react"/.test(astroConfig) && /react\(\)/.test(astroConfig) && /CellStorageExplorer client:load/.test(home) && /GridPartitionExplorer client:load/.test(home) && /CertificateFlow compact eager/.test(home) && /eager\s*\?[\s\S]*client:load[\s\S]*client:visible/.test(certificateFlow) && /CellBernsteinExpressionExplorer mathMarkup=\{mathMarkup\} client:visible/.test(cellBasisWrapper) && /client:visible/.test(pdmatEval) && /client:visible/.test(chooserWrapper));
check("mobile coefficient-to-cell annotations stay readable", /@media \(max-width: 520px\)[\s\S]*\.control-strip em\s*\{[^}]*font-size:\s*0\.78rem/.test(storage));
check("accessible mathematical explorers with last-valid plan state", [elevationPlanExplorer, productPlanExplorer, gramPlanExplorer].every((source) => /<form[^>]*onSubmit=/.test(source) && /type="submit"/.test(source) && /aria-describedby/.test(source) && /role="alert"/.test(source) && /aria-live="polite"/.test(source) && /aria-invalid/.test(source) && /updateLastValid/.test(source)) && /residualDegree/.test(gramPlanExplorer + assemblyPlans) && /2 \* order\[0\] \+ 1/.test(assemblyPlans) && /oneMinusAlpha: \[1\]/.test(assemblyPlans) && /ElevationPlanExplorer client:visible/.test(coefficientAlgebra) && /ProductPlanExplorer client:visible/.test(coefficientAlgebra) && /GramAssemblyExplorer client:visible/.test(markovPutinarMath + sparseFullboxMath) && /RateVertexExplorer client:load/.test(pdvarDiff) && /TensorTraversalExplorer client:visible/.test(griddingMath));
check("interactive A hypercube storage", /aria-pressed/.test(cellExplorer) && /ArrowLeft[\s\S]*ArrowRight[\s\S]*ArrowUp[\s\S]*ArrowDown/.test(cellExplorer) && /c1: 1[\s\S]*c1: 2/.test(cellBernstein) && /A\.LocalValues/.test(cellExplorer) && /3&1\\\\\\\\1&3/.test(cellBernstein) && /7\/4&1\/8\\\\\\\\1\/8&2/.test(cellBernstein));
check("storage selection uses HTML labels and build-time inline math", cellExplorer.includes("<strong>Selected hypercube:</strong>") && /<InlineMath markup=\{cellMath\.selection\}/.test(cellExplorer) && cellExplorer.includes("<strong>Physical domain:</strong>") && /<InlineMath markup=\{cellMath\.domain\}/.test(cellExplorer) && /selection:\s*renderMath\(`c=/.test(home) && (cellBernstein.match(/domainTex: "\\\\rho_1\\\\in\[/g)?.length ?? 0) === 2);
check("complete bordered coefficient cells", /\.cell-coeffs\s*>\s*span\s*\{[^}]*border:\s*1px solid var\(--diagram-border\)[^}]*border-block-start:\s*2px solid var\(--sl-color-accent\)[^}]*border-radius:\s*8px/.test(manualCss));
check("bounded mobile storage connector", /@media \(max-width: 700px\)[\s\S]*\.cell-storage-connector\s*\{[^}]*width:\s*auto[^}]*height:\s*3\.2rem[^}]*grid-template-rows:\s*auto 1fr/.test(manualCss) && /\.cell-storage-connector i\s*\{[^}]*width:\s*0[^}]*height:\s*1\.7rem[^}]*border-block-start:\s*0[^}]*border-inline-start:[^}]*transform:\s*none/.test(manualCss) && /\.cell-storage-connector i::after\s*\{[^}]*inset-block-end:\s*0[^}]*border-block-end:\s*2px solid/.test(manualCss) && !/\.cell-storage-connector i\s*\{\s*transform:\s*rotate\(90deg\)/.test(manualCss));
check("interactive multiplication", /parseCoefficients/.test(multiplicationInput) && /useDeferredValue/.test(multiplyExplorer) && /role="alert"/.test(multiplyExplorer) && /BernsteinPlot/.test(multiplyExplorer));
check("interactive common-degree addition", /alignAndAdd/.test(additionInput) && /elevateBernstein/.test(additionInput) && /maxAdditionCoefficients\s*=\s*256/.test(additionInput) && /useDeferredValue/.test(additionExplorer) && /BernsteinPlot/.test(additionExplorer) && /AdditionExplorer client:visible/.test(pdmatAlgebra) && /MultiplicationExplorer client:visible/.test(pdmatAlgebra));
check("independent multiplication errors", /errors\.left/.test(multiplyExplorer) && /errors\.right/.test(multiplyExplorer) && /aria-invalid/.test(multiplyExplorer));
check("bounded multiplication input", /maxMultiplicationCoefficients\s*=\s*256/.test(multiplicationInput) && /Use at most \$\{maxMultiplicationCoefficients\} coefficients per factor/.test(multiplicationInput) && /maxMultiplicationCoefficients/.test(multiplyExplorer));
check("actual multiplication contributions", /bernsteinContributionsAt/.test(multiplyExplorer) && /term\.weight/.test(multiplyExplorer) && /term\.value/.test(multiplyExplorer) && /<details[\s\S]*<summary>Show/.test(multiplyExplorer) && !/sum over i \+ j/.test(multiplyExplorer));
check("interactive one- and two-dimensional evaluate", /1 \+ 3ρ − 6ρ² \+ 4ρ³/.test(evaluateExplorer) && /Tensor Bernstein degree: 2/.test(evaluateExplorer) && /quadraticCoefficients[\s\S]*quadraticDegree\s*=\s*2/.test(evaluateExplorer) && /evaluateTensorBernstein/.test(evaluateExplorer) && /role="tablist"/.test(evaluateExplorer) && /role="tabpanel"/.test(evaluateExplorer) && /type="range"/.test(evaluateExplorer) && /requestAnimationFrame/.test(evaluateExplorer) && /querySelector\("svg"\)/.test(evaluateExplorer) && /clientXToUnit/.test(evaluateExplorer) && /role="slider"/.test(evaluateExplorer) && /Parameter plane[\s\S]*Function surface[\s\S]*Rotatable three-dimensional degree-two surface of A/.test(evaluateExplorer) && /onPointerDown=\{rotateSurface\}/.test(evaluateExplorer) && /onPointerMove=\{rotateSurface\}/.test(evaluateExplorer) && /onKeyDown=\{rotateSurfaceFromKeyboard\}/.test(evaluateExplorer) && /projectPoint[\s\S]*fitProjection[\s\S]*mapProjection/.test(evaluateExplorer) && /\.evaluate-coordinate-controls\s*\{[^}]*grid-column:\s*1\s*\/\s*-1/.test(manualCss) && /EvaluateExplorer[\s\S]*client:visible/.test(pdmatEval));
check("pdmat evaluate gives the general tensor Bernstein formula", /\\mathcal H_\{\\vect c\}[\s\S]*\\prod_\{s=1\}\^\{\\ell\}[\s\S]*\\vect\\rho&\\in\\mathcal H_\{\\vect c\}/.test(pdmatEval) && /\\alpha_s[\s\S]*\\rho_s\^\{\(c_s\)\}/.test(pdmatEval) && /\\vect m=\(m_1,\\ldots,m_\\ell\)/.test(pdmatEval) && /A\^\{\(\\vect c\)\}\(\\vect\\alpha\)[\s\S]*\\sum_\{\\vect i\\in\\prod_\{s=1\}\^\{\\ell\}\\\{0,\\ldots,m_s\\\}\}/.test(pdmatEval) && /b_s\(i_s,\\alpha_s\)[\s\S]*\\binom\{m_s\}\{i_s\}[\s\S]*\\alpha_s\^\{i_s\}\(1-\\alpha_s\)\^\{m_s-i_s\}[\s\S]*B_\{\\vect i\}\^\{\\vect m\}\(\\vect\\alpha\)[\s\S]*\\prod_\{s=1\}\^\{\\ell\}b_s\(i_s,\\alpha_s\)/.test(pdmatEval) && !/For degree-one scalar data/.test(pdmatEval));
check("Bernstein overview is a four-part conceptual essay with nonempty visuals", ["Local Coordinates And The Tensor Representation", "Convex-Hull Reasoning And The Direct Certificate", "`LocalValues`, Face Continuity, And cell-wise Differentiation", "Exact Algebra, Finite Certificates, And Independent Refinements"].every((heading) => bernsteinMath.includes(`## ${heading}`)) && (bernsteinMath.match(/^## /gm)?.length ?? 0) === 6 && /<BernsteinConceptDiagram kind="basis" \/>/.test(bernsteinMath) && /<BernsteinConceptDiagram kind="convex" \/>/.test(bernsteinMath) && /<CellStorageDiagram \/>/.test(bernsteinMath) && !/<BernsteinConceptDiagram\s*\/>/.test(bernsteinMath));
check("solver smoke keeps fitting plant definitions on one display line", /A\(\\rho\)=\(1-\\rho\)\\begin\{bmatrix\}-1&-1\\\\1&-1\\end\{bmatrix\}\s*\+\\rho\\begin\{bmatrix\}-1&-10\\\\0\.1&-1\\end\{bmatrix\},\s*\\qquad \\rho\\in\[0,1\]\./.test(solverSmoke) && /A\(\\rho\)=\\begin\{bmatrix\}-1&0\.5\\\\-1&-2\\end\{bmatrix\}\s*\+\\rho\\begin\{bmatrix\}-1\.3&-20\\\\2&-10\\end\{bmatrix\}\./.test(solverSmoke) && /B\(\\rho\)=\\begin\{bmatrix\}1&-4\\\\-1&-1\\end\{bmatrix\}\s*\+\\rho\\begin\{bmatrix\}2\.2&0\.5\\\\-6&-5\\end\{bmatrix\}\./.test(solverSmoke) && !/A\(\\rho\)&=|B\(\\rho\)&=/.test(solverSmoke) && /\\begin\{aligned\}[\s\S]*\\dot\{P\}\+PA\+A\^\\top P/.test(solverSmoke));
check("pdmat and pdvar addition remarks expose exact alignment", [pdmatAlgebra, pdvarAlgebra].every((source) => /Implementation remark: exact addition alignment/.test(source) && /sorted-union/.test(source) && /componentwise/.test(source)));
check("pdmat and pdvar multiplication remarks expose ordered convolution", [pdmatAlgebra, pdvarAlgebra].every((source) => /Implementation remark: ordered product convolution/.test(source) && /normalized Bernstein/.test(source) && /matrix-factor order/.test(source)));
check("pdmat evaluate remark exposes boundary and reconstruction mechanics", /Implementation remark: boundary ownership and row reconstruction[\s\S]*cell on the right[\s\S]*tensor[\s\S]*Bernstein weight[\s\S]*stored tensor-product Bernstein sum directly/.test(pdmatEval));
check("pdvar rhodiff remark exposes common-basis rate rows", /Implementation remark: common-basis rate rows[\s\S]*forward differences[\s\S]*common tensor degree[\s\S]*helper\.combRows/.test(pdvarDiff));
check("pdlmi remark exposes selector rebuild and constraint order", /Implementation remark: rebuild, do not stack[\s\S]*stored original[\s\S]*cells\(\)[\s\S]*rate-row order[\s\S]*lbls\(\)[\s\S]*column-major/.test(pdlmiCtor));
check("quadratic-to-linear differentiation detail retained off welcome", /\[0\.8, 2\.2, 1\.4\][\s\S]*\[1\.4, −0\.2, 1\.8\][\s\S]*rhodiff[\s\S]*\[5\.6, −3\.2\][\s\S]*\[−6\.4, 8\]/.test(diffStorage) && !/DifferentiationStorage/.test(home));
check("certificate flow tabs on welcome and interactive reference overview", /CertificateFlow compact/.test(home) && /compact=\{compact\}/.test(certificateFlow) && /Theoretical positive target/.test(certificateFlowTabs) && /<InlineMath markup=\{residualMarkup\}/.test(certificateFlowTabs) && /residualMarkup\s*=\s*renderMath\("S\^\{\(\\\\vect c\)\}/.test(certificateFlow) && !/F\^\{\(\\vect c,v\)\}/.test(certificateFlowTabs) && /role="tablist"/.test(certificateFlowTabs) && /role="tabpanel"/.test(certificateFlowTabs) && /ArrowLeft[\s\S]*ArrowRight[\s\S]*Home[\s\S]*End/.test(certificateFlowTabs) && /option\.formulaMarkup/.test(certificateFlowTabs) && /option\.notationMarkup/.test(certificateFlowTabs) && /MATLAB selector/.test(certificateFlowTabs) && /Open the \{option\.label\} reference/.test(certificateFlowTabs) && /CertificateChooser/.test(pdlmiOverview) && /useState\(0\)/.test(chooser) && /role="tablist"/.test(chooser) && /selected\.toYalmip\(\)/.test(chooser));
check("Pólya card presents transform before coefficient test and index set", certData.includes('cardFormula: "\\\\tilde S^{(\\\\vect c)}(\\\\vect\\\\alpha)=S^{(\\\\vect c)}(\\\\vect\\\\alpha)\\\\prod_{s=1}^{\\\\ell}') && certificateFlow.includes('polya: "\\\\begin{gathered}\\\\tilde C') && certificateFlow.indexOf("\\\\tilde C") < certificateFlow.indexOf("\\\\vect i\\\\in\\\\prod_{s=1}^{\\\\ell}") && certificateFlowTabs.indexOf('className="certificate-flow-panel__formula"') < certificateFlowTabs.indexOf('className="certificate-flow-panel__notation"') && certificateFlowTabs.indexOf("option.formula") < certificateFlowTabs.indexOf("option.notation"));
check("equal-height centered compact certificate tabs and readout", /grid-auto-rows:\s*1fr/.test(manualCss) && /block-size:\s*5rem/.test(manualCss) && /\.certificate-flow-tabs button\s*\{[^}]*align-content:\s*center[^}]*justify-items:\s*center[^}]*text-align:\s*center/.test(manualCss) && /\.certificate-tabs button strong,\s*\.certificate-flow-tabs button strong\s*\{[^}]*overflow-wrap:\s*anywhere[^}]*line-height:\s*1\.15/.test(manualCss) && /certificate-shape-readout p\s*\{[^}]*min-block-size:\s*4\.25rem[^}]*margin:\s*0/.test(manualCss) && !/certificate-default|>Default</.test(chooser) && !/showDefault|default-marker/.test(certificate));
check("shared certificate navigation contract", exactSequence(certificateKeys, expectedCertificateKeys) && exactSequence(certificateAnchors, expectedCertificateAnchors) && exactSequence(certificateLabels, expectedCertificateLabels) && exactSequence(certificateCommands, expectedCertificateCommands) && /CertificateNavigation/.test(pdlmiOverview) && /showSections \? `#\$\{item\.anchor\}`/.test(certificateNavigation) && /item\.detailRoute/.test(certificateNavigation) && /aria-current=\{isSelected \? "page"/.test(certificateNavigation));
check("six certificate states, responsive cards, and distinct sparse controls", [
  manualCss,
  certificateNavigation,
  certificate,
  exportSolve,
].every((source) => /grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\)/.test(source)) &&
  /\.certificate-flow-tabs\s*\{[^}]*grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\)/.test(manualCss) &&
  /@media \(max-width: 700px\)[\s\S]*\.certificate-tabs \{ grid-template-columns: repeat\(2, minmax\(0, 1fr\)\); \}[\s\S]*\.certificate-flow-tabs \{ grid-template-columns: repeat\(2, minmax\(0, 1fr\)\); \}/.test(manualCss) &&
  [certificateNavigation, certificate, exportSolve].every((source) => /@media \(max-width: 760px\)[\s\S]*grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\)/.test(source)) &&
  /@media \(max-width: 390px\)[\s\S]*\.certificate-tabs,[\s\S]*\.certificate-flow-tabs \{ grid-template-columns: 1fr; \}/.test(manualCss) &&
  [certificateNavigation, certificate, exportSolve].every((source) => /@media \(max-width: 390px\)[\s\S]*grid-template-columns:\s*1fr/.test(source)) &&
  /\.certificate-tabs\s*\{[^}]*grid-auto-rows:\s*1fr[^}]*align-items:\s*stretch/.test(manualCss) &&
  /\.certificate-tabs button\s*\{[^}]*align-self:\s*stretch[^}]*block-size:\s*5rem/.test(manualCss) &&
  /\.certificate-flow-tabs\s*\{[^}]*grid-auto-rows:\s*1fr/.test(manualCss) &&
  /\.certificate-flow-tabs button\s*\{[^}]*align-content:\s*center[^}]*min-block-size:\s*5rem/.test(manualCss) &&
  /ArrowLeft[\s\S]*ArrowRight[\s\S]*Home[\s\S]*End/.test(chooser) &&
  /Tensor-window side b[\s\S]*draft\.cliqueSize/.test(chooser) && /Tensor-window side w[\s\S]*draft\.bandWidth/.test(chooser) &&
  /cliqueSize:\s*number/.test(read("src/lib/manual-explorers.ts")) && /bandWidth:\s*number/.test(read("src/lib/manual-explorers.ts")) &&
  /Effective endpoint/.test(chooser) && /`b == 1` returns an actual Direct object[\s\S]*windows saturate[\s\S]*dense Putinar/.test(pdlmiSparsePutinar) &&
  /window size of one[\s\S]*spans every active basis axis[\s\S]*FullBox/i.test(pdlmiSparseFullbox) &&
  exactSequence([...exportSolve.matchAll(/<span>([^<]+)<\/span>/g)].map((match) => match[1]), expectedCertificateLabels));
check("header destinations", /Header: "\.\/src\/components\/Header\.astro"/.test(astroConfig) && ["Manual", "Download", "Examples", "About me"].every((label) => headerLinks.includes(`label: "${label}"`)) && /site-header__brand[\s\S]*site-header__search[\s\S]*site-header__links[\s\S]*site-header__controls/.test(header));
check("responsive header destinations", /<details[^>]*class="site-header__more/.test(header) && /<summary/.test(header) && /@media \(min-width: 72rem\)[\s\S]*site-header__more[\s\S]*display: none/.test(header));
check("direct local KaTeX build pipeline", ["katex", "remark-math", "rehype-katex"].every((name) => Object.hasOwn(directDependencies, name) && Object.hasOwn(lockedDependencies, name)) && /import\s+remarkMath\s+from\s+["']remark-math["']/.test(astroConfig) && /import\s+rehypeKatex\s+from\s+["']rehype-katex["']/.test(astroConfig) && /remarkPlugins:\s*\[[^\]]*remarkMath/.test(astroConfig) && /rehypePlugins:\s*\[[^\]]*rehypeKatex/.test(astroConfig) && astroConfig.includes(katexCssImport));
check("KaTeX has no external URL or runtime asset dependency", !/(?:https?:\/\/|\/\/)[^"'`\s]*katex|katex[^"'`\s]*(?:https?:\/\/|\/\/)/i.test(`${astroConfig}\n${manualCss}\n${katexAstro}\n${katexReact}\n${katexRenderer}\n${katexOptions}`));
check("KaTeX output includes HTML and MathML", /class="katex-html"/.test(renderedFormula) && /<math(?:\s|>)/.test(renderedFormula) && /output:\s*"htmlAndMathml"/.test(katexOptions));
check("formula output contains no <svg", !/<svg(?:\s|>)/i.test(renderedFormula));
check("native KaTeX script and fraction metrics", mathMetricRules.length === 0 && !/\\(?:displaystyle|textstyle|scriptstyle|scriptscriptstyle|tiny|scriptsize|footnotesize|small|large|Large|LARGE|huge|Huge)\b/.test(allSource));
check("welcome storage uses build-time formula markup wrappers", /import \{ InlineMath \} from "\.\/RenderedMath\.tsx"/.test(cellExplorer) && /<InlineMath[\s\S]*markup=/.test(cellExplorer) && !/\btex=|renderMath|renderToString|dangerouslySetInnerHTML/.test(cellExplorer) && /basis:\s*renderMath\("B_\{\\\\vect i\}\^\{\\\\vect m\}\(\\\\vect\\\\alpha\)=\\\\prod/.test(home) && /bernstein:\s*renderMath\(`\\\\begin\{aligned\}\\\\vect m&=\(2,2\),[\s\S]*\\\\sum_\{\\\\vect i\\\\in\\\\prod_\{s=1\}\^\{\\\\ell\}/.test(home) && /className="cell-bernstein-formula formula-block"/.test(cellExplorer) && /storageMath: "A\(\\\\rho_1,\\\\rho_2\)=\\\\begin\{bmatrix\}1\+\\\\rho_1\+\\\\rho_2/.test(home) && !/a_\{11\}|a_\{12\}|a_\{22\}/.test(thirdHomeStep));
check("external plot legends", /plot-legend[\s\S]*<svg/.test(component("BernsteinPlot.tsx")) && /plot-legend[\s\S]*<svg/.test(parameterCurve) && !/<text[^>]*>\{item\.label\}/.test(parameterCurve) && !/<text[^>]*>\{marker\.label\}/.test(parameterCurve) && /<div class="curve-legend"[\s\S]*<\/div>[\s\S]*<svg/.test(multiply) && !/curve-labels/.test(multiply));
check("aligned multiplication header and legend", /multiplication-formulas[\s\S]*grid-template-columns: minmax\(0, 0\.85fr\) minmax\(0, 1\.15fr\)/.test(multiply) && /multiplication-formulas > div[^{]*\{[^}]*margin: 0/.test(multiply) && /curve-legend[\s\S]*grid-template-columns: repeat\(3, minmax\(0, 1fr\)\)[\s\S]*align-items: stretch/.test(multiply) && /curve-copy[\s\S]*height: 100%[\s\S]*min-height: 4\.4rem/.test(multiply) && /@media \(max-width: 560px\)[\s\S]*multiplication-formulas,[\s\S]*curve-legend[\s\S]*grid-template-columns: 1fr/.test(multiply));
check("canonical notation", /id="domains-and-rate-vertices"/.test(notationMath) && /id="grids-cells-and-local-coordinates"/.test(notationMath) && /id="bernstein-labels-and-degrees"/.test(notationMath) && /^## <span id="residual-target"><\/span>Residual And Positive Target$/m.test(notationMath) && !/<span id="residual-and-positive-target"><\/span>/.test(notationMath) && /E_\{\\vect M\\leftarrow\\vect m\}/.test(coefficientAlgebra) && /\\dot\{\\vect\\rho\}\(t\)\\in\\mathcal R/.test(modelMath));
check("canonical axis node counts", [griddingMath, bernsteinMath].every((source) => /k_s/.test(source) && !/N_(?:\d|\\ell|r)/.test(source)));
check("unambiguous tensor and derivative notation", /h_s\^\{\\vect c\}/.test(griddingMath) && /\\vect\\alpha[\s\S]*&=\\phi_\{\\vect c\}\^\{-1\}\(\\vect\\rho\)/.test(griddingMath) && /\\frac\{1\}\{h_s\^\{\\vect c\}\}/.test(rateInterfaceMath) && !/width \$h=/.test(griddingMath));
check("canonical cell-wise function notation", !/P_c|Q_c|dP_c/.test(bernsteinMath + coefficientAlgebra) && /P\^\{\(c\)\}/.test(pdvarCtor) && !/P_\{?[0-9i]/.test(pdvarCtor) && /X\^\{\(\\vect c\)\}\[\\vect i\]/.test(pdvarCtor));
check("dimension-aware Putinar contract", [certData, pdlmiOverview, pdlmiPutinar, pdlmiCtor, sosMath, markovPutinarMath].every((source) => /Markov[–-]Luk[aá]cs/.test(source) && /floor|\\lfloor/.test(source) && /two or more|\\ell\\ge2|\\ell\s*\\ge\s*2/.test(source) && /ceil|\\lceil/.test(source)));
check("cell-indexed DPD-LMI workflow", ["\\\\mathcal H_{\\\\vect c}", "\\\\vect\\\\alpha=\\\\phi_{\\\\vect c}^{-1}", "S^{(\\\\vect c)}", "selected.toYalmip()"].every((fragment) => home.includes(fragment)) && /optional exact scheduling-rate vertex/.test(home) && !/F\^\{\(\\\\vect c,v\)\}|m\+p/.test(home + certData + certificateFlow));
check("welcome begins from the general DPD-LMI template", /From a continuum DPD-LMI to YALMIP and recovered decisions/.test(home) && !/Model an LPV induced-L2-gain problem|x\(t\) is the plant state|\\\\lVert z\\\\rVert_2<\\\\gamma\\\\lVert w\\\\rVert_2/.test(home));
check("new mathematics page contract", detailedMathPages.every((source) => /^---[\s\S]*title:[^\n]+[\s\S]*description:[^\n]+[\s\S]*---/.test(source) && /manual-trail/.test(source) && /^## See Also$/m.test(source)) && /Three Product Kernels/.test(coefficientAlgebra) && /Reusable Bernstein.?Gram Map/.test(markovPutinarMath) && /Sliding Tensor Windows/.test(sparseFullboxMath));
check("legacy mathematics routes and anchors", [bernsteinMath, griddingMath, sosMath].every((source) => /manual-trail/.test(source) && /^## Further Reading$/m.test(source) && /^## See Also$/m.test(source)) && [griddingMath, sosMath].every((source) => /^## Limitations$/m.test(source)) && /id="limitations"/.test(bernsteinMath) && /id="polya-type-coefficient-relaxation"/.test(sosMath) && /^### Worked full-box example: two parameters, degree three$/m.test(sosMath) && !/<span id="worked-full-box-example-two-parameters-degree-three"><\/span>/.test(sosMath) && /id="sparse-full-box-tensor-windows"/.test(sosMath) && /id="fixed-order-full-box-preordering"/.test(bernsteinMath));
check("diagnostic IDs include exact record kind", /slug\(`\$\{record\.id\}-\$\{record\.kind\}`\)/.test(diagnosticIndex));
check("canonical certificate names and symbols", !/Sparse Full Box|Full Box/.test(allSource) && /sliding tensor windows/.test(sparseFullboxMath) && /full-box preordering/i.test(sparseFullboxMath) && !/block[- ]band|usePolya\(p\)/i.test(sparseFullboxUserFacing));
check("source-indexed API inventory matches v1.3.7", referenceEntries.length === 192 && inventoryCounts["pdbase-backend"] === 49 && inventoryCounts.pdmat === 55 && inventoryCounts.pdvar === 52 && inventoryCounts.pdlmi === 22 && inventoryCounts["shared-helpers"] === 13 && inventoryCounts.setup === 1);
check("PDF-equivalent deterministic certificate workflow", /decisionDegree = 1×2 double[\s\S]*2\s+0[\s\S]*polyaIncrement = 1×2 double[\s\S]*0\s+1[\s\S]*elevatedDegree = 1×2 double[\s\S]*2\s+1[\s\S]*constraintCount = 6/.test(certificateSelection) && /directState = 1×3 double[\s\S]*0\s+0\s+3[\s\S]*defaultState = 1×3 double[\s\S]*1\s+1\s+5[\s\S]*putinarState = 1×3 double[\s\S]*1\s+1\s+5[\s\S]*higherState = 1×2 double[\s\S]*2\s+7/.test(certificateSelection) && /replacementState = 1×3 double[\s\S]*0\s+1\s+1[\s\S]*putinarReplacementState = 1×3 double[\s\S]*1\s+0\s+1[\s\S]*exportedConstraintCount = 5/.test(certificateSelection) && /sparsePutinar4State = 1×4 double[\s\S]*1\s+2\s+2\s+8[\s\S]*sparse4State = 1×4 double[\s\S]*1\s+2\s+2\s+8[\s\S]*direct4State = 1×3 double[\s\S]*0\s+0\s+5[\s\S]*full4State = 1×4 double[\s\S]*0\s+1\s+2\s+7/.test(certificateSelection) && /value-semantic/.test(certificateSelection) && /sol\.problem == 0/.test(certificateSelection) && /Equality wrappers use Direct assembly/.test(certificateSelection));
check("welcome known pdmat example is independent", /grid = \{\[0 0\.5 1\], \[0 1\]\}/.test(thirdHomeStep) && /A = pdmat/.test(thirdHomeStep) && /A\.LocalValues\{1\}\{1\}/.test(thirdHomeStep) && !/pdvar|rhodiff/.test(thirdHomeStep) && /A\.LocalValues/.test(cellExplorer));
check("deliberate responsive welcome math preserves intrinsic TeX metrics", /<KaTeXMath class="step-inline-math" tex=\{step\.inlineMath\}/.test(home) && /\.step-inline-math\s*\{[^}]*min-width:\s*0[^}]*padding-block/.test(home) && !/\.step-inline-math\s*\{[^}]*overflow-x:\s*auto|\.math-strip__row\s*\{[^}]*overflow-x:\s*auto/.test(home) && /math:\s*"\\\\mathcal F[\s\S]*=F_0\+\\\\sum_\{k=1\}\^\{N\}F_ky_k\+\\\\sum_\{k=1\}\^\{N\}\\\\sum_\{s=1\}\^\{\\\\ell\}[\s\S]*\\\\preceq0\."/ .test(firstHomeStep) && !/\\\\begin\{(?:aligned|gathered|split)\}|\\\\\\\\/.test(firstHomeStep) && !/\\(?:displaystyle|textstyle|scriptstyle|scriptscriptstyle|tiny|scriptsize|small|large|Large|LARGE|huge|Huge)\b/.test(firstHomeStep) && !/math:\s*\[/.test(firstHomeStep) && /math:\s*\[/.test(secondHomeStep + thirdHomeStep + fourthHomeStep) && /\\\\mathcal P=\\\\prod[\s\S]*\\\\qquad\\\\mathcal R=\\\\prod/.test(secondHomeStep) && !/I_s\^\{\(c_s\)\}/.test(secondHomeStep) && /\\\\prod_\{s=1\}\^\{\\\\ell\}\\\\binom\{m_s\}\{i_s\}/.test(thirdHomeStep) && !/b_s\(i_s,\\\\alpha_s\)/.test(thirdHomeStep) && /\.math-strip\s*\{[^}]*min-width:\s*0/.test(home) && /formulaMarkup:\s*item\.formula\.map/.test(chooserWrapper) && /option\.formulaMarkup\.map/.test(chooser));
check("synchronous SSR has no useEffect readiness or queue", /renderMath/.test(katexAstro + katexReact + katexRenderer) && /set:html/.test(katexAstro) && /dangerouslySetInnerHTML/.test(katexReact) && /export const DisplayMath/.test(katexReact) && /export const InlineMath/.test(katexReact) && !/\buseEffect\b|readiness|queue/i.test(katexAstro + katexReact + katexRenderer + astroConfig));
check("formula geometry matrix and static KaTeX contract", acceptanceViewports.length === 7 && /defaultViewports\s*=\s*\[320,\s*390,\s*700,\s*768,\s*1024,\s*1280,\s*1440\]/.test(geometryCheck) && /defaultThemes\s*=\s*\["light",\s*"dark"\]/.test(geometryCheck) && /formula-one-line/.test(geometryCheck) && /formula-unexpected-multiline/.test(geometryCheck) && /\.formula-math/.test(geometryCheck) && /\.katex/.test(geometryCheck) && /\.katex-display/.test(geometryCheck) && /formula-render-count/.test(geometryCheck) && /formula-readable/.test(geometryCheck) && /formula-hydration/.test(geometryCheck) && /formula-layout-shift/.test(geometryCheck) && /formula-bounds/.test(geometryCheck) && /narrow-constructor-coverage/.test(geometryCheck));
check("ordinary formulas use rendered containment instead of scrollbars", /"check:geometry":\s*"node scripts\/check-rendered-geometry\.mjs"/.test(packageJson) && !/\.formula-display\s*\{[^}]*overflow-x:\s*auto/.test(mathStyleSources) && !/cell-(?:summary__formula|summary__basis|basis-expression__formula|basis-readout p)\s*\{[^}]*overflow-x:\s*auto/.test(manualCss));
check("local formula scrolling stays limited to indivisible elevation and solver displays", (pdmatElevate.match(/className="elevate-direct-coefficient-scroll"/g)?.length ?? 0) === 1 && (solverSmoke.match(/className="solver-one-line"/g)?.length ?? 0) === 3 && /\.elevate-direct-coefficient-scroll\s*\{[^}]*max-width:\s*100%[^}]*overflow-x:\s*auto[^}]*\}/.test(manualCss) && /\.solver-one-line\s*\{[^}]*max-width:\s*100%[^}]*overflow-x:\s*auto[^}]*\}/.test(manualCss) && /"\.elevate-direct-coefficient-scroll, \.solver-one-line"/.test(geometryCheck) && /\["auto",\s*"scroll"\]\.includes\(localScrollerStyle\.overflowX\)/.test(geometryCheck) && /localScroller\.scrollWidth\s*>\s*localScroller\.clientWidth/.test(geometryCheck) && /isElevationScroller[\s\S]*innerWidth\s*<=\s*320\s*&&\s*!localScrollActive/.test(geometryCheck) && /isElevationScroller[\s\S]*innerWidth\s*>=\s*390\s*&&\s*localScrollActive/.test(geometryCheck) && /local-formula-scroll-bounds/.test(geometryCheck) && /local-formula-scroll-required/.test(geometryCheck) && /local-formula-scroll-unneeded/.test(geometryCheck) && !/\.formula-display\s*\{[^}]*overflow-x:\s*(?:auto|scroll)/.test(mathStyleSources));
check("named formula regressions stay direct", /P\^\{\(c\)\}\(\\rho\)[\s\S]*&=B_0\^1\(\\alpha\)P\^\{\(c\)\}\[0\][\s\S]*&\\quad\+B_1\^1\(\\alpha\)P\^\{\(c\)\}\[1\]\./.test(pdvarCtor) && !/\\mathcal F_\{\\mathrm\{alg\}\}|\\mathcal A_k|\\partial_s y_k|\\mathcal D_\{ks\}/.test(modelMath) && !/\\Gamma_\{p,q\}|T_[123]&:=|C_\{00\}&:=|\\mathcal J&:=/.test(pdlmiFullbox) && !/T_\{ij\}\^\{\(k\)\}|\\omega\(i,j;k\)/.test(pdvarAlgebra) && !/L_\{1[123]\}|L_\{2[23]\}|L_\{33\}/.test(solverSmoke));
check("intrinsic certificate formula width", /\.certificate-formula \.formula-display\s*\{[^}]*margin:\s*0[^}]*text-align:\s*start/.test(manualCss));
check("generated install and public maintainer identity", /versionInfo\.current/.test(install) && !/v0\.3\.3/.test(install) && /Yicheng Xu/.test(about) && /https:\/\/www\.ethanyxu\.com\//.test(about) && /portfolio-cta/.test(about) && /TheBigoranger/.test(about));
check("positive pdlmi implemented-behavior heading", !/^## Current Boundary\r?$/mi.test(pdlmiOverview) && /^## Implemented Behavior\r?$/mi.test(pdlmiOverview) && !/Reference Page Shape/.test(page("index.md")));
const plotHash = (file) => crypto.createHash("sha256").update(fs.readFileSync(path.join(root, "public/plots", file))).digest("hex").toUpperCase();
check("accepted v0.4.2 plots synchronized", plotHash("pdmat-plot-1d.png") === "C03C2833EDE515301880BC163CEDCD6E64F6937F287E15294FAC2E1A8C11A6B9" && plotHash("pdmat-plot-2d.png") === "109E2D5CEE899EAFC537FB06225EE2FFD6A38A6DA9AE41304157D1041FAD049B" && plotHash("pdmat-plot-2d-matrix.png") === "3832AD479EECB5484FB7F9E0B2A874BD91DF047B2F3579AC6FDEF9EE1A840D54" && ["two-by-one two-parameter", "FaceAlpha=0.62", "eastoutside", "crossingError", "ordering", "handleCount", "     2"].every((fragment) => pdmatPlot.includes(fragment)) && !fs.existsSync(path.join(root, "public/plots/pdmat-plot-3d-slice.png")));
check("Reference-first and nested API sidebars", /const sidebarOrder = \["Reference", "Learn", "Examples", "Welcome", "Install", "Citing", "Version History", "About", "Thanks"\]/.test(astroConfig) && /label: "Learn"[\s\S]*Learn And Reference Portal[\s\S]*Task And Example Lookup[\s\S]*label: "Notation"[\s\S]*DPD-LMI And LPV L2-Gain Model[\s\S]*Rate-Box Reduction And Interface Analysis[\s\S]*Gridding And Local Coordinates[\s\S]*Bernstein Basis, Continuity, And Storage[\s\S]*Coefficient Algebra[\s\S]*Certificate Map And Selection Guide[\s\S]*Direct And Pólya[\s\S]*Markov–Lukács And Putinar[\s\S]*SparsePutinar Tensor Windows[\s\S]*SparseFullBox And FullBox/.test(astroConfig) && /label: "Reference"[\s\S]*Generated API Lookup/.test(astroConfig) && /label: "Examples"[\s\S]*Certificate Selection[\s\S]*Solver Smoke Cases/.test(astroConfig) && !/label: "Math Concepts"/.test(astroConfig) && [/label: "pdmat"[\s\S]*label: "Matrix Operations"[\s\S]*documents\/reference\/pdmat\/matrix-operations/, /label: "pdvar"[\s\S]*label: "Matrix Operations"[\s\S]*documents\/reference\/pdvar\/matrix-operations/, /label: "pdlmi"[\s\S]*label: "Certificates"[\s\S]*label: "Pólya"[\s\S]*label: "Putinar"[\s\S]*label: "SparsePutinar"[\s\S]*label: "SparseFullBox"[\s\S]*label: "FullBox"/].every((pattern) => pattern.test(astroConfig)));
check("grouped lookup with direct single-symbol links", /ReferenceCategoryHub/.test(documentsHub) && /<table>/.test(referenceCategoryHub) && (referenceCategoryHub.match(/<th scope="col">/g)?.length ?? 0) === 4 && /<th scope="row">\{group\.label\}<\/th>/.test(referenceCategoryHub) && /referenceGroups\.map/.test(referenceCategoryHub) && /referenceEntries\.filter/.test(referenceCategoryHub) && /table-layout:\s*fixed/.test(referenceCategoryHub) && /data-label="Description"/.test(referenceCategoryHub) && /@media \(max-width: 620px\)[\s\S]*tbody tr\s*\{[^}]*display:\s*grid/.test(referenceCategoryHub) && !/overflow-x:\s*auto|tabindex=/.test(referenceCategoryHub) && (generatedReferenceIndex.match(/<details class="reference-index__group"/g)?.length ?? 0) === 6 && ["pdmat", "pdvar", "pdlmi", "pdbase-backend", "shared-helpers", "setup"].every((id) => generatedReferenceIndex.includes(`id="${id}"`)) && /referenceGroups\.map\(groupSection\)/.test(referenceGenerator) && /referenceEntries\.filter\(\(entry\) => entry\.group === group\.id\)/.test(referenceGenerator) && /reference-index__direct-symbol/.test(referenceGenerator) && /reference-index__symbols/.test(referenceGenerator) && /singleEntry/.test(referenceGenerator) && /source data lives in <code>src\/data\/reference-index\.js<\/code>/.test(generatedReferenceIndex) && !/<details class="reference-index__group"[^>]*\sopen(?:\s|>)/.test(generatedReferenceIndex) && !/reference-index__jump|jumpNav\(/.test(referenceGenerator + generatedReferenceIndex) && !/<details class="reference-index__family" open>/.test(referenceGenerator + generatedReferenceIndex) && !/\$\{entry\.name\}\s*—\s*\$\{anchor\}/.test(referenceGenerator));
check("aligned reference family rows", /\.reference-index__family-row\s*\{[^}]*align-items:\s*start/.test(manualCss) && /\.reference-index__family-heading\s*\{[^}]*align-items:\s*start/.test(manualCss) && /\.reference-index__family-content\s*\{[^}]*margin-block-start:\s*0/.test(manualCss) && !/\.reference-index__(?:family-row|family-heading|family-content)\s*\{[^}]*(?:^|[;{])\s*(?:block-size|height|transform)\s*:/m.test(manualCss));
check("reference lookup keeps readable mobile columns", /@media \(max-width: 620px\)[\s\S]*\.reference-index__group-summary\s*\{[^}]*grid-template-columns:\s*0\.55rem minmax\(0,\s*1fr\)/.test(manualCss) && /@media \(max-width: 620px\)[\s\S]*\.reference-index__direct-meta\s*\{[^}]*grid-template-columns:\s*minmax\(0,\s*1fr\)/.test(manualCss) && !/\.reference-index\s+summary\s*\{[^}]*display:\s*block/.test(manualCss) && !/\.reference-index__family\s*>\s*summary/.test(manualCss));
check("reference lookup preserves ASCII compounds without line breaks", /const wrapCompounds =/.test(referenceGenerator) && /wrapCompounds\(entry\.task\)/.test(referenceGenerator) && /wrapCompounds\(singleEntry\.task\)/.test(referenceGenerator) && /wrapCompounds\(group\.description\)/.test(referenceGenerator) && /wrapCompounds\("This generated lookup/.test(referenceGenerator) && /class="reference-index__compound">reference-page<\/span>/.test(generatedReferenceIndex) && /class="reference-index__compound">coefficient-backed<\/span>/.test(generatedReferenceIndex) && /<code>\{"npm --prefix webpage run generate:index"\}<\/code>/.test(generatedReferenceIndex) && !/npm —prefix/.test(generatedReferenceIndex) && /\.reference-index__compound\s*\{[^}]*white-space:\s*nowrap/.test(manualCss));
check("Bernstein backend utilities nested under pdbase", /label: "pdbase"[\s\S]*items: \[[\s\S]*Bernstein Backend Utilities[\s\S]*documents\/reference\/bernstein-utilities/.test(astroConfig) && !/\{ label: "Bernstein Utilities", slug: "documents\/reference\/bernstein-utilities" \}/.test(astroConfig));
check("split matrix-operation routes", [pdmatAlgebra, pdmatStructure, pdmatIndexing, pdvarAlgebra, pdvarStructure, pdvarIndexing].every((source) => /manual-trail/.test(source)) && ["plus", "mtimes", "transpose", "cat", "subsref", "isequal"].every((name) => pdmatOps.includes(`id="pdmat-${name}"`) && pdvarOps.includes(`id="pdvar-${name}"`)));
check("split operation reference depth", /bernTable\(K, \[1 1\], "oneLine"\)/.test(pdmatAlgebra) && /MultiplicationDiagram/.test(pdmatAlgebra) && /MatrixGlyphDiagram/.test(pdmatAlgebra) && /AdditionExplorer/.test(pdmatAlgebra) && /MultiplicationExplorer/.test(pdmatAlgebra) && /ExampleDisclosure/.test(pdvarAlgebra) && !/MultiplicationDiagram|MatrixGlyphDiagram/.test(pdvarAlgebra) && /numerical addition explorer/.test(pdvarAlgebra) && /numerical multiplication explorer/.test(pdvarAlgebra) && [pdmatAlgebra, pdvarAlgebra].every((source) => /\\binom/.test(source) && /```text/.test(source)) && [pdmatStructure, pdvarStructure].every((source) => (source.match(/MatrixGlyphDiagram/g)?.length ?? 0) >= 5 && (source.match(/```matlab/g)?.length ?? 0) >= 4 && (source.match(/```text/g)?.length ?? 0) >= 4) && [pdmatIndexing, pdvarIndexing].every((source) => /MatrixGlyphDiagram/.test(source) && /```matlab/.test(source) && /```text/.test(source) && /isequal/.test(source)));
check("current shared helpers and protected pdbase utilities documented", ["cellget", "chk", "combrows", "iszero", "mkgrid", "mknest", "normdeg", "normmode", "rateverts", "bernconvratios", "bernconvweights", "chkcont", "fitvals"].every((name) => sharedHelpers.includes(`id="helper-${name}"`)) && ["elevRow", "elevData", "prodVals", "bernTbl", "mapVals", "matSubs", "mapUnary"].every((name) => bernsteinUtilities.includes(name)) && /protected|backend/i.test(bernsteinUtilities));
check("comparison and equality contract", /complete original residual/.test(pdvarCompare) && /inclusive tolerance `1e-10`/.test(pdvarCompare) && /pdlmi:ElementwiseInequality/.test(pdvarCompare) && /column-major/.test(pdvarCompare) && /pdvar-comparison-eq/.test(pdvarCompare) && /ordinary operand compared with a derivative operand/.test(pdvarCompare) && /itself mixes ordinary and derivative row kinds across physical cells/.test(pdvarCompare) && /pdvar:MixedGrid/.test(pdvarCompare) && /pdvar:InvalidSubtraction/.test(pdvarCompare) && /pdlmi:UnsupportedEqualityCertificate/.test(pdvarCompare) && /V == V/.test(pdvarCompare) && /isequal/.test(pdvarCompare));
check("centered GitHub header control", /site-header__controls \{[^}]*border-inline-start:[^}]*padding-inline-start/.test(header) && /site-header__social \{[^}]*display: flex[^}]*width: 2\.25rem[^}]*height: 2\.25rem[^}]*align-items: center[^}]*justify-content: center/.test(header) && /site-header__social :global\(a\)[^}]*width: 2\.25rem[^}]*height: 2\.25rem/.test(header) && !/site-header__social::after/.test(header));
check("centered header search", /\.site-header \{[^}]*position:\s*relative/.test(header) && /site-header__search \{[^}]*position:\s*absolute[^}]*inset-inline-start:\s*50%[^}]*transform:\s*translateX\(-50%\)/.test(header) && /site-header__search :global\(site-search\)\s*\{[^}]*justify-content:\s*center/.test(header) && /site-header__brand \{[^}]*flex:\s*none/.test(header));
check("v1.3.7 current documentation and v1.3.0 latest tagged release", versionData.includes('current: "v1.3.7"') && (versionHistory.match(/version:\s*"v/g)?.length ?? 0) === 9 && /version:\s*"v1\.3\.7"[\s\S]*2026-08-10[\s\S]*current documentation/.test(versionHistory) && /version:\s*"v1\.3\.0"[\s\S]*latest tagged GitHub Release/.test(versionHistory) && /version:\s*"v1\.2\.4"[\s\S]*final v1\.2 documentation snapshot/.test(versionHistory) && /Documentation v1\.3\.7/.test(versionPage) && /v1\.3\.0 remains the latest\s+tagged GitHub Release/.test(versionPage) && install.includes("Latest GitHub Release (v1.3.0)"));
check("root-only installer and native transcript output", /adds only that repository root[\s\S]*adds the repository root directly[\s\S]*ordinary\s+subdirectories[\s\S]*Exact-path idempotence/.test(install) && !/fprintf\s*\(/.test(allSource));
check("welcome routes readers into Reference, Learn, and task lookup", !/Manual entrances|manualLinks|manual-entry-list/.test(home) && /label: "Reference"[\s\S]*label: "Learn"[\s\S]*label: "Task lookup"/.test(home));
check("legacy welcome workflow absent", !/WorkflowStepDiagram/.test(home));

if (failures.length > 0) {
  console.error("Visual contract failed:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(`Visual contract passed (${checkCount} checks).`);
