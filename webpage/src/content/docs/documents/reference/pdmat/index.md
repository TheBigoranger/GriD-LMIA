---
title: pdmat
description: Known finite real matrix data on a parameter grid.
---

`pdmat` represents known finite real matrix data on a parameter grid. Use it
for exact function-backed data, coefficient-backed Bernstein data, optional
rate-box metadata and explicit rate rows, differentiation, plotting
diagnostics, known-data certificates, and coefficient-wise matrix operations.

## Reference Index

### Construction

| Reference | Task |
| :--- | :--- |
| [`pdmat constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/) | Build known data from coefficient grids, local values, or function handles. |

### Evaluation and visualization

| Reference | Task |
| :--- | :--- |
| [`Storage`](/PD-LMI-package/documents/reference/pdmat/storage-and-elevation/) | Traverse known coefficient evidence and inspect its cell-local labels and counts. |
| [`elevate`](/PD-LMI-package/documents/reference/pdmat/elevate/) | Exactly elevate the Bernstein representation without changing the represented function. |
| [`evaluate`](/PD-LMI-package/documents/reference/pdmat/evaluate/) | Evaluate known data at one parameter point. |
| [`rhodiff`](/PD-LMI-package/documents/reference/pdmat/rhodiff/) | Differentiate coefficient-backed data into numeric rate-vertex rows. |
| [`plot`](/PD-LMI-package/documents/reference/pdmat/plot/) | Sample one- or two-dimensional diagnostic plots. |
| [`bernsteinTable`](/PD-LMI-package/documents/reference/pdmat/bernsteintable/) | Inspect local Bernstein coefficients in tabular form. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Algebra`](/PD-LMI-package/documents/reference/pdmat/algebra/) | Add, subtract, negate, and multiply coefficient-backed known data. |
| [`Structural operations`](/PD-LMI-package/documents/reference/pdmat/structural-operations/) | Reshape, reduce, assemble, and reorder matrix payloads. |
| [`Indexing and inspection`](/PD-LMI-package/documents/reference/pdmat/indexing-and-inspection/) | Index, assign, compare, display, and inspect payload shape. |
| [`Comparisons`](/PD-LMI-package/documents/reference/pdmat/comparisons/) | Use logical coefficient equality or create known-data `pdlmi` inequalities. |
| [`Legacy matrix-operations overview`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/) | Forward old per-symbol anchors to the focused pages. |

## Inherited Storage

`pdmat` extends [`pdbase`](/PD-LMI-package/documents/reference/pdbase/).
The matrix-operation implementation is centralized there, while
[`pdmat` storage](/PD-LMI-package/documents/reference/pdmat/storage-and-elevation/),
[`pdmat elevate`](/PD-LMI-package/documents/reference/pdmat/elevate/), and the
algebra, structural, and indexing pages retain complete class-specific syntax
and behavior.

## Current Boundaries

- Function-only `pdmat` objects without explicit Bernstein evidence evaluate
  exactly but do not enter coefficient algebra, differentiation, tables, or
  inequalities.
- Ordinary one-row operands broadcast over explicit rate rows. Two rate-row
  operands require matching grids and rate boxes. Multiplication supports
  rate rows on at most one side.
- `pdmat` stores known numeric data only; decision variables belong to [`pdvar`](/PD-LMI-package/documents/reference/pdvar/).
- Plotting and `bernsteinTable` output are diagnostics, not solver-facing behavior.

## See Also

[`pdmat constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/) ·
[`storage`](/PD-LMI-package/documents/reference/pdmat/storage-and-elevation/) ·
[`elevate`](/PD-LMI-package/documents/reference/pdmat/elevate/) ·
[`evaluate`](/PD-LMI-package/documents/reference/pdmat/evaluate/) ·
[`rhodiff`](/PD-LMI-package/documents/reference/pdmat/rhodiff/) ·
[`plot`](/PD-LMI-package/documents/reference/pdmat/plot/) ·
[`bernsteinTable`](/PD-LMI-package/documents/reference/pdmat/bernsteintable/) ·
[`comparisons`](/PD-LMI-package/documents/reference/pdmat/comparisons/)
