import assert from "node:assert/strict";
import test from "node:test";

import {
  buildCertificateShape, buildElevation, buildTensor, combinationRows,
  elevateBernstein, parseRateBounds,
} from "../src/lib/manual-explorers.ts";

test("enumerates tensor and rate rows with the last axis fastest", () => {
  assert.deepEqual(combinationRows([[0, 1], [10, 20]]), [[0, 10], [0, 20], [1, 10], [1, 20]]);
  assert.deepEqual(parseRateBounds("-1 2; -3 5", 3).vertices, [[-1, -3], [-1, 5], [2, -3], [2, 5]]);
  assert.equal(parseRateBounds("-1 1; -2 2; 0 4", 8).vertices.length, 8);
});

test("rejects malformed or adversarial rate inputs", () => {
  assert.throws(() => parseRateBounds("", 1), /one to three/i);
  assert.throws(() => parseRateBounds("2 -1", 1), /lower/i);
  assert.throws(() => parseRateBounds("0 1; 0 1; 0 1; 0 1", 1), /one to three/i);
  assert.throws(() => parseRateBounds("0 Infinity", 1), /finite/i);
});

test("degree elevation preserves endpoints, samples, zero increment, and composition", () => {
  assert.deepEqual(elevateBernstein([1, 2, 6], 0), [1, 2, 6]);
  assert.deepEqual(elevateBernstein([0, 1], 1), [0, 0.5, 1]);
  const once = elevateBernstein([1, -2, 4], 2);
  const repeated = elevateBernstein(elevateBernstein([1, -2, 4], 1), 1);
  assert.deepEqual(once, repeated);
  assert.equal(once[0], 1);
  assert.equal(once.at(-1), 4);
  assert.ok(buildElevation("1 -2 4", 4).maximumSampleError < 1e-12);
  assert.throws(() => buildElevation("1 nope", 1), /finite/i);
  assert.throws(() => elevateBernstein([1], -1), /0 to 8/i);
});

test("reports tensor counts, paths, and last-axis-fastest selections", () => {
  const model = buildTensor([3, 2], 2);
  assert.equal(model.nodeCount, 6);
  assert.equal(model.cellCount, 2);
  assert.equal(model.coefficientsPerCell, 9);
  assert.deepEqual(model.cells, [[1, 1], [2, 1]]);
  assert.deepEqual(model.labels.slice(0, 4), [[0, 0], [0, 1], [0, 2], [1, 0]]);
  assert.throws(() => buildTensor([1], 2), /2 to 8/i);
});

test("matches direct and Polya coefficient-test shapes", () => {
  const common = { cells: 2, nPar: 1, degree: 2, rateRows: 1, matrixSize: 2, mode: "semidefinite" as const };
  assert.equal(buildCertificateShape({ ...common, selector: "direct", order: 0 }).totalConstraints, 6);
  assert.equal(buildCertificateShape({ ...common, selector: "polya", order: 1 }).totalConstraints, 8);
  assert.equal(buildCertificateShape({ ...common, selector: "direct", order: 0, mode: "elementwise", matrixSize: 4 }).totalConstraints, 6);
});

test("matches one-dimensional even, odd, and order-zero Markov-Lukacs shapes", () => {
  const common = { selector: "putinar" as const, cells: 2, nPar: 1, rateRows: 1, matrixSize: 2, mode: "semidefinite" as const };
  const even = buildCertificateShape({ ...common, degree: 2, order: 1 });
  assert.deepEqual([even.psdBlocks, even.coefficientIdentities, even.totalConstraints], [4, 6, 10]);
  const odd = buildCertificateShape({ ...common, cells: 1, degree: 3, order: 1 });
  assert.deepEqual([odd.psdBlocks, odd.coefficientIdentities], [2, 4]);
  const zero = buildCertificateShape({ ...common, cells: 1, degree: 0, order: 0 });
  assert.deepEqual([zero.psdBlocks, zero.coefficientIdentities, zero.blocks.length], [1, 1, 1]);
});

test("matches multivariate Putinar and full-box source fixtures", () => {
  const common = { cells: 1, nPar: 2, degree: 3, rateRows: 1, order: 2, matrixSize: 2, mode: "semidefinite" as const };
  const putinar = buildCertificateShape({ ...common, selector: "putinar" });
  assert.deepEqual([putinar.psdBlocks, putinar.coefficientIdentities, putinar.totalConstraints], [3, 25, 28]);
  const full = buildCertificateShape({ ...common, selector: "fullbox" });
  assert.deepEqual([full.psdBlocks, full.coefficientIdentities, full.totalConstraints], [4, 25, 29]);
  assert.deepEqual(full.blocks.map((block) => block.dimension), [18, 12, 12, 8]);

  const orderZero = buildCertificateShape({ ...common, selector: "fullbox", degree: 0, order: 0 });
  assert.deepEqual([orderZero.blocks.length, orderZero.totalConstraints], [1, 2]);
});

test("counts independent elementwise certificates per matrix entry", () => {
  const shape = buildCertificateShape({ selector: "fullbox", cells: 2, nPar: 2, degree: 2,
    rateRows: 4, order: 1, matrixSize: 3, mode: "elementwise" });
  assert.equal(shape.copies, 72);
  assert.equal(shape.psdBlocks, 288);
  assert.equal(shape.coefficientIdentities, 648);
  assert.ok(shape.blocks.every((block) => block.dimension <= 4));
  assert.throws(() => buildCertificateShape({ selector: "putinar", cells: 1, nPar: 2, degree: 4,
    rateRows: 1, order: 1, matrixSize: 1, mode: "semidefinite" }), /at least 2/i);
  assert.throws(() => buildCertificateShape({ selector: "direct", cells: 1, nPar: 2, degree: 1,
    rateRows: 3, order: 0, matrixSize: 1, mode: "semidefinite" }), /ordinary residual or 4 for rhodiff/i);
});
