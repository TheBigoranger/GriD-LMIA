import { useId, useState } from "react";

import type { CertificateKey } from "../data/certificate-data.ts";

export interface CertificateOption {
  key: CertificateKey;
  anchor: string;
  label: string;
  description: string;
  command: string;
  exportCommand: string;
  constraintCount: string;
  boundaryNote: string;
  mathHtml: readonly string[];
  href: string;
}

/** Switch between certificate summaries with accessible tab semantics. */
export default function CertificateChooser({ options }: { options: CertificateOption[] }) {
  const [selected, setSelected] = useState(0);
  const panelId = useId();
  const option = options[selected];

  const move = (index: number, direction: number) => {
    const next = (index + direction + options.length) % options.length;
    setSelected(next);
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
              onClick={() => setSelected(index)}
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
                  setSelected(0);
                  document.getElementById(`${panelId}-tab-0`)?.focus();
                }
                if (event.key === "End") {
                  event.preventDefault();
                  setSelected(options.length - 1);
                  document.getElementById(`${panelId}-tab-${options.length - 1}`)?.focus();
                }
              }}
              role="tab"
              tabIndex={selected === index ? 0 : -1}
              type="button"
            >
              <strong>{item.label}</strong>
              <code>{item.command}</code>
              {item.key === "direct" ? <small>Default</small> : null}
            </button>
          ))}
        </div>
        <section aria-labelledby={`${panelId}-tab-${selected}`} id={`${panelId}-panel`} role="tabpanel">
          <h3>{option.label}: <code>selected = {option.command}</code></h3>
          <p>{option.description}</p>
          <pre><code>{`yalmip('clear')\nE = pdvar(2, {[0 0.5 1]}, "symmetric", Degree=2);\nL = E >= 0;\n${option.exportCommand}\nnumel(C)`}</code></pre>
          <div className="certificate-formula">
            {option.mathHtml.map((mathHtml, index) => (
              <div
                className="certificate-formula__row"
                dangerouslySetInnerHTML={{ __html: mathHtml }}
                key={`${option.key}-${index}`}
              />
            ))}
          </div>
          <p><strong>Finite shape:</strong> {option.constraintCount}</p>
          <p><strong>At the cell boundary:</strong> {option.boundaryNote}</p>
          <div className="certificate-export" aria-label="Selected certificate exported as YALMIP constraints">
            <code>selected</code><span aria-hidden="true">→</span><code>selected.toYalmip()</code><span aria-hidden="true">→</span><strong>YALMIP Constraint</strong>
          </div>
          <a href={option.href}>Open the {option.label} reference →</a>
        </section>
      </div>
      <figcaption>All four tabs use the same two-cell degree-two residual. Only the finite certificate selector changes.</figcaption>
    </figure>
  );
}
