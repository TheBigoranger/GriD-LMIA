import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");
const readOptional = (file) => {
  const target = path.join(root, file);
  return fs.existsSync(target) ? fs.readFileSync(target, "utf8") : "";
};
const sourceRoot = path.join(root, "src");
const sourceFiles = fs.readdirSync(sourceRoot, { recursive: true })
  .filter((file) => /\.(astro|md|mdx)$/.test(file));
const allSource = sourceFiles
  .map((file) => fs.readFileSync(path.join(sourceRoot, file), "utf8"))
  .join("\n");
const home = read("src/components/HomePortal.astro");
const journey = read("src/components/JourneyCurve.astro");
const storage = read("src/components/CellStorageDiagram.astro");
const multiply = read("src/components/MultiplicationDiagram.astro");
const disclosure = read("src/components/ExampleDisclosure.astro");
const rhodiff = readOptional("src/components/RhodiffDiagram.astro");
const certificate = readOptional("src/components/CertificateSpectrum.astro");
const parameterCurve = readOptional("src/components/ParameterCurveDiagram.astro");
const matrixGlyph = readOptional("src/components/MatrixGlyphDiagram.astro");
const constraintAssembly = readOptional("src/components/ConstraintAssemblyDiagram.astro");

const page = (file) => readOptional(`src/content/docs/documents/${file}`);
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

const stepCount = home.match(/number:\s*"0[1-5]"/g)?.length ?? 0;
const localLabels = storage.match(/>\[[0-2],[0-2]\]</g)?.length ?? 0;
const sharedControls = storage.match(/class="coeff coeff--shared"/g)?.length ?? 0;
const visibleLines = [...home.matchAll(/visibleCode:\s*"([^"]*(?:\\"[^"]*)*)"/g)]
  .map((match) => match[1].split("\\n").length);

const contracts = [
  ["curved four-stage hero", /M58 298 C170[\s\S]*PD-LMI model[\s\S]*cell-local data[\s\S]*finite certificate[\s\S]*YALMIP \/ SDP/, journey],
  ["five welcome steps", stepCount === 5],
  ["exact multiplication coefficients", /Bernstein \[1, 3\][\s\S]*Bernstein \[2, 4\][\s\S]*Bernstein \[2, 5, 12\]/, multiply],
  ["exact product curve and formulas", /R\(ρ\) = 2 \+ 6ρ \+ 4ρ²[\s\S]*d="M60 215 C320 180 580 121\.667 840 40"[\s\S]*\(1·4 \+ 3·2\) \/ 2 = 5/, multiply],
  ["selected 3-by-3 degree-two storage", localLabels === 9 && /shared continuous face[\s\S]*LocalValues\{i1\}\{i2\}/.test(storage)],
  ["one shared interface control", sharedControls === 1 && /five global controls[\s\S]*cell 1 label \[2\][\s\S]*cell 2 label \[0\]/.test(storage)],
  ["truthful ell-2 rate storage", /\(−1, −1\)[\s\S]*\(−1, \+1\)[\s\S]*\(\+1, −1\)[\s\S]*\(\+1, \+1\)/.test(home + rhodiff) && /axis-wise partials have different tensor degree vectors[\s\S]*common degree-m tensor basis[\s\S]*rate-weight and sum/.test(home + rhodiff) && !/mixed partial/i.test(home + rhodiff)],
  ["Direct is the selected default", /class="certificate-spectrum"[\s\S]*<strong class="selected" aria-current="true"><span>Default<\/span>Direct<\/strong[\s\S]*<strong>Pólya<\/strong><strong>Putinar<\/strong><strong>Full Box<\/strong>/.test(home) || /<CertificateSpectrum selected="direct" showDefault/.test(home) && /aria-current=\{isSelected/.test(certificate)],
  ["accessible full examples", /<details>[\s\S]*<summary>/.test(disclosure) && visibleLines.length === 4 && visibleLines.every((count) => count <= 2)],
  ["no legacy welcome workflow", /^(?![\s\S]*WorkflowStepDiagram)/],
  ["reference multiplication adoption", [bernsteinMath, pdmatOps, pdvarOps].every((source) => /MultiplicationDiagram/.test(source))],
  ["reference storage adoption", [pdmatCtor, pdbaseStorage, griddingMath].every((source) => /CellStorageDiagram/.test(source))],
  ["parameter curve semantics and adoption", /series[\s\S]*marker[\s\S]*role="img"/.test(parameterCurve) && [pdmatEval, pdmatPlot, pdvarCompare].every((source) => /ParameterCurveDiagram/.test(source))],
  ["matrix glyph structural adoption", /before[\s\S]*after[\s\S]*matrix-glyph/.test(matrixGlyph) && [pdmatOps, pdvarOps].every((source) => /MatrixGlyphDiagram/.test(source))],
  ["pdvar decision evidence adoption", /decision-handles/.test(pdvarCtor) && /value-evidence/.test(pdvarValue) && /coefficient-row-map/.test(pdvarTable)],
  ["dedicated rhodiff reuse", /lower\/upper tensor order[\s\S]*Degree = m/.test(rhodiff) && [home, pdvarDiff, pdvarTable].every((source) => /RhodiffDiagram/.test(source))],
  ["certificate selected-state adoption", /selected:\s*"direct"\s*\|\s*"polya"\s*\|\s*"putinar"\s*\|\s*"fullbox"/.test(certificate) && /selected="direct"[\s\S]*showDefault/.test(pdlmiOverview) && /selected="direct"[\s\S]*showDefault/.test(pdlmiCtor) && /selected="polya"/.test(pdlmiPolya) && /selected="putinar"/.test(pdlmiPutinar) && /selected="fullbox"/.test(pdlmiFullbox) && ["direct", "polya", "putinar", "fullbox"].every((selected) => new RegExp(`selected="${selected}"`).test(sosMath))],
  ["open YALMIP constraint composition", /coefficient-to-constraint[\s\S]*toYalmip[\s\S]*YALMIP constraints/.test(constraintAssembly) && /ConstraintAssemblyDiagram/.test(pdlmiYalmip)],
  ["legacy visual consumers retired", !/WorkflowStepDiagram|MatrixOperationDiagram|CertificateDiagram|ConvolutionDiagram|PdmatStorageDiagram|GriddingDiagram/.test(allSource)],
  ["legacy visual files removed", ["WorkflowStepDiagram.astro", "MatrixOperationDiagram.astro", "CertificateDiagram.astro", "ConvolutionDiagram.astro", "PdmatStorageDiagram.astro", "GriddingDiagram.astro"].every((file) => !fs.existsSync(path.join(root, "src/components", file)))],
];

const failures = contracts
  .filter(([, condition, source = home]) => typeof condition === "boolean" ? !condition : !condition.test(source))
  .map(([name]) => name);

if (failures.length > 0) {
  console.error("Visual contract failed:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(`Visual contract passed (${contracts.length} checks).`);
