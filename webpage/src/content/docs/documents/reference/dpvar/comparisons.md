---
title: dpvar Comparisons
description: Create dplmi constraints using <= and >=.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpvar/">dpvar</a>
  <span>/</span>
  <span>comparisons</span>
</nav>

## Purpose

Convert a square `dpvar` residual into direct coefficient-wise `dplmi` constraints.

## Syntax

```matlab
C = P <= rhs
C = P >= rhs
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `P` | Square `dpvar` expression or compatible expression after promotion, such as `P` from `dpvar(2,{[0 1]},"symmetric")`. |
| `rhs` | Numeric, `dpmat`, affine `sdpvar`, or `dpvar` expression that can form a residual; the most common value is `0`. |

## Output

`C` is a [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) object.

## Description

The comparison overloads do not solve an optimization problem. They assemble a
coefficient-wise residual and wrap it in `dplmi` so it can later be converted to
YALMIP constraints.

For an ordinary continuous expression with `Nc` physical cells and `Nb`
Bernstein coefficients per cell, the direct constraint count is

$$
N_c N_b.
$$

If the expression includes rate-vertex rows from `rhodiff`, the count is
multiplied by the number of rate vertices.

## Per-symbol reference anchors

### <span id="dpvar-comparison-le"></span>`le` and `<=`

Forms the residual for a nonpositive inequality and returns a `dplmi` object.
The comparison is coefficient-wise after expression promotion and symmetry
validation.

### <span id="dpvar-comparison-ge"></span>`ge` and `>=`

Forms the residual for a nonnegative inequality and returns a `dplmi` object.
The comparison is coefficient-wise after expression promotion and symmetry
validation.

## Examples

### Positive-semidefinite comparison

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
class(C)
numel(C.Constraints)
```

```text
ans =
    'dplmi'

ans =
     2
```

One physical cell with degree one has two local Bernstein coefficients, so the
comparison stores two direct coefficient constraints.

### Negative-semidefinite residual

```matlab
yalmip('clear')
P = dpvar(2, {[0 0.5 1]}, "symmetric");
C = P <= 0;
numel(C.Constraints)
```

```text
ans =
     4
```

Two physical cells times two local degree-one coefficients gives four stored
constraints.

## Validation And Errors

- Comparison residuals must produce square symmetric or Hermitian coefficient matrices before `dplmi` assembly succeeds.
- Nonsquare residuals raise `dplmi:InvalidMatrixSize`.
- Nonsymmetric residual coefficient matrices raise `dplmi:NonSymmetricExpression`.

## See Also

[`dplmi`](/DP-LMI-package/documents/reference/dplmi/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/)
