---
title: dpvar Constructor
description: Construct continuous YALMIP-backed Bernstein decision expressions.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpvar/">dpvar</a>
  <span>/</span>
  <span>constructor</span>
</nav>

## Purpose

Create a continuous cell-local Bernstein decision expression backed by YALMIP coefficients.

## Syntax

```matlab
P = dpvar(n, gridVectors)
P = dpvar(n, n, gridVectors)
P = dpvar(n, m, gridVectors)
P = dpvar(..., "full")
P = dpvar(..., "symmetric")
P = dpvar(..., Degree=0)
P = dpvar(..., Degree=1, RateBounds=rb)
```

## Arguments And Options

| Input | Description |
| :--- | :--- |
| `n`, `m` | Positive integer matrix dimensions. `dpvar(n, gridVectors)` creates an `n x n` object. |
| `gridVectors` | Numeric vector shorthand for one parameter, or a cell array of grid vectors. |
| `"full"` | Use full YALMIP matrix coefficients. |
| `"symmetric"` | Use symmetric YALMIP matrix coefficients. Requires square dimensions. |
| `Degree` | `0` or `1` for constructor-created variables. Default is `1`. |
| `RateBounds` | Finite `ell x 2` lower/upper rate-bound table stored as metadata. |

Unsupported public options: `IsContinuous`, `ContainsDecision`, and `HasRateDependence`.

## Returned Object

`P` is a `dpvar < dpbase` object with `ContainsDecision=true`. Degree-1 variables share boundary coefficient handles across adjacent physical cells; degree-0 variables reuse one symbolic coefficient over all cells.

## Examples

### Default symmetric square variable

```matlab
P = dpvar(2, {[0 1 2]}, "symmetric");
P.MatrixSize
P.Degree
```

```text
ans =
     2     2

ans =
     1
```

### Rectangular full variable

```matlab
Q = dpvar(2, 3, [0 1], "full", Degree=0);
Q.MatrixSize
Q.Degree
```

```text
ans =
     2     3

ans =
     0
```

### Rate metadata

```matlab
P = dpvar(1, {[0 1], [10 20]}, RateBounds=[-1 2; -3 4]);
P.HasRateDependence
P.RateBounds
```

```text
ans =
  logical
   1

ans =
    -1     2
    -3     4
```

## Validation And Errors

- Missing dimensions or grid vectors raise `dpvar:InvalidInput`.
- Nonsquare `"symmetric"` variables raise `dpvar:InvalidStructure`.
- Constructor degrees other than `0` or `1` raise `dpvar:InvalidDegree`.
- Invalid rate metadata raises `dpvar:InvalidRateBounds` or inherited `dpbase:InvalidRateBounds`.
- Unknown options raise `dpvar:UnknownOption`; internal metadata options raise `dpvar:UnsupportedOption`.

## See Also

[`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) · [`dpvar matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/) · [`dpbase`](/DP-LMI-package/documents/reference/dpbase/)
