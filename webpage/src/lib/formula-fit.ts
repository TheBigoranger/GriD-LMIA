/** Fit complete, server-rendered formulas without altering their TeX glyph metrics. */
export function installFormulaFit(root: Document = document) {
  const frames = new Set<HTMLElement>();
  let pending = 0;
  let disposed = false;
  const measure = () => {
    pending = 0;
    for (const frame of frames) {
      if (!frame.isConnected) {
        resize.unobserve(frame);
        frames.delete(frame);
        continue;
      }
      // React must hydrate the unchanged server tree before layout attributes appear.
      if (frame.closest("astro-island[ssr]")) continue;
      if (frame.hasAttribute("data-formula-react") && !frame.hasAttribute("data-formula-ready")) continue;
      const content = frame.querySelector<HTMLElement>(":scope > .formula-fit-size > .formula-fit-content");
      const size = content?.parentElement;
      if (!content || !size || frame.clientWidth === 0) continue;
      const style = getComputedStyle(frame);
      const available = frame.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight);
      const natural = content.offsetWidth;
      if (natural === 0) continue;
      const scale = Math.max(.85, Math.min(1, available / natural));
      size.style.width = `${natural * scale}px`;
      size.style.height = `${content.offsetHeight * scale}px`;
      content.style.transform = `scale(${scale})`;
      frame.dataset.formulaScale = String(scale);
      frame.dataset.formulaFitted = "";
      frame.tabIndex = natural * scale > available + 1 ? 0 : -1;
    }
  };
  const schedule = () => {
    if (!disposed && !pending) pending = requestAnimationFrame(measure);
  };
  const resize = new ResizeObserver(schedule);
  const discover = () => {
    for (const frame of root.querySelectorAll<HTMLElement>("[data-formula-fit]")) {
      if (!frames.has(frame)) {
        frames.add(frame);
        resize.observe(frame);
      }
    }
    schedule();
  };
  // React can replace trusted markup or mount a previously hidden panel.
  const mutations = new MutationObserver(discover);
  mutations.observe(root.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ["ssr", "hidden", "open", "data-formula-ready"] });
  root.fonts.ready.then(schedule);
  root.fonts.addEventListener("loadingdone", schedule);
  discover();
  return () => {
    disposed = true;
    cancelAnimationFrame(pending);
    resize.disconnect();
    mutations.disconnect();
    root.fonts.removeEventListener("loadingdone", schedule);
    frames.clear();
  };
}
