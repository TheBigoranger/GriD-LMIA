---
title: dpmat Constructor
description: Construct known finite real matrix data on a parameter grid.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpmat/">dpmat</a>
  <span>/</span>
  <span>constructor</span>
</nav>

## Purpose

Create a known-data `dpmat` object over one or more parameter-grid dimensions.

## Syntax

```matlab
A = dpmat(gridVector, source)
A = dpmat(gridVector, source, Degree=m)
A = dpmat(gridVectors, source)
A = dpmat(gridVectors, source, Degree=m)
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `gridVectors` | Numeric vector shorthand for one parameter, such as `[0 1 2]`, or a cell array of strictly increasing vectors, such as `{[0 1], [10 20]}`. |
| `source` | Function handle, global cell grid of numeric Bernstein coefficients such as `{1, 2, 3}`, or explicit nested `LocalValues` such as `{{[1 0], [0 1]}, {[2 0], [0 2]}}`. |
| `Degree` | Nonnegative integer Bernstein degree, such as `Degree=1` or `Degree=2`. Required when a function handle should be validated as Bernstein coefficient evidence. |

Unsupported options: `IsContinuous`, `ContainsDecision`, `HasRateDependence`, and `RateBounds`.

## Returned Object

`A` is a `dpmat < dpbase` object. All inherited `dpbase` properties are
readable through dot syntax and have private set access:

| Field | How to inspect it | Meaning for `dpmat` |
| :--- | :--- | :--- |
| `GridInfo` | `A.GridInfo.Vectors{1}`, `A.GridInfo.Points`, `A.GridInfo.Bounds` | Validated tensor-grid metadata. |
| `MatrixSize` | `A.MatrixSize` | Matrix size of each numeric payload. |
| `Degree` | `A.Degree` | Local Bernstein degree. |
| `LocalValues` | `A.LocalValues{1}` or `A.coeffs(1)` | Cell-local numeric Bernstein coefficients. |
| `IsContinuous` | `A.IsContinuous` | Always `true` for current `dpmat` construction. |
| `ContainsDecision` | `A.ContainsDecision` | Always `false`; no YALMIP decisions are stored. |
| `HasRateDependence` | `A.HasRateDependence` | Always `false`; rate dependence belongs to `dpvar`/`rhodiff`. |
| `RateBounds` | `A.RateBounds` | Always empty for `dpmat`. |
| `SourceSummary` | `A.SourceSummary` | Source label such as `coefficient-backed`, `function`, or `function-bernstein`. |
| `FunctionHandle` | `A.FunctionHandle` | Exact evaluator for function-backed objects; empty for coefficient-backed data. |

These fields are exposed for inspection rather than mutation. The constructor
and algebra methods keep `GridInfo`, `Degree`, `LocalValues`, and matrix sizes
consistent; direct assignment would break the coefficient-label contract.

## Examples

### Coefficient-backed scalar data

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
A.MatrixSize
A.Degree
A.SourceSummary
A.FunctionHandle
T = bernsteinTable(A);
T(:, ["TermIndex", "LocalIndex", "Basis", "Value"])
```

```text
ans =
     1     1

ans =
     1

ans =
    "coefficient-backed"

ans =
     []

ans =
  2x4 table

    TermIndex    LocalIndex     Basis     Value
    _________    __________    _______    _____

        1          {[0]}       "a"        {[1]}
        2          {[1]}       "(1-a)"    {[3]}
```

### Tensor-grid coefficient ordering

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
A.GridInfo.Vectors{2}
A.coeffs([1 1])
A.lbls()
T = bernsteinTable(A);
T(:, ["TermIndex", "CellSubscript", "LocalIndex", "Value"])
```

```text
ans =
    10    20

ans =
  1x4 cell array
    {[1]}    {[3]}    {[5]}    {[7]}

ans =
     0     0
     0     1
     1     0
     1     1

ans =
  4x4 table

    TermIndex    CellSubscript    LocalIndex    Value
    _________    _____________    __________    _____

        1           {[1 1]}        {[0 0]}      {[1]}
        2           {[1 1]}        {[0 1]}      {[3]}
        3           {[1 1]}        {[1 0]}      {[5]}
        4           {[1 1]}        {[1 1]}      {[7]}
```

### Function-backed exact evaluator

```matlab
F = dpmat({[0 pi]}, @(rho) sin(rho));
F.evaluate(pi/2)
```

```text
ans =
     1
```

Function-backed objects route evaluation through the retained function handle.

### Explicit nested LocalValues

```matlab
localVals = {{[1 0], [0 1]}, {[2 0], [0 2]}};
C = dpmat({[0 1 2]}, localVals, Degree=1);
C.MatrixSize
C.coeffs(2)
```

```text
ans =
     1     2

ans =
  1x2 cell array
    {[2 0]}    {[0 2]}
```

Nested `LocalValues` are useful when each physical cell has its own local
coefficient matrices.

### Function-backed Bernstein evidence

```matlab
G = dpmat({[0 1]}, @(rho) rho.^2, Degree=2);
G.SourceSummary
G.coeffs(1)
```

```text
ans =
    "function-bernstein"

ans =
  1x3 cell array
    {[0]}    {[0]}    {[1]}
```

Adding `Degree=2` tells the constructor to validate and store Bernstein
coefficient evidence while retaining the exact function handle for evaluation.

## Validation And Errors

- Unknown options raise `dpmat:UnknownOption`.
- Internal metadata options raise `dpmat:UnsupportedOption`.
- Function-handle probing or validation may raise `dpmat:InvalidFunctionHandle` or `dpmat:InvalidFunctionOutput`.
- Numeric coefficient payloads must be nonempty finite real matrices with consistent size.

## Limitations

- Function-only objects without `Degree` keep exact evaluation but are not coefficient evidence.
- Mixed physical bounds are rejected by coefficient algebra until a compatible common grid exists.

## See Also

[`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) · [`bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/) · [`dpbase`](/DP-LMI-package/documents/reference/dpbase/)
