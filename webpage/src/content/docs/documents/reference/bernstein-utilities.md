---
title: Protected pdbase Backend Utilities
description: Current protected elevation, product, storage, rate-row, indexing, and reconstruction methods.
---

<nav class="manual-trail"><a href="/GriD-LMIA/documents/">Documents</a><span>/</span><a href="/GriD-LMIA/documents/reference/pdbase/">pdbase</a><span>/</span><span>protected backend utilities</span></nav>

These methods are protected implementation utilities for maintainers. The public
modeling API enters them through the owning class methods. The current
implementation consolidates elevation in `elevData` and `elevRow`,
multiplication in `prodVals`, and shared unary reconstruction in `mapUnary` and
`mkUnOp`.

## <span id="pdbase-elevrow"></span>`elevRow`

Builds the sparse numeric operator for one source and target tensor degree, then applies it to one packed coefficient row. It preserves numeric and affine payload order.

## <span id="pdbase-elevdata"></span>`elevData`

Groups compatible source degrees and reuses each `elevRow` plan across physical cells and active rate rows. Public [`elevate`](/GriD-LMIA/documents/reference/pdbase/evaluation-and-elevation/#pdbase-elevate) owns validation and class-preserving reconstruction.

## <span id="pdbase-prodvals"></span>`prodVals`

Applies one weighted block contraction to numeric and affine coefficient payloads, reusing planned label pairs and weights across physical cells and rate rows. Public `pdmat` and `pdvar` multiplication own dimension and affinity validation.

## <span id="pdbase-berntbl"></span>`bernTbl`

Builds detailed or one-line coefficient diagnostics for the public [`bernTable`](/GriD-LMIA/documents/reference/pdmat/berntable/) methods.

## <span id="pdbase-mapvals"></span>`mapVals`

Maps one function over every coefficient payload in the nested storage tree.

## <span id="pdbase-matsubs"></span>`matSubs`

Normalizes two-dimensional numeric, logical, colon, and `end` matrix subscripts with caller-owned errors.

## <span id="pdbase-mergegrid"></span>`mergeGrid`

Checks compatible parameter bounds and constructs the sorted union of interior grid nodes before cell-wise algebra.

Ordinary coefficient data are re-expressed on this grid by
[`helper.refineVals`](/GriD-LMIA/documents/reference/shared-helpers/#helper-refinevals),
which applies exact Bernstein restriction within each original cell. This
preserves the separate one-sided values at a discontinuous source face.
Rate-vertex tables require matching physical grids.

## <span id="pdbase-mapunary"></span>`mapUnary` And <span id="pdbase-mkunop"></span>`mkUnOp`

`mapUnary` applies a matrix operation to every cell, label, and rate row. `mkUnOp` rebuilds the same dynamic class with the transformed payload shape.

## <span id="pdbase-joinraterows"></span>`joinRateRows`

This method aligns ordinary and rate-dependent payloads while preserving deterministic rate-row order. Public callers traverse physical cells directly and reuse that row alignment. The former `zipRateRows` helper is retired.

<span id="pdbase-zipraterows"></span>

## Public-Path Example

```matlab
A = pdmat({[0 1]}, {1, 2}, Degree=1);
B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
C = A + B;
D = A * A;
```

The example reaches grid merging, elevation alignment, planned multiplication,
and class-preserving reconstruction through the public owning-class methods.

## See Also

[Coefficient Algebra And Assembly Plans](/GriD-LMIA/documents/math/coordinates-and-bernstein/coefficient-algebra/) · [`pdbase` matrix operations](/GriD-LMIA/documents/reference/pdbase/matrix-operations/) · [`pdmat` algebra](/GriD-LMIA/documents/reference/pdmat/algebra/) · [`pdvar` algebra](/GriD-LMIA/documents/reference/pdvar/algebra/)
