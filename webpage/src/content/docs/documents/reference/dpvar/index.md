---
title: dpvar
description: Continuous YALMIP-backed Bernstein decision expressions.
---

`dpvar` creates gridded YALMIP-backed Bernstein decision expressions. It is method-superior to `dpmat` and `sdpvar`, so mixed known, numeric, symbolic, and decision algebra dispatches through `dpvar`.

## Reference Index

### Construction

| Reference | Task |
| :--- | :--- |
| [`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) | Create continuous decision expressions of any nonnegative Bernstein degree. |

### Differentiation and inspection

| Reference | Task |
| :--- | :--- |
| [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) | Build discontinuous rate-vertex derivative expressions. |
| [`bernsteinTable`](/DP-LMI-package/documents/reference/dpvar/bernsteintable/) | Inspect symbolic coefficient rows and rate vertices. |
| [`value`](/DP-LMI-package/documents/reference/dpvar/value/) | Convert assigned coefficients to known `dpmat` data. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/) | Use affine algebra, supported products, structural transforms, indexing, and assignment. |

### Constraints

| Reference | Task |
| :--- | :--- |
| [`Comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) | Create `dplmi` constraints with `<=` and `>=`. |

## Scope Boundary

`dpvar` represents expressions. It does not choose solvers or call `optimize`; solver handoff begins with [`dplmi`](/DP-LMI-package/documents/reference/dplmi/).

## See Also

[`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) · [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) · [`dplmi`](/DP-LMI-package/documents/reference/dplmi/)
