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
| [`pdmat constructor`](/GriD-LMIA/documents/reference/pdmat/constructor/) | Build known data from coefficient grids, local values, or function handles. |

### Evaluation and visualization

| Reference | Task |
| :--- | :--- |
| [`Storage`](/GriD-LMIA/documents/reference/pdmat/storage-and-elevation/) | Traverse known coefficient evidence and inspect its cell-local labels and counts. |
| [`elevate`](/GriD-LMIA/documents/reference/pdmat/elevate/) | Exactly elevate the Bernstein representation without changing the represented function. |
| [`evaluate`](/GriD-LMIA/documents/reference/pdmat/evaluate/) | Evaluate known data at one parameter point. |
| [`rhodiff`](/GriD-LMIA/documents/reference/pdmat/rhodiff/) | Differentiate coefficient-backed data into numeric rate-vertex rows. |
| [`plot`](/GriD-LMIA/documents/reference/pdmat/plot/) | Sample one- or two-dimensional diagnostic plots. |
| [`bernsteinTable`](/GriD-LMIA/documents/reference/pdmat/bernsteintable/) | Inspect local Bernstein coefficients in tabular form. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Algebra`](/GriD-LMIA/documents/reference/pdmat/algebra/) | Add, subtract, negate, and multiply coefficient-backed known data. |
| [`Structural operations`](/GriD-LMIA/documents/reference/pdmat/structural-operations/) | Reshape, reduce, assemble, and reorder matrix payloads. |
| [`Indexing and inspection`](/GriD-LMIA/documents/reference/pdmat/indexing-and-inspection/) | Index, assign, compare, display, and inspect payload shape. |
| [`Comparisons`](/GriD-LMIA/documents/reference/pdmat/comparisons/) | Use logical coefficient equality or create known-data `pdlmi` inequalities. |
| [`Legacy matrix-operations overview`](/GriD-LMIA/documents/reference/pdmat/matrix-operations/) | Forward old per-symbol anchors to the focused pages. |

## Inherited Storage

`pdmat` extends [`pdbase`](/GriD-LMIA/documents/reference/pdbase/).
The matrix-operation implementation is centralized there, while
[`pdmat` storage](/GriD-LMIA/documents/reference/pdmat/storage-and-elevation/),
[`pdmat elevate`](/GriD-LMIA/documents/reference/pdmat/elevate/), and the
algebra, structural, and indexing pages retain complete class-specific syntax
and behavior.

## Current Boundaries

- Function-only `pdmat` objects without explicit Bernstein evidence evaluate
  exactly but do not enter coefficient algebra, differentiation, tables, or
  inequalities.
- Ordinary one-row operands broadcast over explicit rate rows. Two rate-row
  operands require matching grids and rate boxes. Multiplication supports
  rate rows on at most one side.
- `pdmat` stores known numeric data only; decision variables belong to [`pdvar`](/GriD-LMIA/documents/reference/pdvar/).
- Plotting and `bernsteinTable` output are diagnostics, not solver-facing behavior.

## See Also

[`pdmat constructor`](/GriD-LMIA/documents/reference/pdmat/constructor/) ·
[`storage`](/GriD-LMIA/documents/reference/pdmat/storage-and-elevation/) ·
[`elevate`](/GriD-LMIA/documents/reference/pdmat/elevate/) ·
[`evaluate`](/GriD-LMIA/documents/reference/pdmat/evaluate/) ·
[`rhodiff`](/GriD-LMIA/documents/reference/pdmat/rhodiff/) ·
[`plot`](/GriD-LMIA/documents/reference/pdmat/plot/) ·
[`bernsteinTable`](/GriD-LMIA/documents/reference/pdmat/bernsteintable/) ·
[`comparisons`](/GriD-LMIA/documents/reference/pdmat/comparisons/)
