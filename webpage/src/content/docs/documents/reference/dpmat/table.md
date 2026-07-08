---
title: dpmat table
description: Return a command-line Bernstein coefficient table for dpmat.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpmat/">dpmat</a>
  <span>/</span>
  <span>table</span>
</nav>

## Purpose

Inspect coefficient-backed `dpmat` local Bernstein data as a MATLAB table.

## Syntax

```matlab
T = table(A)
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `A` | A coefficient-backed `dpmat` object. |

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

## Example

```matlab
A = dpmat({[0 1]}, {1, 2, 3}, Degree=2);
T = table(A);
T(:, ["TermIndex", "LocalIndex", "Basis", "IsPhysicalNode"])
```

```text
ans =
  3x4 table

    TermIndex    LocalIndex       Basis       IsPhysicalNode
    _________    __________    ___________    ______________

        1          {[0]}       "a^2"              true
        2          {[1]}       "2a(1-a)"         false
        3          {[2]}       "(1-a)^2"          true
```

## Validation And Errors

Function-only objects without Bernstein coefficient evidence raise `dpmat:FunctionOnlyTable`.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/)
