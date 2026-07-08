---
title: dplmi toYalmip
description: Concatenate stored dplmi entries into YALMIP constraints.
---

## Purpose

Convert stored coefficient-wise `dplmi` entries into a YALMIP constraint array.

## Syntax

```matlab
F = toYalmip(C)
F = C.toYalmip()
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `C` | A `dplmi` object. |

## Output

`F` is a YALMIP constraint array suitable for ordinary solver calls such as `optimize(F, objective, sdpsettings(...))`.

## Example

```matlab
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
```

`F` concatenates the stored cell-local coefficient constraints at the solver-facing boundary.

## Limitations

`toYalmip` does not select solvers, add objectives, apply relaxation margins, or run `optimize`.

## See Also

[`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/)
