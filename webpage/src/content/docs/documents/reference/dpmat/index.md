---
title: dpmat
description: Known finite real matrix data on a parameter grid.
---

`dpmat` represents known finite real matrix data on a parameter grid. Use it for exact function-backed data, coefficient-backed Bernstein data, plotting diagnostics, and coefficient-wise matrix operations.

## Reference Index

### Construction

| Reference | Task |
| :--- | :--- |
| [`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) | Build known data from coefficient grids, local values, or function handles. |

### Evaluation and visualization

| Reference | Task |
| :--- | :--- |
| [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) | Evaluate known data at one parameter point. |
| [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/) | Sample one- or two-dimensional diagnostic plots. |
| [`bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/) | Inspect local Bernstein coefficients in tabular form. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/) | Use algebra, concatenation, indexing, assignment, and structural transforms. |

## Inherited Storage

`dpmat` extends [`dpbase`](/DP-LMI-package/documents/reference/dpbase/) and exposes `GridInfo`, `MatrixSize`, `Degree`, `LocalValues`, local labels, and cell-local coefficient inspection.

## Current Boundaries

- Function-only `dpmat` objects without explicit Bernstein evidence evaluate exactly but do not enter coefficient algebra.
- `dpmat` stores known numeric data only; decision variables belong to [`dpvar`](/DP-LMI-package/documents/reference/dpvar/).
- Plotting and `bernsteinTable` output are diagnostics, not solver-facing behavior.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) · [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/) · [`bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/)
