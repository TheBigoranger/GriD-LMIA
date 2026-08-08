import { useId, useState } from "react";

import { buildElevationPlan, updateLastValid } from "../lib/assembly-plans.ts";

const initial = buildElevationPlan({ sourceDegree: [1], targetDegree: [2], coefficients: [1, 3] });

function parseVector(draft: string, name: string): number[] {
  const values = draft.split(/[\s,]+/).filter(Boolean).map(Number);
  if (values.length < 1 || values.length > 2 || values.some((value) => !Number.isInteger(value) || value < 0 || value > 4)) {
    throw new RangeError(`${name} needs one or two integers from 0 to 4.`);
  }
  return values;
}

function parseCoefficients(draft: string): number[] {
  const values = draft.split(/[\s,]+/).filter(Boolean).map(Number);
  if (values.length < 1 || values.some((value) => !Number.isFinite(value))) {
    throw new TypeError("Coefficients must be a nonempty finite list.");
  }
  return values;
}

/** Inspect the sparse numeric plan behind tensor Bernstein degree elevation. */
export default function ElevationPlanExplorer() {
  const id = useId();
  const [draft, setDraft] = useState({ source: "1", target: "2", coefficients: "1 3" });
  const [model, setModel] = useState(() => initial);
  const [error, setError] = useState("");

  const calculate = () => {
    const next = updateLastValid(model, () => buildElevationPlan({
      sourceDegree: parseVector(draft.source, "Source degree"),
      targetDegree: parseVector(draft.target, "Target degree"),
      coefficients: parseCoefficients(draft.coefficients),
    }));
    setModel(next.model);
    setError(next.error);
  };

  return (
    <figure className="diagram-frame interactive-figure plan-explorer">
      <div className="diagram-frame__body explorer-stack">
        <form className="explorer-controls plan-controls" onSubmit={(event) => { event.preventDefault(); calculate(); }}>
          <label htmlFor={`${id}-source`}>Source tensor degree</label>
          <input id={`${id}-source`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft.source}
            onChange={(event) => setDraft((current) => ({ ...current, source: event.target.value }))} />
          <label htmlFor={`${id}-target`}>Target tensor degree</label>
          <input id={`${id}-target`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft.target}
            onChange={(event) => setDraft((current) => ({ ...current, target: event.target.value }))} />
          <label htmlFor={`${id}-coefficients`}>Packed source coefficients</label>
          <input id={`${id}-coefficients`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft.coefficients}
            onChange={(event) => setDraft((current) => ({ ...current, coefficients: event.target.value }))} />
          <button type="submit">Build elevation plan</button>
          <p className="explorer-error" id={`${id}-error`} role="alert">{error}</p>
        </form>
        <section className="plan-summary" aria-live="polite">
          <p><strong>Packed shape:</strong> [{model.packedShape.join(" × ")}] → [{model.targetShape.join(" × ")}]</p>
          <p><strong>Sparse entries:</strong> {model.nnz}</p>
          <p><strong>Transformed coefficients:</strong> [{model.transformed.map((value) => Number(value.toPrecision(6))).join(", ")}]</p>
          <p><strong>Maximum sampled identity error:</strong> {model.maximumSampleError.toExponential(2)}</p>
        </section>
        <div className="plan-entry-grid" aria-label="Nonzero elevation operator entries">
          {model.entries.map((entry, index) => (
            <div className="plan-entry" key={`${entry.target.join("-")}-${entry.source.join("-")}-${index}`}>
              <code>target [{entry.target.join(", ")}]</code>
              <span>←</span>
              <code>source [{entry.source.join(", ")}]</code>
              <strong>{Number(entry.weight.toPrecision(6))}</strong>
            </div>
          ))}
        </div>
      </div>
      <figcaption>The operator is numeric and sparse. An invalid draft leaves the last valid transformation visible.</figcaption>
    </figure>
  );
}
