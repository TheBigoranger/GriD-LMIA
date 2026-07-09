---
title: dplmi toYalmip
description: Concatenate stored dplmi entries into YALMIP constraints.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dplmi/">dplmi</a>
  <span>/</span>
  <span>toYalmip</span>
</nav>

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
| `C` | A `dplmi` object, such as `C = P >= 0`. |

## Output

`F` is a YALMIP constraint array suitable for ordinary solver calls such as `optimize(F, objective, sdpsettings(...))`.

## Description

`dplmi` stores constraints in package-owned cell-local form so the package can
assemble one condition per physical cell, Bernstein coefficient, and rate
vertex. `toYalmip` is the boundary where those stored entries become a regular
YALMIP constraint array:

$$
F = [F_1,\ldots,F_{N_cN_bN_v}].
$$

It does not choose a solver, create an objective, apply relaxation margins, or
run `optimize`.

## Examples

### Function-call form

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
isa(F, "lmi") || isa(F, "constraint")
length(F)
```

```text
ans =
  logical
   1

ans =
     2
```

The two YALMIP entries correspond to one physical cell and two degree-one
Bernstein coefficients.

### Dot-call form

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = C.toYalmip();
isa(F, "lmi") || isa(F, "constraint")
length(F)
```

```text
ans =
  logical
   1

ans =
     2
```

The dot-call form is equivalent and is convenient when chaining from a stored
`dplmi` object.

## Limitations

`toYalmip` does not select solvers, add objectives, apply relaxation margins, or run `optimize`.

## See Also

[`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/)
