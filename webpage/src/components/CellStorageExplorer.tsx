import { useId, useState } from "react";
import { renderDisplayMath, renderInlineMath } from "../lib/katex.js";

const cells = [
  {
    c1: 1,
    domainTex: "\\rho_1\\in[0,0.5],\\;\\rho_2\\in[0,1]",
    coefficients: [
      "[1 0; 0 2]", "[3/2 0; 0 2]", "[2 0; 0 2]",
      "[5/4 0; 0 2]", "[7/4 1/8; 1/8 2]", "[9/4 1/4; 1/4 2]",
      "[3/2 0; 0 9/4]", "[2 1/4; 1/4 9/4]", "[5/2 1/2; 1/2 9/4]",
    ],
  },
  {
    c1: 2,
    domainTex: "\\rho_1\\in[0.5,1],\\;\\rho_2\\in[0,1]",
    coefficients: [
      "[3/2 0; 0 9/4]", "[2 1/4; 1/4 9/4]", "[5/2 1/2; 1/2 9/4]",
      "[7/4 0; 0 5/2]", "[9/4 3/8; 3/8 5/2]", "[11/4 3/4; 3/4 5/2]",
      "[2 0; 0 3]", "[5/2 1/2; 1/2 3]", "[3 1; 1 3]",
    ],
  },
] as const;

/** Select one of the two physical hypercubes that store A's degree-two data. */
interface Props {
  formulaHtml?: string[];
  axisHtml?: { x: string[]; y: string[] };
}

const matrixToTex = (value: string) => {
  const rows = value.slice(1, -1).split(";").map((row) => row.trim().split(/\s+/).join("&"));
  return `\\begin{bmatrix}${rows.join("\\\\")}\\end{bmatrix}`;
};

export default function CellStorageExplorer({ formulaHtml = [], axisHtml = { x: [], y: [] } }: Props) {
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
            {formulaHtml[1] && <div dangerouslySetInnerHTML={{ __html: formulaHtml[1] }} />}
          </div>
          <section className="cell-summary__selection" aria-live="polite">
            <p><strong>Selected hypercube:</strong>{" "}<span dangerouslySetInnerHTML={{ __html: renderInlineMath(`c=(${cell.c1},1)`) }} /></p>
            <p><strong>Physical domain:</strong>{" "}<span dangerouslySetInnerHTML={{ __html: renderInlineMath(cell.domainTex) }} /></p>
            <p className="cell-storage-path"><strong>Storage:</strong> <code>A.LocalValues{'{'}c1{'}'}{'{'}1{'}'}</code> → <code>A.LocalValues{'{'}{cell.c1}{'}'}{'{'}1{'}'}</code></p>
          </section>
          <div className="cell-summary__basis" aria-label="Tensor Bernstein basis">
            <a className="cell-basis-link" href="https://en.wikipedia.org/wiki/Bernstein_polynomial">Bernstein basis</a>
            <div dangerouslySetInnerHTML={{ __html: renderDisplayMath("\\footnotesize B_{\\mathbf i}^{m}(\\boldsymbol\\alpha)=\\prod_{s=1}^{\\ell}\\binom{m}{i_s}\\alpha_s^{i_s}(1-\\alpha_s)^{m-i_s}") }} />
          </div>
        </div>
        <div className="cell-layout">
          <div className="cell-grid-panel">
          <div className="cell-grid-stage">
            <div className="cell-axis-y-wrap">
              <div className="cell-axis-ticks cell-axis-ticks--y" aria-label="ρ₁ grid knots">
                {[...axisHtml.y].reverse().map((label) => <span key={label} dangerouslySetInnerHTML={{ __html: label }} />)}
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
                  <span dangerouslySetInnerHTML={{ __html: renderInlineMath(`c_1=${item.c1}`) }} />
                </button>
              ))}
            </div>
            <div className="cell-axis-ticks cell-axis-ticks--x" aria-label="ρ₂ grid knots">
              {axisHtml.x.map((label) => <span key={label} dangerouslySetInnerHTML={{ __html: label }} />)}
            </div>
            </div>
          </div>
          <div className="cell-transform-arrow" aria-hidden="true"><i /></div>
          <section className="cell-coefficient-structure" aria-label="Local Bernstein coefficient structure">
          <div className="cell-coefficient-flow">
            <div className="cell-coeffs" aria-label={`Nine degree-two coefficient matrices in cell (${cell.c1}, 1)`}>
              {cell.coefficients.map((coefficient, index) => (
                <span key={coefficient}>
                  <small dangerouslySetInnerHTML={{ __html: renderInlineMath(`C^{(${cell.c1},1)}_{${Math.floor(index / 3)},${index % 3}}`) }} />
                  <div className="cell-coeff-math" dangerouslySetInnerHTML={{ __html: renderInlineMath(matrixToTex(coefficient)) }} />
                </span>
              ))}
            </div>
            </div>
          </section>
          <div className="cell-transform-arrow" aria-hidden="true"><i /></div>
          <aside className="cell-bernstein-readout" aria-label="Bernstein representation of the selected matrix">
            <div
              className="cell-bernstein-formula"
              dangerouslySetInnerHTML={{
                __html: renderDisplayMath(`\\footnotesize\\begin{gathered}A^{(${cell.c1},1)}(\\boldsymbol\\alpha)=\\sum_{\\mathbf i\\in\\mathcal I_m}C_{\\mathbf i}^{(${cell.c1},1)}B_{\\mathbf i}^{m}(\\boldsymbol\\alpha)\\\\\\mathcal I_m=\\{0,\\ldots,m\\}^{\\ell},\\quad m=2\\end{gathered}`),
              }}
            />
          </aside>
        </div>
      </div>
      <figcaption>For <code>grid = {'{'}[0 0.5 1], [0 1]{'}'}</code>, each button selects one physical hypercube of the degree-two known matrix <code>A</code>.</figcaption>
    </figure>
  );
}
