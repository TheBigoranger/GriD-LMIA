---
title: dpbase
description: Backend parent class for DP-LMI cell-local Bernstein objects.
---

## Purpose

`dpbase` is the backend parent for `dpmat` and `dpvar`. It owns tensor-grid metadata, matrix payload size, Bernstein degree, nested `LocalValues`, local labels, and shared inspection utilities.

Ordinary users should model with [`dpmat`](/DP-LMI-package/documents/reference/dpmat/) and [`dpvar`](/DP-LMI-package/documents/reference/dpvar/). This page exists to explain inherited storage and inspection behavior.

## Syntax

`dpbase` is not the primary public modeling constructor. Subclasses call it internally with validated grid, size, degree, local values, continuity, decision, and rate metadata.

## Description

Both `dpmat` and `dpvar` expose the same grid and coefficient inspection shape because they inherit from `dpbase`. Continuous subclasses may share boundary data across adjacent cells; derivative expressions produced by `rhodiff` intentionally keep discontinuous cell-local rows.

## Inherited Inspection Properties

| Property | Meaning |
| :--- | :--- |
| `GridInfo` | Validated tensor-grid vectors, bounds, and node counts. |
| `MatrixSize` | Matrix payload size for each coefficient. |
| `Degree` | Scalar Bernstein degree used by the object. |
| `LocalValues` | Nested physical-cell storage with flat coefficient cells inside each cell. |
| `IsContinuous` | Whether the object represents continuous physical-cell data. |
| `ContainsDecision` | Whether coefficients include YALMIP decisions. |
| `HasRateDependence` | Whether coefficients carry rate-vertex rows. |
| `RateBounds` | `ell x 2` rate-bound table when rate metadata exists. |
| `SourceSummary` | Short source label such as `decision`, `function`, or derivative metadata. |

## Methods

### `cells`

Returns physical cell subscripts. For a scalar grid with two physical intervals, `cells(obj)` returns two rows.

### `coeffs`

Returns the local Bernstein coefficient family for a physical cell. For rate-vertex derivative expressions, coefficient data can have multiple rows.

### `lbls`

Enumerates local Bernstein labels in flat row order over `{0, ..., Degree}^ell`.

### `ncell`, `ncoeff`, `npar`, `size`

Return physical cell count, local coefficient count, parameter count, and matrix payload dimensions.

## Example

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
labels = A.lbls()
```

```text
labels =
     0     0
     0     1
     1     0
     1     1
```

## Validation And Errors

`dpbase` validates grid monotonicity, matrix size, coefficient count, local storage shape, rate metadata, and matrix payload compatibility. User-facing validation is normally reached through `dpmat`, `dpvar`, or `dplmi`.

## Limitations

- Do not treat `dpbase` as a primary modeling API.
- Do not write solver workflows around raw `dpbase` objects.
- Rate-dependent algebra and LMI assembly belong to `dpvar` and `dplmi`.

## See Also

[`dpmat`](/DP-LMI-package/documents/reference/dpmat/) · [`dpvar`](/DP-LMI-package/documents/reference/dpvar/) · [`Bernstein Polynomial`](/DP-LMI-package/documents/math/bernstein-polynomial/)
