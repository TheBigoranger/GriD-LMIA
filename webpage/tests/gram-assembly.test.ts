import assert from "node:assert/strict";
import test from "node:test";

import {
  buildGramAssembly,
  parseGramResidualDegreeDraft,
  updateLastValid,
} from "../src/lib/assembly-plans.ts";

test("groups diagonal and paired off-diagonal contributions for z=[B0^1,B1^1]", () => {
  const model = buildGramAssembly({
    family: "fullbox", residualDegree: [2], order: [1], windowSize: 2, matrixSize: 1,
    entries: 1, cells: 1, rateRows: 1,
  });

  assert.deepEqual(model.targetLabels, [[0], [1], [2]]);
  assert.deepEqual(model.blocks[0].map, [
    { target: [0], kind: "diagonal", pair: [[0], [0]], weight: 1 },
    { target: [1], kind: "paired off-diagonal", pair: [[0], [1]], weight: 1 },
    { target: [2], kind: "diagonal", pair: [[1], [1]], weight: 1 },
  ]);
  assert.equal(model.blocks[0].psdDimension, 2);
  assert.deepEqual(model.blocks.map((block) => block.generatorPowers), [
    { alpha: [0], oneMinusAlpha: [0] },
    { alpha: [1], oneMinusAlpha: [1] },
  ]);
});

test("matches the one-dimensional odd endpoint-weighted parity specification", () => {
  const model = buildGramAssembly({
    family: "putinar", residualDegree: [3], order: [2], windowSize: 3, matrixSize: 1,
    entries: 1, cells: 1, rateRows: 1,
  });

  assert.deepEqual(model.targetDegree, [5]);
  assert.equal(model.targetLabels.length, 6);
  assert.deepEqual(model.blocks.map((block) => block.generatorPowers), [
    { alpha: [0], oneMinusAlpha: [1] },
    { alpha: [1], oneMinusAlpha: [0] },
  ]);
  assert.deepEqual(model.blocks.map((block) => block.psdDimension), [3, 3]);
  assert.deepEqual(model.blocks[0].map[0], {
    target: [0], kind: "diagonal", pair: [[0], [0]], weight: 1,
  });
  assert.deepEqual(model.blocks[1].map[0], {
    target: [1], kind: "diagonal", pair: [[0], [0]], weight: 0.2,
  });
});

test("parses residual degrees through 8 independently from the explorer order limit", () => {
  for (let degree = 4; degree <= 8; degree += 1) {
    assert.deepEqual(parseGramResidualDegreeDraft(`${degree}`), [degree]);
  }

  for (const degree of [4, 5, 6, 7]) {
    assert.doesNotThrow(() => buildGramAssembly({
      family: "putinar", residualDegree: [degree], order: [Math.floor(degree / 2)],
      windowSize: 1, matrixSize: 1, entries: 1, cells: 1, rateRows: 1,
    }));
  }
  assert.throws(() => parseGramResidualDegreeDraft("4.5"), /Residual degree/);
  assert.throws(() => parseGramResidualDegreeDraft(""), /Residual degree/);
  assert.throws(() => buildGramAssembly({
    family: "putinar", residualDegree: [8], order: [3], windowSize: 1,
    matrixSize: 1, entries: 1, cells: 1, rateRows: 1,
  }), /Gram order must be at least \[4\]/);
});

test("enumerates sliding tensor windows and separates reusable maps from fresh Gram variables", () => {
  const model = buildGramAssembly({
    family: "sparsefullbox", residualDegree: [4], order: [2], windowSize: 2, matrixSize: 2,
    entries: 4, cells: 3, rateRows: 2,
  });

  assert.deepEqual(model.blocks.slice(0, 2).map((block) => block.windowStart), [[0], [1]]);
  assert.ok(model.blocks.every((block) => block.psdDimension <= 4));
  assert.equal(model.freshGramCopies, 24 * model.blocks.length);
  assert.equal(model.reusableNumericMaps, model.blocks.length);

  const next = updateLastValid(model, () => buildGramAssembly({
    family: "sparsefullbox", residualDegree: [2], order: [1], windowSize: 3, matrixSize: 1,
    entries: 1, cells: 1, rateRows: 1,
  }));
  assert.equal(next.model, model);
  assert.match(next.error, /window size.*at most/i);
});
