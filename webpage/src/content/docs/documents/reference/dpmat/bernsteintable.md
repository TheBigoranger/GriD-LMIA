---
title: dpmat bernsteinTable
description: Return a command-line Bernstein coefficient table for dpmat.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpmat/">dpmat</a>
  <span>/</span>
  <span>bernsteinTable</span>
</nav>

## Purpose

Inspect coefficient-backed `dpmat` local Bernstein data as a MATLAB table.

## Syntax

```matlab
T = bernsteinTable(A)
T = bernsteinTable(A, cellSubs)
T = bernsteinTable(A, "oneLine")
T = bernsteinTable(A, cellSubs, "oneLine")
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `A` | A coefficient-backed `dpmat` object. |
| `cellSubs` | Physical-cell subscript to inspect, such as `1` for a one-parameter grid or `[1 1]` for a tensor grid. |
| `"oneLine"` | Compact mode that returns one row per selected physical cell with a readable Bernstein expression. |

## Output

`T` is a MATLAB table with variables:

| Variable | Meaning |
| :--- | :--- |
| `TermIndex` | Row number in the expanded coefficient table. |
| `CellSubscript` | Physical cell subscript. |
| `CoeffSubscript` | Expanded coefficient-grid subscript. |
| `LocalIndex` | Local Bernstein label. |
| `Basis` | Local basis factor text. |
| `IsPhysicalNode` | Whether the coefficient lies on a physical grid node. |
| `Value` | Stored numeric matrix coefficient. |

For one parameter and degree `m`, the `Basis` column displays terms of the form

$$
\binom{m}{j}a^{m-j}(1-a)^j.
$$

For multiple parameters, the basis text is the tensor product of the
corresponding one-parameter factors.

## Examples

### Compact expression for one cell

Use `"oneLine"` when the goal is to see the Bernstein expression rather than
the full metadata table.

```matlab
A = dpmat({[0 1]}, {[0 1], [1 2]}, Degree=1);
T = bernsteinTable(A, 1, "oneLine");
disp(T)
```

```text
    CellSubscript          Expression
    _____________    _______________________

        {[1]}        "a*[0 1] + (1-a)*[1 2]"
```

The compact expression is useful for quick coefficient checks in the MATLAB
Command Window.

### Full degree-two metadata

```matlab
A = dpmat({[0 1]}, {1, 2, 3}, Degree=2);
T = bernsteinTable(A);
disp(T)
```

```text
    TermIndex    CellSubscript    CoeffSubscript    LocalIndex      Basis      IsPhysicalNode    Value
    _________    _____________    ______________    __________    _________    ______________    _____

        1            {[1]}            {[1]}           {[0]}       "a^2"            true          {[1]}
        2            {[1]}            {[2]}           {[1]}       "2a(1-a)"        false         {[2]}
        3            {[1]}            {[3]}           {[2]}       "(1-a)^2"        true          {[3]}
```

The middle row is not a physical grid node for degree two; it is the middle
Bernstein coefficient for the single physical cell.

### Tensor-grid label order

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
T = bernsteinTable(A, [1 1]);
T(:, ["TermIndex", "LocalIndex", "Value"])
```

```text
ans =
  4x3 table

    TermIndex    LocalIndex    Value
    _________    __________    _____

        1         {[0 0]}      {[1]}
        2         {[0 1]}      {[3]}
        3         {[1 0]}      {[5]}
        4         {[1 1]}      {[7]}
```

The tensor-grid order matches `A.lbls()` and is the same order used by
coefficient algebra and `dplmi` assembly.

## Validation And Errors

- Function-only objects without Bernstein coefficient evidence raise `dpmat:FunctionOnlyBernsteinTable` when calling `bernsteinTable`; backend degree elevation instead raises `dpbase:MissingCoefficientEvidence`.
- Invalid cell subscripts raise `dpbase:InvalidCellSubs`.
- Unknown display modes, such as `"wide"`, raise `dpmat:InvalidBernsteinTableInput`.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/)
