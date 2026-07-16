import { useId, useState } from "react";

import type { CertificateKey } from "../data/certificate-data.ts";

export interface CertificateOption {
  key: CertificateKey;
  label: string;
  description: string;
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
              }}
              role="tab"
              tabIndex={selected === index ? 0 : -1}
              type="button"
            >
              {item.label}{item.key === "direct" ? <small>Default</small> : null}
            </button>
          ))}
        </div>
        <section aria-labelledby={`${panelId}-tab-${selected}`} id={`${panelId}-panel`} role="tabpanel">
          <h3>{option.label}</h3>
          <p>{option.description}</p>
          <div className="certificate-formula">
            {option.mathHtml.map((mathHtml, index) => (
              <div
                className="certificate-formula__row"
                dangerouslySetInnerHTML={{ __html: mathHtml }}
                key={`${option.key}-${index}`}
              />
            ))}
          </div>
          <a href={option.href}>Open the {option.label} reference →</a>
        </section>
      </div>
      <figcaption>Select a method to compare its finite certificate and follow the link to callable syntax and boundaries.</figcaption>
    </figure>
  );
}
