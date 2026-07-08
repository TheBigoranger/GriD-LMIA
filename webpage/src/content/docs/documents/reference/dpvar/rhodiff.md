---
title: dpvar rhodiff
description: Rate-weighted cell-local derivative of a dpvar expression.
---

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
| `rb` | Finite `ell x 2` rate-bound table. Required unless `P` already carries matching `RateBounds`. |

## Output

`D` is a `dpvar` with `HasRateDependence=true`. Each physical cell stores one coefficient row per active `rho_dot` vertex.

## Example

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

Scalar degree-1 derivatives become degree-0 coefficient rows. Multivariate derivatives are elevated into a common tensor degree basis before the rate-weighted sum is stored.

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
