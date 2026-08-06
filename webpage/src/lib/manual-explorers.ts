import { evaluateBernstein, parseCoefficients, sampleBernstein } from "./bernstein.ts";

export type CertificateSelector = "direct" | "polya" | "putinar" | "sparseputinar" | "sparsefullbox" | "fullbox";
export type CertificateMode = "semidefinite" | "elementwise";

export interface RateVertexModel {
  bounds: readonly (readonly [number, number])[];
  vertices: number[][];
  coefficientColumns: number;
}

export interface ElevationModel {
  original: number[];
  elevated: number[];
  increment: number;
  maximumSampleError: number;
}

export interface TensorModel {
  nodes: number[];
  degree: number;
  nodeCount: number;
  cellCount: number;
  coefficientsPerCell: number;
  cells: number[][];
  labels: number[][];
}

export interface GramBlockShape {
  label: string;
  gramDegree: number[];
  dimension: number;
}

export interface CertificateShape {
  selector: CertificateSelector;
  effectiveSelector: CertificateSelector;
  targetDegree: number | number[];
  coefficientTests: number;
  coefficientIdentities: number;
  psdBlocks: number;
  totalConstraints: number;
  blocks: GramBlockShape[];
  copies: number;
  minimumOrder: number | number[];
  cliqueSize: number;
  bandWidth: number;
}

/** Cartesian rows in helper.combRows order: earlier axes vary more slowly. */
export function combinationRows<T>(axes: readonly (readonly T[])[]): T[][] {
  if (axes.length === 0 || axes.some((axis) => axis.length === 0)) {
    throw new TypeError("Every tensor axis must contain at least one value.");
  }
  return axes.reduce<T[][]>((rows, axis) => rows.flatMap((row) => axis.map((value) => [...row, value])), [[]]);
}

export function parseRateBounds(input: string, coefficientColumns: number): RateVertexModel {
  if (!Number.isInteger(coefficientColumns) || coefficientColumns < 1 || coefficientColumns > 64) {
    throw new RangeError("Coefficient columns must be an integer from 1 to 64.");
  }
  const rows = input.split(/[;\n]+/).map((row) => row.trim()).filter(Boolean);
  if (rows.length < 1 || rows.length > 3) throw new RangeError("Enter one to three rate-bound rows.");
  const bounds = rows.map((row) => {
    const values = row.split(/[\s,]+/).filter(Boolean).map(Number);
    if (values.length !== 2 || values.some((value) => !Number.isFinite(value)) || values[0] > values[1]) {
      throw new TypeError("Each row needs finite lower and upper bounds with lower ≤ upper.");
    }
    return values as [number, number];
  });
  return { bounds, vertices: combinationRows(bounds), coefficientColumns };
}

/** One-dimensional normalized Bernstein elevation, applied one degree at a time. */
export function elevateBernstein(coefficients: readonly number[], increment: number): number[] {
  if (coefficients.length === 0 || coefficients.some((value) => !Number.isFinite(value))) {
    throw new TypeError("Elevation requires finite coefficients.");
  }
  if (!Number.isInteger(increment) || increment < 0 || increment > 8) {
    throw new RangeError("Elevation increment must be an integer from 0 to 8.");
  }
  let result = [...coefficients];
  for (let step = 0; step < increment; step += 1) {
    const degree = result.length - 1;
    result = Array.from({ length: degree + 2 }, (_, index) => {
      if (index === 0) return result[0];
      if (index === degree + 1) return result[degree];
      return index / (degree + 1) * result[index - 1]
        + (1 - index / (degree + 1)) * result[index];
    });
  }
  return result;
}

export function buildElevation(input: string, increment: number): ElevationModel {
  const original = parseCoefficients(input);
  if (original.length > 16) throw new RangeError("Enter at most 16 coefficients.");
  const elevated = elevateBernstein(original, increment);
  const maximumSampleError = Math.max(...sampleBernstein(original).map((point) =>
    Math.abs(point.y - evaluateBernstein(elevated, point.x))));
  return { original, elevated, increment, maximumSampleError };
}

export function buildTensor(nodes: readonly number[], degree: number): TensorModel {
  if (nodes.length < 1 || nodes.length > 3 || nodes.some((value) => !Number.isInteger(value) || value < 2 || value > 8)) {
    throw new RangeError("Use one to three integer node counts from 2 to 8.");
  }
  if (!Number.isInteger(degree) || degree < 0 || degree > 6) {
    throw new RangeError("Degree must be an integer from 0 to 6.");
  }
  const cells = combinationRows(nodes.map((count) => Array.from({ length: count - 1 }, (_, index) => index + 1)));
  const labels = combinationRows(nodes.map(() => Array.from({ length: degree + 1 }, (_, index) => index)));
  return {
    nodes: [...nodes], degree,
    nodeCount: nodes.reduce((product, value) => product * value, 1),
    cellCount: cells.length,
    coefficientsPerCell: labels.length,
    cells, labels,
  };
}

function masks(nPar: number): number[][] {
  return combinationRows(Array.from({ length: nPar }, () => [0, 1]));
}

function axisVector(value: number | readonly number[], nPar: number, name: string): number[] {
  const values = typeof value === "number" ? Array(nPar).fill(value) : [...value];
  if (values.length !== nPar || values.some((entry) => !Number.isInteger(entry) || entry < 0 || entry > 8)) {
    throw new RangeError(`${name} must be an integer from 0 to 8 or a ${nPar}-entry vector in that range.`);
  }
  return values;
}

function compactAxis(values: readonly number[]): number | number[] {
  return values.every((value) => value === values[0]) ? values[0] : [...values];
}

function tensorCount(values: readonly number[]): number {
  return values.reduce((product, value) => product * value, 1);
}

/** Constraint counts mirror mkCoeffCons/mkGramCons, including omitted order-zero blocks. */
export function buildCertificateShape(input: {
  selector: CertificateSelector;
  cells: number;
  nPar: number;
  degree: number | readonly number[];
  rateRows: number;
  order: number | readonly number[];
  matrixSize: number;
  mode: CertificateMode;
  cliqueSize?: number;
  bandWidth?: number;
}): CertificateShape {
  const { selector, cells, nPar, rateRows, matrixSize, mode } = input;
  const cliqueSize = input.cliqueSize ?? 2;
  const bandWidth = input.bandWidth ?? 2;
  for (const [name, value, min, max] of [
    ["cells", cells, 1, 12], ["parameter dimension", nPar, 1, 3],
    ["rate rows", rateRows, 1, 8], ["matrix size", matrixSize, 1, 4],
  ] as const) {
    if (!Number.isInteger(value) || value < min || value > max) throw new RangeError(`${name} must be an integer from ${min} to ${max}.`);
  }
  const degree = axisVector(input.degree, nPar, "degree");
  const order = axisVector(input.order, nPar, "order");
  if (!Number.isInteger(cliqueSize) || cliqueSize < 1 || cliqueSize > 9) {
    throw new RangeError("clique size b must be an integer from 1 to 9.");
  }
  if (!Number.isInteger(bandWidth) || bandWidth < 1 || bandWidth > 9) {
    throw new RangeError("bandwidth w must be an integer from 1 to 9.");
  }
  if (rateRows !== 1 && rateRows !== 2 ** nPar) {
    throw new RangeError(`Active rate rows must be 1 for an ordinary residual or ${2 ** nPar} for rhodiff in ${nPar} dimensions.`);
  }
  const physicalCopies = cells * rateRows;
  const minimumOrder = degree.map((value) => nPar === 1 ? Math.floor(value / 2) : Math.ceil(value / 2));
  const gramSelector = ["putinar", "sparseputinar", "sparsefullbox", "fullbox"].includes(selector);
  if (gramSelector && order.some((value, axis) => value < minimumOrder[axis])) {
    const minimumText = minimumOrder.every((value) => value === minimumOrder[0])
      ? String(minimumOrder[0])
      : `[${minimumOrder.join(", ")}]`;
    throw new RangeError(`Order must be at least ${minimumText} for this degree and dimension.`);
  }
  const targetCount = tensorCount(degree.map((value) => value + 1));
  if (selector === "sparseputinar" && nPar === 1 && cliqueSize === 1) {
    const coefficientTests = physicalCopies * targetCount;
    return { selector, effectiveSelector: "direct", targetDegree: compactAxis(degree), coefficientTests,
      coefficientIdentities: 0, psdBlocks: 0, totalConstraints: coefficientTests,
      blocks: [], copies: physicalCopies, minimumOrder: compactAxis(minimumOrder), cliqueSize, bandWidth };
  }
  if (selector === "sparsefullbox" && bandWidth === 1) {
    const coefficientTests = physicalCopies * targetCount;
    return { selector, effectiveSelector: "direct", targetDegree: compactAxis(degree), coefficientTests,
      coefficientIdentities: 0, psdBlocks: 0, totalConstraints: coefficientTests,
      blocks: [], copies: physicalCopies, minimumOrder: compactAxis(minimumOrder), cliqueSize, bandWidth };
  }
  if (selector === "direct" || selector === "polya") {
    const targetDegrees = degree.map((value, axis) => value + (selector === "polya" ? order[axis] : 0));
    // mkCoeffCons stores one vectorized YALMIP constraint per coefficient,
    // including rectangular/elementwise residuals; matrix entries are metadata.
    const coefficientTests = physicalCopies * tensorCount(targetDegrees.map((value) => value + 1));
    return { selector, effectiveSelector: selector, targetDegree: compactAxis(targetDegrees), coefficientTests,
      coefficientIdentities: 0, psdBlocks: 0, totalConstraints: coefficientTests,
      blocks: [], copies: physicalCopies, minimumOrder: compactAxis(minimumOrder), cliqueSize, bandWidth };
  }

  let targetDegrees: number[];
  let specs: { label: string; gramDegree: number[] }[];
  if (nPar === 1 && degree[0] % 2 === 1) {
    targetDegrees = [2 * order[0] + 1];
    specs = ["(1−α) S₀", "α S₁"].map((label) => ({ label, gramDegree: [order[0]] }));
  } else if (nPar === 1) {
    targetDegrees = [2 * order[0]];
    specs = [{ label: "S₀", gramDegree: [order[0]] }];
    if (order[0] > 0) specs.push({ label: "α(1−α) S₁", gramDegree: [order[0] - 1] });
  } else {
    targetDegrees = order.map((value) => 2 * value);
    const selectedMasks = selector === "putinar" || selector === "sparseputinar"
      ? [Array(nPar).fill(0), ...Array.from({ length: nPar }, (_, axis) => Array.from({ length: nPar }, (__, index) => Number(index === axis)))]
      : masks(nPar);
    specs = selectedMasks
      .map((mask) => ({ label: mask.every((value) => value === 0) ? "S∅" : `S{${mask.map((value, axis) => value ? axis + 1 : null).filter(Boolean).join(",")}}`, gramDegree: mask.map((value, axis) => order[axis] - value) }))
      .filter((spec) => spec.gramDegree.every((value) => value >= 0));
  }
  const copies = physicalCopies * (mode === "elementwise" ? matrixSize ** 2 : 1);
  const denseBlocks = specs.map((spec) => ({ ...spec,
    dimension: (mode === "semidefinite" ? matrixSize : 1) * spec.gramDegree.reduce((product, value) => product * (value + 1), 1),
  }));
  const denseEndpoint = (selector === "sparseputinar" && cliqueSize > 1 && cliqueSize >= Math.max(...order.map((value) => value + 1)))
    || (selector === "sparsefullbox" && bandWidth >= Math.max(...order.map((value) => value + 1)));
  let blocks = denseBlocks;
  if ((selector === "sparseputinar" || selector === "sparsefullbox") && !denseEndpoint) {
    // Sparse support is a tensor window, not a flattened band. Enumerating
    // every start tuple mirrors mkGramCons and preserves asymmetric corners.
    blocks = specs.flatMap((spec) => {
      const axisStarts = spec.gramDegree.map((axisDegree) => {
        const window = Math.min(selector === "sparseputinar" ? cliqueSize : bandWidth, axisDegree + 1);
        return Array.from({ length: axisDegree - window + 2 }, (_, index) => index);
      });
      return combinationRows(axisStarts).map((start, index) => {
        const windowSize = spec.gramDegree.map((axisDegree) => Math.min(selector === "sparseputinar" ? cliqueSize : bandWidth, axisDegree + 1));
        return {
          label: `${spec.label} Gram block ${index + 1}`,
          gramDegree: windowSize.map((size) => size - 1),
          dimension: (mode === "semidefinite" ? matrixSize : 1)
            * windowSize.reduce((product, size) => product * size, 1),
        };
      });
    });
  }
  const identitiesPerCopy = tensorCount(targetDegrees.map((value) => value + 1));
  const coefficientIdentities = copies * identitiesPerCopy;
  const psdBlocks = copies * blocks.length;
  const effectiveSelector = denseEndpoint ? (selector === "sparseputinar" ? "putinar" : "fullbox") : selector;
  return { selector, effectiveSelector, targetDegree: compactAxis(targetDegrees), coefficientTests: 0,
    coefficientIdentities, psdBlocks, totalConstraints: coefficientIdentities + psdBlocks,
    blocks, copies, minimumOrder: compactAxis(minimumOrder), cliqueSize, bandWidth };
}
