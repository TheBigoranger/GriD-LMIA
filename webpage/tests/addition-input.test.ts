import assert from "node:assert/strict";
import test from "node:test";

import {
  alignAndAdd,
  initialAdditionInput,
  maxAdditionCoefficients,
  updateAdditionInput,
} from "../src/lib/addition-input.ts";
import { evaluateBernstein } from "../src/lib/bernstein.ts";

test("adds equal-degree coefficient rows labelwise", () => {
  assert.deepEqual(alignAndAdd([1, 3, 5], [2, 4, 6]), {
    left: [1, 3, 5],
    right: [2, 4, 6],
    sum: [3, 7, 11],
  });
});

test("elevates unequal degrees exactly before addition", () => {
  const aligned = alignAndAdd([1, 2], [10, 20, 30]);
  assert.deepEqual(aligned.left, [1, 1.5, 2]);
  assert.deepEqual(aligned.right, [10, 20, 30]);
  assert.deepEqual(aligned.sum, [11, 21.5, 32]);
});

test("elevation preserves endpoints and the represented function", () => {
  const original = [2, -1];
  const aligned = alignAndAdd(original, [0, 0, 0, 0]);
  assert.equal(aligned.left[0], original[0]);
  assert.equal(aligned.left.at(-1), original.at(-1));
  for (let index = 0; index <= 20; index += 1) {
    const alpha = index / 20;
    assert.ok(Math.abs(
      evaluateBernstein(original, alpha)
      - evaluateBernstein(aligned.left, alpha),
    ) < 1e-12);
  }
});

test("reports empty and nonfinite drafts while preserving the last valid plot", () => {
  const empty = updateAdditionInput(initialAdditionInput, "left", "");
  assert.match(empty.errors.left, /at least one/i);
  assert.deepEqual(empty.valid, initialAdditionInput.valid);

  const nonfinite = updateAdditionInput(empty, "right", "NaN");
  assert.match(nonfinite.errors.left, /at least one/i);
  assert.match(nonfinite.errors.right, /finite number/i);
  assert.deepEqual(nonfinite.valid, initialAdditionInput.valid);
});

test("rejects oversized input and recovers both addends atomically", () => {
  const maximum = Array(maxAdditionCoefficients).fill("1").join(",");
  const accepted = updateAdditionInput(initialAdditionInput, "left", maximum);
  assert.equal(accepted.valid.left.length, maxAdditionCoefficients);

  const oversized = updateAdditionInput(accepted, "right", `${maximum},1`);
  assert.match(oversized.errors.right, /at most 256 coefficients per addend/i);
  assert.deepEqual(oversized.valid, accepted.valid);

  const leftEdit = updateAdditionInput(oversized, "left", "5, 6");
  assert.deepEqual(leftEdit.valid, accepted.valid);
  const recovered = updateAdditionInput(leftEdit, "right", "7, 8");
  assert.deepEqual(recovered.errors, { left: "", right: "" });
  assert.deepEqual(recovered.valid, { left: [5, 6], right: [7, 8] });
});

test("rejects nonfinite derived sums without replacing the last valid pair", () => {
  const huge = updateAdditionInput(initialAdditionInput, "left", "1e308");
  const overflow = updateAdditionInput(huge, "right", "1e308");
  assert.match(overflow.errors.left, /non-finite coefficients/i);
  assert.match(overflow.errors.right, /non-finite coefficients/i);
  assert.deepEqual(overflow.valid, huge.valid);
});
