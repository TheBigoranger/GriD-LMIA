---
title: dpvar Comparisons
description: Create dplmi constraints using <= and >=.
---

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
| `P` | Square `dpvar` expression or compatible expression after promotion. |
| `rhs` | Numeric, `dpmat`, affine `sdpvar`, or `dpvar` expression that can form a residual. |

## Output

`C` is a [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) object.

## Example

```matlab
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
```

`F` is a YALMIP constraint array suitable for ordinary `optimize` calls.

## Validation And Errors

Comparison residuals must produce square symmetric or Hermitian coefficient matrices before `dplmi` assembly succeeds.

## See Also

[`dplmi`](/DP-LMI-package/documents/reference/dplmi/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/)
