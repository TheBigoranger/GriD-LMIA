import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

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
const parameterCurve = component("ParameterCurveDiagram.astro");
const matrixGlyph = component("MatrixGlyphDiagram.astro");
const constraintAssembly = component("ConstraintAssemblyDiagram.astro");
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
const documentsHub = page("index.mdx");
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
const pdlmiOverview = page("reference/pdlmi/index.mdx");
const pdlmiCtor = page("reference/pdlmi/constructor.mdx");
const pdlmiPolya = page("reference/pdlmi/applypolya.mdx");
const pdlmiPutinar = page("reference/pdlmi/applyputinar.mdx");
const pdlmiFullbox = page("reference/pdlmi/applyfullboxpreorder.mdx");
const pdlmiYalmip = page("reference/pdlmi/toyalmip.mdx");
const sharedHelpers = page("reference/shared-helpers.md");
const versionHistory = read("src/data/version-history.js");
const versionData = read("src/data/version.js");

const astroConfig = read("astro.config.mjs");
const packageJson = read("package.json");
const manualCss = read("src/styles/manual.css");
const headerLinks = read("src/data/header-links.ts");
const certData = read("src/data/certificate-data.ts");
const multiplicationInput = read("src/lib/multiplication-input.ts");
const install = read("src/content/docs/install.mdx");
const about = read("src/content/docs/about.mdx");

const stepCount = home.match(/number:\s*"0[1-5]"/g)?.length ?? 0;
const visibleLines = [...home.matchAll(/visibleCode:\s*"([^"]*(?:\\"[^"]*)*)"/g)]
  .map((match) => match[1].split("\\n").length);
const failures = [];
let checkCount = 0;
const check = (name, condition) => {
  checkCount += 1;
  if (!condition) failures.push(name);
};

check("five-node forward-only journey", (journey.match(/<circle cx=/g)?.length ?? 0) === 5 && ["Form the DPD-LMI", "Grid the ρ-space", "Build constraints in each hypercube", "Select a certificate", "Export, solve, recover"].every((label) => journey.includes(label)) && /marker-end: url\(#journey-arrow\)/.test(journey) && !/feedback|journey-return|solved matrix/.test(journey));
check("accessible responsive journey SVG", /aria-labelledby="journey-title"[\s\S]*aria-describedby="journey-desc"/.test(journey) && /class="journey-desktop" aria-hidden="true"/.test(journey) && /journey-desktop svg[\s\S]*width: 100%[\s\S]*height: auto/.test(journey));
check("staggered journey cards", /journey-stage-map/.test(journey) && /li:nth-child\(odd\)[\s\S]*align-self: start/.test(journey) && /li:nth-child\(even\)[\s\S]*align-self: end/.test(journey) && /font-size: clamp/.test(journey) && !/<svg[\s\S]*<text/.test(journey) && /journey-leaders/.test(journey));
check("separate vertical mobile journey", /<ol class="journey-mobile" aria-hidden="true">/.test(journey) && /@media \(max-width: 700px\)[\s\S]*journey-desktop \{ display: none[\s\S]*journey-mobile \{ display: grid/.test(journey));
check("five welcome stages and required mathematics", stepCount === 5 && ["Form the DPD-LMI", "Grid the ρ-space", "Build constraints inside each hypercube", "Select a finite certificate", "Export, solve, and recover the decision matrix"].every((label) => home.includes(label)) && ["\\\\mathcal F(\\\\rho,\\\\dot\\\\rho)", "\\\\sum_{s=1}^{\\\\ell}", "\\\\mathcal H_{\\\\mathbf c}", "F^{(\\\\mathbf c,v)}", "toYalmip", "optimize", "value(P)"].every((fragment) => home.includes(fragment)));
check("static multiplication evidence", /Bernstein \[4, 2\][\s\S]*Bernstein \[0\.5, 3\][\s\S]*Bernstein \[2, 6\.5, 6\]/.test(multiply));
check("separated cell storage evidence", /physical grid[\s\S]*shared interface[\s\S]*global controls[\s\S]*cell-local leaves/.test(storage) && /LocalValues[\s\S]*i1[\s\S]*i2/.test(storage) && /\[0,0\]/.test(storage));
check("accessible full examples", /<details>[\s\S]*<summary>/.test(disclosure) && visibleLines.length === 4 && visibleLines.every((count) => count <= 2));
check("reference multiplication adoption", [bernsteinMath, pdmatAlgebra, pdvarAlgebra].every((source) => /MultiplicationDiagram/.test(source)));
check("reference storage adoption", [pdmatCtor, pdbaseStorage, griddingMath].every((source) => /CellStorageDiagram/.test(source)));
check("parameter curve static adoption", /series[\s\S]*marker[\s\S]*role="img"/.test(parameterCurve) && /ParameterCurveDiagram/.test(pdmatPlot));
check("matrix glyph structural adoption", /before[\s\S]*after[\s\S]*matrix-glyph/.test(matrixGlyph) && [pdmatStructure, pdvarStructure].every((source) => /MatrixGlyphDiagram/.test(source)));
check("pdvar decision evidence adoption", /decision-handles/.test(pdvarCtor) && /value-evidence/.test(pdvarValue) && /coefficient-row-map/.test(pdvarTable));
check("dedicated rhodiff detail reuse", /lower\/upper tensor order[\s\S]*Degree = m/.test(rhodiff) && [pdvarDiff, pdvarTable].every((source) => /RhodiffDiagram/.test(source)));
check("shared certificate detail navigation", [pdlmiCtor, pdlmiPolya, pdlmiPutinar, pdlmiFullbox].every((source) => /CertificateNavigation/.test(source) && /showSections=\{false\}/.test(source)) && [[pdlmiCtor, "direct"], [pdlmiPolya, "polya"], [pdlmiPutinar, "putinar"], [pdlmiFullbox, "fullbox"]].every(([source, selected]) => new RegExp(`selected="${selected}"`).test(source)) && ["direct", "polya", "putinar", "fullbox"].every((selected) => new RegExp(`selected="${selected}"`).test(sosMath)));
check("open YALMIP constraint composition", /coefficient-to-constraint[\s\S]*toYalmip[\s\S]*YALMIP constraints/.test(constraintAssembly) && /ConstraintAssemblyDiagram/.test(pdlmiYalmip));

check("official visible React islands", /@astrojs\/react/.test(packageJson) && /import react from "@astrojs\/react"/.test(astroConfig) && /react\(\)/.test(astroConfig) && /client:visible/.test(home) && /client:visible/.test(pdmatEval) && /client:visible/.test(chooserWrapper));
check("accessible mathematical explorers", [rateExplorer, elevationExplorer, tensorExplorer].every((source) => /role="alert"/.test(source) && /aria-live="polite"/.test(source)) && /RateVertexExplorer client:visible/.test(pdvarDiff) && /DegreeElevationExplorer client:visible/.test(bernsteinMath) && /TensorTraversalExplorer client:visible/.test(griddingMath) && /CertificateChooser/.test(sosMath));
check("interactive A hypercube storage", /aria-pressed/.test(cellExplorer) && /ArrowLeft[\s\S]*ArrowRight[\s\S]*ArrowUp[\s\S]*ArrowDown/.test(cellExplorer) && /c1: 1[\s\S]*c1: 2/.test(cellExplorer) && /A\.LocalValues/.test(cellExplorer) && /\[3 1; 1 3\]/.test(cellExplorer) && /\[7\/4 1\/8; 1\/8 2\]/.test(cellExplorer));
check("complete bordered coefficient cells", /\.cell-coeffs span\s*\{[^}]*border:\s*1px solid var\(--diagram-border\)[^}]*border-block-start:\s*2px solid var\(--sl-color-accent\)[^}]*border-radius:\s*8px/.test(manualCss));
check("bounded mobile storage connector", /@media \(max-width: 700px\)[\s\S]*\.cell-storage-connector\s*\{[^}]*width:\s*auto[^}]*height:\s*3\.2rem[^}]*grid-template-rows:\s*auto 1fr/.test(manualCss) && /\.cell-storage-connector i\s*\{[^}]*width:\s*0[^}]*height:\s*1\.7rem[^}]*border-block-start:\s*0[^}]*border-inline-start:[^}]*transform:\s*none/.test(manualCss) && /\.cell-storage-connector i::after\s*\{[^}]*inset-block-end:\s*0[^}]*border-block-end:\s*2px solid/.test(manualCss) && !/\.cell-storage-connector i\s*\{\s*transform:\s*rotate\(90deg\)/.test(manualCss));
check("interactive multiplication", /parseCoefficients/.test(multiplicationInput) && /useDeferredValue/.test(multiplyExplorer) && /role="alert"/.test(multiplyExplorer) && /BernsteinPlot/.test(multiplyExplorer));
check("independent multiplication errors", /errors\.left/.test(multiplyExplorer) && /errors\.right/.test(multiplyExplorer) && /aria-invalid/.test(multiplyExplorer));
check("bounded multiplication input", /maxMultiplicationCoefficients\s*=\s*256/.test(multiplicationInput) && /Use at most \$\{maxMultiplicationCoefficients\} coefficients per factor/.test(multiplicationInput) && /maxMultiplicationCoefficients/.test(multiplyExplorer));
check("actual multiplication contributions", /bernsteinContributionsAt/.test(multiplyExplorer) && /term\.weight/.test(multiplyExplorer) && /term\.value/.test(multiplyExplorer) && /<details[\s\S]*<summary>Show/.test(multiplyExplorer) && !/sum over i \+ j/.test(multiplyExplorer));
check("interactive cubic evaluate", /1 \+ 3ρ − 6ρ² \+ 4ρ³/.test(evaluateExplorer) && /requestAnimationFrame/.test(evaluateExplorer) && /querySelector\("svg"\)/.test(evaluateExplorer) && /clientXToUnit/.test(evaluateExplorer) && /role="slider"/.test(evaluateExplorer) && /EvaluateExplorer[\s\S]*client:visible/.test(pdmatEval));
check("quadratic-to-linear differentiation detail retained off welcome", /\[0\.8, 2\.2, 1\.4\][\s\S]*\[1\.4, −0\.2, 1\.8\][\s\S]*rhodiff[\s\S]*\[5\.6, −3\.2\][\s\S]*\[−6\.4, 8\]/.test(diffStorage) && !/DifferentiationStorage/.test(home));
check("interactive certificate overview", /CertificateChooser/.test(home) && /CertificateChooser/.test(pdlmiOverview) && /useState\(0\)/.test(chooser) && /role="tablist"/.test(chooser) && /selected\.toYalmip\(\)/.test(chooser));
check("equal-height certificate tabs without a default badge", /grid-auto-rows:\s*1fr/.test(manualCss) && /block-size:\s*5\.7rem/.test(manualCss) && !/certificate-default|>Default</.test(chooser) && !/showDefault|default-marker/.test(certificate));
check("shared certificate navigation contract", ["direct", "polya", "putinar", "full-box"].every((anchor) => certData.includes(`anchor: "${anchor}"`)) && ["L", "L.applyPolya(1)", "L.applyPutinar()", "L.applyFullBoxPreorder()"].every((command) => certData.includes(`command: "${command}"`)) && /CertificateNavigation/.test(pdlmiOverview) && /showSections \? `#\$\{item\.anchor\}`/.test(certificateNavigation) && /item\.detailRoute/.test(certificateNavigation) && /aria-current=\{isSelected \? "page"/.test(certificateNavigation));
check("header destinations", /Header: "\.\/src\/components\/Header\.astro"/.test(astroConfig) && ["Manual", "Download", "Examples", "About me"].every((label) => headerLinks.includes(`label: "${label}"`)) && /site-header__brand[\s\S]*site-header__search[\s\S]*site-header__links[\s\S]*site-header__controls/.test(header));
check("responsive header destinations", /<details[^>]*class="site-header__more/.test(header) && /<summary/.test(header) && /@media \(min-width: 72rem\)[\s\S]*site-header__more[\s\S]*display: none/.test(header));
check("global formula type scale", /(?<!sl-markdown-content )mjx-container\[display="true"\][\s\S]*font-size: 1\.5em/.test(manualCss) && /mjx-container:not\(\[display="true"\]\)[\s\S]*font-size: 1em[\s\S]*line-height: inherit[\s\S]*margin: 0[\s\S]*vertical-align/.test(manualCss) && !/max-width: 520px[\s\S]*mjx-container\[display="true"\][^}]*font-size/.test(manualCss));
check("external plot legends", /plot-legend[\s\S]*<svg/.test(component("BernsteinPlot.tsx")) && /plot-legend[\s\S]*<svg/.test(parameterCurve) && !/<text[^>]*>\{item\.label\}/.test(parameterCurve) && !/<text[^>]*>\{marker\.label\}/.test(parameterCurve) && /<div class="curve-legend"[\s\S]*<\/div>[\s\S]*<svg/.test(multiply) && !/curve-labels/.test(multiply));
check("aligned multiplication header and legend", /multiplication-formulas[\s\S]*grid-template-columns: minmax\(0, 0\.85fr\) minmax\(0, 1\.15fr\)/.test(multiply) && /multiplication-formulas > div[^{]*\{[^}]*margin: 0/.test(multiply) && /curve-legend[\s\S]*grid-template-columns: repeat\(3, minmax\(0, 1fr\)\)[\s\S]*align-items: stretch/.test(multiply) && /curve-copy[\s\S]*height: 100%[\s\S]*min-height: 4\.4rem/.test(multiply) && /@media \(max-width: 560px\)[\s\S]*multiplication-formulas,[\s\S]*curve-legend[\s\S]*grid-template-columns: 1fr/.test(multiply));
check("canonical notation", /\\rho_s\^\{\(j\)\}/.test(griddingMath) && /\\mathbf c=\(c_1,\\ldots,c_\\ell\)/.test(griddingMath) && /C\^\{\(\\mathbf c\)\}\[\\mathbf i\]/.test(griddingMath) && /B_i\^m/.test(bernsteinMath));
check("canonical axis node counts", [griddingMath, bernsteinMath].every((source) => /k_s/.test(source) && !/N_(?:\d|\\ell|r)/.test(source)));
check("unambiguous tensor and derivative notation", /physical node has multi-index[\s\S]*\\mathbf j/.test(bernsteinMath) && /width \$h_c=/.test(bernsteinMath) && !/width \$h=/.test(bernsteinMath));
check("canonical cell-local function notation", !/P_c|Q_c|dP_c/.test(bernsteinMath) && /P\^\{\(c\)\}/.test(bernsteinMath) && !/P_\{?[0-9i]/.test(pdvarCtor) && /P\^\{\(c\)\}\[i\]/.test(pdvarCtor));
check("dimension-aware Putinar contract", [certData, pdlmiOverview, pdlmiPutinar, pdlmiCtor, sosMath, bernsteinMath].every((source) => /Markov[–-]Luk[aá]cs/.test(source) && /floor|\\lfloor/.test(source) && /two or more|\\ell\\ge2|\\ell\s*\\ge\s*2/.test(source) && /ceil|\\lceil/.test(source)));
check("cell-indexed DPD-LMI workflow", ["\\\\mathcal F(\\\\rho,\\\\dot\\\\rho)", "\\\\mathcal H_{\\\\mathbf c}=", "F^{(\\\\mathbf c,v)}(\\\\alpha)\\\\preceq0", "selected.toYalmip()"].every((fragment) => home.includes(fragment)) && /every cell-and-rate pair/.test(home));
check("welcome begins from the general DPD-LMI", /\\\\mathcal F\(\\\\rho,\\\\dot\\\\rho\)/.test(home) && /R_i\(\\\\rho\)/.test(home) && /F_i\(\\\\rho\)x_i\(\\\\rho\)/.test(home) && !/\\\\dot P\(\\\\rho\(t\)\)\+P\(\\\\rho\)A\(\\\\rho\)/.test(home));
check("welcome A example is wired to both cells", /grid = \{\[0 0\.5 1\], \[0 1\]\}/.test(home) && /A = pdmat/.test(home) && /A\.LocalValues\{c1\}\{1\}/.test(home));
check("stacked mobile display math", home.includes('number: "01"') && home.includes('number: "05"') && (home.match(/math: \[/g)?.length ?? 0) >= 3 && /item\.formula\.map\(renderDisplayMath\)/.test(chooserWrapper) && /option\.mathHtml\.map/.test(chooser) && /key:\s*"putinar"[\s\S]*?formula:\s*\[/.test(certData) && !/key:\s*"putinar"[^\n]*\\qquad/.test(certData));
check("intrinsic certificate MathJax width", /\.diagram-frame \.certificate-formula svg\s*\{[^}]*width:\s*auto[^}]*max-width:\s*100%[^}]*height:\s*auto/.test(manualCss));
check("generated install and public maintainer identity", /versionInfo\.current/.test(install) && !/v0\.3\.3/.test(install) && /Yicheng Xu/.test(about) && /https:\/\/www\.ethanyxu\.com\//.test(about) && /portfolio-cta/.test(about) && /TheBigoranger/.test(about));
check("positive pdlmi implemented-behavior heading", !/^## (?:Validation And )?Limitations\r?$/mi.test(allSource) && !/^## Current Boundary\r?$/mi.test(pdlmiOverview) && /^## Implemented Behavior\r?$/mi.test(pdlmiOverview) && !/Reference Page Shape/.test(page("index.md")));
const plotHash = (file) => crypto.createHash("sha256").update(fs.readFileSync(path.join(root, "public/plots", file))).digest("hex").toUpperCase();
check("accepted v0.4.2 plots synchronized", plotHash("pdmat-plot-1d.png") === "C03C2833EDE515301880BC163CEDCD6E64F6937F287E15294FAC2E1A8C11A6B9" && plotHash("pdmat-plot-2d.png") === "109E2D5CEE899EAFC537FB06225EE2FFD6A38A6DA9AE41304157D1041FAD049B" && plotHash("pdmat-plot-2d-matrix.png") === "3832AD479EECB5484FB7F9E0B2A874BD91DF047B2F3579AC6FDEF9EE1A840D54" && ["two-by-one two-parameter", "FaceAlpha=0.62", "eastoutside", "crossingError", "ordering", "handleCount", "     2"].every((fragment) => pdmatPlot.includes(fragment)) && !fs.existsSync(path.join(root, "public/plots/pdmat-plot-3d-slice.png")));
check("nested operation and certificate sidebars", [/label: "pdmat"[\s\S]*label: "Matrix Operations"[\s\S]*items: \[[\s\S]*documents\/reference\/pdmat\/matrix-operations/, /label: "pdvar"[\s\S]*label: "Matrix Operations"[\s\S]*items: \[[\s\S]*documents\/reference\/pdvar\/matrix-operations/, /label: "pdlmi"[\s\S]*label: "toYalmip"[\s\S]*label: "Certificates"[\s\S]*label: "Pólya"[\s\S]*label: "Putinar"[\s\S]*label: "Full Box"/].every((pattern) => pattern.test(astroConfig)));
check("categorized three-level lookup view", /ReferenceCategoryHub/.test(documentsHub) && /referenceGroups/.test(referenceIndex) && ["pdmat", "pdvar", "pdlmi", "pdbase-backend", "shared-helpers"].every((group) => referenceIndex.includes(`id: "${group}"`)) && /reference-index__group[\s\S]*open/.test(read("scripts/generate-reference-index.mjs")) && /reference-index__family[\s\S]*open/.test(read("scripts/generate-reference-index.mjs")) && /reference-index__symbols/.test(read("scripts/generate-reference-index.mjs")));
check("Bernstein backend utilities nested under pdbase", /label: "pdbase"[\s\S]*items: \[[\s\S]*Bernstein Backend Utilities[\s\S]*documents\/reference\/bernstein-utilities/.test(astroConfig) && !/\{ label: "Bernstein Utilities", slug: "documents\/reference\/bernstein-utilities" \}/.test(astroConfig));
check("split matrix-operation routes", [pdmatAlgebra, pdmatStructure, pdmatIndexing, pdvarAlgebra, pdvarStructure, pdvarIndexing].every((source) => /manual-trail/.test(source)) && ["plus", "mtimes", "transpose", "cat", "subsref", "isequal"].every((name) => pdmatOps.includes(`id="pdmat-${name}"`) && pdvarOps.includes(`id="pdvar-${name}"`)));
check("split operation reference depth", [pdmatAlgebra, pdvarAlgebra].every((source) => /ExampleDisclosure/.test(source) && /MultiplicationDiagram/.test(source) && /MatrixGlyphDiagram/.test(source) && /\\binom/.test(source) && /```text/.test(source)) && [pdmatStructure, pdvarStructure].every((source) => (source.match(/MatrixGlyphDiagram/g)?.length ?? 0) >= 5 && (source.match(/```matlab/g)?.length ?? 0) >= 4 && (source.match(/```text/g)?.length ?? 0) >= 4) && [pdmatIndexing, pdvarIndexing].every((source) => /MatrixGlyphDiagram/.test(source) && /```matlab/.test(source) && /```text/.test(source) && /isequal/.test(source)));
check("all shared helpers documented", ["berntbl", "cellget", "chk", "combrows", "iszero", "mapvals", "matsubs", "mkgrid", "mknest"].every((name) => sharedHelpers.includes(`id="helper-${name}"`)) && /backend-only|implementation utilities/.test(sharedHelpers));
check("comparison and equality contract", /complete original residual/.test(pdvarCompare) && /inclusive tolerance `1e-10`/.test(pdvarCompare) && /pdlmi:ElementwiseInequality/.test(pdvarCompare) && /column-major/.test(pdvarCompare) && /pdvar-comparison-eq/.test(pdvarCompare) && /ordinary operand compared with a derivative operand/.test(pdvarCompare) && /itself mixes ordinary and derivative row kinds across physical cells/.test(pdvarCompare) && /pdvar:MixedGrid/.test(pdvarCompare) && /pdvar:InvalidSubtraction/.test(pdvarCompare) && /pdlmi:UnsupportedEqualityCertificate/.test(pdvarCompare) && /V == V/.test(pdvarCompare) && /isequal/.test(pdvarCompare));
check("centered GitHub header control", /site-header__controls \{[^}]*border-inline-start:[^}]*padding-inline-start/.test(header) && /site-header__social \{[^}]*display: flex[^}]*width: 2\.25rem[^}]*height: 2\.25rem[^}]*align-items: center[^}]*justify-content: center/.test(header) && /site-header__social :global\(a\)[^}]*width: 2\.25rem[^}]*height: 2\.25rem/.test(header) && !/site-header__social::after/.test(header));
check("content-aligned header search", /site-header__links \{[^}]*margin-inline-start:\s*auto/.test(header) && /site-header__more \{[^}]*margin-inline-start:\s*auto/.test(header) && /site-header__search \{[^}]*margin-inline-start:\s*0/.test(header) && /site-header__brand \{[^}]*flex:\s*none/.test(header));
check("v0.4.7 public metadata with retained minor history", /current:\s*"v0\.4\.7"/.test(versionData) && /Version 0\.4\.7/.test(pdlmiOverview) && (versionHistory.match(/version:\s*"v/g)?.length ?? 0) === 4 && ["v0.1.0", "v0.2.12", "v0.3.6", "v0.4.4"].every((version) => versionHistory.includes(`version: "${version}"`)) && ["63c06ee", "98b63e5", "fe74a65"].every((commit) => versionHistory.includes(commit)) && !["v0.2.0", "v0.3.0", "v0.3.5", "v0.4.1", "v0.4.2", "v0.4.3", "v0.4.7"].some((version) => versionHistory.includes(`version: "${version}"`)) && /version:\s*"v0\.4\.4"[\s\S]*date:\s*"2026-07-18"/.test(versionHistory));
check("welcome manual cards removed", !/Manual entrances|manualLinks|manual-entry-list/.test(home) && /Open manual/.test(home));
check("legacy welcome workflow absent", !/WorkflowStepDiagram/.test(home));

if (failures.length > 0) {
  console.error("Visual contract failed:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(`Visual contract passed (${checkCount} checks).`);
