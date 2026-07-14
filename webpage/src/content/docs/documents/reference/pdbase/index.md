---
title: pdbase
description: Backend parent class for DP-LMI cell-local Bernstein objects.
---

`pdbase` is the backend parent for `pdmat` and `pdvar`. Ordinary users should model with `pdmat` and `pdvar`; this page explains inherited storage and inspection behavior.

## Reference Index

### Storage and inspection

| Reference | Task |
| :--- | :--- |
| [`Storage and inspection`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/) | Inspect `GridInfo`, `MatrixSize`, `Degree`, `LocalValues`, cells, coefficients, labels, and shape counts. |

### Bernstein backend context

| Reference | Task |
| :--- | :--- |
| [`Bernstein polynomial background`](/DP-LMI-package/documents/math/bernstein-polynomial/) | Review local coordinates, labels, convolution, and coefficient-wise constraints. |

## Current Boundary

Do not treat `pdbase` as a primary modeling API or solver API. Rate-dependent algebra and LMI assembly belong to `pdvar` and `pdlmi`.

## See Also

[`pdmat`](/DP-LMI-package/documents/reference/pdmat/) · [`pdvar`](/DP-LMI-package/documents/reference/pdvar/)
