---
title: pdmat bernTable
description: Return a command-line Bernstein coefficient table for pdmat.
---

<nav class="manual-trail">
  <a href="/GriD-LMIA/documents/">Documents</a>
  <span>/</span>
  <a href="/GriD-LMIA/documents/reference/pdmat/">pdmat</a>
  <span>/</span>
  <span>bernTable</span>
</nav>

Cell indices, local labels, and degree symbols follow the
[global notation](/GriD-LMIA/documents/math/notation/#bernstein-labels-and-degrees).

## Purpose

Inspect coefficient-backed `pdmat` local Bernstein data as a MATLAB table.

## Syntax

```matlab
T = bernTable(A)
T = bernTable(A, cellSubs)
T = bernTable(A, "oneLine")
T = bernTable(A, cellSubs, "oneLine")
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `A` | A coefficient-backed `pdmat` object. |
| `cellSubs` | Physical-cell subscript to inspect, such as `1` for a one-parameter grid or `[1 1]` for a tensor grid. |
| `"oneLine"` | Compact mode that returns one row per selected physical cell and active rate vertex with a readable Bernstein expression. |

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

For explicit rate rows, the full table additionally contains
`RateVertexIndex` and `RateVertex`. Their order is
`helper.combRows(num2cell(A.RateBounds,2).')`.

Public formulas use the forward coordinate
$\alpha=(\rho-\rho_1^{(c)})/(\rho_1^{(c+1)}-\rho_1^{(c)})$ and the normalized factors

$$
\mathbf m=(m_1).
$$

$$
B_{i_1}^{m_1}(\alpha)=\binom{m_1}{i_1}(1-\alpha)^{m_1-i_1}\alpha^{i_1}.
$$

The diagnostic uses the same public `alpha` name. Its rows are
`(1-alpha)^2`, `2(1-alpha)alpha`, and `alpha^2` in forward-coordinate order.
For multiple parameters, the basis text is the tensor product of the
corresponding one-parameter factors.

## Examples

### Compact expression for one cell

Use `"oneLine"` when the goal is to see the Bernstein expression rather than
the full metadata table.

```matlab
A = pdmat({[0 0.2 1]}, {[0 1], [1 1], [1 2]}, Degree=1);
T = bernTable(A, "oneLine");
disp(T)
```

```text
    CellSubscript              Expression
    _____________    _______________________________

        {[1]}        "(1-alpha)*[0 1] + alpha*[1 1]"
        {[2]}        "(1-alpha)*[1 1] + alpha*[1 2]"
```

The compact expression is useful for quick coefficient checks in the MATLAB
Command Window and reads directly in the public forward coordinate.

### Full degree-two metadata

```matlab
A = pdmat({[0 1]}, {1, 2, 3}, Degree=2);
T = bernTable(A);
disp(T)
```

```text
    TermIndex    CellSubscript    CoeffSubscript    LocalIndex          Basis          IsPhysicalNode    Value
    _________    _____________    ______________    __________    _________________    ______________    _____

        1            {[1]}            {[1]}           {[0]}       "(1-alpha)^2"            true          {[1]}
        2            {[1]}            {[2]}           {[1]}       "2(1-alpha)alpha"        false         {[2]}
        3            {[1]}            {[3]}           {[2]}       "alpha^2"                true          {[3]}
```

The middle row is not a physical grid node for degree two. It is the middle
Bernstein coefficient for the single physical cell.

### Tensor-grid label order

```matlab
A = pdmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=[1 1]);
T = bernTable(A, [1 1]);
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
coefficient algebra and `pdlmi` assembly.

### Explicit rate rows

```matlab
A = pdmat([0 1], {{1, 3; 10, 14}}, ...
    Degree=1, RateBounds=[-1 2]);
T = bernTable(A, "oneLine");
disp("vertexIndices =")
disp(T.RateVertexIndex)
disp("rateVertices =")
disp(vertcat(T.RateVertex{:}))
disp("expressionCount =")
disp(height(T))
```

```text
vertexIndices =
     1
     2

rateVertices =
    -1
     2

expressionCount =
     2
```

## Validation And Errors

- Function-only objects without Bernstein coefficient evidence raise `pdmat:FunctionOnlyBernsteinTable` when calling `bernTable`. Backend degree elevation instead raises `pdbase:MissingCoefficientEvidence`.
- Invalid cell subscripts raise `pdbase:InvalidCellSubs`.
- Unknown display modes, such as `"wide"`, raise `pdmat:InvalidBernsteinTableInput`.

## See Also

[`pdmat constructor`](/GriD-LMIA/documents/reference/pdmat/constructor/) ·
[`rhodiff`](/GriD-LMIA/documents/reference/pdmat/rhodiff/) ·
[`plot`](/GriD-LMIA/documents/reference/pdmat/plot/)
