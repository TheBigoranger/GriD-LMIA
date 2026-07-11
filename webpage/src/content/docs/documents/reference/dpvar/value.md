---
title: dpvar value
description: Convert assigned symbolic coefficients to known dpmat data.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpvar/">dpvar</a>
  <span>/</span>
  <span>value</span>
</nav>

## Purpose

Convert a `dpvar` expression whose symbolic coefficients have finite assigned
YALMIP values into known coefficient-backed `dpmat` data.

## Syntax

```matlab
A = value(P)
rows = value(rhodiff(P))
```

## Output

For an ordinary expression, `A` is one `dpmat` that preserves the parameter
grid, matrix size, Bernstein degree, local coefficient order, and continuity
metadata. For a derivative expression with rate rows, `rows` is a `1-by-2^ell`
cell array of `dpmat` objects, in the lower/upper Cartesian vertex order of
`helper.combRows(RateBounds)`; returned `dpmat` objects do not retain rate
metadata.

## Example

```matlab
yalmip('clear')
P = dpvar(1, [0 1], Degree=2);
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
`dpvar:UnassignedValue`.

## Limitations

`value` evaluates stored coefficients, not an arbitrary parameter point. Use
[`dpmat evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) after
conversion when an exact point evaluation is needed.

## See Also

[`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) · [`dpmat`](/DP-LMI-package/documents/reference/dpmat/) · [`bernsteinTable`](/DP-LMI-package/documents/reference/dpvar/bernsteintable/)
