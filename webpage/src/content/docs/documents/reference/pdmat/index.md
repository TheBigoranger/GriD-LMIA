---
title: pdmat
description: Known finite real matrix data on a parameter grid.
---

`pdmat` represents known finite real matrix data on a parameter grid. Use it for exact function-backed data, coefficient-backed Bernstein data, plotting diagnostics, and coefficient-wise matrix operations.

## Reference Index

### Construction

| Reference | Task |
| :--- | :--- |
| [`pdmat constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/) | Build known data from coefficient grids, local values, or function handles. |

### Evaluation and visualization

| Reference | Task |
| :--- | :--- |
| [`evaluate`](/PD-LMI-package/documents/reference/pdmat/evaluate/) | Evaluate known data at one parameter point. |
| [`plot`](/PD-LMI-package/documents/reference/pdmat/plot/) | Sample one- or two-dimensional diagnostic plots. |
| [`bernsteinTable`](/PD-LMI-package/documents/reference/pdmat/bernsteintable/) | Inspect local Bernstein coefficients in tabular form. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Matrix operations`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/) | Use algebra, concatenation, indexing, assignment, and structural transforms. |

## Inherited Storage

`pdmat` extends [`pdbase`](/PD-LMI-package/documents/reference/pdbase/) and exposes `GridInfo`, `MatrixSize`, `Degree`, `LocalValues`, local labels, and cell-local coefficient inspection.

## Current Boundaries

- Function-only `pdmat` objects without explicit Bernstein evidence evaluate exactly but do not enter coefficient algebra.
- `pdmat` stores known numeric data only; decision variables belong to [`pdvar`](/PD-LMI-package/documents/reference/pdvar/).
- Plotting and `bernsteinTable` output are diagnostics, not solver-facing behavior.

## See Also

[`pdmat constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/) · [`evaluate`](/PD-LMI-package/documents/reference/pdmat/evaluate/) · [`plot`](/PD-LMI-package/documents/reference/pdmat/plot/) · [`bernsteinTable`](/PD-LMI-package/documents/reference/pdmat/bernsteintable/)
