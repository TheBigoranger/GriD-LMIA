---
title: dpmat evaluate
description: Evaluate known dpmat data at one parameter point.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpmat/">dpmat</a>
  <span>/</span>
  <span>evaluate</span>
</nav>

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
| `pt` | Finite real scalar for one parameter, such as `0.25`, or a row vector with one entry per parameter, such as `[0.25 12]`. The point must lie inside the grid bounds. |

## Output

`val` is a numeric matrix with size `A.MatrixSize`.

## Description

For coefficient-backed data on one cell, `evaluate` applies local Bernstein
interpolation. For degree-one scalar data on `[rho0,rho1]`,

$$
A(\rho)=(1-\alpha)A_0+\alpha A_1,\qquad
\alpha=\frac{\rho-\rho_0}{\rho_1-\rho_0}.
$$

For matrix-valued data, the same formula is applied entrywise to each stored
coefficient matrix. Function-backed objects keep the exact MATLAB function
handle and call it directly.

## Examples

### Function-call form

```matlab
A = dpmat({[0 1]}, {2, 4}, Degree=1);
val = evaluate(A, 0.25)
```

```text
val =
    2.5000
```

At `rho = 0.25`, the public forward coordinate is `alpha = 0.25`, so the value is
`0.75*2 + 0.25*4`.

### Dot-call form

```matlab
A = dpmat({[0 1]}, {2, 4}, Degree=1);
val = A.evaluate(0.75)
```

```text
val =
    3.5000
```

The dot-call form is equivalent to `evaluate(A, pt)` and is often convenient in
interactive MATLAB sessions.

### Function-backed evaluation

```matlab
F = dpmat({[0 pi]}, @(rho) sin(rho));
val = F.evaluate(pi/2)
```

```text
val =
     1
```

Function-backed objects route evaluation through the retained function handle.

## Validation And Errors

- Bad point shape or nonfinite values raise `dpmat:InvalidPoint`.
- Points outside grid bounds raise `dpmat:PointOutOfBounds`.
- Function-handle failures during evaluation raise `dpmat:InvalidFunctionValue`.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/)
