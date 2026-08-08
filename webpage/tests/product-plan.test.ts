import assert from "node:assert/strict";
import test from "node:test";

import { buildProductPlan, updateLastValid } from "../src/lib/assembly-plans.ts";

test("builds normalized label pairs for the numeric convolution route", () => {
  const plan = buildProductPlan({
    leftDegree: [1], rightDegree: [1], route: "numeric",
    leftCoefficients: [4, 2], rightCoefficients: [0.5, 3],
  });

  assert.deepEqual(plan.outputDegree, [2]);
  assert.deepEqual(plan.packedShapes, [[2], [2], [3]]);
  assert.deepEqual(plan.outputCoefficients, [2, 6.5, 6]);
  assert.deepEqual(plan.contributions.filter((item) => item.target[0] === 1), [
    { target: [1], left: [0], right: [1], weight: 0.5 },
    { target: [1], left: [1], right: [0], weight: 0.5 },
  ]);
});

test("reports the known-affine contraction and generic planned fallback without numeric convolution", () => {
  const affine = buildProductPlan({ leftDegree: [1], rightDegree: [1], route: "known-affine" });
  assert.equal(affine.kernel, "planned block contraction");
  assert.deepEqual(affine.contractionBlocks, ["known-left × affine-right", "affine-left × known-right"]);
  assert.equal(affine.usesConvn, false);

  const generic = buildProductPlan({ leftDegree: [1, 0], rightDegree: [0, 1], route: "generic" });
  assert.equal(generic.kernel, "planned pair accumulation");
  assert.equal(generic.contributions.length, 4);
  assert.equal(generic.usesConvn, false);

  const next = updateLastValid(generic, () => buildProductPlan({
    leftDegree: [1], rightDegree: [1, 1], route: "generic",
  }));
  assert.equal(next.model, generic);
  assert.match(next.error, /same number of axes/i);
});
