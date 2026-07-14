---
title: pdvar Comparisons
description: Create pdlmi constraints using <= and >=.
---

<nav class="manual-trail">
  <a href="/PD-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/PD-LMI-package/documents/reference/pdvar/">pdvar</a>
  <span>/</span>
  <span>comparisons</span>
</nav>

## Purpose

Convert a square `pdvar` residual into direct coefficient-wise `pdlmi` constraints.

## Syntax

```matlab
C = P <= rhs
C = P >= rhs
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `P` | Square `pdvar` expression or compatible expression after promotion, such as `P` from `pdvar(2,{[0 1]},"symmetric")`. |
| `rhs` | Numeric, `pdmat`, affine `sdpvar`, or `pdvar` expression that can form a residual; the most common value is `0`. |

## Output

`C` is a [`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/) object.

## Description

The comparison overloads do not solve an optimization problem. They assemble a
coefficient-wise residual and wrap it in `pdlmi` so it can later be converted to
YALMIP constraints.

For an ordinary continuous expression with `Nc` physical cells and `Nb`
Bernstein coefficients per cell, the direct constraint count is

$$
N_c N_b.
$$

If the expression includes rate-vertex rows from `rhodiff`, the count is
multiplied by the number of rate vertices.

## Per-symbol reference anchors

### <span id="pdvar-comparison-le"></span>`le` and `<=`

Forms the residual for a nonpositive inequality and returns a `pdlmi` object.
The comparison is coefficient-wise after expression promotion and symmetry
validation.

### <span id="pdvar-comparison-ge"></span>`ge` and `>=`

Forms the residual for a nonnegative inequality and returns a `pdlmi` object.
The comparison is coefficient-wise after expression promotion and symmetry
validation.

## Examples

### Positive-semidefinite comparison

```matlab
yalmip('clear')
P = pdvar(2, {[0 1]}, "symmetric");
C = P >= 0;
class(C)
numel(C.Constraints)
```

```text
ans =
    'pdlmi'

ans =
     2
```

One physical cell with degree one has two local Bernstein coefficients, so the
comparison stores two direct coefficient constraints.

### Negative-semidefinite residual

```matlab
yalmip('clear')
P = pdvar(2, {[0 0.5 1]}, "symmetric");
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

- Comparison residuals must produce square symmetric or Hermitian coefficient matrices before `pdlmi` assembly succeeds.
- Nonsquare residuals raise `pdlmi:InvalidMatrixSize`.
- Nonsymmetric residual coefficient matrices raise `pdlmi:NonSymmetricExpression`.

## See Also

[`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/) · [`toYalmip`](/PD-LMI-package/documents/reference/pdlmi/toyalmip/)
