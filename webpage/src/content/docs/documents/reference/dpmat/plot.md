---
title: dpmat plot
description: Plot dpmat matrix entries over one or two grid dimensions.
---

## Purpose

Sample a `dpmat` object through `evaluate` and plot each matrix entry over one or two selected parameter dimensions.

## Syntax

```matlab
h = plot(A)
h = plot(A, dims, Name, Value)
h = plot(A, SamplesPerCell=n)
```

## Arguments And Options

| Input | Description |
| :--- | :--- |
| `A` | A `dpmat` object. |
| `dims` | One or two positive parameter indices. Defaults to `1` for scalar objects and `[1 2]` for multi-parameter objects. |
| `SamplesPerCell` | Positive integer scalar. Default is `15`. |
| `Name, Value` | Additional plotting arguments passed to MATLAB `plot` or `surf`. |

## Output

`h` is a graphics object array, one entry per matrix payload element.

## Examples

### One-dimensional function-backed data

```matlab
A = dpmat({[0 1]}, @(rho) [rho, rho^2]);
h = plot(A, SamplesPerCell=4, LineWidth=2);
numel(h)
h(1).YData
```

```text
ans =
     2

ans =
         0    0.2500    0.5000    0.7500    1.0000
```

### Two-dimensional surface

```matlab
A = dpmat({[0 1], [10 20]}, @(rho, eta) [rho + eta, rho - eta]);
h = plot(A, [1 2], SamplesPerCell=2, EdgeColor="none");
size(h(1).XData)
h(1).FaceAlpha
```

```text
ans =
     3     3

ans =
    0.5000
```

## Validation And Errors

- Invalid `dims` raises `dpmat:InvalidPlotDimensions`.
- Invalid or missing `SamplesPerCell` raises `dpmat:InvalidPlotOptions`.

## Limitations

- Plotting is diagnostic and samples through `evaluate`.
- For higher-dimensional objects, unselected dimensions are fixed at their lower grid bounds.

## See Also

[`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) · [`table`](/DP-LMI-package/documents/reference/dpmat/table/)
