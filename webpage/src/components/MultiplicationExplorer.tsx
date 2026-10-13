import { useDeferredValue, useMemo, useState } from "react";

import BernsteinPlot from "./BernsteinPlot.tsx";
import {
  bernsteinContributionsAt,
  bernsteinProduct,
  sampleBernstein,
} from "../lib/bernstein.ts";
import {
  initialMultiplicationInput,
  maxMultiplicationCoefficients,
  updateMultiplicationInput,
} from "../lib/multiplication-input.ts";

const format = (value: number) => {
  if (Number.isInteger(value)) return String(value);
  if (Math.abs(value) < 1e-4 || Math.abs(value) >= 1e6) {
    return value.toExponential(4);
  }
  return value.toFixed(6).replace(/0+$/, "");
};

/** Materialize large anti-diagonals only when their accessible disclosure opens. */
function ContributionTerms({
  eager,
  k,
  left,
  right,
}: {
  eager: boolean;
  k: number;
  left: readonly number[];
  right: readonly number[];
}) {
  const [open, setOpen] = useState(eager);
  const terms = open ? bernsteinContributionsAt(left, right, k) : [];
  const content = terms.map((term) => (
    <span className="contribution-term" key={`${term.i}-${term.j}`}>
      {format(term.weight)} × P[{term.i}] ({format(left[term.i])}) × Q[{term.j}] ({format(right[term.j])}) = {format(term.value)}
    </span>
  ));

  if (eager) return content;
  const count = Math.min(left.length - 1, k) - Math.max(0, k - right.length + 1) + 1;
  return (
    <details onToggle={(event) => setOpen(event.currentTarget.open)}>
      <summary>Show {count} weighted terms</summary>
      {content}
    </details>
  );
}

/** Explore arbitrary finite Bernstein coefficient lists while retaining the last valid plot. */
export default function MultiplicationExplorer() {
  const [input, setInput] = useState(initialMultiplicationInput);
  const deferred = useDeferredValue(input.valid);
  const product = useMemo(
    () => bernsteinProduct(deferred.left, deferred.right),
    [deferred],
  );
  const m = deferred.left.length - 1;
  const n = deferred.right.length - 1;

  return (
    <figure className="diagram-frame interactive-figure">
      <div className="diagram-frame__body explorer-stack">
        <div className="coefficient-inputs">
          <label>
            P coefficients
            <input
              aria-describedby="coefficient-help p-error"
              aria-invalid={Boolean(input.errors.left)}
              value={input.leftText}
              onChange={(event) => setInput((current) => updateMultiplicationInput(current, "left", event.target.value))}
            />
            <span className="input-error" id="p-error" role="alert">{input.errors.left}</span>
          </label>
          <label>
            Q coefficients
            <input
              aria-describedby="coefficient-help q-error"
              aria-invalid={Boolean(input.errors.right)}
              value={input.rightText}
              onChange={(event) => setInput((current) => updateMultiplicationInput(current, "right", event.target.value))}
            />
            <span className="input-error" id="q-error" role="alert">{input.errors.right}</span>
          </label>
        </div>
        <p className="input-help" id="coefficient-help">
          Enter nonempty finite lists separated by commas and/or spaces. Use at most {maxMultiplicationCoefficients} coefficients per factor.
        </p>
        <BernsteinPlot
          ariaLabel={`Degree ${m} P and degree ${n} Q with their degree ${m + n} product`}
          series={[
            { label: `P · degree ${m}`, points: sampleBernstein(deferred.left), tone: "first" },
            { label: `Q · degree ${n}`, points: sampleBernstein(deferred.right), tone: "second" },
            { label: `PQ · degree ${m + n}`, points: sampleBernstein(product), tone: "result" },
          ]}
        />
        <p className="product-result"><strong>Result:</strong> [{product.map(format).join(", ")}]</p>
        <div className="contribution-table" role="table" aria-label="Normalized Bernstein coefficient contributions">
          {product.map((value, k) => (
            <div role="row" key={k}>
              <strong role="cell">k = {k}</strong>
              <span role="cell">
                <ContributionTerms
                  eager={product.length <= 9}
                  k={k}
                  left={deferred.left}
                  right={deferred.right}
                />
              </span>
              <code role="cell">C[{k}] = {format(value)}</code>
            </div>
          ))}
        </div>
      </div>
      <figcaption>The product degree is derived from the input lengths. Malformed edits report an error and leave the last valid plot in place.</figcaption>
    </figure>
  );
}
