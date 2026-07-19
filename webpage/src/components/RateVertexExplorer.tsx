import { useId, useState } from "react";
import { parseRateBounds } from "../lib/manual-explorers.ts";

const initial = parseRateBounds("-1 2; -3 5", 4);

export default function RateVertexExplorer() {
  const [bounds, setBounds] = useState("-1 2; -3 5");
  const [columns, setColumns] = useState("4");
  const [model, setModel] = useState(initial);
  const [error, setError] = useState("");
  const id = useId();
  const update = () => {
    try {
      setModel(parseRateBounds(bounds, Number(columns)));
      setError("");
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Invalid rate bounds.");
    }
  };
  return (
    <figure className="diagram-frame interactive-figure manual-explorer">
      <div className="diagram-frame__body">
        <div className="explorer-controls">
          <label htmlFor={`${id}-bounds`}>Rate bounds (one <code>lower upper</code> row per axis)</label>
          <textarea id={`${id}-bounds`} rows={3} value={bounds} onChange={(event) => setBounds(event.target.value)} />
          <label htmlFor={`${id}-columns`}>Coefficient columns per cell</label>
          <input id={`${id}-columns`} inputMode="numeric" value={columns} onChange={(event) => setColumns(event.target.value)} />
          <button type="button" onClick={update}>Update vertices</button>
          <p className="explorer-error" role="alert">{error}</p>
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
