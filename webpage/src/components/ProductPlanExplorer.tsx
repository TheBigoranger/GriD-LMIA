import { useId, useState } from "react";

import { buildProductPlan, updateLastValid, type ProductRoute } from "../lib/assembly-plans.ts";

const initial = buildProductPlan({
  leftDegree: [1], rightDegree: [1], route: "numeric",
  leftCoefficients: [4, 2], rightCoefficients: [0.5, 3],
});

function parseDegree(draft: string): number[] {
  const values = draft.split(/[\s,]+/).filter(Boolean).map(Number);
  if (values.length < 1 || values.length > 2 || values.some((value) => !Number.isInteger(value) || value < 0 || value > 3)) {
    throw new RangeError("Each degree needs one or two integers from 0 to 3.");
  }
  return values;
}

function parseValues(draft: string): number[] {
  const values = draft.split(/[\s,]+/).filter(Boolean).map(Number);
  if (values.length < 1 || values.some((value) => !Number.isFinite(value))) {
    throw new TypeError("Numeric routes need finite coefficient lists.");
  }
  return values;
}

/** Compare the three product kernels through their shared coefficient-pair plan. */
export default function ProductPlanExplorer() {
  const id = useId();
  const [draft, setDraft] = useState({ leftDegree: "1", rightDegree: "1", route: "numeric" as ProductRoute, left: "4 2", right: "0.5 3" });
  const [model, setModel] = useState(() => initial);
  const [error, setError] = useState("");

  const calculate = () => {
    const next = updateLastValid(model, () => buildProductPlan({
      leftDegree: parseDegree(draft.leftDegree),
      rightDegree: parseDegree(draft.rightDegree),
      route: draft.route,
      leftCoefficients: draft.route === "numeric" ? parseValues(draft.left) : undefined,
      rightCoefficients: draft.route === "numeric" ? parseValues(draft.right) : undefined,
    }));
    setModel(next.model);
    setError(next.error);
  };

  return (
    <figure className="diagram-frame interactive-figure plan-explorer">
      <div className="diagram-frame__body explorer-stack">
        <form className="explorer-controls plan-controls" onSubmit={(event) => { event.preventDefault(); calculate(); }}>
          <label htmlFor={`${id}-left-degree`}>Left tensor degree</label>
          <input id={`${id}-left-degree`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft.leftDegree}
            onChange={(event) => setDraft((current) => ({ ...current, leftDegree: event.target.value }))} />
          <label htmlFor={`${id}-right-degree`}>Right tensor degree</label>
          <input id={`${id}-right-degree`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft.rightDegree}
            onChange={(event) => setDraft((current) => ({ ...current, rightDegree: event.target.value }))} />
          <label htmlFor={`${id}-route`}>Payload route</label>
          <select id={`${id}-route`} aria-describedby={`${id}-error`} value={draft.route}
            onChange={(event) => setDraft((current) => ({ ...current, route: event.target.value as ProductRoute }))}>
            <option value="numeric">Numeric tensor convolution</option>
            <option value="known-affine">Known–affine contraction</option>
            <option value="generic">Generic planned fallback</option>
          </select>
          {draft.route === "numeric" ? <>
            <label htmlFor={`${id}-left`}>Left coefficients</label>
            <input id={`${id}-left`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft.left}
              onChange={(event) => setDraft((current) => ({ ...current, left: event.target.value }))} />
            <label htmlFor={`${id}-right`}>Right coefficients</label>
            <input id={`${id}-right`} aria-describedby={`${id}-error`} aria-invalid={Boolean(error)} value={draft.right}
              onChange={(event) => setDraft((current) => ({ ...current, right: event.target.value }))} />
          </> : null}
          <button type="submit">Build product plan</button>
          <p className="explorer-error" id={`${id}-error`} role="alert">{error}</p>
        </form>
        <section className="plan-summary" aria-live="polite">
          <p><strong>Kernel:</strong> {model.kernel}</p>
          <p><strong>Packed tensor shapes:</strong> {model.packedShapes.map((shape) => `[${shape.join(" × ")}]`).join(" → ")}</p>
          <p><strong>Planned label pairs:</strong> {model.contributions.length}</p>
          <p><strong><code>convn</code> route:</strong> {model.usesConvn ? "Numeric payload" : "Inactive"}</p>
          {model.outputCoefficients ? <p><strong>Product coefficients:</strong> [{model.outputCoefficients.map((value) => Number(value.toPrecision(6))).join(", ")}]</p> : null}
          {model.contractionBlocks.length ? <p><strong>Affine blocks:</strong> {model.contractionBlocks.join(" and ")}</p> : null}
        </section>
        <div className="plan-entry-grid" aria-label="Planned normalized product contributions">
          {model.contributions.map((item, index) => (
            <div className="plan-entry" key={`${item.target.join("-")}-${index}`}>
              <code>[{item.left.join(", ")}] + [{item.right.join(", ")}]</code>
              <span>→</span>
              <code>[{item.target.join(", ")}]</code>
              <strong>{Number(item.weight.toPrecision(6))}</strong>
            </div>
          ))}
        </div>
      </div>
      <figcaption>All payload routes use the same normalized label pairs. Only purely numeric tensors enter <code>convn</code>.</figcaption>
    </figure>
  );
}
