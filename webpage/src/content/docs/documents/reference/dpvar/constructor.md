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
| `n`, `m` | Positive integer matrix dimensions. `dpvar(n, gridVectors)` creates an `n x n` object, such as `dpvar(2,{[0 1]})`; `dpvar(n,m,gridVectors)` creates an `n x m` object, such as `dpvar(2,3,[0 1])`. |
| `gridVectors` | Numeric vector shorthand for one parameter, such as `[0 1 2]`, or a cell array of grid vectors, such as `{[0 1], [10 20]}`. |
| `"full"` | Use full YALMIP matrix coefficients, as in `dpvar(2,2,{[0 1]},"full")`. |
| `"symmetric"` | Use symmetric YALMIP matrix coefficients, as in `dpvar(2,{[0 1]},"symmetric")`. Requires square dimensions. |
| `Degree` | Finite nonnegative integer scalar. Default is `1`; use `Degree=0` for a parameter-independent decision, or higher degrees for continuous piecewise Bernstein decision data. |
| `RateBounds` | Finite `ell x 2` lower/upper rate-bound table stored as metadata, such as `RateBounds=[-1 1]` or `RateBounds=[-1 2; -3 4]`. |

Unsupported public options: `IsContinuous`, `ContainsDecision`, and `HasRateDependence`.

## Returned Object

`P` is a parameter-dependent `dpvar < dpbase` object with
`ContainsDecision=true`. It is not one isolated `sdpvar` matrix. For the
default degree-1 constructor, each local grid cell stores the Bernstein
coefficient matrices that define `P(rho)` on that cell. The coefficient payloads
are YALMIP `sdpvar` matrices, and the cell-local storage lives in
`LocalValues`.

For one parameter segment, the scalar-entry mental model is:

$$
P(\rho) =
B_0^1(\alpha)P_i + B_1^1(\alpha)P_{i+1},
\qquad
\alpha = \frac{\rho-\rho_i}{\rho_{i+1}-\rho_i},
\qquad
B_j^1(\alpha)=(1-\alpha)^{1-j}\alpha^j.
$$

Here `P_i` and `P_{i+1}` stand for YALMIP matrix coefficients. Adjacent
degree-1 cells share the boundary coefficient handle, so continuity is stored
directly in the coefficient graph instead of being enforced by a separate LMI
constraint. Degree-0 variables reuse one symbolic coefficient over all physical
cells while still carrying grid metadata.

This is the standard forward-coordinate convention: `alpha=0` at the left
endpoint, so local label `0` selects `P_i`; `alpha=1` at the right endpoint,
so local label `1` selects `P_{i+1}`. At general degree $m$, label $j$ uses
$B_j^m(\alpha)=\binom{m}{j}(1-\alpha)^{m-j}\alpha^j$.

In the stored object, each labeled endpoint is a YALMIP matrix coefficient, and
the stored leaves are `LocalValues{1} = {P_0, P_1}`,
`LocalValues{2} = {P_1, P_2}`, and so on.

The inherited fields are readable through dot syntax and have private set
access:

| Field | How to inspect it | Meaning for `dpvar` |
| :--- | :--- | :--- |
| `GridInfo` | `P.GridInfo.Vectors{1}`, `P.GridInfo.Points`, `P.GridInfo.Bounds` | Tensor-grid metadata inherited from `dpbase`. |
| `MatrixSize` | `P.MatrixSize` | Matrix size of each YALMIP coefficient payload. |
| `Degree` | `P.Degree` | Constructor-created objects accept every nonnegative integer degree; algebra can also raise degree. |
| `LocalValues` | `P.LocalValues{1}` or `P.coeffs(1)` | Cell-local YALMIP coefficient payloads. |
| `IsContinuous` | `P.IsContinuous` | `true` for constructor-created variables; `rhodiff` outputs are discontinuous. |
| `ContainsDecision` | `P.ContainsDecision` | `true` unless algebra proves a zero/nondecision result. |
| `HasRateDependence` | `P.HasRateDependence` | `true` when rate metadata or rate rows are present. |
| `RateBounds` | `P.RateBounds` | Empty or the `ell x 2` rate-bound table. |
| `SourceSummary` | `P.SourceSummary` | Source label such as `decision` or `derivative`. |

`dpvar` has no `FunctionHandle` field. Its internal values are symbolic
coefficient expressions in `LocalValues`. These fields are inspectable but not
assignable so that `Degree`, grid dimension, label order, continuity metadata,
and coefficient storage stay synchronized.

## Examples

### Default symmetric square variable

```matlab
yalmip('clear')
P = dpvar(2, {[0 1 2]}, "symmetric");
P.GridInfo.Vectors{1}
first = P.coeffs(1);
second = P.coeffs(2);
isequal(getvariables(first{2}), getvariables(second{1}))
P.MatrixSize
P.Degree
P.IsContinuous
P.ContainsDecision
P.SourceSummary
```

```text
ans =
     0     1     2

ans =
  logical
   1

ans =
     2     2

ans =
     1

ans =
  logical
   1

ans =
  logical
   1

ans =
    "decision"
```

### Rectangular full variable

```matlab
yalmip('clear')
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
yalmip('clear')
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
- Negative, noninteger, nonscalar, or nonfinite constructor degrees raise `dpvar:InvalidDegree`.
- Invalid rate metadata raises `dpvar:InvalidRateBounds` or inherited `dpbase:InvalidRateBounds`.
- Unknown options raise `dpvar:UnknownOption`; internal metadata options raise `dpvar:UnsupportedOption`.

## See Also

[`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) · [`dpvar matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/) · [`dpbase`](/DP-LMI-package/documents/reference/dpbase/)
