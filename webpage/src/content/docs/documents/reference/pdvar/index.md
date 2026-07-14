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
| [`rhodiff`](/PD-LMI-package/documents/reference/pdvar/rhodiff/) | Build discontinuous rate-vertex derivative expressions. |
| [`bernsteinTable`](/PD-LMI-package/documents/reference/pdvar/bernsteintable/) | Inspect symbolic coefficient rows and rate vertices. |
| [`value`](/PD-LMI-package/documents/reference/pdvar/value/) | Convert assigned coefficients to known `pdmat` data. |

### Algebra and matrix operations

| Reference | Task |
| :--- | :--- |
| [`Matrix operations`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/) | Use affine algebra, supported products, structural transforms, indexing, and assignment. |

### Constraints

| Reference | Task |
| :--- | :--- |
| [`Comparisons`](/PD-LMI-package/documents/reference/pdvar/comparisons/) | Create `pdlmi` constraints with `<=` and `>=`. |

## Scope Boundary

`pdvar` represents expressions. It does not choose solvers or call `optimize`; solver handoff begins with [`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/).

## See Also

[`pdvar constructor`](/PD-LMI-package/documents/reference/pdvar/constructor/) · [`rhodiff`](/PD-LMI-package/documents/reference/pdvar/rhodiff/) · [`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/)
