import { useId, useState } from "react";
import { buildTensor } from "../lib/manual-explorers.ts";

const initial = buildTensor([3, 2], 2);

export default function TensorTraversalExplorer() {
  const [nodes, setNodes] = useState("3, 2");
  const [degree, setDegree] = useState("2");
  const [model, setModel] = useState(initial);
  const [cellIndex, setCellIndex] = useState(0);
  const [labelIndex, setLabelIndex] = useState(0);
  const [error, setError] = useState("");
  const id = useId();
  const update = () => {
    try {
      const parsed = nodes.split(/[\s,]+/).filter(Boolean).map(Number);
      setModel(buildTensor(parsed, degree.trim() === "" ? Number.NaN : Number(degree))); setCellIndex(0); setLabelIndex(0); setError("");
    } catch (reason) { setError(reason instanceof Error ? reason.message : "Invalid tensor grid."); }
  };
  const cell = model.cells[cellIndex];
  const label = model.labels[labelIndex];
  return (
    <figure className="diagram-frame interactive-figure manual-explorer">
      <div className="diagram-frame__body explorer-stack">
        <div className="explorer-controls explorer-controls--row">
          <label htmlFor={`${id}-nodes`}>Node counts by axis</label><input id={`${id}-nodes`} value={nodes} onChange={(event) => setNodes(event.target.value)} />
          <label htmlFor={`${id}-degree`}>Common degree</label><input id={`${id}-degree`} inputMode="numeric" value={degree} onChange={(event) => setDegree(event.target.value)} />
          <button type="button" onClick={update}>Build tensor traversal</button><p className="explorer-error" role="alert">{error}</p>
        </div>
        <div
          className="tensor-counts"
          aria-live="polite"
          style={{ gridTemplateColumns: "repeat(auto-fit, minmax(8.5rem, 1fr))" }}
        >
          <span><strong>{model.nodeCount}</strong> grid nodes</span><span><strong>{model.cellCount}</strong> physical cells</span><span><strong>{model.coefficientsPerCell}</strong> coefficients/<wbr />cell</span>
        </div>
        <div className="tensor-selectors">
          <label htmlFor={`${id}-cell`}>Cell in traversal order</label>
          <select id={`${id}-cell`} value={cellIndex} onChange={(event) => setCellIndex(Number(event.target.value))}>{model.cells.map((value, index) => <option value={index} key={value.join(",")}>{index + 1}: ({value.join(", ")})</option>)}</select>
          <label htmlFor={`${id}-label`}>Local Bernstein label</label>
          <select id={`${id}-label`} value={labelIndex} onChange={(event) => setLabelIndex(Number(event.target.value))}>{model.labels.map((value, index) => <option value={index} key={value.join(",")}>{index + 1}: [{value.join(", ")}]</option>)}</select>
        </div>
        <section className="explorer-readout" aria-live="polite">
          <p><strong>Selected cell:</strong> c = ({cell.join(", ")}). <strong>Label:</strong> [{label.join(", ")}]</p>
          <p><strong>MATLAB path:</strong> <code>A.LocalValues{cell.map((value) => `{${value}}`).join("")}{`{${labelIndex + 1}}`}</code> <span>(flat coefficient column {labelIndex + 1})</span></p>
          <p>The last axis varies fastest in both lists.</p>
        </section>
      </div>
      <figcaption>Physical nodes, cells, and local Bernstein labels are separate tensor products. Changing degree preserves the grid nodes.</figcaption>
    </figure>
  );
}
