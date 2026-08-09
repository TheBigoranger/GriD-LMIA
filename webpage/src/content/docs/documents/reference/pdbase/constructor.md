---
title: pdbase Constructor
description: Validated backend construction for shared grid and cell-local Bernstein storage.
---

<nav class="manual-trail"><a href="/GriD-LMIA/documents/">Documents</a><span>/</span><a href="/GriD-LMIA/documents/reference/pdbase/">pdbase</a><span>/</span><span>constructor</span></nav>

## Purpose

`pdbase` owns the common grid, payload-shape, degree, local-value, continuity,
decision, and rate metadata inherited by `pdmat` and `pdvar`. Direct
construction is mainly useful for backend tests and maintainers. modeling code
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
| `localValues` | Optional nested physical-cell tree. An ordinary leaf is a `1 × prod(degree+1)` coefficient cell. a rate-dependent leaf is a rate-row-by-coefficient cell array. |
| `IsContinuous` | Logical scalar metadata. default `false`. |
| `ContainsDecision` | Logical scalar metadata. default `false`. |
| `RateBounds` | Empty or finite `npar × 2` lower/upper bounds with each lower bound less than or equal to its upper bound. |
| `SourceSummary` | Source label. default `"coefficient-backed"`. |
| `ValidationMode` | Case-insensitive scalar text `"fast"` or `"strict"`. Default `"fast"` and transient for the current construction. |

When `localValues` is omitted or empty, each physical cell receives a
coefficient-backed zero payload with the requested matrix size. Explicit
rate-row payloads require nonempty `RateBounds`. `RateBounds` alone is metadata
and leaves `NumRateRows=0`.

## Returned object

The returned value has private-set `GridInfo`, `MatrixSize`, direction-wise
row-vector `Degree`,
`LocalValues`, `IsContinuous`, `ContainsDecision`, `NumRateRows`, `RateBounds`,
and `SourceSummary` properties. It is a value object: later
operations return new values while preserving the source.

## Example

```matlab
obj = pdbase({[0 1], [10 20], [-2 2]}, [1 1], [1 3 0]);
objectClass = class(obj)
degree = obj.Degree
labels = obj.lbls()
coefficientCount = obj.ncoeff()
```

```text
objectClass = 'pdbase'
degree =
     1     3     0

labels =
     0     0     0
     0     1     0
     0     2     0
     0     3     0
     1     0     0
     1     1     0
     1     2     0
     1     3     0

coefficientCount =
     8
```

The backend stores the full vector. It is linear along the first parameter,
cubic along the second, and constant along the third. The eight labels are
$\prod_s(m_s+1)=2\cdot4\cdot1$.

## Validation and limitations

Grid failures use `pdbase:InvalidGrid` or `pdbase:InvalidGridVector`.
Payload shape, degree, local-tree, coefficient-count, coefficient-payload, and
rate failures use the corresponding `pdbase:Invalid...` identifier. Direct
`pdbase` values are backend containers. The derived classes provide `pdmat`
algebra, `pdvar` decision construction, plotting, comparisons, and LMI assembly.

Fast mode checks repeated supplied coefficient structure only in the first
physical cell. malformed later coefficient counts, payloads, or rate-row
layouts can remain undetected. Strict mode audits every supplied cell. Grid,
metadata, and options are global in both modes. This raw backend exception
defines the raw backend contract. The public `pdmat` and `pdvar` constructors
apply their documented validation rules.

## See Also

[`storage and inspection`](/GriD-LMIA/documents/reference/pdbase/storage-inspection/) ·
[`evaluation and elevation`](/GriD-LMIA/documents/reference/pdbase/evaluation-and-elevation/) ·
[`pdmat constructor`](/GriD-LMIA/documents/reference/pdmat/constructor/) ·
[`pdvar constructor`](/GriD-LMIA/documents/reference/pdvar/constructor/)
