import { useId, useState } from "react";
import { InlineMath } from "./RenderedMath.tsx";

interface CertificateFlowOption {
  key: string;
  label: string;
  command: string;
  formulaMarkup: string;
  notationMarkup: string;
  notationRows?: Array<{
    formulaMarkup: string;
    label: string;
  }>;
  href: string;
}

/** Choose a certificate name before opening its detailed reference page. */
export default function CertificateFlow({
  compact = false,
  options,
  residualMarkup,
}: {
  compact?: boolean;
  options: CertificateFlowOption[];
  residualMarkup: string;
}) {
  const [selected, setSelected] = useState(0);
  const id = useId();
  const option = options[selected];

  const select = (index: number) => {
    setSelected(index);
    document.getElementById(`${id}-tab-${index}`)?.focus();
  };

  const move = (index: number, direction: number) => select((index + direction + options.length) % options.length);

  return (
    <figure className="diagram-frame certificate-flow-figure" aria-label="Finite certificate selection flow">
      <div className="diagram-frame__body certificate-flow">
        <div className="certificate-flow__residual"><strong>Theoretical positive target</strong><InlineMath markup={residualMarkup} /></div>
        <span className="certificate-flow__arrow" aria-hidden="true">↓</span>
        <div aria-label="Finite certificate method" className="certificate-flow-tabs" role="tablist">
          {options.map((item, index) => (
            <button
              aria-controls={`${id}-panel`}
              aria-selected={selected === index}
              id={`${id}-tab-${index}`}
              key={item.key}
              onClick={() => setSelected(index)}
              onKeyDown={(event) => {
                if (["ArrowLeft", "ArrowUp"].includes(event.key)) { event.preventDefault(); move(index, -1); }
                if (["ArrowRight", "ArrowDown"].includes(event.key)) { event.preventDefault(); move(index, 1); }
                if (event.key === "Home") { event.preventDefault(); select(0); }
                if (event.key === "End") { event.preventDefault(); select(options.length - 1); }
              }}
              role="tab"
              tabIndex={selected === index ? 0 : -1}
              type="button"
            >
              <strong>{item.label}</strong>{!compact && <code>{item.command}</code>}
            </button>
          ))}
        </div>
        <section aria-labelledby={`${id}-tab-${selected}`} className="certificate-flow-panel" id={`${id}-panel`} role="tabpanel">
          <p className="certificate-flow-panel__formula"><InlineMath markup={option.formulaMarkup} /></p>
          {option.notationRows
            ? (
                <div className="certificate-flow-panel__notation certificate-flow-panel__notation-rows">
                  {option.notationRows.map((row) => (
                    <span key={row.label}>
                      <InlineMath markup={row.formulaMarkup} />
                      <span aria-hidden="true">:</span>
                      <span>{row.label}</span>
                    </span>
                  ))}
                </div>
              )
            : option.notationMarkup && <p className="certificate-flow-panel__notation"><InlineMath markup={option.notationMarkup} /></p>}
          <p><strong>MATLAB selector:</strong> <code>selected = {option.command};</code></p>
          <a href={option.href}>Open the {option.label} reference →</a>
        </section>
      </div>
      <figcaption>Select a certificate to reveal one representative formula and selector; the linked reference contains the complete construction.</figcaption>
    </figure>
  );
}
