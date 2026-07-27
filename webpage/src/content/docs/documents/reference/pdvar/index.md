---
title: pdvar
description: Continuous YALMIP-backed Bernstein decision expressions.
---

`pdvar` creates gridded YALMIP-backed Bernstein decision expressions. It is method-superior to `pdmat` and `sdpvar`, so mixed known, numeric, symbolic, and decision algebra dispatches through `pdvar`.

## Reference Index

### Construction

| Reference | Task |
| :--- | :--- |
| [`pdvar constructor`](/PD-LMI-package/documents/reference/pdvar/constructor/) | Create continuous decision expressions of any nonnegative Bernstein degree. |

### Differentiation and inspection

| Reference | Task |
| :--- | :--- |
| [`Storage and evaluation`](/PD-LMI-package/documents/reference/pdvar/storage-and-evaluation/) | Traverse symbolic/rate rows, elevate them independently, and evaluate without consulting assignments. |
| [`rhodiff`](/PD-LMI-package/documents/reference/pdvar/rhodiff/) | Build discontinuous rate-vertex derivative expressions. |
| [`bernsteinTable`](/PD-LMI-package/documents/reference/pdvar/bernsteintable/) | Inspect symbolic coefficient rows and rate vertices. |
| [`value`](/PD-LMI-package/documents/reference/pdvar/value/) | Convert assigned coefficients to known `pdmat` data. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Algebra`](/PD-LMI-package/documents/reference/pdvar/algebra/) | Build affine sums, differences, and supported products. |
| [`Structural operations`](/PD-LMI-package/documents/reference/pdvar/structural-operations/) | Reshape, reduce, assemble, and reorder symbolic payloads. |
| [`Indexing and inspection`](/PD-LMI-package/documents/reference/pdvar/indexing-and-inspection/) | Index, assign, structurally compare, display, and inspect payload shape. |
| [`Legacy matrix-operations overview`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/) | Forward old per-symbol anchors to the focused pages. |

### Constraints

| Reference | Task |
| :--- | :--- |
| [`Comparisons`](/PD-LMI-package/documents/reference/pdvar/comparisons/) | Create semidefinite or entry-wise inequalities with `<=`/`>=`, and direct equalities with `==`. |

## Scope Boundary

`pdvar` represents expressions. It does not choose solvers or call `optimize`; solver handoff begins with [`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/).
Its common matrix operations are centralized in `pdbase`, but every inherited
operation remains documented here with `pdvar` symbolic and rate-aware
behavior.

## See Also

[`pdvar constructor`](/PD-LMI-package/documents/reference/pdvar/constructor/) · [`storage and evaluation`](/PD-LMI-package/documents/reference/pdvar/storage-and-evaluation/) · [`rhodiff`](/PD-LMI-package/documents/reference/pdvar/rhodiff/) · [`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/)
