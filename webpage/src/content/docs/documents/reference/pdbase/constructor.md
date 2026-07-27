---
title: pdbase Constructor
description: Validated backend construction for shared grid and cell-local Bernstein storage.
---

<nav class="manual-trail"><a href="/PD-LMI-package/documents/">Documents</a><span>/</span><a href="/PD-LMI-package/documents/reference/pdbase/">pdbase</a><span>/</span><span>constructor</span></nav>

## Purpose

`pdbase` owns the common grid, payload-shape, degree, local-value, continuity,
decision, and rate metadata inherited by `pdmat` and `pdvar`. Direct
construction is mainly useful for backend tests and maintainers; modeling code
normally starts with a [`pdmat`](/PD-LMI-package/documents/reference/pdmat/constructor/)
or [`pdvar`](/PD-LMI-package/documents/reference/pdvar/constructor/).

## Syntax

```matlab
obj = pdbase(gridVectors, matrixSize, degree)
obj = pdbase(gridVectors, matrixSize, degree, localValues)
obj = pdbase(gridVectors, matrixSize, degree, localValues, Name=Value)
```

## Arguments and options

| Input | Contract |
| :--- | :--- |
| `gridVectors` | Nonempty cell array of finite, real, strictly increasing vectors, each with at least two nodes. |
| `matrixSize` | Positive integer row vector `[rows columns]`. |
| `degree` | Finite nonnegative integer scalar, used on every parameter axis. |
| `localValues` | Optional nested physical-cell tree. An ordinary leaf is a `1 × (degree+1)^npar` coefficient cell; a rate-dependent leaf is a rate-row-by-coefficient cell array. |
| `IsContinuous` | Logical scalar metadata; default `false`. |
| `ContainsDecision` | Logical scalar metadata; default `false`. |
| `HasRateDependence` | Logical scalar metadata; default `false`. |
| `RateBounds` | Empty or finite `npar × 2` lower/upper bounds with lower not exceeding upper. |
| `SourceSummary` | Source label; default `"coefficient-backed"`. |

When `localValues` is omitted or empty, each physical cell receives a
coefficient-backed zero payload with the requested matrix size. Rate-dependent
payloads require nonempty `RateBounds`.

## Returned object

The returned value has private-set `GridInfo`, `MatrixSize`, `Degree`,
`LocalValues`, `IsContinuous`, `ContainsDecision`, `HasRateDependence`,
`RateBounds`, and `SourceSummary` properties. It is a value object: later
operations return new values without mutating the source.

## Example

```matlab
obj = pdbase({[0 1 2]}, [2 2], 1)
obj.GridInfo.NumNodes
obj.MatrixSize
obj.ncell()
obj.ncoeff()
```

```text
obj =
  pdbase with properties:
    GridInfo: [1x1 struct]
    MatrixSize: [2 2]
    Degree: 1
    ...

ans =
     3

ans =
     2     2

ans =
     2

ans =
     2
```

## Validation and limitations

Grid failures use `pdbase:InvalidGrid` or `pdbase:InvalidGridVector`.
Payload shape, degree, local-tree, coefficient-count, coefficient-payload, and
rate failures use the corresponding `pdbase:Invalid...` identifier. Direct
`pdbase` values are backend containers; they do not implement `pdmat` algebra,
`pdvar` decision construction, plotting, comparisons, or LMI assembly.

## See Also

[`storage and inspection`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/) ·
[`evaluation and elevation`](/PD-LMI-package/documents/reference/pdbase/evaluation-and-elevation/) ·
[`pdmat constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/) ·
[`pdvar constructor`](/PD-LMI-package/documents/reference/pdvar/constructor/)
