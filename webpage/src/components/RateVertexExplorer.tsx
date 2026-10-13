import { useId, useState } from "react";
import { parseRateBounds } from "../lib/manual-explorers.ts";

const initial = parseRateBounds("-1 2; -3 5", 4);

export default function RateVertexExplorer() {
  const [boundsDraft, setBoundsDraft] = useState("-1 2; -3 5");
  const [columnsDraft, setColumnsDraft] = useState("4");
  const [model, setModel] = useState(initial);
  const [error, setError] = useState("");
  const [errorField, setErrorField] = useState<"bounds" | "columns" | "">("");
  const [status, setStatus] = useState("Showing the initial four rate rows.");
  const id = useId();
  const markDraft = () => {
    setError("");
    setErrorField("");
    setStatus("Draft changed. Select Update vertices to validate and apply it.");
  };
  const update = () => {
    try {
      const next = parseRateBounds(boundsDraft, Number(columnsDraft));
      setModel(next);
      setError("");
      setErrorField("");
      setStatus(`Updated to ${next.vertices.length} rate rows and ${next.coefficientColumns} coefficient columns.`);
    } catch (reason) {
      const message = reason instanceof Error ? reason.message : "Invalid rate bounds.";
      setError(message);
      setErrorField(message.startsWith("Coefficient columns") ? "columns" : "bounds");
      setStatus("Draft not applied. The last valid rate table remains visible.");
    }
  };
  return (
    <figure className="diagram-frame interactive-figure manual-explorer">
      <div className="diagram-frame__body">
        <div className="explorer-controls">
          <label htmlFor={`${id}-bounds`}>Rate bounds (one <code>lower upper</code> row per axis)</label>
          <textarea
            aria-describedby={`${id}-status ${id}-error`}
            aria-invalid={errorField === "bounds"}
            id={`${id}-bounds`}
            rows={3}
            value={boundsDraft}
            onChange={(event) => {
              setBoundsDraft(event.target.value);
              markDraft();
            }}
          />
          <label htmlFor={`${id}-columns`}>Coefficient columns per cell</label>
          <input
            aria-describedby={`${id}-status ${id}-error`}
            aria-invalid={errorField === "columns"}
            id={`${id}-columns`}
            inputMode="numeric"
            value={columnsDraft}
            onChange={(event) => {
              setColumnsDraft(event.target.value);
              markDraft();
            }}
          />
          <button type="button" onClick={update}>Update vertices</button>
          <p id={`${id}-status`} role="status">{status}</p>
          <p className="explorer-error" id={`${id}-error`} role="alert">{error}</p>
        </div>
        <section className="explorer-readout" aria-live="polite">
          <p><strong>{model.vertices.length} rate rows × {model.coefficientColumns} coefficient columns</strong> in each physical cell.</p>
          <ol className="vertex-list">
            {model.vertices.map((vertex, index) => <li key={`${index}-${vertex.join(",")}`}><code>row {index + 1}: ({vertex.join(", ")})</code></li>)}
          </ol>
          <p className="storage-strip"><code>LocalValues{'{'}c₁{'}'}…{'{'}cℓ{'}'}</code> → rate row → Bernstein coefficient</p>
        </section>
      </div>
      <figcaption>Earlier axes vary more slowly and the last axis varies fastest, exactly as in <code>helper.combRows</code>. Invalid edits leave the last valid table visible.</figcaption>
    </figure>
  );
}
