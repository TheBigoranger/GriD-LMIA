import { useEffect, useRef } from "react";

declare global {
  interface Window {
    MathJax?: {
      startup?: { promise?: Promise<unknown> };
      typesetClear?: (elements?: Element[]) => void;
      typesetPromise?: (elements?: Element[]) => Promise<unknown>;
    };
    pdLmiTypeset?: (elements: Element[], update?: () => void) => Promise<unknown>;
  }
}

interface MathProps {
  className?: string;
  display?: boolean;
  tex: string;
}

/** Typeset one raw TeX expression and clear its stale MathItem before every update. */
function MathJaxMath({ className = "", display = false, tex }: MathProps) {
  const ref = useRef<HTMLElement>(null);
  const initialSource = useRef(display ? `\\[${tex}\\]` : `\\(${tex}\\)`);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    let cancelled = false;
    const typeset = () => {
      if (cancelled) return;
      const source = display ? `\\[${tex}\\]` : `\\(${tex}\\)`;
      void window.pdLmiTypeset?.([element], () => {
        if (!cancelled) element.textContent = source;
      });
    };

    const startup = window.MathJax?.startup?.promise;
    if (document.documentElement.dataset.mathjaxReady === "true") {
      typeset();
    } else if (startup) {
      void startup.then(typeset);
    } else {
      document.addEventListener("mathjax:ready", typeset, { once: true });
    }

    return () => {
      cancelled = true;
      document.removeEventListener("mathjax:ready", typeset);
      void window.pdLmiTypeset?.([element], () => {
        element.textContent = "";
      });
    };
  }, [display, tex]);

  const classes = `tex-math ${display ? "tex-display" : "tex-inline"} ${className}`.trim();
  return display
    ? <div className={classes} ref={ref as React.RefObject<HTMLDivElement>}>{initialSource.current}</div>
    : <span className={classes} ref={ref as React.RefObject<HTMLSpanElement>}>{initialSource.current}</span>;
}

export const DisplayMath = (props: Omit<MathProps, "display">) => <MathJaxMath {...props} display />;
export const InlineMath = (props: Omit<MathProps, "display">) => <MathJaxMath {...props} />;
