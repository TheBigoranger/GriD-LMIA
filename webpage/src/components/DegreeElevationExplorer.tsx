import { useId, useState } from "react";
import BernsteinPlot from "./BernsteinPlot.tsx";
import { buildElevation } from "../lib/manual-explorers.ts";
import { sampleBernstein } from "../lib/bernstein.ts";

const initialCoefficients = "1 2 6 2";
const initial = buildElevation(initialCoefficients, 2);

export default function DegreeElevationExplorer() {
  const [coefficients, setCoefficients] = useState(initialCoefficients);
  const [increment, setIncrement] = useState("2");
  const [model, setModel] = useState(initial);
  const [error, setError] = useState("");
  const id = useId();
  const update = () => {
    try { setModel(buildElevation(coefficients, increment.trim() === "" ? Number.NaN : Number(increment))); setError(""); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "Invalid coefficients."); }
  };
  return (
    <figure className="diagram-frame interactive-figure manual-explorer">
      <div className="diagram-frame__body explorer-stack">
        <div className="explorer-controls explorer-controls--row">
          <label htmlFor={`${id}-coeffs`}>Normalized Bernstein coefficients</label>
          <input id={`${id}-coeffs`} value={coefficients} onChange={(event) => setCoefficients(event.target.value)} />
          <label htmlFor={`${id}-inc`}>Degree increment (0–8)</label>
          <input id={`${id}-inc`} inputMode="numeric" value={increment} onChange={(event) => setIncrement(event.target.value)} />
          <button type="button" onClick={update}>Elevate degree</button>
          <p className="explorer-error" role="alert">{error}</p>
        </div>
        <section className="explorer-readout" aria-live="polite">
          <p><strong>Degree {model.original.length - 1} → {model.elevated.length - 1}</strong>. The physical grid stays fixed.</p>
          <p><code>[{model.original.map((value) => Number(value.toPrecision(6))).join(", ")}]</code></p>
          <p><code>[{model.elevated.map((value) => Number(value.toPrecision(6))).join(", ")}]</code></p>
          <p>Maximum sampled difference: <code>{model.maximumSampleError.toExponential(2)}</code></p>
        </section>
        <BernsteinPlot ariaLabel="Original and elevated Bernstein representations coincide" series={[
          { label: "Original representation", points: sampleBernstein(model.original), tone: "first" },
          { label: "Elevated representation", points: sampleBernstein(model.elevated), tone: "result" },
        ]} />
      </div>
      <figcaption>Degree elevation changes coefficient evidence while preserving the polynomial and physical grid. The two sampled curves coincide.</figcaption>
    </figure>
  );
}
