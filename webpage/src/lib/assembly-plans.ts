export interface PlanState<T> {
  model: T;
  error: string;
}

export interface ElevationEntry {
  target: number[];
  source: number[];
  weight: number;
}

export interface ElevationPlan {
  sourceDegree: number[];
  targetDegree: number[];
  packedShape: number[];
  targetShape: number[];
  entries: ElevationEntry[];
  nnz: number;
  transformed: number[];
  maximumSampleError: number;
}

export type ProductRoute = "numeric" | "known-affine" | "generic";

export interface ProductContribution {
  target: number[];
  left: number[];
  right: number[];
  weight: number;
}

export interface ProductPlan {
  route: ProductRoute;
  kernel: "scaled tensor convolution" | "planned block contraction" | "planned pair accumulation";
  outputDegree: number[];
  packedShapes: [number[], number[], number[]];
  contributions: ProductContribution[];
  outputCoefficients: number[] | null;
  contractionBlocks: string[];
  usesConvn: boolean;
}

export type GramFamily = "putinar" | "sparseputinar" | "sparsefullbox" | "fullbox";

export interface GramMapEntry {
  target: number[];
  kind: "diagonal" | "paired off-diagonal";
  pair: [number[], number[]];
  weight: number;
}

export interface GramBlockPlan {
  generator: string;
  generatorPowers: { alpha: number[]; oneMinusAlpha: number[] };
  windowStart: number[];
  windowShape: number[];
  psdDimension: number;
  map: GramMapEntry[];
}

export interface GramAssembly {
  family: GramFamily;
  residualDegree: number[];
  order: number[];
  targetDegree: number[];
  targetLabels: number[][];
  blocks: GramBlockPlan[];
  reusableNumericMaps: number;
  freshGramCopies: number;
}

/** Keep the prior model when a draft cannot be converted into a valid plan. */
export function updateLastValid<T>(current: T, build: () => T): PlanState<T> {
  try {
    return { model: build(), error: "" };
  } catch (reason) {
    return {
      model: current,
      error: reason instanceof Error ? reason.message : "Invalid plan input.",
    };
  }
}

/** Parse the residual-degree field used by the Gram assembly explorer. */
export function parseGramResidualDegreeDraft(draft: string): number[] {
  const values = draft.split(/[\s,]+/).filter(Boolean).map(Number);
  if (values.length < 1 || values.length > 2
    || values.some((value) => !Number.isInteger(value) || value < 0 || value > 8)) {
    throw new RangeError("Residual degree needs one or two integers from 0 to 8.");
  }
  return values;
}

function binomial(n: number, k: number): number {
  if (k < 0 || k > n) return 0;
  const r = Math.min(k, n - k);
  let value = 1;
  for (let index = 1; index <= r; index += 1) {
    value *= (n - r + index) / index;
  }
  return value;
}

function validateDegree(value: readonly number[], name: string): number[] {
  if (value.length < 1 || value.length > 3
    || value.some((entry) => !Number.isInteger(entry) || entry < 0 || entry > 8)) {
    throw new RangeError(`${name} must contain one to three integers from 0 to 8.`);
  }
  return [...value];
}

function tensorRows(degree: readonly number[]): number[][] {
  return degree.reduce<number[][]>(
    (rows, axisDegree) => rows.flatMap((row) =>
      Array.from({ length: axisDegree + 1 }, (_, value) => [...row, value])),
    [[]],
  );
}

function tensorBernsteinValue(coefficients: readonly number[], degree: readonly number[], point: readonly number[]): number {
  return tensorRows(degree).reduce((sum, label, index) => {
    const basis = label.reduce((product, value, axis) => product
      * binomial(degree[axis], value)
      * point[axis] ** value
      * (1 - point[axis]) ** (degree[axis] - value), 1);
    return sum + coefficients[index] * basis;
  }, 0);
}

/** Build the numeric sparse map used to elevate packed tensor coefficients. */
export function buildElevationPlan(input: {
  sourceDegree: readonly number[];
  targetDegree: readonly number[];
  coefficients: readonly number[];
}): ElevationPlan {
  const sourceDegree = validateDegree(input.sourceDegree, "Source degree");
  const targetDegree = validateDegree(input.targetDegree, "Target degree");
  if (sourceDegree.length !== targetDegree.length) {
    throw new RangeError("Source and target degrees must use the same number of axes.");
  }
  if (targetDegree.some((value, axis) => value < sourceDegree[axis])) {
    throw new RangeError("Every target degree must be at least the source degree.");
  }
  const sourceLabels = tensorRows(sourceDegree);
  const targetLabels = tensorRows(targetDegree);
  if (input.coefficients.length !== sourceLabels.length
    || input.coefficients.some((value) => !Number.isFinite(value))) {
    throw new RangeError(`Coefficients must contain ${sourceLabels.length} finite values.`);
  }

  const entries: ElevationEntry[] = [];
  const transformed = targetLabels.map((target) => sourceLabels.reduce((sum, source, sourceIndex) => {
    let weight = 1;
    for (let axis = 0; axis < sourceDegree.length; axis += 1) {
      const increment = targetDegree[axis] - sourceDegree[axis];
      const factor = binomial(sourceDegree[axis], source[axis])
        * binomial(increment, target[axis] - source[axis])
        / binomial(targetDegree[axis], target[axis]);
      weight *= factor;
    }
    if (weight !== 0) entries.push({ target: [...target], source: [...source], weight });
    return sum + input.coefficients[sourceIndex] * weight;
  }, 0));

  const sampleAxes = sourceDegree.map(() => [0, 0.25, 0.5, 0.75, 1]);
  const samplePoints = sampleAxes.reduce<number[][]>(
    (rows, axis) => rows.flatMap((row) => axis.map((value) => [...row, value])),
    [[]],
  );
  const maximumSampleError = Math.max(...samplePoints.map((point) => Math.abs(
    tensorBernsteinValue(input.coefficients, sourceDegree, point)
      - tensorBernsteinValue(transformed, targetDegree, point),
  )));

  return {
    sourceDegree,
    targetDegree,
    packedShape: sourceDegree.map((value) => value + 1),
    targetShape: targetDegree.map((value) => value + 1),
    entries,
    nnz: entries.length,
    transformed,
    maximumSampleError,
  };
}

/** Build the normalized coefficient-pair plan used by each product payload route. */
export function buildProductPlan(input: {
  leftDegree: readonly number[];
  rightDegree: readonly number[];
  route: ProductRoute;
  leftCoefficients?: readonly number[];
  rightCoefficients?: readonly number[];
}): ProductPlan {
  const leftDegree = validateDegree(input.leftDegree, "Left degree");
  const rightDegree = validateDegree(input.rightDegree, "Right degree");
  if (leftDegree.length !== rightDegree.length) {
    throw new RangeError("Left and right degrees must use the same number of axes.");
  }
  const outputDegree = leftDegree.map((value, axis) => value + rightDegree[axis]);
  const leftLabels = tensorRows(leftDegree);
  const rightLabels = tensorRows(rightDegree);
  const outputLabels = tensorRows(outputDegree);
  const contributions: ProductContribution[] = [];

  for (const target of outputLabels) {
    for (const left of leftLabels) {
      for (const right of rightLabels) {
        if (!target.every((value, axis) => value === left[axis] + right[axis])) continue;
        const weight = target.reduce((product, value, axis) => product
          * binomial(leftDegree[axis], left[axis])
          * binomial(rightDegree[axis], right[axis])
          / binomial(outputDegree[axis], value), 1);
        contributions.push({ target: [...target], left: [...left], right: [...right], weight });
      }
    }
  }

  let outputCoefficients: number[] | null = null;
  if (input.route === "numeric") {
    if (input.leftCoefficients?.length !== leftLabels.length
      || input.rightCoefficients?.length !== rightLabels.length
      || [...input.leftCoefficients, ...input.rightCoefficients].some((value) => !Number.isFinite(value))) {
      throw new RangeError(`Numeric coefficients must have shapes ${leftLabels.length} and ${rightLabels.length}.`);
    }
    outputCoefficients = outputLabels.map((target) => contributions
      .filter((item) => item.target.every((value, axis) => value === target[axis]))
      .reduce((sum, item) => {
        const leftIndex = leftLabels.findIndex((label) => label.every((value, axis) => value === item.left[axis]));
        const rightIndex = rightLabels.findIndex((label) => label.every((value, axis) => value === item.right[axis]));
        return sum + input.leftCoefficients![leftIndex] * input.rightCoefficients![rightIndex] * item.weight;
      }, 0));
  }

  const routeData = {
    numeric: { kernel: "scaled tensor convolution" as const, usesConvn: true, contractionBlocks: [] },
    "known-affine": {
      kernel: "planned block contraction" as const,
      usesConvn: false,
      contractionBlocks: ["known-left × affine-right", "affine-left × known-right"],
    },
    generic: { kernel: "planned pair accumulation" as const, usesConvn: false, contractionBlocks: [] },
  }[input.route];

  return {
    route: input.route,
    ...routeData,
    outputDegree,
    packedShapes: [leftDegree.map((value) => value + 1), rightDegree.map((value) => value + 1), outputDegree.map((value) => value + 1)],
    contributions,
    outputCoefficients,
  };
}

interface GramSpec {
  degree: number[];
  alpha: number[];
  oneMinusAlpha: number[];
  label: string;
}

/** Mirror putSpec/boxSpec, including the one-dimensional parity split. */
function gramSpecs(family: GramFamily, residualDegree: readonly number[], order: readonly number[]): {
  targetDegree: number[];
  specs: GramSpec[];
} {
  const nPar = order.length;
  if (nPar === 1 && residualDegree[0] % 2 === 1) {
    return {
      targetDegree: [2 * order[0] + 1],
      specs: [
        { degree: [order[0]], alpha: [0], oneMinusAlpha: [1], label: "(1-alpha) endpoint" },
        { degree: [order[0]], alpha: [1], oneMinusAlpha: [0], label: "alpha endpoint" },
      ],
    };
  }
  if (nPar === 1) {
    const specs: GramSpec[] = [
      { degree: [order[0]], alpha: [0], oneMinusAlpha: [0], label: "unweighted" },
    ];
    if (order[0] > 0) {
      specs.push({
        degree: [order[0] - 1], alpha: [1], oneMinusAlpha: [1],
        label: "alpha(1-alpha)",
      });
    }
    return { targetDegree: [2 * order[0]], specs };
  }

  if (family === "putinar" || family === "sparseputinar") {
    const masks = [Array(nPar).fill(0), ...Array.from({ length: nPar }, (_, axis) =>
      Array.from({ length: nPar }, (__, index) => Number(index === axis)))];
    return {
      targetDegree: order.map((value) => 2 * value),
      specs: masks.map((mask) => ({
        degree: order.map((value, axis) => value - mask[axis]),
        alpha: mask,
        oneMinusAlpha: [...mask],
        label: mask.every((value) => value === 0)
          ? "unweighted"
          : `axis ${mask.findIndex(Boolean) + 1} generator`,
      })).filter((spec) => spec.degree.every((value) => value >= 0)),
    };
  }
  const masks = Array.from({ length: 2 ** nPar }, (_, mask) =>
    Array.from({ length: nPar }, (__, axis) => (mask >> (nPar - axis - 1)) & 1));
  return {
    targetDegree: order.map((value) => 2 * value),
    specs: masks.map((mask) => ({
      degree: order.map((value, axis) => value - mask[axis]),
      alpha: mask,
      oneMinusAlpha: [...mask],
      label: mask.every((value) => value === 0)
        ? "unweighted"
        : `axes ${mask.map((value, axis) => value ? axis + 1 : null).filter(Boolean).join(", ")} generator`,
    })).filter((spec) => spec.degree.every((value) => value >= 0)),
  };
}

function sameLabel(left: readonly number[], right: readonly number[]): boolean {
  return left.every((value, axis) => value === right[axis]);
}

/** Build reusable Bernstein–Gram maps and count independent Gram allocations. */
export function buildGramAssembly(input: {
  family: GramFamily;
  residualDegree: readonly number[];
  order: readonly number[];
  windowSize: number;
  matrixSize: number;
  entries: number;
  cells: number;
  rateRows: number;
}): GramAssembly {
  const residualDegree = validateDegree(input.residualDegree, "Residual degree");
  const order = validateDegree(input.order, "Gram order");
  if (residualDegree.length !== order.length) {
    throw new RangeError("Residual degree and Gram order must use the same number of axes.");
  }
  const minimumOrder = residualDegree.map((value) => order.length === 1
    ? Math.floor(value / 2)
    : Math.ceil(value / 2));
  if (order.some((value, axis) => value < minimumOrder[axis])) {
    throw new RangeError(`Gram order must be at least [${minimumOrder.join(", ")}] for this residual degree.`);
  }
  const maxBasisSide = Math.max(...order.map((value) => value + 1));
  if (!Number.isInteger(input.windowSize) || input.windowSize < 1 || input.windowSize > maxBasisSide) {
    throw new RangeError(`Window size must be an integer from 1 to at most ${maxBasisSide}.`);
  }
  for (const [name, value, maximum] of [
    ["Matrix size", input.matrixSize, 4], ["Matrix entries", input.entries, 16],
    ["Physical cells", input.cells, 12], ["Rate rows", input.rateRows, 8],
  ] as const) {
    if (!Number.isInteger(value) || value < 1 || value > maximum) {
      throw new RangeError(`${name} must be an integer from 1 to ${maximum}.`);
    }
  }

  const sparse = input.family === "sparseputinar" || input.family === "sparsefullbox";
  const { targetDegree, specs } = gramSpecs(input.family, residualDegree, order);
  const targetLabels = tensorRows(targetDegree);
  const blocks: GramBlockPlan[] = [];

  for (const spec of specs) {
    const windowShape = spec.degree.map((value) => sparse ? Math.min(input.windowSize, value + 1) : value + 1);
    const startAxes = spec.degree.map((value, axis) =>
      Array.from({ length: value - windowShape[axis] + 2 }, (_, start) => start));
    const starts = startAxes.reduce<number[][]>(
      (rows, axis) => rows.flatMap((row) => axis.map((value) => [...row, value])),
      [[]],
    );
    for (const windowStart of starts) {
      const basisLabels = tensorRows(windowShape.map((value) => value - 1))
        .map((label) => label.map((value, axis) => value + windowStart[axis]));
      const map: GramMapEntry[] = [];
      for (let leftIndex = 0; leftIndex < basisLabels.length; leftIndex += 1) {
        for (let rightIndex = leftIndex; rightIndex < basisLabels.length; rightIndex += 1) {
          const left = basisLabels[leftIndex];
          const right = basisLabels[rightIndex];
          const target = left.map((value, axis) => value + right[axis] + spec.alpha[axis]);
          const baseWeight = target.reduce((product, value, axis) => product
            * binomial(spec.degree[axis], left[axis])
            * binomial(spec.degree[axis], right[axis])
            / binomial(targetDegree[axis], value), 1);
          const diagonal = sameLabel(left, right);
          map.push({
            target,
            kind: diagonal ? "diagonal" : "paired off-diagonal",
            pair: [[...left], [...right]],
            weight: diagonal ? baseWeight : 2 * baseWeight,
          });
        }
      }
      blocks.push({
        generator: spec.label,
        generatorPowers: { alpha: [...spec.alpha], oneMinusAlpha: [...spec.oneMinusAlpha] },
        windowStart,
        windowShape,
        psdDimension: input.matrixSize * windowShape.reduce((product, value) => product * value, 1),
        map,
      });
    }
  }

  return {
    family: input.family,
    residualDegree,
    order,
    targetDegree,
    targetLabels,
    blocks,
    reusableNumericMaps: blocks.length,
    freshGramCopies: input.entries * input.cells * input.rateRows * blocks.length,
  };
}
