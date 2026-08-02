---
title: pdbase Constructor
description: Validated backend construction for shared grid and cell-local Bernstein storage.
---

<nav class="manual-trail"><a href="/GriD-LMIA/documents/">Documents</a><span>/</span><a href="/GriD-LMIA/documents/reference/pdbase/">pdbase</a><span>/</span><span>constructor</span></nav>

## Purpose

`pdbase` owns the common grid, payload-shape, degree, local-value, continuity,
decision, and rate metadata inherited by `pdmat` and `pdvar`. Direct
construction is mainly useful for backend tests and maintainers; modeling code
normally starts with a [`pdmat`](/GriD-LMIA/documents/reference/pdmat/constructor/)
or [`pdvar`](/GriD-LMIA/documents/reference/pdvar/constructor/).

## Syntax

```matlab
obj = pdbase(gridVectors, matrixSize, degree)
obj = pdbase(gridVectors, matrixSize, degree, localValues)
obj = pdbase(gridVectors, matrixSize, degree, localValues, Name=Value)
obj = pdbase(..., ValidationMode=mode)
```

## Arguments and options

| Input | Contract |
| :--- | :--- |
| `gridVectors` | Nonempty cell array of finite, real, strictly increasing vectors, each with at least two nodes. |
| `matrixSize` | Positive integer row vector `[rows columns]`. |
| `degree` | One finite nonnegative integer scalar shorthand or an `npar`-element direction-wise vector. A scalar expands uniformly, and the result is stored as a `1 × npar` row. |
| `localValues` | Optional nested physical-cell tree. An ordinary leaf is a `1 × prod(degree+1)` coefficient cell; a rate-dependent leaf is a rate-row-by-coefficient cell array. |
| `IsContinuous` | Logical scalar metadata; default `false`. |
| `ContainsDecision` | Logical scalar metadata; default `false`. |
| `HasRateDependence` | Logical scalar metadata; default `false`. |
| `RateBounds` | Empty or finite `npar × 2` lower/upper bounds with lower not exceeding upper. |
| `SourceSummary` | Source label; default `"coefficient-backed"`. |
| `ValidationMode` | Case-insensitive scalar text `"fast"` or `"strict"`; default `"fast"`, transient, and not stored. |

When `localValues` is omitted or empty, each physical cell receives a
coefficient-backed zero payload with the requested matrix size. Rate-dependent
payloads require nonempty `RateBounds`.

## Returned object

The returned value has private-set `GridInfo`, `MatrixSize`, direction-wise
row-vector `Degree`,
`LocalValues`, `IsContinuous`, `ContainsDecision`, `HasRateDependence`,
`RateBounds`, and `SourceSummary` properties. It is a value object: later
operations return new values without mutating the source.

## Example

```matlab
obj = pdbase({[0 1 2]}, [2 2], 1);
objectClass = class(obj)
matrixSize = obj.MatrixSize
degree = obj.Degree
cellCount = obj.ncell()
coefficientCount = obj.ncoeff()
parameterCount = obj.npar()
objectSize = size(obj)
```

```text
objectClass = 'pdbase'
matrixSize = 1×2 double
     2     2

degree = 1
cellCount = 2
coefficientCount = 2
parameterCount = 1
objectSize = 1×2 double
     2     2
```

## Validation and limitations

Grid failures use `pdbase:InvalidGrid` or `pdbase:InvalidGridVector`.
Payload shape, degree, local-tree, coefficient-count, coefficient-payload, and
rate failures use the corresponding `pdbase:Invalid...` identifier. Direct
`pdbase` values are backend containers; they do not implement `pdmat` algebra,
`pdvar` decision construction, plotting, comparisons, or LMI assembly.

Fast mode checks repeated supplied coefficient structure only in the first
physical cell; malformed later coefficient counts, payloads, or rate-row
layouts can remain undetected. Strict mode audits every supplied cell. Grid,
metadata, and options are global in both modes. This raw backend exception
must not be inferred as the public `pdmat` or `pdvar` constructor contract.

## See Also

[`storage and inspection`](/GriD-LMIA/documents/reference/pdbase/storage-inspection/) ·
[`evaluation and elevation`](/GriD-LMIA/documents/reference/pdbase/evaluation-and-elevation/) ·
[`pdmat constructor`](/GriD-LMIA/documents/reference/pdmat/constructor/) ·
[`pdvar constructor`](/GriD-LMIA/documents/reference/pdvar/constructor/)
