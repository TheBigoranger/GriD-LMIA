---
title: pdbase
description: Shared backend parent for GriD-LMIA storage, evaluation, elevation, and matrix operations.
---

`pdbase` is the backend parent of `pdmat` and `pdvar`. It centralizes the
tensor-grid, cell-local Bernstein, shape, evaluation, elevation, unary,
structural, reduction, and MATLAB indexing protocols. Central ownership avoids
duplicate implementations; it does not remove these inherited public features
from the `pdmat` and `pdvar` APIs.

Ordinary modeling code should construct `pdmat` and `pdvar` values. The pages
below make the common implementation and direct-backend behavior discoverable.

## Reference index

| Reference | Coverage |
| :--- | :--- |
| [`Constructor`](/GriD-LMIA/documents/reference/pdbase/constructor/) | Direct backend construction, private-set metadata, validation, and limitations. |
| [`Storage and inspection`](/GriD-LMIA/documents/reference/pdbase/storage-inspection/) | Properties, cells, coefficients, labels, cell/label/parameter counts, and payload shape. |
| [`Evaluation and elevation`](/GriD-LMIA/documents/reference/pdbase/evaluation-and-elevation/) | Numeric/symbolic evaluation, right-cell ownership, `elevate`, and class-preserving `elevate`. |
| [`Matrix operations`](/GriD-LMIA/documents/reference/pdbase/matrix-operations/) | Unary sign, transpose, reshape, reductions, triangular transforms, repeat/reorder, and direct-base concatenation rejection. |
| [`Indexing protocol`](/GriD-LMIA/documents/reference/pdbase/indexing-protocol/) | `end` and `numArgumentsFromSubscript` infrastructure inherited by both derived classes. |
| [`Protected backend utilities`](/GriD-LMIA/documents/reference/bernstein-utilities/) | All nine protected methods; not callable public API. |

## Current boundary

Direct `pdbase` values are validated coefficient containers, not decision
variables or LMI wrappers. `pdmat` adds known-data construction, algebra,
assignment, diagnostics, and plotting. `pdvar` adds YALMIP decisions, affine
algebra, differentiation, comparisons, and value recovery. `pdlmi` owns finite
certificate assembly and solver handoff.

## See Also

[`pdmat`](/GriD-LMIA/documents/reference/pdmat/) ·
[`pdvar`](/GriD-LMIA/documents/reference/pdvar/) ·
[`pdlmi`](/GriD-LMIA/documents/reference/pdlmi/) ·
[`reference lookup`](/GriD-LMIA/documents/reference-index/)
