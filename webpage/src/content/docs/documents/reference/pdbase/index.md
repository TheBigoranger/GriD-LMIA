---
title: pdbase
description: Shared backend parent for PD-LMI storage, evaluation, elevation, and matrix operations.
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
| [`Constructor`](/PD-LMI-package/documents/reference/pdbase/constructor/) | Direct backend construction, private-set metadata, validation, and limitations. |
| [`Storage and inspection`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/) | Properties, cells, coefficients, labels, cell/label/parameter counts, and payload shape. |
| [`Evaluation and elevation`](/PD-LMI-package/documents/reference/pdbase/evaluation-and-elevation/) | Numeric/symbolic evaluation, right-cell ownership, `elevVals`, and class-preserving `elevate`. |
| [`Matrix operations`](/PD-LMI-package/documents/reference/pdbase/matrix-operations/) | Unary sign, transpose, reshape, reductions, triangular transforms, repeat/reorder, and direct-base concatenation rejection. |
| [`Indexing protocol`](/PD-LMI-package/documents/reference/pdbase/indexing-protocol/) | `end` and `numArgumentsFromSubscript` infrastructure inherited by both derived classes. |
| [`Protected backend utilities`](/PD-LMI-package/documents/reference/bernstein-utilities/) | All nine protected methods; not callable public API. |

## Current boundary

Direct `pdbase` values are validated coefficient containers, not decision
variables or LMI wrappers. `pdmat` adds known-data construction, algebra,
assignment, diagnostics, and plotting. `pdvar` adds YALMIP decisions, affine
algebra, differentiation, comparisons, and value recovery. `pdlmi` owns finite
certificate assembly and solver handoff.

## See Also

[`pdmat`](/PD-LMI-package/documents/reference/pdmat/) ·
[`pdvar`](/PD-LMI-package/documents/reference/pdvar/) ·
[`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/) ·
[`reference lookup`](/PD-LMI-package/documents/reference-index/)
