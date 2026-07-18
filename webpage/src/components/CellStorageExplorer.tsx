import { useId, useState } from "react";

const cells = [
  {
    c1: 1,
    domain: "ρ₁ ∈ [0, 0.5], ρ₂ ∈ [0, 1]",
    coefficients: [
      "[1 0; 0 2]", "[3/2 0; 0 2]", "[2 0; 0 2]",
      "[5/4 0; 0 2]", "[7/4 1/8; 1/8 2]", "[9/4 1/4; 1/4 2]",
      "[3/2 0; 0 9/4]", "[2 1/4; 1/4 9/4]", "[5/2 1/2; 1/2 9/4]",
    ],
  },
  {
    c1: 2,
    domain: "ρ₁ ∈ [0.5, 1], ρ₂ ∈ [0, 1]",
    coefficients: [
      "[3/2 0; 0 9/4]", "[2 1/4; 1/4 9/4]", "[5/2 1/2; 1/2 9/4]",
      "[7/4 0; 0 5/2]", "[9/4 3/8; 3/8 5/2]", "[11/4 3/4; 3/4 5/2]",
      "[2 0; 0 3]", "[5/2 1/2; 1/2 3]", "[3 1; 1 3]",
    ],
  },
] as const;

/** Select one of the two physical hypercubes that store A's degree-two data. */
export default function CellStorageExplorer() {
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
        <div className="cell-grid-stage">
          <span className="cell-axis cell-axis--y" aria-hidden="true">ρ₂</span>
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
                type="button"
              >
                c₁ = {item.c1}
              </button>
            ))}
          </div>
          <span className="cell-axis cell-axis--x" aria-hidden="true">ρ₁</span>
        </div>
        <div className="cell-storage-connector" aria-hidden="true"><span>select c₁</span><i /></div>
        <section className="cell-readout" aria-live="polite">
          <p><strong>Selected hypercube:</strong> c = ({cell.c1}, 1)</p>
          <p><strong>Physical domain:</strong> {cell.domain}</p>
          <p className="cell-storage-path"><strong>Storage:</strong> <code>A.LocalValues{'{'}c1{'}'}{'{'}1{'}'}</code> → <code>A.LocalValues{'{'}{cell.c1}{'}'}{'{'}1{'}'}</code></p>
          <div className="cell-coeffs" aria-label={`Nine degree-two coefficient matrices in cell (${cell.c1}, 1)`}>
            {cell.coefficients.map((coefficient, index) => (
              <span key={coefficient}><small>C<sup>({cell.c1},1)</sup>[{Math.floor(index / 3)},{index % 3}]</small><code>{coefficient}</code></span>
            ))}
          </div>
        </section>
      </div>
      <figcaption>For <code>grid = {'{'}[0 0.5 1], [0 1]{'}'}</code>, each button selects one physical hypercube of the degree-two known matrix <code>A</code>.</figcaption>
    </figure>
  );
}
