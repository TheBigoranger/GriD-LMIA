import { bernsteinBasisWeights } from "./bernstein.ts";

export type Matrix2 = readonly [number, number, number, number];

export interface CellCoefficient {
  tex: string;
  values: Matrix2;
}

export interface CellBernsteinTerm {
  coefficient: CellCoefficient;
  i: number;
  j: number;
  weight: number;
}

/** Arrange tensor terms as a Cartesian plot: alpha1 left-to-right, alpha2 bottom-to-top. */
export function orderCellBernsteinTermsForAxes<T extends Pick<CellBernsteinTerm, "i" | "j">>(
  terms: readonly T[],
) {
  return [...terms].sort((left, right) => right.j - left.j || left.i - right.i);
}

export const pdmatCellData = [
  {
    c1: 1,
    domainTex: "\\rho_1\\in[0,0.5],\\;\\rho_2\\in[0,1]",
    coefficients: [
      { tex: "\\begin{bmatrix}1&0\\\\0&2\\end{bmatrix}", values: [1, 0, 0, 2] },
      { tex: "\\begin{bmatrix}3/2&0\\\\0&2\\end{bmatrix}", values: [1.5, 0, 0, 2] },
      { tex: "\\begin{bmatrix}2&0\\\\0&2\\end{bmatrix}", values: [2, 0, 0, 2] },
      { tex: "\\begin{bmatrix}5/4&0\\\\0&2\\end{bmatrix}", values: [1.25, 0, 0, 2] },
      { tex: "\\begin{bmatrix}7/4&1/8\\\\1/8&2\\end{bmatrix}", values: [1.75, 0.125, 0.125, 2] },
      { tex: "\\begin{bmatrix}9/4&1/4\\\\1/4&2\\end{bmatrix}", values: [2.25, 0.25, 0.25, 2] },
      { tex: "\\begin{bmatrix}3/2&0\\\\0&9/4\\end{bmatrix}", values: [1.5, 0, 0, 2.25] },
      { tex: "\\begin{bmatrix}2&1/4\\\\1/4&9/4\\end{bmatrix}", values: [2, 0.25, 0.25, 2.25] },
      { tex: "\\begin{bmatrix}5/2&1/2\\\\1/2&9/4\\end{bmatrix}", values: [2.5, 0.5, 0.5, 2.25] },
    ],
  },
  {
    c1: 2,
    domainTex: "\\rho_1\\in[0.5,1],\\;\\rho_2\\in[0,1]",
    coefficients: [
      { tex: "\\begin{bmatrix}3/2&0\\\\0&9/4\\end{bmatrix}", values: [1.5, 0, 0, 2.25] },
      { tex: "\\begin{bmatrix}2&1/4\\\\1/4&9/4\\end{bmatrix}", values: [2, 0.25, 0.25, 2.25] },
      { tex: "\\begin{bmatrix}5/2&1/2\\\\1/2&9/4\\end{bmatrix}", values: [2.5, 0.5, 0.5, 2.25] },
      { tex: "\\begin{bmatrix}7/4&0\\\\0&5/2\\end{bmatrix}", values: [1.75, 0, 0, 2.5] },
      { tex: "\\begin{bmatrix}9/4&3/8\\\\3/8&5/2\\end{bmatrix}", values: [2.25, 0.375, 0.375, 2.5] },
      { tex: "\\begin{bmatrix}11/4&3/4\\\\3/4&5/2\\end{bmatrix}", values: [2.75, 0.75, 0.75, 2.5] },
      { tex: "\\begin{bmatrix}2&0\\\\0&3\\end{bmatrix}", values: [2, 0, 0, 3] },
      { tex: "\\begin{bmatrix}5/2&1/2\\\\1/2&3\\end{bmatrix}", values: [2.5, 0.5, 0.5, 3] },
      { tex: "\\begin{bmatrix}3&1\\\\1&3\\end{bmatrix}", values: [3, 1, 1, 3] },
    ],
  },
] as const;

/** Evaluate the physical-coordinate matrix represented by the documented cell coefficients. */
export function documentedMatrixAt(rho1: number, rho2: number): Matrix2 {
  if (![rho1, rho2].every((value) => Number.isFinite(value) && value >= 0 && value <= 1)) {
    throw new RangeError("The documented parameter point must belong to [0,1]^2.");
  }
  return [1 + rho1 + rho2, rho1 * rho2, rho1 * rho2, 2 + rho1 ** 2];
}

/** Build the tensor degree-two Bernstein expression for one physical cell. */
export function buildCellBernsteinModel(cellIndex: number, alpha1: number, alpha2: number) {
  if (!Number.isInteger(cellIndex) || cellIndex < 0 || cellIndex >= pdmatCellData.length) {
    throw new RangeError("Cell index is outside the documented physical grid.");
  }
  const firstAxis = bernsteinBasisWeights(2, alpha1);
  const secondAxis = bernsteinBasisWeights(2, alpha2);
  const cell = pdmatCellData[cellIndex];
  const value: [number, number, number, number] = [0, 0, 0, 0];
  const terms: CellBernsteinTerm[] = cell.coefficients.map((coefficient, index) => {
    const i = Math.floor(index / 3);
    const j = index % 3;
    const weight = firstAxis[i] * secondAxis[j];
    coefficient.values.forEach((entry, matrixIndex) => {
      value[matrixIndex] += weight * entry;
    });
    return { coefficient, i, j, weight };
  });
  return { cell, terms, value };
}
