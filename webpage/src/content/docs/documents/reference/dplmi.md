---
title: dplmi
description: Cell-local YALMIP constraints for DP-LMI expressions.
---

## Purpose

`dplmi` stores cell-local YALMIP constraints generated from `dpvar` residual expressions. The current implementation assembles direct coefficient-wise constraints.

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
| `PolyaDegree` | Nonnegative integer scalar. Default `0`; values greater than zero are reserved and currently rejected. |

## Description

For each physical cell, local Bernstein coefficient, and active rate-vertex row, `dplmi` creates one YALMIP constraint. This implements the direct coefficient-wise sufficient condition.

## Returned Object

| Property | Meaning |
| :--- | :--- |
| `Constraints` | Cell array of YALMIP constraint entries. |
| `RelaxLemma` | Stored option value. Currently must be `false`. |
| `UsePolya` | Stored option value. Currently must be `false`. |
| `PolyaDegree` | Stored option value. Currently must be `0`. |

## Example

```matlab
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
```

`F` is a YALMIP constraint array ready to concatenate with additional constraints before calling `optimize`.

## `toYalmip`

```matlab
F = toYalmip(C)
F = C.toYalmip()
```

`toYalmip` concatenates stored coefficient constraints at the solver-facing boundary. This keeps `dplmi.Constraints` inspectable as one entry per coefficient before solver handoff.

## Validation And Errors

- Nonsquare residual coefficient matrices raise `dplmi:InvalidMatrixSize`.
- Nonsymmetric or non-Hermitian coefficient matrices raise `dplmi:NonSymmetricExpression`.
- Nondefault relaxation raises `dplmi:UnsupportedRelaxLemma`.
- `UsePolya=true` or `PolyaDegree>0` raises `dplmi:UnsupportedPolya`.
- Invalid Polya degree values raise `dplmi:InvalidPolyaDegree`.

## Limitations

- Relaxation-lemma workflows are reserved and unsupported in this implementation slice.
- Polya assembly is reserved and unsupported.
- Strictness margins, residual evidence, diagnostics, and package-owned solver wrappers are future layers.
- `dplmi` hands constraints to YALMIP; ordinary solver calls use `sdpsettings` and `optimize`.

## See Also

[`dpvar`](/DP-LMI-package/documents/reference/dpvar/) · [`toYalmip`](#toyalmip) · [`Bernstein Polynomial`](/DP-LMI-package/documents/math/bernstein-polynomial/)
