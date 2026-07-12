---
title: dplmi applyPolya
description: Rebuild a DP-LMI residual with a Pólya degree increment.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dplmi/">dplmi</a>
  <span>/</span>
  <span>applyPolya</span>
</nav>

## Purpose

Create a new `dplmi` using the original stored residual and a selected Pólya
degree increment.

## Syntax

```matlab
Cpolya = C.applyPolya()
Cpolya = C.applyPolya(degreeIncrement)
```

## Description

The no-argument form selects increment one. A finite nonnegative integer
increment elevates the residual in every parameter direction before `dplmi`
constrains every elevated coefficient and every active rate-vertex row. The
method is value-like: it returns a new object and leaves `C` unchanged.

Each call rebuilds from `C.Residual`, rather than compounding a previous
elevation. Thus `C.applyPolya(2)` and `C.applyPolya().applyPolya(2)` both use
an increment of two from the original residual.

## Example

```matlab
yalmip('clear')
P = dpvar(1, [0 1], Degree=1);
direct = P >= 0;
one = direct.applyPolya();
two = one.applyPolya(2);
[direct.PolyaDegree one.PolyaDegree two.PolyaDegree]
```

```text
ans =
     0     1     2
```

## Validation And Errors

The increment must be a finite nonnegative integer scalar. Invalid values raise
`dplmi:InvalidPolyaDegree`.

## Limitations

The residual must still meet the ordinary `dplmi` square and
symmetric/Hermitian requirements.

## See Also

[`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) · [`dpbase storage and inspection`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/)
