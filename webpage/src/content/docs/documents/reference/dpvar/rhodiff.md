---
title: dpvar rhodiff
description: Rate-weighted cell-local derivative of a dpvar expression.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpvar/">dpvar</a>
  <span>/</span>
  <span>rhodiff</span>
</nav>

## Purpose

Return a discontinuous, rate-vertex derivative expression for a `dpvar` object.

## Syntax

```matlab
D = rhodiff(P, rb)
D = rhodiff(P)
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `P` | A `dpvar` expression that is not already a rate-vertex derivative expression. |
| `rb` | Finite `ell x 2` rate-bound table, such as `[-1 1]` or `[-1 2; -3 5]`. Required unless `P` already carries matching `RateBounds`. |

## Output

`D` is a `dpvar` with `HasRateDependence=true`, `IsContinuous=false`, and
`SourceSummary="derivative"`. It inherits the usual read-only fields
(`GridInfo`, `MatrixSize`, `Degree`, `LocalValues`, `ContainsDecision`,
`RateBounds`, and the rest) and is inspected with ordinary dot syntax or
`coeffs`.

Each physical cell stores one coefficient row per active `rho_dot` vertex. If
`rb` has `ell` rows, each row contributes a lower and upper rate choice, so
`rhodiff` forms the Cartesian product of those choices and stores `2^ell`
rate rows. The coefficient columns still follow the Bernstein label order
returned by `D.lbls()`.

## Example

```matlab
yalmip('clear')
P = dpvar(1, {[0 1 2]}, RateBounds=[-1 1]);
D = rhodiff(P);
D.Degree
D.IsContinuous
D.HasRateDependence
D.RateBounds
size(D.coeffs(1))
```

```text
ans =
     0

ans =
  logical
   0

ans =
  logical
   1

ans =
    -1     1

ans =
     2     1
```

The `2 x 1` coefficient table has two rate rows because the scalar rate box
has two vertices, `-1` and `1`; it has one coefficient column because scalar
degree-1 derivatives become degree-0 coefficient rows.

For multiple parameters, the rate vertices are ordered as the same
lower/upper tensor product used by `helper.combRows`. For example,
`rb = [-1 2; -3 5]` gives four rows:

```text
(-1, -3)
(-1,  5)
( 2, -3)
( 2,  5)
```

Three parameters give `2^3 = 8` rows:

```matlab
yalmip('clear')
rb = [-1 2; -3 5; 0 4];
P = dpvar(1, {[0 1], [0 1], [0 1]}, RateBounds=rb);
D = rhodiff(P);
size(D.coeffs([1 1 1]))
```

```text
ans =
     8     8
```

The first `8` is the number of rate vertices. The second `8` is
`(D.Degree+1)^3`; multivariate derivatives are elevated into a common tensor
degree basis before the rate-weighted sum is stored. This design keeps
derivative evidence cell-local and lets `dplmi` later check affine
`rho_dot` dependence by finite rate-box vertices.

## Validation And Errors

- `rhodiff(P)` without stored rate bounds raises `dpvar:MissingRateBounds`.
- Explicit bounds with the wrong shape or invalid lower/upper order raise `dpvar:InvalidRateBounds`.
- Explicit bounds that do not match existing object bounds raise `dpvar:RateBoundsMismatch`.
- Re-differentiating an existing rate-vertex expression raises `dpvar:InvalidDiff`.

## Limitations

- Products with rate dependence on both sides are rejected.
- Products between a rate-dependent expression and another decision expression remain rejected.

## See Also

[`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) · [`dplmi`](/DP-LMI-package/documents/reference/dplmi/)
