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
A = dpmat(gridVectors, source)
A = dpmat(gridVectors, source, Degree=m)
```

## Arguments

| Argument | Description |
| :--- | :--- |
| `gridVectors` | Numeric vector shorthand for one parameter, or a cell array of strictly increasing vectors. |
| `source` | Function handle, global cell grid of numeric Bernstein coefficients, or explicit nested `LocalValues`. |
| `Degree` | Nonnegative integer Bernstein degree. Required when a function handle should be validated as Bernstein coefficient evidence. |

Unsupported options: `IsContinuous`, `ContainsDecision`, `HasRateDependence`, and `RateBounds`.

## Returned Object

`A` is a `dpmat < dpbase` object. Function-backed objects retain a private `FunctionHandle`; all `dpmat` objects have known numeric matrix payloads and no YALMIP decisions.

## Examples

### Coefficient-backed scalar data

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
A.MatrixSize
A.Degree
```

```text
ans =
     1     1

ans =
     1
```

### Tensor-grid coefficient ordering

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

### Function-backed exact evaluator

```matlab
F = dpmat({[0 pi]}, @(rho) sin(rho));
F.evaluate(pi/2)
```

```text
ans =
     1
```

## Validation And Errors

- Unknown options raise `dpmat:UnknownOption`.
- Internal metadata options raise `dpmat:UnsupportedOption`.
- Function-handle probing or validation may raise `dpmat:InvalidFunctionHandle` or `dpmat:InvalidFunctionOutput`.
- Numeric coefficient payloads must be nonempty finite real matrices with consistent size.

## Limitations

- Function-only objects without `Degree` keep exact evaluation but are not coefficient evidence.
- Mixed physical bounds are rejected by coefficient algebra until a compatible common grid exists.

## See Also

[`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) · [`table`](/DP-LMI-package/documents/reference/dpmat/table/) · [`dpbase`](/DP-LMI-package/documents/reference/dpbase/)
