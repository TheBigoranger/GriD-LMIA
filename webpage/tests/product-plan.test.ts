import assert from "node:assert/strict";
import test from "node:test";
import { buildProductPlan, updateLastValid } from "../src/lib/assembly-plans.ts";

test("contracts numeric coefficients with independently known Bernstein weights", () => {
  const plan = buildProductPlan({ leftDegree: [1], rightDegree: [1], route: "numeric", leftCoefficients: [4, 2], rightCoefficients: [0.5, 3] });
  assert.equal(plan.kernel, "weighted block contraction");
  assert.deepEqual(plan.outputDegree, [2]);
  assert.deepEqual(plan.labelCounts, [2, 2, 3]);
  assert.deepEqual(plan.outputCoefficients, [2, 6.5, 6]);
  assert.deepEqual(plan.contributions.filter((item) => item.target[0] === 1), [
    { target: [1], left: [0], right: [1], weight: 0.5 },
    { target: [1], left: [1], right: [0], weight: 0.5 },
  ]);
});

test("both affine orientations retain the same tensor weights and ordered payload identity", () => {
  for (const route of ["known-affine", "affine-known"] as const) {
    const plan = buildProductPlan({ leftDegree: [1, 0], rightDegree: [0, 1], route });
    assert.equal(plan.kernel, "weighted block contraction");
    assert.deepEqual(plan.contractionBlocks, [route === "known-affine" ? "known-left x affine-right" : "affine-left x known-right"]);
    assert.deepEqual(plan.contributions, [
      {target:[0,0],left:[0,0],right:[0,0],weight:1},
      {target:[0,1],left:[0,0],right:[0,1],weight:1},
      {target:[1,0],left:[1,0],right:[0,0],weight:1},
      {target:[1,1],left:[1,0],right:[0,1],weight:1},
    ]);
    assert.equal(plan.outputCoefficients, null);
    const next = updateLastValid(plan, () => buildProductPlan({leftDegree:[1],rightDegree:[1,1],route}));
    assert.equal(next.model, plan);
    assert.match(next.error, /same number of axes/i);
  }
});

test("unequal degrees produce the direct polynomial product at interior points", () => {
  const plan = buildProductPlan({leftDegree:[2],rightDegree:[1],route:"numeric",leftCoefficients:[1,3,-2],rightCoefficients:[4,-1]});
  // (1+4t-7t^2)(4-5t) = 4+11t-48t^2+35t^3.
  for (const t of [0,.13,.5,.81,1]) {
    const c=plan.outputCoefficients!;
    const actual=c[0]*(1-t)**3+3*c[1]*t*(1-t)**2+3*c[2]*t*t*(1-t)+c[3]*t**3;
    assert.ok(Math.abs(actual-(4+11*t-48*t*t+35*t**3))<1e-12);
  }
});
