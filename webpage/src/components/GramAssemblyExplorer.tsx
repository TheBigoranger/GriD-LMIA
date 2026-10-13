import { useId, useState } from "react";

import {
  buildGramAssembly,
  parseGramResidualDegreeDraft,
  updateLastValid,
  type GramFamily,
} from "../lib/assembly-plans.ts";
import { TermText } from "./TermText.tsx";

const initial = buildGramAssembly({
  family: "fullbox", residualDegree: [2], order: [1], windowSize: 2, matrixSize: 1,
  entries: 1, cells: 1, rateRows: 1,
});

function numberDraft(draft: string, name: string): number {
  const value = draft.trim() === "" ? Number.NaN : Number(draft);
  if (!Number.isInteger(value)) throw new RangeError(`${name} must be an integer.`);
  return value;
}

function orderDraft(draft: string): number[] {
  const values = draft.split(/[\s,]+/).filter(Boolean).map(Number);
  if (values.length < 1 || values.length > 2 || values.some((value) => !Number.isInteger(value) || value < 0 || value > 3)) {
    throw new RangeError("Order needs one or two integers from 0 to 3.");
  }
  return values;
}

/** Inspect reusable Bernstein–Gram maps separately from fresh decision variables. */
export default function GramAssemblyExplorer() {
  const id = useId();
  const [draft, setDraft] = useState({ family: "fullbox" as GramFamily, degree: "2", order: "1", window: "2", matrix: "1", entries: "1", cells: "1", rates: "1" });
  const [model, setModel] = useState(() => initial);
  const [error, setError] = useState("");

  const calculate = () => {
    const next = updateLastValid(model, () => buildGramAssembly({
      family: draft.family,
      residualDegree: parseGramResidualDegreeDraft(draft.degree),
      order: orderDraft(draft.order),
      windowSize: numberDraft(draft.window, "Window size"),
      matrixSize: numberDraft(draft.matrix, "Matrix size"),
      entries: numberDraft(draft.entries, "Matrix entries"),
      cells: numberDraft(draft.cells, "Physical cells"),
      rateRows: numberDraft(draft.rates, "Rate rows"),
    }));
    setModel(next.model);
    setError(next.error);
  };

  return (
    <figure className="diagram-frame interactive-figure plan-explorer gram-plan-explorer">
      <div className="diagram-frame__body explorer-stack">
        <form className="explorer-controls plan-controls" onSubmit={(event) => { event.preventDefault(); calculate(); }}>
          <label htmlFor={`${id}-family`}>Certificate family</label>
          <select id={`${id}-family`} value={draft.family}
            aria-describedby={`${id}-error`}
            onChange={(event) => setDraft((current) => ({ ...current, family: event.target.value as GramFamily }))}>
            <option value="putinar">Putinar</option><option value="sparseputinar">SparsePutinar</option>
            <option value="sparsefullbox">SparseFullBox</option><option value="fullbox">FullBox</option>
          </select>
          {(["degree", "order", "window", "matrix", "entries", "cells", "rates"] as const).map((key) => (
            <label key={key} htmlFor={`${id}-${key}`}>{({ degree: "Residual tensor degree", order: "Tensor order", window: "Tensor-window side", matrix: "Matrix size", entries: "Independent entries", cells: "Physical cells", rates: "Stored rate rows" })[key]}
              <input id={`${id}-${key}`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft[key]}
                onChange={(event) => setDraft((current) => ({ ...current, [key]: event.target.value }))} />
            </label>
          ))}
          <button type="submit">Build Gram plan</button>
          <p className="explorer-error" id={`${id}-error`} role="alert">{error}</p>
        </form>
        <section className="plan-summary" aria-live="polite">
          <p><strong>Target degree:</strong> [{model.targetDegree.join(", ")}]</p>
          <p><strong>Target labels:</strong> {model.targetLabels.map((label) => `[${label.join(", ")}]`).join(" ")}</p>
          <p><strong>Reusable numeric maps:</strong> {model.reusableNumericMaps}</p>
          <p><strong>Fresh Gram variables:</strong> {model.freshGramCopies}</p>
          <p>Numeric maps may be reused. Every entry, cell, rate row, and block receives a fresh Gram variable.</p>
        </section>
        <div className="gram-plan-grid" aria-label="Gram blocks and coefficient maps">
          {model.blocks.map((block, index) => (
            <section className="gram-plan-block" key={`${block.generator}-${block.windowStart.join("-")}-${index}`}>
              <h4>{block.generator}, window [{block.windowStart.join(", ")}]</h4>
              <p>Generator powers: alpha [{block.generatorPowers.alpha.join(", ")}], one-minus-alpha [{block.generatorPowers.oneMinusAlpha.join(", ")}]</p>
              <p><TermText>Shape and PSD dimension</TermText>: [{block.windowShape.join(" × ")}], {block.psdDimension}</p>
              <ul>{block.map.map((entry, mapIndex) => <li key={`${entry.target.join("-")}-${mapIndex}`}>
                <code>[{entry.target.join(", ")}]</code>: {entry.kind}, weight {Number(entry.weight.toPrecision(6))}
              </li>)}</ul>
            </section>
          ))}
        </div>
      </div>
      <figcaption>Sliding tensor windows select local basis labels. Their support lies in the tensor label lattice and differs from a band on a flattened Gram matrix.</figcaption>
    </figure>
  );
}
