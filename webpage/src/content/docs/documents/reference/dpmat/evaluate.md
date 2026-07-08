---
title: dpmat evaluate
description: Evaluate known dpmat data at one parameter point.
---

## Purpose

Evaluate a `dpmat` object at a finite parameter point.

## Syntax

```matlab
val = evaluate(A, pt)
val = A.evaluate(pt)
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `A` | A `dpmat` object. |
| `pt` | Finite real vector with one entry per parameter. The point must lie inside the grid bounds. |

## Output

`val` is a numeric matrix with size `A.MatrixSize`.

## Example

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
val = A.evaluate(0.25)
```

```text
val =
    1.5000
```

The local coordinate is `alpha = 0.75`, so the value is `0.75*1 + 0.25*3`.

## Function-Backed Evaluation

```matlab
F = dpmat({[0 pi]}, @(rho) sin(rho));
F.evaluate(pi/2)
```

```text
ans =
     1
```

Function-backed objects route evaluation through the retained function handle.

## Validation And Errors

- Bad point shape or nonfinite values raise `dpmat:InvalidPoint`.
- Points outside grid bounds raise `dpmat:PointOutOfBounds`.
- Function-handle failures during evaluation raise `dpmat:InvalidFunctionValue`.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/)
