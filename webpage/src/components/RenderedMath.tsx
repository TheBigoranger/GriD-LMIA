import { useEffect, useRef } from "react";

interface MathProps {
  className?: string;
  display?: boolean;
  markup: string;
}

/** Present trusted build-time KaTeX markup without loading a client-side TeX parser. */
function RenderedMath({ className = "", display = false, markup }: MathProps) {
  const frame = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (frame.current) frame.current.dataset.formulaReady = "";
  }, [markup]);
  const classes = `not-content formula-math ${display ? "formula-display" : "formula-inline"} ${className}`.trim();

  return display
    ? <div ref={frame} className={classes} data-formula-fit data-formula-react tabIndex={0} aria-label="Mathematical formula"><span className="formula-fit-size"><span className="formula-fit-content" dangerouslySetInnerHTML={{ __html: markup }} /></span></div>
    : <span className={classes} dangerouslySetInnerHTML={{ __html: markup }} />;
}

export const DisplayMath = (props: Omit<MathProps, "display">) => <RenderedMath {...props} display />;
export const InlineMath = (props: Omit<MathProps, "display">) => <RenderedMath {...props} />;
