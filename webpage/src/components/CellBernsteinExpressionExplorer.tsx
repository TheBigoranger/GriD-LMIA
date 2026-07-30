import { useId, useMemo, useState } from "react";
import {
  buildCellBernsteinModel,
  type Matrix2,
  orderCellBernsteinTermsForAxes,
  pdmatCellData,
} from "../lib/cell-bernstein.ts";
import { DisplayMath, InlineMath } from "./RenderedMath.tsx";

const formatNumber = (value: number) => {
  const rounded = Math.abs(value) < 5e-10 ? 0 : Number(value.toFixed(4));
  return `${rounded}`;
};

interface MathMarkup {
  globalFormula: string;
  alpha1: string[];
  alpha2: string[];
  termBasis: string[];
  termWeightPrefix: string[];
  cells: Array<{
    domain: string;
    formula: string;
    coefficientLabels: string[];
    coefficientValues: string[];
    valuePrefix: string;
  }>;
}

function MatrixMath({ matrix }: { matrix: Matrix2 }) {
  const values = matrix.map(formatNumber);
  return (
    <span
      aria-label={`matrix ${values[0]}, ${values[1]}; ${values[2]}, ${values[3]}`}
      className="structured-math-matrix"
      role="math"
    >
      {values.map((value, index) => <span key={index}>{value}</span>)}
    </span>
  );
}

/** Explore the tensor Bernstein expression stored independently on each physical cell. */
export default function CellBernsteinExpressionExplorer({ mathMarkup }: { mathMarkup: MathMarkup }) {
  const [selectedCell, setSelectedCell] = useState(0);
  const [alpha1, setAlpha1] = useState(0.35);
  const [alpha2, setAlpha2] = useState(0.6);
  const [selectedTerm, setSelectedTerm] = useState(4);
  const id = useId();
  const model = useMemo(
    () => buildCellBernsteinModel(selectedCell, alpha1, alpha2),
    [selectedCell, alpha1, alpha2],
  );
  const cellMath = mathMarkup.cells[selectedCell];
  const sliderIndex = (value: number) => Math.round(value * 20);
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
          markup={mathMarkup.globalFormula}
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
              <InlineMath markup={mathMarkup.cells[index].domain} />
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
            markup={cellMath.formula}
          />
          <div className="cell-basis-workspace">
            <div className="cell-basis-coordinate-frame">
              <strong className="cell-basis-coordinate-frame__title">Local coordinates</strong>
              <label className="cell-basis-axis cell-basis-axis--vertical" htmlFor={`${id}-alpha-2`}>
                <InlineMath markup={mathMarkup.alpha2[sliderIndex(alpha2)]} />
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
                    <InlineMath markup={mathMarkup.termBasis[storageIndex]} />
                    <small>{formatNumber(item.weight)}</small>
                  </button>
                  );
                })}
              </div>
              <label className="cell-basis-axis cell-basis-axis--horizontal" htmlFor={`${id}-alpha-1`}>
                <input id={`${id}-alpha-1`} max="1" min="0" onChange={(event) => setAlpha1(Number(event.target.value))} step="0.05" type="range" value={alpha1} />
                <InlineMath markup={mathMarkup.alpha1[sliderIndex(alpha1)]} />
              </label>
              <p className="cell-basis-coordinate-frame__storage"><code>A.LocalValues{'{'}{model.cell.c1}{'}'}{'{'}1{'}'}</code> stores the nine coefficient matrices above.</p>
            </div>
            <aside className="cell-basis-readout" aria-live="polite">
              <strong>Selected term</strong>
              <p>
                <InlineMath markup={cellMath.coefficientLabels[selectedTerm]} />
                <InlineMath markup={cellMath.coefficientValues[selectedTerm]} />
              </p>
              <p><InlineMath markup={mathMarkup.termWeightPrefix[selectedTerm]} /><span className="structured-math-number">{formatNumber(term.weight)}</span></p>
              <span>Weighted contribution</span>
              <p><MatrixMath matrix={contribution} /></p>
              <span>Complete cell value</span>
              <p>
                <InlineMath markup={cellMath.valuePrefix} />
                <MatrixMath matrix={model.value} />
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
