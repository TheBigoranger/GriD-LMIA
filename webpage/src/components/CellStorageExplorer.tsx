import { useId, useState } from "react";
import { pdmatCellData as cells } from "../lib/cell-bernstein.ts";
import { DisplayMath, InlineMath } from "./MathJaxMath.tsx";

/** Select one of the two physical hypercubes that store A's degree-two data. */
interface Props {
  formulaTex?: string;
  axisTex?: { x: string[]; y: string[] };
}

export default function CellStorageExplorer({ formulaTex = "", axisTex = { x: [], y: [] } }: Props) {
  const [selected, setSelected] = useState(0);
  const groupId = useId();
  const cell = cells[selected];

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
            {formulaTex && <DisplayMath tex={formulaTex} />}
          </div>
          <section className="cell-summary__selection" aria-live="polite">
            <p><strong>Selected hypercube:</strong>{" "}<InlineMath tex={`c=(${cell.c1},1)`} /></p>
            <p><strong>Physical domain:</strong>{" "}<InlineMath tex={cell.domainTex} /></p>
            <p className="cell-storage-path"><strong>Storage:</strong> <code>A.LocalValues{'{'}c1{'}'}{'{'}1{'}'}</code> → <code>A.LocalValues{'{'}{cell.c1}{'}'}{'{'}1{'}'}</code></p>
          </section>
          <div className="cell-summary__basis" aria-label="Tensor Bernstein basis">
            <a className="cell-basis-link" href="https://en.wikipedia.org/wiki/Bernstein_polynomial">Bernstein basis</a>
            <DisplayMath tex="B_{\mathbf i}^{m}(\boldsymbol\alpha)=\prod_{s=1}^{\ell}\binom{m}{i_s}\alpha_s^{i_s}(1-\alpha_s)^{m-i_s}" />
          </div>
        </div>
        <div className="cell-layout">
          <div className="cell-grid-panel">
          <div className="cell-grid-stage">
            <div className="cell-axis-y-wrap">
              <div className="cell-axis-ticks cell-axis-ticks--y" aria-label="ρ₁ grid knots">
                {[...axisTex.y].reverse().map((label) => <InlineMath key={label} tex={label} />)}
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
                  <InlineMath tex={`c_1=${item.c1}`} />
                </button>
              ))}
            </div>
            <div className="cell-axis-ticks cell-axis-ticks--x" aria-label="ρ₂ grid knots">
              {axisTex.x.map((label) => <InlineMath key={label} tex={label} />)}
            </div>
            </div>
          </div>
          <div className="cell-transform-arrow" aria-hidden="true"><i /></div>
          <section className="cell-coefficient-structure" aria-label="Local Bernstein coefficient structure">
          <div className="cell-coefficient-flow">
            <div className="cell-coeffs" aria-label={`Nine degree-two coefficient matrices in cell (${cell.c1}, 1)`}>
              {cell.coefficients.map((coefficient, index) => (
                <span key={`${cell.c1}-${index}`}>
                  <small><InlineMath tex={`C^{(${cell.c1},1)}_{${Math.floor(index / 3)},${index % 3}}`} /></small>
                  <div className="cell-coeff-math"><InlineMath tex={coefficient.tex} /></div>
                </span>
              ))}
            </div>
            </div>
          </section>
          <div className="cell-transform-arrow" aria-hidden="true"><i /></div>
          <aside className="cell-bernstein-readout" aria-label="Bernstein representation of the selected matrix">
            <DisplayMath
              className="cell-bernstein-formula"
              tex={`A^{(${cell.c1},1)}(\\boldsymbol\\alpha)=\\sum_{\\mathbf i\\in\\{0,1,2\\}^{\\ell}}C_{\\mathbf i}^{(${cell.c1},1)}B_{\\mathbf i}^{2}(\\boldsymbol\\alpha)`}
            />
          </aside>
        </div>
      </div>
      <figcaption>For <code>grid = {'{'}[0 0.5 1], [0 1]{'}'}</code>, each button selects one physical hypercube of the degree-two known matrix <code>A</code>.</figcaption>
    </figure>
  );
}
