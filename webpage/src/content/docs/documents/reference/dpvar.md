---
title: dpvar
description: Continuous YALMIP-backed Bernstein decision expressions.
---

## Purpose

`dpvar` creates gridded YALMIP-backed Bernstein decision expressions. It is method-superior to `dpmat` and `sdpvar`, so mixed known, numeric, symbolic, and decision algebra dispatches through `dpvar`.

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
| `gridVectors` | Scalar vector shorthand or cell array of grid vectors. |
| `"full"` | Use full YALMIP matrix coefficients. |
| `"symmetric"` | Use symmetric YALMIP matrix coefficients. Requires square dimensions. |
| `Degree` | `0` or `1` for constructor-created variables. Default is `1`. |
| `RateBounds` | Finite `ell x 2` lower/upper rate-bound table. |

`IsContinuous`, `ContainsDecision`, and `HasRateDependence` are internal metadata and are not public constructor options.

## Description

Degree-1 `dpvar` objects share boundary coefficient handles across adjacent cells, so continuity is represented by shared YALMIP decisions rather than added equality constraints. Degree-0 objects store one parameter-independent symbolic coefficient over all physical cells.

## Examples

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

## Algebra

`dpvar` supports affine addition/subtraction, unary operations, matrix multiplication with decision dependence on at most one side, numeric and affine `sdpvar` promotion, coefficient-backed `dpmat` promotion, and structural matrix operations over local coefficients.

Supported structural operations include shape inspection, triangular/diagonal/trace/sum/mean/cumsum, reshape/repmat/vectorization, flips/rotations, `blkdiag`, concatenation, and two-dimensional matrix indexing/assignment.

## `rhodiff`

```matlab
D = rhodiff(P, rb)
D = rhodiff(P)
```

`rhodiff(P, rb)` returns a discontinuous, rate-vertex `dpvar` derivative expression. Each physical cell stores one coefficient row per `rho_dot` vertex. `rhodiff(P)` is supported when `P` already carries matching nonempty `RateBounds`.

```matlab
P = dpvar(1, {[0 1 2]}, RateBounds=[-1 1]);
D = rhodiff(P);
D.HasRateDependence
D.RateBounds
```

```text
ans =
  logical
   1

ans =
    -1     1
```

Scalar degree-1 derivatives become degree-0 rows. Multivariate derivatives are accumulated into a common tensor degree basis after local partial elevation.

## Comparisons

```matlab
C1 = P <= 0
C2 = P >= 0
```

Comparison overloads form a residual and return a [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) object. `dpvar` itself does not choose solvers or call `optimize`.

## Validation And Errors

- Missing dimensions or grid vectors raise `dpvar:InvalidInput`.
- Unsupported options raise `dpvar:UnknownOption` or `dpvar:UnsupportedOption`.
- Nonsquare symmetric variables raise `dpvar:InvalidStructure`.
- Constructor `Degree` values other than `0` or `1` raise `dpvar:InvalidDegree`.
- Invalid constructor `RateBounds` metadata can raise `dpvar:InvalidRateBounds` or inherited `dpbase:InvalidRateBounds`, depending on the validation point.
- `rhodiff(P)` without stored rate bounds raises `dpvar:MissingRateBounds`.
- `rhodiff(P, rb)` with explicit bounds that do not match existing object bounds raises `dpvar:RateBoundsMismatch`.
- Re-differentiating an existing rate-vertex expression raises `dpvar:InvalidDiff`.
- Products with rate dependence on both sides or decision dependence on both sides are rejected by algebra helpers.

## Limitations

- Constructor-created variables are limited to degree 0 or degree 1.
- `dpvar` does not implement a package-owned solver wrapper.
- Relaxation lemma and Polya assembly are not part of `dpvar` algebra.

## See Also

[`dpmat`](/DP-LMI-package/documents/reference/dpmat/) · [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) · [`Bernstein Polynomial`](/DP-LMI-package/documents/math/bernstein-polynomial/)
