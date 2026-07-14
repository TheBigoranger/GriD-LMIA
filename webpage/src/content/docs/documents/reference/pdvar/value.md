---
title: pdvar value
description: Convert assigned symbolic coefficients to known pdmat data.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/pdvar/">pdvar</a>
  <span>/</span>
  <span>value</span>
</nav>

## Purpose

Convert a `pdvar` expression whose symbolic coefficients have finite assigned
YALMIP values into known coefficient-backed `pdmat` data.

## Syntax

```matlab
A = value(P)
rows = value(rhodiff(P))
```

## Output

For an ordinary expression, `A` is one `pdmat` that preserves the parameter
grid, matrix size, Bernstein degree, local coefficient order, and continuity
metadata. For a derivative expression with rate rows, `rows` is a `1-by-2^ell`
cell array of `pdmat` objects, in the lower/upper Cartesian vertex order of
`helper.combRows(RateBounds)`; returned `pdmat` objects do not retain rate
metadata.

## Example

```matlab
yalmip('clear')
P = pdvar(1, [0 1], Degree=2);
c = P.coeffs(1);
assign([c{:}], [1 2 3]);
A = value(P);
A.coeffs(1)
```

```text
ans =
  1x3 cell array
    {[1]}    {[2]}    {[3]}
```

## Validation And Errors

Every symbolic coefficient must have an assigned finite real numeric value.
Unassigned, nonnumeric, nonreal, nonfinite, or unavailable values raise
`pdvar:UnassignedValue`.

## Limitations

`value` evaluates stored coefficients, not an arbitrary parameter point. Use
[`pdmat evaluate`](/DP-LMI-package/documents/reference/pdmat/evaluate/) after
conversion when an exact point evaluation is needed.

## See Also

[`rhodiff`](/DP-LMI-package/documents/reference/pdvar/rhodiff/) · [`pdmat`](/DP-LMI-package/documents/reference/pdmat/) · [`bernsteinTable`](/DP-LMI-package/documents/reference/pdvar/bernsteintable/)
