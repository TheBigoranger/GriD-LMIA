import fs from "node:fs";
import path from "node:path";

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
const header = component("Header.astro");

const pdmatCtor = page("reference/pdmat/constructor.mdx");
const pdmatEval = page("reference/pdmat/evaluate.mdx");
const pdmatPlot = page("reference/pdmat/plot.mdx");
const pdmatOps = page("reference/pdmat/matrix-operations.mdx");
const pdvarCtor = page("reference/pdvar/constructor.mdx");
const pdvarValue = page("reference/pdvar/value.mdx");
const pdvarTable = page("reference/pdvar/bernsteintable.mdx");
const pdvarCompare = page("reference/pdvar/comparisons.mdx");
const pdvarOps = page("reference/pdvar/matrix-operations.mdx");
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
const check = (name, condition) => {
  if (!condition) failures.push(name);
};

check("curved four-stage hero", /PD-LMI model[\s\S]*cell-local data[\s\S]*finite certificate[\s\S]*YALMIP \/ SDP/.test(journey));
check("five welcome steps", stepCount === 5);
check("static multiplication evidence", /Bernstein \[1, 3\][\s\S]*Bernstein \[2, 4\][\s\S]*Bernstein \[2, 5, 12\]/.test(multiply));
check("static cell storage evidence", />\[0,0\]</.test(storage) && /LocalValues\{i1\}\{i2\}/.test(storage));
check("accessible full examples", /<details>[\s\S]*<summary>/.test(disclosure) && visibleLines.length === 4 && visibleLines.every((count) => count <= 2));
check("reference multiplication adoption", [bernsteinMath, pdmatOps, pdvarOps].every((source) => /MultiplicationDiagram/.test(source)));
check("reference storage adoption", [pdmatCtor, pdbaseStorage, griddingMath].every((source) => /CellStorageDiagram/.test(source)));
check("parameter curve static adoption", /series[\s\S]*marker[\s\S]*role="img"/.test(parameterCurve) && [pdmatPlot, pdvarCompare].every((source) => /ParameterCurveDiagram/.test(source)));
check("matrix glyph structural adoption", /before[\s\S]*after[\s\S]*matrix-glyph/.test(matrixGlyph) && [pdmatOps, pdvarOps].every((source) => /MatrixGlyphDiagram/.test(source)));
check("pdvar decision evidence adoption", /decision-handles/.test(pdvarCtor) && /value-evidence/.test(pdvarValue) && /coefficient-row-map/.test(pdvarTable));
check("dedicated rhodiff detail reuse", /lower\/upper tensor order[\s\S]*Degree = m/.test(rhodiff) && [pdvarDiff, pdvarTable].every((source) => /RhodiffDiagram/.test(source)));
check("static certificate detail adoption", /selected:\s*"direct"\s*\|\s*"polya"\s*\|\s*"putinar"\s*\|\s*"fullbox"/.test(certificate) && /selected="direct"[\s\S]*showDefault/.test(pdlmiCtor) && /selected="polya"/.test(pdlmiPolya) && /selected="putinar"/.test(pdlmiPutinar) && /selected="fullbox"/.test(pdlmiFullbox) && ["direct", "polya", "putinar", "fullbox"].every((selected) => new RegExp(`selected="${selected}"`).test(sosMath)));
check("open YALMIP constraint composition", /coefficient-to-constraint[\s\S]*toYalmip[\s\S]*YALMIP constraints/.test(constraintAssembly) && /ConstraintAssemblyDiagram/.test(pdlmiYalmip));

check("official visible React islands", /@astrojs\/react/.test(packageJson) && /import react from "@astrojs\/react"/.test(astroConfig) && /react\(\)/.test(astroConfig) && /client:visible/.test(home) && /client:visible/.test(pdmatEval) && /client:visible/.test(chooserWrapper));
check("interactive storage", /aria-pressed/.test(cellExplorer) && /LocalValues/.test(cellExplorer) && /\[0, 1, 2\]/.test(cellExplorer));
check("interactive multiplication", /parseCoefficients/.test(multiplicationInput) && /useDeferredValue/.test(multiplyExplorer) && /role="alert"/.test(multiplyExplorer) && /BernsteinPlot/.test(multiplyExplorer));
check("independent multiplication errors", /errors\.left/.test(multiplyExplorer) && /errors\.right/.test(multiplyExplorer) && /aria-invalid/.test(multiplyExplorer));
check("bounded multiplication input", /maxMultiplicationCoefficients\s*=\s*256/.test(multiplicationInput) && /Use at most \$\{maxMultiplicationCoefficients\} coefficients per factor/.test(multiplicationInput) && /maxMultiplicationCoefficients/.test(multiplyExplorer));
check("actual multiplication contributions", /bernsteinContributionsAt/.test(multiplyExplorer) && /term\.weight/.test(multiplyExplorer) && /term\.value/.test(multiplyExplorer) && /<details[\s\S]*<summary>Show/.test(multiplyExplorer) && !/sum over i \+ j/.test(multiplyExplorer));
check("interactive cubic evaluate", /1 \+ 3ρ − 6ρ² \+ 4ρ³/.test(evaluateExplorer) && /requestAnimationFrame/.test(evaluateExplorer) && /querySelector\("svg"\)/.test(evaluateExplorer) && /clientXToUnit/.test(evaluateExplorer) && /role="slider"/.test(evaluateExplorer) && /EvaluateExplorer[\s\S]*client:visible/.test(pdmatEval));
check("static differentiation storage", /\[P₀, P₁, P₂\][\s\S]*−2\(P₁−P₀\)[\s\S]*\+2\(P₁−P₀\)/.test(diffStorage) && /DifferentiationStorage/.test(home));
check("interactive certificate overview", /CertificateChooser/.test(home) && /CertificateChooser/.test(pdlmiOverview) && /useState\(0\)/.test(chooser) && /role="tablist"/.test(chooser) && /key: "direct"/.test(certData));
check("header destinations", /Header: "\.\/src\/components\/Header\.astro"/.test(astroConfig) && ["Manual", "Download", "Examples", "About me"].every((label) => headerLinks.includes(`label: "${label}"`)) && ["SiteTitle", "Search", "SocialIcons", "ThemeSelect", "LanguageSelect"].every((name) => header.includes(name)));
check("responsive header destinations", /<details[^>]*class="site-header__more/.test(header) && /<summary/.test(header) && /@media \(min-width: 72rem\)[\s\S]*site-header__more[\s\S]*display: none/.test(header));
check("formula type scale", /mjx-container\[display="true"\][\s\S]*font-size: 2rem/.test(manualCss) && /max-width: 520px[\s\S]*mjx-container\[display="true"\][^}]*font-size: 1\.5rem/.test(manualCss) && /mjx-container:not\(\[display="true"\]\)[\s\S]*font-size: 1em/.test(manualCss));
check("external plot legends", /plot-legend[\s\S]*<svg/.test(component("BernsteinPlot.tsx")) && /plot-legend[\s\S]*<svg/.test(parameterCurve) && !/<text[^>]*>\{item\.label\}/.test(parameterCurve) && !/<text[^>]*>\{marker\.label\}/.test(parameterCurve) && /curve-copy[\s\S]*<svg/.test(multiply) && !/curve-labels/.test(multiply));
check("canonical notation", /\\rho_s\^\{\(j\)\}/.test(griddingMath) && /\\mathbf c=\(c_1,\\ldots,c_\\ell\)/.test(griddingMath) && /C\^\{\(\\mathbf c\)\}\[\\mathbf i\]/.test(griddingMath) && /B_i\^m/.test(bernsteinMath));
check("canonical axis node counts", [griddingMath, bernsteinMath].every((source) => /k_s/.test(source) && !/N_(?:\d|\\ell|r)/.test(source)));
check("unambiguous tensor and derivative notation", /physical node has multi-index[\s\S]*\\mathbf j/.test(bernsteinMath) && /width \$h_c=/.test(bernsteinMath) && !/width \$h=/.test(bernsteinMath));
check("canonical cell-local function notation", !/P_c|Q_c|dP_c/.test(bernsteinMath) && /P\^\{\(c\)\}/.test(bernsteinMath) && !/P_\{?[0-9i]/.test(pdvarCtor) && /P\^\{\(c\)\}\[i\]/.test(pdvarCtor));
check("dimension-aware Putinar contract", [certData, pdlmiOverview, pdlmiPutinar, pdlmiCtor, sosMath, bernsteinMath].every((source) => /Markov[–-]Luk[aá]cs/.test(source) && /floor|\\lfloor/.test(source) && /two or more|\\ell\\ge2|\\ell\s*\\ge\s*2/.test(source) && /ceil|\\lceil/.test(source)));
check("stacked mobile display math", /number:\s*"04"[\s\S]*?math:\s*\[[\s\S]*?\\Delta P[\s\S]*?number:\s*"05"[\s\S]*?math:\s*\[[\s\S]*?finite Gram constraints/.test(home) && /item\.formula\.map\(renderDisplayMath\)/.test(chooserWrapper) && /option\.mathHtml\.map/.test(chooser) && /key:\s*"putinar"[\s\S]*?formula:\s*\[/.test(certData) && !/key:\s*"putinar"[^\n]*\\qquad/.test(certData));
check("intrinsic certificate MathJax width", /\.diagram-frame \.certificate-formula svg\s*\{[^}]*width:\s*auto[^}]*max-width:\s*100%[^}]*height:\s*auto/.test(manualCss));
check("generated install and project about", /versionInfo\.current/.test(install) && !/v0\.3\.3/.test(install) && /TheBigoranger/.test(about));
check("welcome manual cards removed", !/Manual entrances|manualLinks|manual-entry-list/.test(home) && /Open manual/.test(home));
check("legacy welcome workflow absent", !/WorkflowStepDiagram/.test(home));

if (failures.length > 0) {
  console.error("Visual contract failed:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log("Visual contract passed (36 checks).");
