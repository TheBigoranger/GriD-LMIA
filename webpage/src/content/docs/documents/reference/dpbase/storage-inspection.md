---
title: dpbase Storage And Inspection
description: Inherited grid, local value, label, and coefficient inspection behavior.
---

## Purpose

Understand the inherited storage contract used by `dpmat` and `dpvar`.

## Inherited Properties

| Property | Meaning |
| :--- | :--- |
| `GridInfo` | Validated tensor-grid vectors, bounds, and node counts. |
| `MatrixSize` | Matrix payload size for each coefficient. |
| `Degree` | Scalar Bernstein degree. |
| `LocalValues` | Nested physical-cell storage with flat coefficient cells inside each cell. |
| `IsContinuous` | Whether the object represents continuous physical-cell data. |
| `ContainsDecision` | Whether coefficients include YALMIP decisions. |
| `HasRateDependence` | Whether coefficients carry rate-vertex rows. |
| `RateBounds` | `ell x 2` rate-bound table when rate metadata exists. |
| `SourceSummary` | Short source label such as `decision`, `function`, or derivative metadata. |

## Inspection Methods

| Method | Output |
| :--- | :--- |
| `cells(obj)` | Physical cell subscripts. |
| `coeffs(obj, cellSubscript)` | Local Bernstein coefficient family for one physical cell. |
| `lbls(obj)` | Local Bernstein labels in flat row order. |
| `ncell(obj)` | Number of physical cells. |
| `ncoeff(obj)` | Number of local coefficients per cell. |
| `npar(obj)` | Number of parameters. |
| `size(obj)` | Matrix payload dimensions. |

### cells

```matlab
C = cells(obj)
```

Returns one row per physical cell. Each row contains tensor-grid cell subscripts.

### coeffs

```matlab
V = coeffs(obj, cellSubscript)
```

Returns the local Bernstein coefficient family stored at one physical cell.

### lbls

```matlab
L = lbls(obj)
```

Returns local Bernstein multi-index labels in the same flat order used by `LocalValues`.

## Example

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
A.cells()
A.lbls()
```

```text
ans =
     1     1

ans =
     0     0
     0     1
     1     0
     1     1
```

## Validation Boundary

`dpbase` validates grid monotonicity, matrix size, coefficient count, local storage shape, rate metadata, and matrix payload compatibility. User-facing validation is normally reached through `dpmat`, `dpvar`, or `dplmi`.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/)
