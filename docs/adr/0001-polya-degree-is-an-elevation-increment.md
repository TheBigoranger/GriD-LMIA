# Pólya degree is an elevation increment

`PolyaDegree=d` means elevate a Residual from degree `m` to `m+d` in every parameter direction, rather than target absolute degree `d`. This keeps the option's meaning independent of the Residual's starting degree and supports reusable constraint wrappers: `applyPolya` always selects a hierarchy level from the stored Residual, so reapplication replaces the prior selection instead of compounding it.
