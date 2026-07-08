---
title: dpmat
description: Known finite real matrix data on a parameter grid.
---

## Purpose

`dpmat` represents known finite real matrix data on a parameter grid. It supports exact function-backed data, coefficient-backed Bernstein data, matrix operations, structural transforms, display/table diagnostics, and one- or two-dimensional plotting.

## Syntax

```matlab
A = dpmat(gridVectors, source)
A = dpmat(gridVectors, source, Degree=m)
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `gridVectors` | Scalar vector shorthand or cell array of strictly increasing parameter-grid vectors. |
| `source` | Function handle, global cell grid of numeric Bernstein coefficients, or explicit nested `LocalValues` in the `dpbase` contract. |
| `Degree` | Nonnegative integer Bernstein degree. Required when a function handle should be validated as Bernstein evidence. |

Unsupported constructor options include `IsContinuous`, `ContainsDecision`, `HasRateDependence`, and `RateBounds`; these are fixed internally for known data.

## Description

Function-backed `dpmat` objects without `Degree` retain the exact `FunctionHandle` and probe only enough to infer matrix size. Their inherited local values are placeholders, not coefficient evidence, so they do not enter coefficient algebra.

Coefficient-backed objects support common-refinement algebra when physical bounds are compatible. Matrix payload operations are applied coefficient-wise.

## Returned Object

The returned object extends `dpbase` and has a private `FunctionHandle` property when constructed from a function.

## Examples

### Scalar coefficient-backed data

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
val = A.evaluate(0.25)
```

```text
val =
    1.5000
```

The local coordinate is `alpha = 0.75`, so the value is `0.75*1 + 0.25*3`.

### Tensor-grid data

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
A.lbls()
```

```text
ans =
     0     0
     0     1
     1     0
     1     1
```

### Function-backed data

```matlab
F = dpmat({[0 pi]}, @(rho) sin(rho));
F.evaluate(pi/2)
```

```text
ans =
     1
```

## Supported Operations

Coefficient-backed `dpmat` supports `+`, `-`, unary `-`, matrix multiplication, transpose/ctranspose, horizontal and vertical concatenation, `cat` along dimensions 1 and 2, indexing, numeric or `dpmat` block assignment, `vec`, `diag`, `reshape`, `tril`, `triu`, `blkdiag`, `squeeze`, unary plus, and `isequal`.

### `evaluate`

```matlab
val = evaluate(A, pt)
val = A.evaluate(pt)
```

`pt` must be a finite real vector with one entry per parameter and must lie inside the grid bounds.

### Display, table, and plot

`disp`, `display`, and `table` provide command-window diagnostics. `plot` samples through `evaluate` for one- and two-parameter views; unselected higher-dimensional parameters are fixed at lower bounds.

## Validation And Errors

- Invalid option names raise `dpmat:UnknownOption`.
- Unsupported internal metadata options raise `dpmat:UnsupportedOption`.
- Out-of-grid evaluation points raise `dpmat:PointOutOfBounds`.
- Function-handle construction can raise `dpmat:InvalidFunctionHandle` or `dpmat:InvalidFunctionOutput` when probing or validating the handle.
- Later failed or incorrectly sized evaluations raise `dpmat:InvalidFunctionValue`.

## Limitations

- Function-only objects without explicit Bernstein evidence are rejected from coefficient algebra and coefficient-structural methods.
- `dpmat` stores known numeric data only; YALMIP decisions belong to `dpvar`.
- Plotting is a diagnostic sampled view, not a solver-facing operation.

## See Also

[`dpbase`](/DP-LMI-package/documents/reference/dpbase/) · [`dpvar`](/DP-LMI-package/documents/reference/dpvar/) · [`Bernstein Polynomial`](/DP-LMI-package/documents/math/bernstein-polynomial/)
