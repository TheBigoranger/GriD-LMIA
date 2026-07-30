import { useId, useState } from "react";

import type { CertificateKey } from "../data/certificate-data.ts";
import { buildCertificateShape, type CertificateMode } from "../lib/manual-explorers.ts";
import { DisplayMath } from "./RenderedMath.tsx";

export interface CertificateOption {
  key: CertificateKey;
  anchor: string;
  label: string;
  description: string;
  command: string;
  exportCommand: string;
  constraintCount: string;
  boundaryNote: string;
  formulaMarkup: readonly string[];
  href: string;
}

/** Switch between certificate summaries with accessible tab semantics. */
export default function CertificateChooser({ options }: { options: CertificateOption[] }) {
  const [selected, setSelected] = useState(0);
  const [draft, setDraft] = useState({ cells: "2", nPar: "1", degree: "2", rateMode: "ordinary" as "ordinary" | "rhodiff", order: "1", bandWidth: "2", matrixSize: "2", mode: "semidefinite" as CertificateMode });
  const [shape, setShape] = useState(() => buildCertificateShape({ selector: "direct", cells: 2, nPar: 1, degree: 2, rateRows: 1, order: 1, matrixSize: 2, mode: "semidefinite" }));
  const [error, setError] = useState("");
  const panelId = useId();
  const option = options[selected];
  const numberFrom = (value: string) => value.trim() === "" ? Number.NaN : Number(value);

  const calculate = (selector = option.key, nextDraft = draft) => {
    try {
      const nPar = numberFrom(nextDraft.nPar);
      setShape(buildCertificateShape({ selector, cells: numberFrom(nextDraft.cells), nPar, degree: numberFrom(nextDraft.degree), rateRows: nextDraft.rateMode === "rhodiff" ? 2 ** nPar : 1, order: numberFrom(nextDraft.order), bandWidth: numberFrom(nextDraft.bandWidth), matrixSize: numberFrom(nextDraft.matrixSize), mode: nextDraft.mode }));
      setError("");
    } catch (reason) { setError(reason instanceof Error ? reason.message : "Invalid certificate shape."); }
  };

  const selectOption = (index: number) => {
    setSelected(index);
    const selector = options[index].key;
    const minimum = numberFrom(draft.nPar) === 1 ? Math.floor(numberFrom(draft.degree) / 2) : Math.ceil(numberFrom(draft.degree) / 2);
    const nextDraft = (selector === "putinar" || selector === "sparsefullbox" || selector === "fullbox") && numberFrom(draft.order) < minimum ? { ...draft, order: String(minimum) } : draft;
    setDraft(nextDraft);
    calculate(selector, nextDraft);
  };

  const move = (index: number, direction: number) => {
    const next = (index + direction + options.length) % options.length;
    selectOption(next);
    document.getElementById(`${panelId}-tab-${next}`)?.focus();
  };

  return (
    <figure className="diagram-frame interactive-figure certificate-chooser">
      <div className="diagram-frame__body">
        <p className="certificate-origin"><code>L = E &gt;= 0</code></p>
        <div aria-label="Finite certificate method" className="certificate-tabs" role="tablist">
          {options.map((item, index) => (
            <button
              aria-controls={`${panelId}-panel`}
              aria-selected={selected === index}
              id={`${panelId}-tab-${index}`}
              key={item.key}
              onClick={() => selectOption(index)}
              onKeyDown={(event) => {
                if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
                  event.preventDefault();
                  move(index, -1);
                }
                if (event.key === "ArrowRight" || event.key === "ArrowDown") {
                  event.preventDefault();
                  move(index, 1);
                }
                if (event.key === "Home") {
                  event.preventDefault();
                  selectOption(0);
                  document.getElementById(`${panelId}-tab-0`)?.focus();
                }
                if (event.key === "End") {
                  event.preventDefault();
                  selectOption(options.length - 1);
                  document.getElementById(`${panelId}-tab-${options.length - 1}`)?.focus();
                }
              }}
              role="tab"
              tabIndex={selected === index ? 0 : -1}
              type="button"
            >
              <strong>{item.label}</strong>
              <code>{item.command}</code>
            </button>
          ))}
        </div>
        <section aria-labelledby={`${panelId}-tab-${selected}`} id={`${panelId}-panel`} role="tabpanel">
          <h3>{option.label}: <code>selected = {option.command}</code></h3>
          <p>{option.description}</p>
          <p><strong>Calculator scope:</strong> uniform residual degree and
            uniform certificate order across all parameter axes. The MATLAB API
            also accepts direction-wise degree and order vectors.</p>
          <div className="certificate-shape-controls">
            {(["cells", "nPar", "degree", "matrixSize"] as const).map((key) => (
              <label key={key}>{({ cells: "Physical cells", nPar: "Parameter axes", degree: "Residual degree", matrixSize: "Square matrix size n" })[key]}
                <input inputMode="numeric" value={draft[key]} onChange={(event) => setDraft({ ...draft, [key]: event.target.value })} />
              </label>
            ))}
            <label>Residual rows
              <select value={draft.rateMode} onChange={(event) => setDraft({ ...draft, rateMode: event.target.value as "ordinary" | "rhodiff" })}>
                <option value="ordinary">ordinary: 1 row</option><option value="rhodiff">rhodiff: 2^ℓ rows</option>
              </select>
            </label>
            {option.key === "direct" ? <p><strong>Order:</strong> not used by the direct selector.</p> : <label>{option.key === "polya" ? "Elevation increment" : "Gram order"}
              <input inputMode="numeric" value={draft.order} onChange={(event) => setDraft({ ...draft, order: event.target.value })} />
            </label>}
            {option.key === "sparsefullbox" ? <label>Bandwidth w
              <input inputMode="numeric" value={draft.bandWidth} onChange={(event) => setDraft({ ...draft, bandWidth: event.target.value })} />
            </label> : null}
            <label>Assembly mode
              <select value={draft.mode} onChange={(event) => setDraft({ ...draft, mode: event.target.value as CertificateMode })}>
                <option value="semidefinite">symmetric semidefinite</option><option value="elementwise">entrywise n × n</option>
              </select>
            </label>
            <button type="button" onClick={() => calculate()}>Calculate finite shape</button>
            <p className="explorer-error" role="alert">{error}</p>
          </div>
          <div className="certificate-formula">
            {option.formulaMarkup.map((markup, index) => (
              <DisplayMath
                className="certificate-formula__row"
                key={`${option.key}-${index}`}
                markup={markup}
              />
            ))}
          </div>
          <div className="certificate-shape-readout" aria-live="polite">
            <p><strong>Target tensor degree:</strong> {shape.targetDegree}</p>
            <p><strong>Coefficient sign tests:</strong> {shape.coefficientTests}</p>
            <p><strong>Coefficient identities:</strong> {shape.coefficientIdentities}</p>
            <p><strong>PSD blocks:</strong> {shape.psdBlocks}</p>
            <p><strong>Total stored constraints:</strong> {shape.totalConstraints}</p>
            {option.key === "sparsefullbox" ? <p><strong>Effective endpoint:</strong> {shape.effectiveSelector}</p> : null}
          </div>
          <details className="certificate-transcript">
            <summary>Show the matching MATLAB transcript</summary>
            <pre><code>{`yalmip('clear')\nE = pdvar(2, {[0 0.5 1]}, "symmetric", Degree=2);\nL = E >= 0;\n${option.exportCommand}\nnumel(C)`}</code></pre>
          </details>
          {shape.blocks.length ? <div className="gram-block-list"><strong>One certificate copy uses:</strong><ul>{shape.blocks.map((block) => <li key={block.label}><code>{block.label}</code>: Gram degree [{block.gramDegree.join(", ")}], block {block.dimension} × {block.dimension}</li>)}</ul></div> : null}
          <p><strong>Source-verified fixture:</strong> {option.constraintCount}</p>
          <p><strong>At the cell boundary:</strong> {option.boundaryNote}</p>
          <div className="certificate-export" aria-label="Selected certificate exported as YALMIP constraints">
            <code>selected</code><span aria-hidden="true">→</span><code>selected.toYalmip()</code><span aria-hidden="true">→</span><strong>YALMIP Constraint</strong>
          </div>
          <a href={option.href}>Open the {option.label} reference →</a>
        </section>
      </div>
      <figcaption>Counts follow the stored YALMIP constraint cells: direct tests are vectorized per coefficient, while entrywise Gram certificates create independent scalar copies. Invalid edits retain the last valid shape.</figcaption>
    </figure>
  );
}
