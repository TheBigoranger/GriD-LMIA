import assert from "node:assert/strict";
import test from "node:test";

import {
  bernsteinContributionsAt,
  bernsteinProduct,
  clientXToUnit,
  evaluateBernstein,
  parseCoefficients,
  plotScale,
  sampleBernstein,
} from "../src/lib/bernstein.ts";

const closeTo = (actual: number, expected: number, tolerance = 1e-12) => {
  assert.ok(
    Math.abs(actual - expected) <= tolerance,
    `expected ${actual} to be within ${tolerance} of ${expected}`,
  );
};

test("parses finite coefficient lists separated by commas or whitespace", () => {
  assert.deepEqual(parseCoefficients(" 1, 2  3,4 "), [1, 2, 3, 4]);
  assert.deepEqual(parseCoefficients("-1.5 2e2"), [-1.5, 200]);
});

test("rejects empty and nonfinite coefficient lists", () => {
  assert.throws(() => parseCoefficients(" ,  "), /at least one finite number/i);
  assert.throws(() => parseCoefficients("1, Infinity"), /finite number/i);
  assert.throws(() => parseCoefficients("1, nope"), /finite number/i);
});

test("evaluates normalized Bernstein coefficients at endpoints", () => {
  assert.equal(evaluateBernstein([3, 5, 9], 0), 3);
  assert.equal(evaluateBernstein([3, 5, 9], 1), 9);
});

test("evaluates the documented cubic represented by [1, 2, 1, 2]", () => {
  for (const alpha of [0, 0.25, 0.5, 0.75, 1]) {
    const expected = 1 + 3 * alpha - 6 * alpha ** 2 + 4 * alpha ** 3;
    closeTo(evaluateBernstein([1, 2, 1, 2], alpha), expected);
  }
});

test("multiplies normalized Bernstein coefficients exactly", () => {
  assert.deepEqual(bernsteinProduct([4, 2], [0.5, 3]), [2, 6.5, 6]);

  const product = bernsteinProduct([1, 2, 6], [2, 4]);
  const expected = [2, 4, 28 / 3, 24];
  product.forEach((value, index) => closeTo(value, expected[index]));
});

test("keeps high-degree normalized convolution finite", () => {
  const ones = Array<number>(601).fill(1);
  const product = bernsteinProduct(ones, ones);

  assert.equal(product.length, 1201);
  product.forEach((value) => closeTo(value, 1, 2e-12));
});

test("reports nonfinite products instead of returning NaN or Infinity", () => {
  assert.throws(() => bernsteinProduct([1e308], [1e308]), /non-finite product/i);
});

test("exposes actual normalized anti-diagonal contributions", () => {
  assert.deepEqual(bernsteinContributionsAt([4, 2], [0.5, 3], 1), [
    { i: 0, j: 1, weight: 0.5, value: 6 },
    { i: 1, j: 0, weight: 0.5, value: 0.5 },
  ]);
});

test("samples a Bernstein polynomial including both endpoints", () => {
  assert.deepEqual(sampleBernstein([1, 2, 1, 2], 3), [
    { x: 0, y: 1 },
    { x: 0.5, y: 1.5 },
    { x: 1, y: 2 },
  ]);
});

test("adds readable padding for negative and constant plot ranges", () => {
  assert.deepEqual(plotScale([-4, -2]), { min: -4.2, max: -1.8 });
  assert.deepEqual(plotScale([4, 4]), { min: 3, max: 5 });
  assert.throws(() => plotScale([-1e308, 1e308]), /finite plot range/i);
});

test("maps pointer positions through the SVG plot-area margins", () => {
  const bounds = { left: 100, width: 380 };
  const left = bounds.left + bounds.width * 58 / 760;
  const right = bounds.left + bounds.width * (760 - 28) / 760;

  assert.equal(clientXToUnit(left, bounds), 0);
  assert.equal(clientXToUnit(right, bounds), 1);
  assert.equal(clientXToUnit(bounds.left, bounds), 0);
  assert.equal(clientXToUnit(bounds.left + bounds.width, bounds), 1);
  closeTo(clientXToUnit((left + right) / 2, bounds), 0.5);
  assert.throws(() => clientXToUnit(100, { left: 100, width: 0 }), /positive width/i);
});
