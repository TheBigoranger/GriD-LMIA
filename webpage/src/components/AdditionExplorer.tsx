import { useDeferredValue, useMemo, useState } from "react";

import BernsteinPlot from "./BernsteinPlot.tsx";
import {
  alignAndAdd,
  initialAdditionInput,
  maxAdditionCoefficients,
  updateAdditionInput,
} from "../lib/addition-input.ts";
import { sampleBernstein } from "../lib/bernstein.ts";

const format = (value: number) => Number(value.toPrecision(7)).toString();

/** Explore exact common-degree addition while retaining the last valid plot. */
export default function AdditionExplorer() {
  const [input, setInput] = useState(initialAdditionInput);
  const deferred = useDeferredValue(input.valid);
  const aligned = useMemo(
    () => alignAndAdd(deferred.left, deferred.right),
    [deferred],
  );
  const degree = aligned.sum.length - 1;

  return (
    <figure className="diagram-frame interactive-figure">
      <div className="diagram-frame__body explorer-stack">
        <div className="coefficient-inputs">
          <label>
            A coefficients
            <input
              aria-describedby="addition-help addition-a-error"
              aria-invalid={Boolean(input.errors.left)}
              value={input.leftText}
              onChange={(event) => setInput((current) => updateAdditionInput(current, "left", event.target.value))}
            />
            <span className="input-error" id="addition-a-error" role="alert">{input.errors.left}</span>
          </label>
          <label>
            B coefficients
            <input
              aria-describedby="addition-help addition-b-error"
              aria-invalid={Boolean(input.errors.right)}
              value={input.rightText}
              onChange={(event) => setInput((current) => updateAdditionInput(current, "right", event.target.value))}
            />
            <span className="input-error" id="addition-b-error" role="alert">{input.errors.right}</span>
          </label>
        </div>
        <p className="input-help" id="addition-help">
          Enter nonempty finite lists separated by commas and/or spaces. Use at most {maxAdditionCoefficients} coefficients per addend.
        </p>
        <section className="addition-readout" aria-live="polite">
          <p><strong>Common degree {degree}</strong></p>
          <p><span>Elevated A</span><code>[{aligned.left.map(format).join(", ")}]</code></p>
          <p><span>Elevated B</span><code>[{aligned.right.map(format).join(", ")}]</code></p>
          <p><span>A + B</span><code>[{aligned.sum.map(format).join(", ")}]</code></p>
        </section>
        <BernsteinPlot
          ariaLabel={`Aligned degree ${degree} addends and their sum`}
          series={[
            { label: `A · degree ${degree}`, points: sampleBernstein(aligned.left), tone: "first" },
            { label: `B · degree ${degree}`, points: sampleBernstein(aligned.right), tone: "second" },
            { label: `A + B · degree ${degree}`, points: sampleBernstein(aligned.sum), tone: "result" },
          ]}
        />
      </div>
      <figcaption>Both rows are elevated exactly to a common degree before labelwise addition. Malformed edits leave the last jointly valid plot in place.</figcaption>
    </figure>
  );
}
