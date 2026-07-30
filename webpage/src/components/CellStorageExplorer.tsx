import { useId, useState } from "react";
import { pdmatCellData as cells } from "../lib/cell-bernstein.ts";
import { DisplayMath, InlineMath } from "./RenderedMath.tsx";

/** Select one of the two physical hypercubes that store A's degree-two data. */
interface Props {
  mathMarkup: {
    formula: string;
    basis: string;
    axis: { x: string[]; y: string[] };
    cells: Array<{
      selection: string;
      domain: string;
      button: string;
      coefficients: Array<{ label: string; value: string }>;
      bernstein: string;
    }>;
  };
}

export default function CellStorageExplorer({ mathMarkup }: Props) {
  const [selected, setSelected] = useState(0);
  const groupId = useId();
  const cell = cells[selected];
  const cellMath = mathMarkup.cells[selected];

  const move = (index: number, key: string) => {
    const next = ["ArrowLeft", "ArrowUp"].includes(key)
      ? (index + cells.length - 1) % cells.length
      : (index + 1) % cells.length;
    setSelected(next);
    document.getElementById(`${groupId}-${next}`)?.focus();
  };

  return (
    <figure className="diagram-frame interactive-figure">
      <div className="diagram-frame__body cell-explorer">
        <div className="cell-summary">
          <div className="cell-summary__formula" aria-label="Known matrix formula">
            <strong>Known matrix</strong>
            <DisplayMath markup={mathMarkup.formula} />
          </div>
          <section className="cell-summary__selection" aria-live="polite">
            <p><strong>Selected hypercube:</strong>{" "}<InlineMath markup={cellMath.selection} /></p>
            <p><strong>Physical domain:</strong>{" "}<InlineMath markup={cellMath.domain} /></p>
            <p className="cell-storage-path"><strong>Storage:</strong> <code>A.LocalValues{'{'}c1{'}'}{'{'}1{'}'}</code> → <code>A.LocalValues{'{'}{cell.c1}{'}'}{'{'}1{'}'}</code></p>
          </section>
          <div className="cell-summary__basis" aria-label="Tensor Bernstein basis">
            <a className="cell-basis-link" href="https://en.wikipedia.org/wiki/Bernstein_polynomial">Bernstein basis</a>
            <DisplayMath markup={mathMarkup.basis} />
          </div>
        </div>
        <div className="cell-layout">
          <div className="cell-grid-panel">
          <div className="cell-grid-stage">
            <div className="cell-axis-y-wrap">
              <div className="cell-axis-ticks cell-axis-ticks--y" aria-label="ρ₁ grid knots">
                {[...mathMarkup.axis.y].reverse().map((markup, index) => <InlineMath key={index} markup={markup} />)}
              </div>
            </div>
            <div className="cell-grid" role="group" aria-label="Select one of two hypercubes with arrow keys">
              {cells.map((item, index) => (
                <button
                  aria-pressed={selected === index}
                  className={selected === index ? "selected" : ""}
                  id={`${groupId}-${index}`}
                  key={item.c1}
                  onClick={() => setSelected(index)}
                  onKeyDown={(event) => {
                    if (["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(event.key)) {
                      event.preventDefault();
                      move(index, event.key);
                    }
                  }}
                  style={{ gridRow: cells.length - index }}
                  type="button"
                >
                  <InlineMath markup={mathMarkup.cells[index].button} />
                </button>
              ))}
            </div>
            <div className="cell-axis-ticks cell-axis-ticks--x" aria-label="ρ₂ grid knots">
              {mathMarkup.axis.x.map((markup, index) => <InlineMath key={index} markup={markup} />)}
            </div>
            </div>
          </div>
          <div className="cell-transform-arrow" aria-hidden="true"><i /></div>
          <section className="cell-coefficient-structure" aria-label="Local Bernstein coefficient structure">
          <div className="cell-coefficient-flow">
            <div className="cell-coeffs" aria-label={`Nine degree-two coefficient matrices in cell (${cell.c1}, 1)`}>
              {cell.coefficients.map((_, index) => (
                <span key={`${cell.c1}-${index}`}>
                  <small><InlineMath markup={cellMath.coefficients[index].label} /></small>
                  <div className="cell-coeff-math"><InlineMath markup={cellMath.coefficients[index].value} /></div>
                </span>
              ))}
            </div>
            </div>
          </section>
          <div className="cell-transform-arrow" aria-hidden="true"><i /></div>
          <aside className="cell-bernstein-readout" aria-label="Bernstein representation of the selected matrix">
            <DisplayMath
              className="cell-bernstein-formula"
              markup={cellMath.bernstein}
            />
          </aside>
        </div>
      </div>
      <figcaption>For <code>grid = {'{'}[0 0.5 1], [0 1]{'}'}</code>, each button selects one physical hypercube of the degree-two known matrix <code>A</code>.</figcaption>
    </figure>
  );
}
