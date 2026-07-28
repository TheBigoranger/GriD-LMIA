import assert from "node:assert/strict";
import test from "node:test";

import {
  clampPitch,
  enumerateCells,
  getCellBounds,
  normalizeKnots,
  projectPoint,
  resetRotation,
} from "../src/lib/grid-partition.ts";

test("enumerates one-, two-, and three-dimensional cells with the last axis fastest", () => {
  assert.deepEqual(enumerateCells([0.35]), [[0], [1]]);
  assert.deepEqual(enumerateCells([0.4, 0.25]), [[0, 0], [0, 1], [1, 0], [1, 1]]);
  assert.equal(enumerateCells([0.3, 0.55, 0.75]).length, 8);
});

test("normalizes finite knots to the visible interaction bounds", () => {
  assert.deepEqual(normalizeKnots([0.35, 0.05, 0.95]), [0.35, 0.1, 0.9]);
  assert.throws(() => normalizeKnots([]), /one to three/i);
  assert.throws(() => normalizeKnots([0.4, Number.NaN]), /finite/i);
  assert.throws(() => normalizeKnots([0.4, 0.5, 0.6, 0.7]), /one to three/i);
});

test("reports the selected physical intervals for each cell", () => {
  assert.deepEqual(getCellBounds([0.4, 0.25], [1, 0]), [[0.4, 1], [0, 0.25]]);
  assert.throws(() => getCellBounds([0.4], [2]), /0 or 1/i);
  assert.throws(() => getCellBounds([0.4, 0.25], [0]), /same dimension/i);
});

test("clamps pitch and projects rotated cube points to finite coordinates", () => {
  assert.equal(clampPitch(100), 70);
  assert.equal(clampPitch(-100), -70);
  assert.equal(clampPitch(25), 25);

  const projected = projectPoint([1, 1, 1], 35, 25);
  assert.ok(Number.isFinite(projected.x));
  assert.ok(Number.isFinite(projected.y));
  assert.ok(projected.depth > 0);
  assert.throws(() => projectPoint([1, Number.POSITIVE_INFINITY, 1], 0, 0), /finite/i);
});

test("resets the three-dimensional view to the documented finite rotation", () => {
  assert.deepEqual(resetRotation(), { yaw: 35, pitch: 25 });
  const reset = resetRotation();
  const projected = projectPoint([0.5, 0.5, 0.5], reset.yaw, reset.pitch);
  assert.ok([projected.x, projected.y, projected.depth].every(Number.isFinite));
});
