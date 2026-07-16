export interface PlotPoint {
  x: number;
  y: number;
}

export interface PlotRange {
  min: number;
  max: number;
}

export interface ProductContribution {
  i: number;
  j: number;
  weight: number;
  value: number;
}

export interface ClientBounds {
  left: number;
  width: number;
}

export const bernsteinPlotGeometry = {
  width: 760,
  height: 300,
  margin: { left: 58, right: 28, top: 24, bottom: 42 },
} as const;

const separators = /[\s,]+/;

/** Parse a nonempty list of finite coefficients separated by commas or whitespace. */
export function parseCoefficients(input: string): number[] {
  const parts = input.trim().split(separators).filter(Boolean);
  if (parts.length === 0) {
    throw new TypeError("Enter at least one finite number.");
  }

  const values = parts.map(Number);
  if (values.some((value) => !Number.isFinite(value))) {
    throw new TypeError("Every coefficient must be a finite number.");
  }
  return values;
}

/** Evaluate normalized Bernstein coefficients on the local coordinate [0, 1]. */
export function evaluateBernstein(coeffs: readonly number[], alpha: number): number {
  if (coeffs.length === 0 || !Number.isFinite(alpha)) {
    throw new TypeError("Evaluation requires coefficients and a finite coordinate.");
  }

  // De Casteljau evaluation avoids explicit powers and remains exact at endpoints.
  const work = [...coeffs];
  for (let level = work.length - 1; level > 0; level -= 1) {
    for (let i = 0; i < level; i += 1) {
      work[i] = (1 - alpha) * work[i] + alpha * work[i + 1];
    }
  }
  return work[0];
}

/** Multiply two normalized Bernstein expansions and return degree m+n coefficients. */
export function bernsteinProduct(left: readonly number[], right: readonly number[]): number[] {
  validateFactors(left, right);
  const m = left.length - 1;
  const n = right.length - 1;
  const weights = new Float64Array(Math.min(m, n) + 1);
  return Array.from({ length: m + n + 1 }, (_, k) => {
    const { count, first, total } = fillWeights(m, n, k, weights);
    let sum = 0;
    let correction = 0;
    for (let offset = 0; offset < count; offset += 1) {
      const i = first + offset;
      const value = weightedProduct(left[i], right[k - i], weights[offset] / total);
      if (!Number.isFinite(value)) {
        throw new RangeError("Bernstein multiplication produced a non-finite product.");
      }
      const adjusted = value - correction;
      const next = sum + adjusted;
      correction = (next - sum) - adjusted;
      sum = next;
    }
    if (!Number.isFinite(sum)) {
      throw new RangeError("Bernstein multiplication produced a non-finite product.");
    }
    return sum;
  });
}

/** Return one output coefficient's weighted terms for lazy table disclosure. */
export function bernsteinContributionsAt(
  left: readonly number[],
  right: readonly number[],
  k: number,
): ProductContribution[] {
  validateFactors(left, right);
  const m = left.length - 1;
  const n = right.length - 1;
  if (!Number.isInteger(k) || k < 0 || k > m + n) {
    throw new RangeError("Contribution index is outside the product degree.");
  }
  const weights = new Float64Array(Math.min(m, n) + 1);
  const { count, first, total } = fillWeights(m, n, k, weights);
  return Array.from({ length: count }, (_, offset) => {
    const i = first + offset;
    const j = k - i;
    const weight = weights[offset] / total;
    const value = weightedProduct(left[i], right[j], weight);
    if (!Number.isFinite(value)) {
      throw new RangeError("Bernstein multiplication produced a non-finite product.");
    }
    return { i, j, weight, value };
  });
}

/** Sample a Bernstein expansion uniformly, including both interval endpoints. */
export function sampleBernstein(
  coeffs: readonly number[],
  count = 81,
): PlotPoint[] {
  if (!Number.isInteger(count) || count < 2) {
    throw new RangeError("Sample count must be an integer of at least two.");
  }
  const points = Array.from({ length: count }, (_, index) => {
    const x = index / (count - 1);
    return { x, y: evaluateBernstein(coeffs, x) };
  });
  if (points.some((point) => !Number.isFinite(point.y))) {
    throw new RangeError("Bernstein sampling produced a non-finite value.");
  }
  return points;
}

/** Add ten-percent vertical padding, with a one-unit minimum for constant data. */
export function plotScale(values: readonly number[]): PlotRange {
  if (values.length === 0 || values.some((value) => !Number.isFinite(value))) {
    throw new TypeError("Plot scaling requires finite values.");
  }

  let min = values[0];
  let max = values[0];
  for (const value of values.slice(1)) {
    min = Math.min(min, value);
    max = Math.max(max, value);
  }

  const span = max - min;
  const padding = span === 0 ? Math.max(1, Math.abs(min) * 0.1) : span * 0.1;
  const range = { min: min - padding, max: max + padding };
  if (![span, padding, range.min, range.max].every(Number.isFinite)) {
    throw new RangeError("Plot scaling requires a finite plot range.");
  }
  return range;
}

/** Map a viewport x coordinate to [0, 1] using the rendered SVG plot area. */
export function clientXToUnit(clientX: number, bounds: ClientBounds): number {
  if (![clientX, bounds.left, bounds.width].every(Number.isFinite) || bounds.width <= 0) {
    throw new TypeError("Pointer mapping requires finite bounds with positive width.");
  }

  // The SVG scales uniformly, so its viewBox margins scale with the client width.
  const scale = bounds.width / bernsteinPlotGeometry.width;
  const left = bounds.left + bernsteinPlotGeometry.margin.left * scale;
  const right = bounds.left
    + (bernsteinPlotGeometry.width - bernsteinPlotGeometry.margin.right) * scale;
  return Math.max(0, Math.min(1, (clientX - left) / (right - left)));
}

/** Apply a normalized weight without overflowing an avoidable intermediate product. */
function weightedProduct(left: number, right: number, weight: number): number {
  if (left === 0 || right === 0 || weight === 0) return 0;
  const direct = left * right;
  const weighted = direct * weight;
  if (Number.isFinite(weighted)) return weighted;

  const logValue = Math.log(Math.abs(left)) + Math.log(Math.abs(right)) + Math.log(weight);
  const magnitude = Math.exp(logValue);
  return Math.sign(left) * Math.sign(right) * magnitude;
}

/** Fill relative hypergeometric weights around their mode without binomials. */
function fillWeights(
  m: number,
  n: number,
  k: number,
  weights: Float64Array,
): { count: number; first: number; total: number } {
  const first = Math.max(0, k - n);
  const last = Math.min(m, k);
  const count = last - first + 1;
  const mode = Math.max(first, Math.min(last, Math.floor((k + 1) * (m + 1) / (m + n + 2))));
  const modeOffset = mode - first;
  weights[modeOffset] = 1;

  for (let i = mode; i < last; i += 1) {
    weights[i + 1 - first] = weights[i - first]
      * (m - i) / (i + 1)
      * (k - i) / (n - k + i + 1);
  }
  for (let i = mode; i > first; i -= 1) {
    weights[i - 1 - first] = weights[i - first]
      * i / (m - i + 1)
      * (n - k + i) / (k - i + 1);
  }

  let total = 0;
  for (let offset = 0; offset < count; offset += 1) total += weights[offset];
  return { count, first, total };
}

/** Reject malformed factor arrays before coefficient algebra. */
function validateFactors(left: readonly number[], right: readonly number[]): void {
  if (left.length === 0 || right.length === 0
      || left.some((value) => !Number.isFinite(value))
      || right.some((value) => !Number.isFinite(value))) {
    throw new TypeError("Both factors require finite coefficients.");
  }
}
