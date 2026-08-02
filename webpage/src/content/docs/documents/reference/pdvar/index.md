---
title: pdvar
description: Continuous YALMIP-backed Bernstein decision expressions.
---

`pdvar` creates gridded YALMIP-backed Bernstein decision expressions. It is method-superior to `pdmat` and `sdpvar`, so mixed known, numeric, symbolic, and decision algebra dispatches through `pdvar`.

## Reference Index

### Construction

| Reference | Task |
| :--- | :--- |
| [`pdvar constructor`](/GriD-LMIA/documents/reference/pdvar/constructor/) | Create continuous decision expressions of any nonnegative Bernstein degree. |

### Differentiation and inspection

| Reference | Task |
| :--- | :--- |
| [`Storage and evaluation`](/GriD-LMIA/documents/reference/pdvar/storage-and-evaluation/) | Traverse symbolic/rate rows, elevate them independently, and evaluate without consulting assignments. |
| [`rhodiff`](/GriD-LMIA/documents/reference/pdvar/rhodiff/) | Build discontinuous rate-vertex derivative expressions. |
| [`bernsteinTable`](/GriD-LMIA/documents/reference/pdvar/bernsteintable/) | Inspect symbolic coefficient rows and rate vertices. |
| [`value`](/GriD-LMIA/documents/reference/pdvar/value/) | Convert assigned coefficients to known `pdmat` data. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Algebra`](/GriD-LMIA/documents/reference/pdvar/algebra/) | Build affine sums, differences, and supported products. |
| [`Structural operations`](/GriD-LMIA/documents/reference/pdvar/structural-operations/) | Reshape, reduce, assemble, and reorder symbolic payloads. |
| [`Indexing and inspection`](/GriD-LMIA/documents/reference/pdvar/indexing-and-inspection/) | Index, assign, structurally compare, display, and inspect payload shape. |
| [`Legacy matrix-operations overview`](/GriD-LMIA/documents/reference/pdvar/matrix-operations/) | Forward old per-symbol anchors to the focused pages. |

### Constraints

| Reference | Task |
| :--- | :--- |
| [`Comparisons`](/GriD-LMIA/documents/reference/pdvar/comparisons/) | Create semidefinite or entry-wise inequalities with `<=`/`>=`, and direct equalities with `==`. |

## Scope Boundary

`pdvar` represents expressions. It does not choose solvers or call `optimize`; solver handoff begins with [`pdlmi`](/GriD-LMIA/documents/reference/pdlmi/).
Its common matrix operations are centralized in `pdbase`, but every inherited
operation remains documented here with `pdvar` symbolic and rate-aware
behavior.

## See Also

[`pdvar constructor`](/GriD-LMIA/documents/reference/pdvar/constructor/) · [`storage and evaluation`](/GriD-LMIA/documents/reference/pdvar/storage-and-evaluation/) · [`rhodiff`](/GriD-LMIA/documents/reference/pdvar/rhodiff/) · [`pdlmi`](/GriD-LMIA/documents/reference/pdlmi/)
