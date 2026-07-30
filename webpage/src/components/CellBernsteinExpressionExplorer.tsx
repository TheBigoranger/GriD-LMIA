import { useId, useMemo, useState } from "react";
import {
  buildCellBernsteinModel,
  type Matrix2,
  orderCellBernsteinTermsForAxes,
  pdmatCellData,
} from "../lib/cell-bernstein.ts";
import { DisplayMath, InlineMath } from "./MathJaxMath.tsx";

const formatNumber = (value: number) => {
  const rounded = Math.abs(value) < 5e-10 ? 0 : Number(value.toFixed(4));
  return `${rounded}`;
};

const matrixToTex = (matrix: Matrix2) => (
  `\\begin{bmatrix}${formatNumber(matrix[0])}&${formatNumber(matrix[1])}\\\\${formatNumber(matrix[2])}&${formatNumber(matrix[3])}\\end{bmatrix}`
);

/** Explore the tensor Bernstein expression stored independently on each physical cell. */
export default function CellBernsteinExpressionExplorer() {
  const [selectedCell, setSelectedCell] = useState(0);
  const [alpha1, setAlpha1] = useState(0.35);
  const [alpha2, setAlpha2] = useState(0.6);
  const [selectedTerm, setSelectedTerm] = useState(4);
  const id = useId();
  const model = useMemo(
    () => buildCellBernsteinModel(selectedCell, alpha1, alpha2),
    [selectedCell, alpha1, alpha2],
  );
  const displayedTerms = orderCellBernsteinTermsForAxes(model.terms);
  const term = model.terms[selectedTerm];
  const contribution: Matrix2 = [
    term.coefficient.values[0] * term.weight,
    term.coefficient.values[1] * term.weight,
    term.coefficient.values[2] * term.weight,
    term.coefficient.values[3] * term.weight,
  ];

  const selectCell = (index: number) => {
    setSelectedCell(index);
    document.getElementById(`${id}-cell-${index}`)?.focus();
  };

  return (
    <figure className="diagram-frame interactive-figure cell-basis-expression">
      <div className="diagram-frame__body">
        <DisplayMath
          className="cell-basis-expression__global-formula"
          tex={`\\begin{aligned}
              A(\\boldsymbol\\rho)
              &=
              \\begin{bmatrix}
              1+\\rho_1+\\rho_2 & \\rho_1\\rho_2\\\\
              \\rho_1\\rho_2 & 2+\\rho_1^2
              \\end{bmatrix},
              \\qquad \\boldsymbol\\rho\\in[0,1]^2.
              \\end{aligned}`}
        />
        <p className="cell-basis-expression__global-note">
          The tabs below show how this single matrix function is pulled back to local
          coordinates and represented independently on each physical cell.
        </p>
        <div className="cell-basis-tabs" role="tablist" aria-label="Physical cell for the Bernstein expression">
          {pdmatCellData.map((cell, index) => (
            <button
              aria-controls={`${id}-panel`}
              aria-selected={selectedCell === index}
              id={`${id}-cell-${index}`}
              key={cell.c1}
              onClick={() => setSelectedCell(index)}
              onKeyDown={(event) => {
                if (["ArrowLeft", "ArrowUp"].includes(event.key)) {
                  event.preventDefault();
                  selectCell((index + pdmatCellData.length - 1) % pdmatCellData.length);
                }
                if (["ArrowRight", "ArrowDown"].includes(event.key)) {
                  event.preventDefault();
                  selectCell((index + 1) % pdmatCellData.length);
                }
              }}
              role="tab"
              tabIndex={selectedCell === index ? 0 : -1}
              type="button"
            >
              <strong>Cell {cell.c1}</strong>
              <InlineMath tex={cell.domainTex} />
            </button>
          ))}
        </div>
        <section
          aria-labelledby={`${id}-cell-${selectedCell}`}
          className="cell-basis-panel"
          id={`${id}-panel`}
          role="tabpanel"
        >
          <DisplayMath
            className="cell-basis-expression__formula"
            tex={`\\begin{aligned}A^{(${model.cell.c1},1)}(\\boldsymbol\\alpha)&=\\sum_{\\mathbf i\\in\\{0,1,2\\}^{2}}C_{\\mathbf i}^{(${model.cell.c1},1)}B_{\\mathbf i}^{2}(\\boldsymbol\\alpha),\\\\B_{\\mathbf i}^{2}(\\boldsymbol\\alpha)&=B_{i_1}^{2}(\\alpha_1)B_{i_2}^{2}(\\alpha_2).\\end{aligned}`}
          />
          <div className="cell-basis-workspace">
            <div className="cell-basis-coordinate-frame">
              <strong className="cell-basis-coordinate-frame__title">Local coordinates</strong>
              <label className="cell-basis-axis cell-basis-axis--vertical" htmlFor={`${id}-alpha-2`}>
                <InlineMath tex={`\\alpha_2=${alpha2.toFixed(2)}`} />
                <input id={`${id}-alpha-2`} max="1" min="0" onChange={(event) => setAlpha2(Number(event.target.value))} step="0.05" type="range" value={alpha2} />
              </label>
              <div className="cell-basis-term-grid" aria-label="Select one tensor Bernstein term">
                {displayedTerms.map((item) => {
                  const storageIndex = model.terms.indexOf(item);
                  return (
                  <button
                    aria-pressed={selectedTerm === storageIndex}
                    key={`${item.i}-${item.j}`}
                    onClick={() => setSelectedTerm(storageIndex)}
                    type="button"
                  >
                    <InlineMath tex={`B_{(${item.i},${item.j})}^{2}(\\boldsymbol\\alpha)`} />
                    <small>{formatNumber(item.weight)}</small>
                  </button>
                  );
                })}
              </div>
              <label className="cell-basis-axis cell-basis-axis--horizontal" htmlFor={`${id}-alpha-1`}>
                <input id={`${id}-alpha-1`} max="1" min="0" onChange={(event) => setAlpha1(Number(event.target.value))} step="0.05" type="range" value={alpha1} />
                <InlineMath tex={`\\alpha_1=${alpha1.toFixed(2)}`} />
              </label>
              <p className="cell-basis-coordinate-frame__storage"><code>A.LocalValues{'{'}{model.cell.c1}{'}'}{'{'}1{'}'}</code> stores the nine coefficient matrices above.</p>
            </div>
            <aside className="cell-basis-readout" aria-live="polite">
              <strong>Selected term</strong>
              <p>
                <InlineMath tex={`C_{${term.i},${term.j}}^{(${model.cell.c1},1)}=`} />
                <InlineMath tex={term.coefficient.tex} />
              </p>
              <p><InlineMath tex={`B_{${term.i}}^2(\\alpha_1)B_{${term.j}}^2(\\alpha_2)=${formatNumber(term.weight)}`} /></p>
              <span>Weighted contribution</span>
              <p><InlineMath tex={matrixToTex(contribution)} /></p>
              <span>Complete cell value</span>
              <p>
                <InlineMath tex={`A^{(${model.cell.c1},1)}(\\boldsymbol\\alpha)=`} />
                <InlineMath tex={matrixToTex(model.value)} />
              </p>
            </aside>
          </div>
        </section>
      </div>
      <figcaption>
        Select a physical cell, move the local coordinates, and inspect how its nine coefficient matrices combine through the tensor degree-two Bernstein basis.
      </figcaption>
    </figure>
  );
}
