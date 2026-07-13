---
title: dpvar bernsteinTable
description: Inspect symbolic Bernstein coefficients and rate-vertex rows.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpvar/">dpvar</a>
  <span>/</span>
  <span>bernsteinTable</span>
</nav>

## Purpose

Inspect a `dpvar` object's local Bernstein coefficient rows. This is a diagnostic
view for checking tensor labels, symbolic payloads, and the rate rows produced
by [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/). It does not
change the decision expression or send anything to YALMIP's optimizer.

## Syntax

```matlab
T = bernsteinTable(P)
T = bernsteinTable(P, "oneLine")
T = bernsteinTable(P, cellSubscript)
T = bernsteinTable(P, cellSubscript, "oneLine")
T = P.bernsteinTable(...)
```

## Description

The ordinary form returns a MATLAB table with one row for each local
coefficient. Its metadata includes the physical cell, local label, Bernstein
basis, and a symbolic or numeric value representation. The optional
`"oneLine"` mode returns a compact table of coefficient expressions, useful
when a full symbolic table would be too wide. Supplying a cell subscript limits
the inspection to one physical cell.

For a rate-dependent object, each rate vertex is represented as a separate row
family. Use this page together with `rhodiff` when checking how a rate-bound
box becomes finite vertex rows.

## Arguments And Options

| Input | Meaning |
| :--- | :--- |
| `P` | A `dpvar` object. |
| `cellSubscript` | Optional tensor-cell subscript accepted by `P.coeffs(...)`. Omit it to inspect all cells. |
| `"oneLine"` | Optional display mode that prints one compact expression per local row. The default is the expanded table. |

Unsupported names, malformed cell subscripts, and unsupported display modes are
rejected by the current validation path.

## Returned Table

`T` is a MATLAB `table`. Use `disp(T)` for a stable command-window view, or
select the metadata columns when comparing adjacent cells. The table is a
snapshot of the object state; editing it does not edit `P`.

## Example

```matlab
yalmip('clear')
P = dpvar(1, {[0 1]}, "symmetric");
T = bernsteinTable(P, "oneLine");
disp(T)
```

```text
    CellSubscript       Expression
    _____________    ________________

        {[1]}        "a*internal(1) + (1-a)*internal(2)"
```

The exact symbolic labels depend on the current YALMIP variable allocation;
the stable contract is the row structure and the association with local
Bernstein labels, not a particular internal `sdpvar` name. This literal
runtime diagnostic uses `a=1-alpha`, where
$\alpha=(\rho-\rho_k)/(\rho_{k+1}-\rho_k)$ is the public forward coordinate.
Accordingly, the unchanged transcript represents
$(1-\alpha)\,\texttt{internal(1)}+\alpha\,\texttt{internal(2)}$.

## Validation And Errors

- The object must be a `dpvar` instance.
- A requested cell must exist in the tensor grid.
- Rate-row inspection requires the derivative object's rate metadata to be
  present and internally consistent.
- The table helper is diagnostic; it does not enable unsupported products or
  relaxation modes.

## Limitations

`dpvar` accepts any nonnegative constructor degree, and products may elevate
coefficient degree further. `bernsteinTable` reports the resulting stored rows;
it is an inspection aid, not a serialization format for the internal
coefficient tree.

## See Also

[`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) ·
[`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) ·
[`dpmat bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/)
