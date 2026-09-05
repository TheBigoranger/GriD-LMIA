/** Remove only the measured outer fit transform, retaining native glyph geometry. */
export function intrinsicFormulaRect(snapshot) {
  const { formulaRect, wrapperRect, scale } = snapshot ?? {};
  if (!formulaRect || !wrapperRect || !Number.isFinite(scale?.x) || !Number.isFinite(scale?.y) || scale.x <= 0 || scale.y <= 0) return null;
  return {
    left: (formulaRect.left - wrapperRect.left) / scale.x,
    top: (formulaRect.top - wrapperRect.top) / scale.y,
    width: formulaRect.width / scale.x,
    height: formulaRect.height / scale.y,
  };
}
