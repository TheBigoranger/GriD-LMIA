import assert from "node:assert/strict";
import test from "node:test";

import {
  initialMultiplicationInput,
  maxMultiplicationCoefficients,
  updateMultiplicationInput,
} from "../src/lib/multiplication-input.ts";

test("tracks factor errors independently and preserves the last jointly valid factors", () => {
  const leftInvalid = updateMultiplicationInput(
    initialMultiplicationInput,
    "left",
    "bad",
  );
  assert.match(leftInvalid.errors.left, /finite number/i);
  assert.equal(leftInvalid.errors.right, "");
  assert.deepEqual(leftInvalid.valid, initialMultiplicationInput.valid);

  const bothInvalid = updateMultiplicationInput(leftInvalid, "right", "");
  assert.match(bothInvalid.errors.left, /finite number/i);
  assert.match(bothInvalid.errors.right, /at least one/i);
  assert.deepEqual(bothInvalid.valid, initialMultiplicationInput.valid);

  const rightStillInvalid = updateMultiplicationInput(bothInvalid, "left", "5, 6");
  assert.equal(rightStillInvalid.errors.left, "");
  assert.match(rightStillInvalid.errors.right, /at least one/i);
  assert.deepEqual(rightStillInvalid.valid, initialMultiplicationInput.valid);

  const jointlyValid = updateMultiplicationInput(rightStillInvalid, "right", "7 8");
  assert.deepEqual(jointlyValid.errors, { left: "", right: "" });
  assert.deepEqual(jointlyValid.valid, { left: [5, 6], right: [7, 8] });
});

test("a valid edit cannot clear or commit past the other factor error", () => {
  const invalid = updateMultiplicationInput(initialMultiplicationInput, "left", "NaN");
  const rightEdit = updateMultiplicationInput(invalid, "right", "10, 20, 30");

  assert.match(rightEdit.errors.left, /finite number/i);
  assert.equal(rightEdit.errors.right, "");
  assert.deepEqual(rightEdit.valid, initialMultiplicationInput.valid);
});

test("nonfinite derived data reports both inputs and preserves the last valid pair", () => {
  const leftHuge = updateMultiplicationInput(initialMultiplicationInput, "left", "1e308");
  assert.match(leftHuge.errors.left, /non-finite product/i);
  assert.match(leftHuge.errors.right, /non-finite product/i);
  assert.deepEqual(leftHuge.valid, initialMultiplicationInput.valid);

  const bothHuge = updateMultiplicationInput(leftHuge, "right", "1e308");
  assert.match(bothHuge.errors.left, /non-finite product/i);
  assert.match(bothHuge.errors.right, /non-finite product/i);
  assert.deepEqual(bothHuge.valid, initialMultiplicationInput.valid);
});

test("nonfinite plot bounds cannot replace the last jointly valid pair", () => {
  const zeroRight = updateMultiplicationInput(initialMultiplicationInput, "right", "0");
  assert.deepEqual(zeroRight.valid, { left: [1, 3], right: [0] });

  const unscalable = updateMultiplicationInput(zeroRight, "left", "1e308, -1e308");
  assert.match(unscalable.errors.left, /finite plot range/i);
  assert.match(unscalable.errors.right, /finite plot range/i);
  assert.deepEqual(unscalable.valid, zeroRight.valid);
});

test("accepts 256 coefficients, rejects 257, and recovers atomically", () => {
  const maximum = Array(maxMultiplicationCoefficients).fill("1").join(",");
  const accepted = updateMultiplicationInput(initialMultiplicationInput, "left", maximum);
  assert.deepEqual(accepted.errors, { left: "", right: "" });
  assert.equal(accepted.valid.left.length, maxMultiplicationCoefficients);

  const oversized = updateMultiplicationInput(accepted, "left", `${maximum},1`);
  assert.match(oversized.errors.left, /at most 256 coefficients per factor/i);
  assert.equal(oversized.errors.right, "");
  assert.deepEqual(oversized.valid, accepted.valid);

  const recovered = updateMultiplicationInput(oversized, "left", "5, 6");
  assert.deepEqual(recovered.errors, { left: "", right: "" });
  assert.deepEqual(recovered.valid, { left: [5, 6], right: [2, 4] });
});
