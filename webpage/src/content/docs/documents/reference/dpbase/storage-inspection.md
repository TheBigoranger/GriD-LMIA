---
title: dpbase Storage And Inspection
description: Inherited grid, local value, label, and coefficient inspection behavior.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpbase/">dpbase</a>
  <span>/</span>
  <span>storage inspection</span>
</nav>

## Purpose

Understand the inherited storage contract used by `dpmat` and `dpvar`.

## Inherited Properties

`dpmat` and `dpvar` inherit these read-only public properties from `dpbase`.
They are accessed with ordinary dot syntax, such as `A.Degree`,
`P.GridInfo.Vectors{1}`, or `D.LocalValues{1}`. The properties have private
set access: users can inspect them, but constructor and algebra methods are
responsible for keeping grid metadata, coefficient counts, continuity flags,
and rate metadata consistent.

| Property | Meaning |
| :--- | :--- |
| `GridInfo` | Struct with `Vectors`, `Points`, `Bounds`, and `NumNodes`. Use `obj.GridInfo.Vectors{k}` for one parameter grid, `obj.GridInfo.Points` for tensor-product node rows, `obj.GridInfo.Bounds(k,:)` for physical parameter bounds, and `obj.GridInfo.NumNodes(k)` for the node count. |
| `MatrixSize` | Matrix payload size for each coefficient. |
| `Degree` | Scalar Bernstein degree. |
| `LocalValues` | Nested physical-cell storage. Each ordinary leaf stores a flat coefficient cell; a `rhodiff` leaf stores a rate-row-by-coefficient cell array. Prefer `coeffs(obj, cellSubscript)` for normal inspection. |
| `IsContinuous` | Whether the object represents continuous physical-cell data. |
| `ContainsDecision` | Whether coefficients include YALMIP decisions. |
| `HasRateDependence` | Whether coefficients carry rate-vertex rows. |
| `RateBounds` | `ell x 2` rate-bound table when rate metadata exists. |
| `SourceSummary` | Short source label such as `decision`, `function`, or derivative metadata. |

`dpmat` adds a read-only `FunctionHandle` property. It is nonempty only for
function-backed construction. `dpvar` does not expose `FunctionHandle`; its
payloads are YALMIP expressions stored in inherited `LocalValues`.

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

### <span id="dpbase-cells"></span>`cells`

```matlab
C = cells(obj)
```

Returns one row per physical cell. Each row contains tensor-grid cell subscripts.

### <span id="dpbase-coeffs"></span>`coeffs`

```matlab
V = coeffs(obj, cellSubscript)
```

Returns the local Bernstein coefficient family stored at one physical cell.

### <span id="dpbase-lbls"></span>`lbls`

```matlab
L = lbls(obj)
```

Returns local Bernstein multi-index labels in the same flat order used by `LocalValues`.

### <span id="dpbase-ncell"></span>`ncell`

```matlab
n = ncell(obj)
```

Returns the number of physical tensor-grid cells, equal to the product of
`NumNodes(k)-1` over all parameter dimensions.

### <span id="dpbase-ncoeff"></span>`ncoeff`

```matlab
n = ncoeff(obj)
```

Returns the number of local coefficient columns in one ordinary cell. For
degree `m` and `ell` parameters, this is `(m+1)^ell`.

### <span id="dpbase-npar"></span>`npar`

```matlab
n = npar(obj)
```

Returns the number of parameter-grid dimensions represented by the object.

### <span id="dpbase-size"></span>`size`

```matlab
[m, n] = size(obj)
n = size(obj, dim)
```

Reports matrix payload dimensions using MATLAB's standard `size` forms. The
coefficient grid and matrix payload are separate: `size(obj)` describes one
stored matrix, not the number of physical cells.

## Example

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
A.GridInfo.Vectors{2}
A.MatrixSize
A.LocalValues{1}{1}
A.cells()
A.lbls()
```

```text
ans =
    10    20

ans =
     1     1

ans =
  1x4 cell array
    {[1]}    {[3]}    {[5]}    {[7]}

ans =
     1     1

ans =
     0     0
     0     1
     1     0
     1     1
```

For an ordinary object with Bernstein degree `m` and `ell` parameter
dimensions, one physical-cell leaf contains `(m+1)^ell` local coefficients in
the `lbls()` order. For a derivative object returned by `rhodiff`, one leaf is
a two-dimensional cell array with `2^ell` rate rows and
`(outDegree+1)^ell` coefficient columns.

## Validation Boundary

`dpbase` validates grid monotonicity, matrix size, coefficient count, local storage shape, rate metadata, and matrix payload compatibility. User-facing validation is normally reached through `dpmat`, `dpvar`, or `dplmi`.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/)
