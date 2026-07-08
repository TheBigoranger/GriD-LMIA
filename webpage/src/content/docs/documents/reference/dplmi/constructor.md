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
C = dplmi(expr, "<=")
C = dplmi(expr, ">=", relaxLemma=false, UsePolya=false, PolyaDegree=0)
C = expr <= rhs
C = expr >= rhs
```

## Arguments And Options

| Input | Description |
| :--- | :--- |
| `expr` | Square `dpvar` residual expression. |
| `relation` | Either `"<="` or `">="`. |
| `relaxLemma` | Logical option. Default `false`; `true` is reserved and currently rejected. |
| `UsePolya` | Logical option. Default `false`; `true` is reserved and currently rejected. |
| `PolyaDegree` | Nonnegative integer scalar. Default `0`; positive values are reserved and rejected. |

## Output

`C` is a `dplmi` object with `Constraints`, `RelaxLemma`, `UsePolya`, and `PolyaDegree` properties.

## Example

```matlab
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
numel(C.Constraints)
```

```text
ans =
     2
```

A scalar grid with one physical cell and degree 1 has two local Bernstein coefficients, so this direct constraint has two stored coefficient entries.

## Validation And Errors

- Nonsquare residual coefficient matrices raise `dplmi:InvalidMatrixSize`.
- Nonsymmetric or non-Hermitian coefficient matrices raise `dplmi:NonSymmetricExpression`.
- Nondefault relaxation raises `dplmi:UnsupportedRelaxLemma`.
- `UsePolya=true` or `PolyaDegree>0` raises `dplmi:UnsupportedPolya`.
- Invalid Polya degree values raise `dplmi:InvalidPolyaDegree`.

## See Also

[`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/)
