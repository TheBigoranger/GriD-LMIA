interface MathProps {
  className?: string;
  display?: boolean;
  markup: string;
}

/** Present trusted build-time KaTeX markup without loading a client-side TeX parser. */
function RenderedMath({ className = "", display = false, markup }: MathProps) {
  const classes = `not-content formula-math ${display ? "formula-display" : "formula-inline"} ${className}`.trim();

  return display
    ? <div className={classes} dangerouslySetInnerHTML={{ __html: markup }} />
    : <span className={classes} dangerouslySetInnerHTML={{ __html: markup }} />;
}

export const DisplayMath = (props: Omit<MathProps, "display">) => <RenderedMath {...props} display />;
export const InlineMath = (props: Omit<MathProps, "display">) => <RenderedMath {...props} />;
