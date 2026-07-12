---
title: dplmi Constructor
description: Assemble direct coefficient-wise DP-LMI constraints.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dplmi/">dplmi</a>
  <span>/</span>
  <span>constructor</span>
</nav>

## Purpose

Build a `dplmi` object from a square `dpvar` residual expression.

## Syntax

```matlab
C = dplmi(expr, relation)
C = dplmi(expr, relation, "UsePolya")
C = dplmi(expr, relation, UsePolya=true, PolyaDegree=d)
C = dplmi(expr, relation, "UsePolya", "PolyaDegree", d)
C = lhs <= rhs
C = lhs >= rhs
```

## Arguments And Options

| Input | Description |
| :--- | :--- |
| `expr` | Square `dpvar` residual expression, such as `P` or `diffP + P*A + A'*P`. |
| `relation` | Either `"<="` or `">="`. |
| `UsePolya` | Logical option. Default `false`. The bare flag `"UsePolya"` enables Pólya assembly with increment one. |
| `PolyaDegree` | Finite nonnegative integer scalar. Default `0`. Supplying it without `UsePolya` enables Pólya and warns `dplmi:ImplicitUsePolya`. |

## Output

`C` is a `dplmi` object with `Constraints`, `Residual`, `Relation`, `UsePolya`, and `PolyaDegree` properties.

## Examples

### Direct constructor form

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
C = dplmi(P, ">=");
class(C)
numel(C.Constraints)
```

```text
ans =
    'dplmi'

ans =
     2
```

The direct constructor is useful when code already has a residual expression
and a relation string.

### Comparison-overload form

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

A scalar grid with one physical cell and degree 1 has two local Bernstein coefficients, so this direct constraint has two stored coefficient entries.

### Pólya option forms

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
one = dplmi(P, "<=", "UsePolya");
two = dplmi(P, "<=", UsePolya=true, PolyaDegree=2);
implicit = dplmi(P, "<=", PolyaDegree=2);
```

`one` uses an increment of one. `two` uses two, while `implicit` also uses two
and emits `dplmi:ImplicitUsePolya`. Pólya assembly rebuilds the stored residual
at the selected degree, constraining every elevated coefficient and active
rate-vertex row. It does not mutate the input expression.

## Validation And Errors

- Nonsquare residual coefficient matrices raise `dplmi:InvalidMatrixSize`.
- Nonsymmetric or non-Hermitian coefficient matrices raise `dplmi:NonSymmetricExpression`.
- Invalid Polya degree values raise `dplmi:InvalidPolyaDegree`.
- `UsePolya=false` with a positive `PolyaDegree` raises `dplmi:ConflictingPolyaOptions`.
- Malformed, duplicate, or unknown options raise `dplmi:InvalidOptions`, `dplmi:DuplicateOption`, or `dplmi:UnknownOption`.

## See Also

[`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/)
