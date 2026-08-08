import assert from "node:assert/strict";
import test from "node:test";

import {
  buildCellBernsteinModel,
  documentedMatrixAt,
  orderCellBernsteinTermsForAxes,
} from "../src/lib/cell-bernstein.ts";

const closeTo = (actual: number, expected: number, tolerance = 1e-12) => {
  assert.ok(Math.abs(actual - expected) <= tolerance);
};

test("tensor Bernstein weights form a partition of unity in each cell", () => {
  for (const cellIndex of [0, 1]) {
    const model = buildCellBernsteinModel(cellIndex, 0.35, 0.6);
    closeTo(model.terms.reduce((sum, term) => sum + term.weight, 0), 1);
    model.value.forEach((entry) => assert.ok(Number.isFinite(entry)));
  }
});

test("display order follows alpha1 horizontally and alpha2 vertically", () => {
  const displayedTerms = orderCellBernsteinTermsForAxes(
    buildCellBernsteinModel(0, 0.35, 0.6).terms,
  );
  assert.deepEqual(
    displayedTerms.map(({ i, j }) => [i, j]),
    [
      [0, 2], [1, 2], [2, 2],
      [0, 1], [1, 1], [2, 1],
      [0, 0], [1, 0], [2, 0],
    ],
  );
});

test("cell corners recover the corresponding coefficient matrices", () => {
  assert.deepEqual(buildCellBernsteinModel(0, 0, 0).value, [1, 0, 0, 2]);
  assert.deepEqual(buildCellBernsteinModel(1, 1, 1).value, [3, 1, 1, 3]);
});

test("the two cell expressions agree on their shared physical boundary", () => {
  for (const alpha2 of [0, 0.2, 0.5, 0.8, 1]) {
    const left = buildCellBernsteinModel(0, 1, alpha2).value;
    const right = buildCellBernsteinModel(1, 0, alpha2).value;
    left.forEach((entry, index) => closeTo(entry, right[index]));
  }
});

test("both cell expansions recover the documented physical-coordinate matrix", () => {
  for (const [rho1, rho2] of [[0, 0], [0.2, 0.7], [0.5, 0.3], [0.8, 0.4], [1, 1]]) {
    const cellIndex = rho1 <= 0.5 ? 0 : 1;
    const alpha1 = cellIndex === 0 ? 2 * rho1 : 2 * rho1 - 1;
    const actual = buildCellBernsteinModel(cellIndex, alpha1, rho2).value;
    const expected = documentedMatrixAt(rho1, rho2);
    actual.forEach((entry, index) => closeTo(entry, expected[index]));
  }
});
