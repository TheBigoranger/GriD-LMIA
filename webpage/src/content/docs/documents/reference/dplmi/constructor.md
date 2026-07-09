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
C = dplmi(expr, relation, relaxLemma=false, UsePolya=false, PolyaDegree=0)
C = lhs <= rhs
C = lhs >= rhs
```

## Arguments And Options

| Input | Description |
| :--- | :--- |
| `expr` | Square `dpvar` residual expression, such as `P` or `diffP + P*A + A'*P`. |
| `relation` | Either `"<="` or `">="`. |
| `relaxLemma` | Logical option. Default `false`; `relaxLemma=true` is reserved and currently rejected. |
| `UsePolya` | Logical option. Default `false`; `UsePolya=true` is reserved and currently rejected. |
| `PolyaDegree` | Nonnegative integer scalar. Default `0`; positive values such as `PolyaDegree=1` are reserved and rejected. |

## Output

`C` is a `dplmi` object with `Constraints`, `RelaxLemma`, `UsePolya`, and `PolyaDegree` properties.

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

### Reserved option rejection

Relaxation-lemma and Polya options are visible as reserved defaults, but
nondefault values are rejected in the current implementation.

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
dplmi(P, "<=", relaxLemma=true)
```

The call raises `dplmi:UnsupportedRelaxLemma`. Similarly, `UsePolya=true` or
`PolyaDegree=1` raises the reserved Polya-option errors listed in the
validation section.

## Validation And Errors

- Nonsquare residual coefficient matrices raise `dplmi:InvalidMatrixSize`.
- Nonsymmetric or non-Hermitian coefficient matrices raise `dplmi:NonSymmetricExpression`.
- Nondefault relaxation raises `dplmi:UnsupportedRelaxLemma`.
- `UsePolya=true` or `PolyaDegree>0` raises `dplmi:UnsupportedPolya`.
- Invalid Polya degree values raise `dplmi:InvalidPolyaDegree`.

## See Also

[`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/)
