import { useEffect, useRef, useState } from "react";

import BernsteinPlot from "./BernsteinPlot.tsx";
import { clientXToUnit, evaluateBernstein, sampleBernstein } from "../lib/bernstein.ts";

const coeffs = [1, 2, 1, 2];

/** Evaluate the documented cubic from pointer position or keyboard input. */
export default function EvaluateExplorer() {
  const [rho, setRho] = useState(0.5);
  const frame = useRef<number | null>(null);
  const plot = useRef<HTMLDivElement>(null);
  const value = evaluateBernstein(coeffs, rho);

  useEffect(() => () => {
    if (frame.current !== null) cancelAnimationFrame(frame.current);
  }, []);

  const selectFromPointer = (clientX: number) => {
    const bounds = plot.current?.querySelector("svg")?.getBoundingClientRect();
    if (!bounds) return;
    const next = clientXToUnit(clientX, bounds);
    if (frame.current !== null) cancelAnimationFrame(frame.current);
    // Pointer movement is transient and is coalesced to one state update per frame.
    frame.current = requestAnimationFrame(() => setRho(next));
  };

  return (
    <figure className="diagram-frame interactive-figure">
      <div className="diagram-frame__body evaluate-explorer">
        <div className="evaluate-expression">
          <strong>A(ρ) = 1 + 3ρ − 6ρ² + 4ρ³</strong>
          <span>Bernstein coefficients: [1, 2, 1, 2]</span>
          <output aria-live="polite">ρ = {rho.toFixed(3)} · A(ρ) = {value.toFixed(4)}</output>
        </div>
        <div
          aria-label="Evaluate A between rho zero and one"
          aria-valuemax={1}
          aria-valuemin={0}
          aria-valuenow={Number(rho.toFixed(3))}
          className="interactive-plot"
          onClick={(event) => selectFromPointer(event.clientX)}
          onKeyDown={(event) => {
            if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
              event.preventDefault();
              setRho((current) => Math.max(0, Math.min(1, current + (event.key === "ArrowRight" ? 0.025 : -0.025))));
            } else if (event.key === "Home" || event.key === "End") {
              event.preventDefault();
              setRho(event.key === "Home" ? 0 : 1);
            }
          }}
          onPointerMove={(event) => {
            if (event.pointerType === "mouse") selectFromPointer(event.clientX);
          }}
          ref={plot}
          role="slider"
          tabIndex={0}
        >
          <BernsteinPlot
            ariaLabel="Cubic A of rho with a movable evaluation marker"
            marker={{ x: rho, y: value }}
            series={[{ label: "A(ρ)", points: sampleBernstein(coeffs), tone: "first" }]}
          />
        </div>
      </div>
      <figcaption>Move the pointer, click or tap, or focus the plot and use the arrow, Home, and End keys.</figcaption>
    </figure>
  );
}
