---
title: dpbase
description: Backend parent class for DP-LMI cell-local Bernstein objects.
---

`dpbase` is the backend parent for `dpmat` and `dpvar`. Ordinary users should model with `dpmat` and `dpvar`; this page explains inherited storage and inspection behavior.

## Reference Index

### Storage and inspection

| Reference | Task |
| :--- | :--- |
| [`Storage and inspection`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/) | Inspect `GridInfo`, `MatrixSize`, `Degree`, `LocalValues`, cells, coefficients, labels, and shape counts. |

### Bernstein backend context

| Reference | Task |
| :--- | :--- |
| [`Bernstein polynomial background`](/DP-LMI-package/documents/math/bernstein-polynomial/) | Review local coordinates, labels, convolution, and coefficient-wise constraints. |

## Current Boundary

Do not treat `dpbase` as a primary modeling API or solver API. Rate-dependent algebra and LMI assembly belong to `dpvar` and `dplmi`.

## See Also

[`dpmat`](/DP-LMI-package/documents/reference/dpmat/) · [`dpvar`](/DP-LMI-package/documents/reference/dpvar/)
