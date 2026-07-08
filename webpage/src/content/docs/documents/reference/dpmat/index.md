---
title: dpmat
description: Known finite real matrix data on a parameter grid.
---

`dpmat` represents known finite real matrix data on a parameter grid. Use it for exact function-backed data, coefficient-backed Bernstein data, plotting diagnostics, and coefficient-wise matrix operations.

<div class="method-grid">
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpmat/constructor/"><strong>Constructor</strong><span>Build known data from coefficient grids, local values, or function handles.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpmat/evaluate/"><strong>evaluate</strong><span>Evaluate known data at one parameter point.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpmat/plot/"><strong>plot</strong><span>Sample one- or two-dimensional diagnostic plots.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpmat/table/"><strong>table</strong><span>Inspect local Bernstein coefficients in tabular form.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpmat/matrix-operations/"><strong>Matrix operations</strong><span>Algebra, concatenation, indexing, assignment, and structural transforms.</span></a>
</div>

## Inherited Storage

`dpmat` extends [`dpbase`](/DP-LMI-package/documents/reference/dpbase/) and exposes `GridInfo`, `MatrixSize`, `Degree`, `LocalValues`, local labels, and cell-local coefficient inspection.

## Current Boundaries

- Function-only `dpmat` objects without explicit Bernstein evidence evaluate exactly but do not enter coefficient algebra.
- `dpmat` stores known numeric data only; decision variables belong to [`dpvar`](/DP-LMI-package/documents/reference/dpvar/).
- Plotting and table output are diagnostics, not solver-facing behavior.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) · [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/) · [`table`](/DP-LMI-package/documents/reference/dpmat/table/)
