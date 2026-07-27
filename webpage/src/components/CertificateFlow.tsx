import { useId, useState } from "react";
import { renderInlineMath } from "../lib/katex.js";

interface CertificateFlowOption {
  key: string;
  label: string;
  command: string;
  formula: string;
  notation: string;
  href: string;
}

/** Choose a compact certificate summary before opening its reference page. */
export default function CertificateFlow({ options }: { options: CertificateFlowOption[] }) {
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
        <div className="certificate-flow__residual"><strong>Positive target</strong><span dangerouslySetInnerHTML={{ __html: renderInlineMath("S^{(\\mathbf c)}(\\boldsymbol\\alpha)\\succeq0") }} /></div>
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
              <strong>{item.label}</strong><code>{item.command}</code>
            </button>
          ))}
        </div>
        <section aria-labelledby={`${id}-tab-${selected}`} className="certificate-flow-panel" id={`${id}-panel`} role="tabpanel">
          <p className="certificate-flow-panel__formula" dangerouslySetInnerHTML={{ __html: renderInlineMath(option.formula) }} />
          {option.notation && <p className="certificate-flow-panel__notation" dangerouslySetInnerHTML={{ __html: renderInlineMath(option.notation) }} />}
          <p><strong>Key code:</strong> <code>selected = {option.command};</code></p>
          <a href={option.href}>Open the {option.label} reference →</a>
        </section>
      </div>
      <figcaption>Select a certificate to reveal its key code, then open its API reference for the complete method details.</figcaption>
    </figure>
  );
}
