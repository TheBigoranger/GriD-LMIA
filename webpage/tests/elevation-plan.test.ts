import assert from "node:assert/strict";
import test from "node:test";

import { buildElevationPlan, updateLastValid } from "../src/lib/assembly-plans.ts";

test("builds the sparse elevation operator and verifies the represented polynomial", () => {
  const plan = buildElevationPlan({ sourceDegree: [1], targetDegree: [2], coefficients: [1, 3] });

  assert.deepEqual(plan.entries, [
    { target: [0], source: [0], weight: 1 },
    { target: [1], source: [0], weight: 0.5 },
    { target: [1], source: [1], weight: 0.5 },
    { target: [2], source: [1], weight: 1 },
  ]);
  assert.deepEqual(plan.transformed, [1, 2, 3]);
  assert.equal(plan.nnz, 4);
  assert.ok(plan.maximumSampleError < 1e-12);
});

test("supports tensor degrees and preserves the last valid model after malformed drafts", () => {
  const valid = buildElevationPlan({ sourceDegree: [1, 0], targetDegree: [2, 1], coefficients: [2, 4] });
  assert.deepEqual(valid.packedShape, [2, 1]);
  assert.deepEqual(valid.targetShape, [3, 2]);
  assert.deepEqual(valid.transformed, [2, 2, 3, 3, 4, 4]);

  const next = updateLastValid(valid, () => buildElevationPlan({
    sourceDegree: [2], targetDegree: [1], coefficients: [1, 2, 3],
  }));
  assert.equal(next.model, valid);
  assert.match(next.error, /at least the source degree/i);
});
