import { useState } from "react";

const cells = [
  { c: [1, 2], domain: "ρ₁ ∈ [0, 1], ρ₂ ∈ [1, 2]" },
  { c: [2, 2], domain: "ρ₁ ∈ [1, 2], ρ₂ ∈ [1, 2]" },
  { c: [1, 1], domain: "ρ₁ ∈ [0, 1], ρ₂ ∈ [0, 1]" },
  { c: [2, 1], domain: "ρ₁ ∈ [1, 2], ρ₂ ∈ [0, 1]" },
] as const;

/** Show how one cell index selects a nested LocalValues payload. */
export default function CellStorageExplorer() {
  const [selected, setSelected] = useState(2);
  const cell = cells[selected];
  const cLabel = `(${cell.c[0]},${cell.c[1]})`;

  return (
    <figure className="diagram-frame interactive-figure">
      <div className="diagram-frame__body cell-explorer">
        <div className="cell-grid" role="group" aria-label="Select one two-dimensional grid cell">
          {cells.map((item, index) => (
            <button
              aria-pressed={selected === index}
              className={selected === index ? "selected" : ""}
              key={item.c.join("-")}
              onClick={() => setSelected(index)}
              type="button"
            >
              c = ({item.c.join(",")})
            </button>
          ))}
        </div>
        <section className="cell-readout" aria-live="polite">
          <p><strong>Selected hypercube:</strong> c = {cLabel}</p>
          <p><strong>Physical domain:</strong> {cell.domain}</p>
          <p><strong>Storage:</strong> <code>LocalValues{'{'}{cell.c[0]}{'}'}{'{'}{cell.c[1]}{'}'}</code></p>
          <div className="cell-coeffs" aria-label={`Nine degree-two labels in cell ${cLabel}`}>
            {[0, 1, 2].flatMap((i) => [0, 1, 2].map((j) => (
              <span key={`${i}-${j}`}>C<sup>{cLabel}</sup>[{i},{j}]</span>
            )))}
          </div>
        </section>
      </div>
      <figcaption>Subscripts identify grid axes; the parenthesized vector superscript identifies the physical hypercube. Bernstein labels remain zero-based.</figcaption>
    </figure>
  );
}
