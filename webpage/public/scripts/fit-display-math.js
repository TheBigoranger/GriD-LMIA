(() => {
  const stateKey = "__pdLmiFormulaFitter";
  const phoneWidth = window.matchMedia("(max-width: 700px)");
  let frame = 0;

  const reset = (display) => {
    display.style.removeProperty("--formula-size");
    delete display.dataset.formulaScale;
  };

  /** Fit one intact KaTeX display without changing its TeX or MathML. */
  const fitDisplay = (display) => {
    reset(display);
    if (!phoneWidth.matches || display.closest("pre")) return;

    const formula = display.firstElementChild;
    const available = display.clientWidth;
    if (!formula || available <= 0) return;

    // The outer KaTeX span fills the row, so its intrinsic formula width is
    // represented by scrollWidth rather than its full-row bounding box.
    const natural = Math.max(formula.scrollWidth, formula.getBoundingClientRect().width);
    const scale = natural > available ? (available - 2) / natural : 1;
    display.style.setProperty("--formula-size", `${1.5 * scale}em`);
    display.dataset.formulaScale = scale.toFixed(4);
  };

  const fitAll = () => {
    frame = 0;
    document.querySelectorAll(".katex-display").forEach(fitDisplay);
  };

  const schedule = () => {
    if (frame) cancelAnimationFrame(frame);
    frame = requestAnimationFrame(fitAll);
  };

  if (window[stateKey]) {
    window[stateKey].schedule();
    return;
  }
  window[stateKey] = { schedule };

  // React islands and opened disclosures can introduce or reveal formulas.
  const observer = new MutationObserver(schedule);
  observer.observe(document.documentElement, {
    attributeFilter: ["class", "hidden", "open"],
    attributes: true,
    childList: true,
    subtree: true,
  });

  window.addEventListener("resize", schedule, { passive: true });
  document.addEventListener("astro:page-load", schedule);
  document.fonts?.ready.then(schedule);
  schedule();
})();
