---
title: Shared Helper Utilities
description: Seven backend-only +helper utilities shared across the package.
---

<nav class="manual-trail"><a href="/PD-LMI-package/documents/">Documents</a><span>/</span><span>shared helpers</span></nav>

The `+helper` namespace contains exactly seven shared implementation utilities.
They are documented for maintainers, not as primary modeling API. `bernTbl`,
`mapVals`, and `matSubs` are protected `pdbase` methods and therefore belong
on the [protected backend utilities](/PD-LMI-package/documents/reference/bernstein-utilities/)
page.

## <span id="helper-cellget"></span>`helper.cellGet`

**Syntax:** `leaf = helper.cellGet(values,cellSubscripts)`.

Returns one nested physical-cell leaf. The caller supplies a validated tree and
one subscript per parameter axis; ordinary MATLAB cell-access errors surface
for malformed internal use.

## <span id="helper-chk"></span>`helper.chk`

**Syntax:** `value = helper.chk(value,errorId,message,tags...,Name,Value)`.

Returns the unchanged value after common predicates pass. Supported tags cover
numeric/real/cell/struct type, emptiness, scalar/vector/matrix shape, finite
integer sign, strict increase, and row bounds; size/count/range options add
exact constraints. A failed predicate raises the caller-owned identifier.
Malformed validator syntax raises `helper:InvalidValidatorCall`.

## <span id="helper-combrows"></span>`helper.combRows`

**Syntax:** `rows = helper.combRows(vectors)`.

Returns Cartesian-product rows with earlier axes varying more slowly. This one
order governs tensor grid points, physical-cell subscripts, Bernstein labels,
and rate vertices. Callers validate the axis values.

## <span id="helper-iszero"></span>`helper.isZero`

**Syntax:** `tf = helper.isZero(value,mode,...)`.

Modes `"num"`, `"add"`, `"vals"`, and `"obj"` apply the package's numeric,
additive, coefficient-tree, and object evidence rules. A function-only
`pdmat` placeholder is not coefficient zero evidence. Bad modes and arity use
`helper:InvalidZeroMode` or `helper:InvalidZeroCall`.

## <span id="helper-mkgrid"></span>`helper.mkGrid`

**Syntax:** `info = helper.mkGrid(grid)` or
`info = helper.mkGrid(grid,owner)`.

Validates a nonempty cell array of finite, real, strictly increasing vectors
with at least two nodes. Returns `Vectors`, tensor-product `Points`, `Bounds`,
and `NumNodes`. Errors use `<owner>:InvalidGrid` or
`<owner>:InvalidGridVector`; the default owner is `pdbase`.

## <span id="helper-mknest"></span>`helper.mkNest`

**Syntax:** `values = helper.mkNest(cellCounts,makeLeaf)`.

Constructs `values{i1}{i2}...{i_npar}` and calls `makeLeaf` once for each
physical-cell subscript row. Inputs are internal validated values; allocation
or callback failures propagate.

## <span id="helper-normalizedegree"></span>`helper.normalizeDegree`

**Syntax:** `degree = helper.normalizeDegree(value,nPar,errorId,label)`.

Accepts one finite nonnegative integer scalar shorthand or an `nPar`-element
direction-wise vector. A scalar expands uniformly, a column vector is reshaped,
and every accepted result is a `1 × nPar` double row. Empty, nonnumeric,
complex, nonfinite, noninteger, negative, or incorrectly sized input raises the
caller-owned `errorId`; `label` supplies the public option name in the message
and defaults to `"Degree"`.

```matlab
degree = helper.normalizeDegree([0; 2; 1], 3, ...
    "demo:InvalidDegree", "Degree")
```

```text
degree =
     0     2     1
```

## Ordering example

```matlab
helper.combRows({0:1, 10:10:20})
```

```text
ans =
     0    10
     0    20
     1    10
     1    20
```

## See Also

[`protected pdbase utilities`](/PD-LMI-package/documents/reference/bernstein-utilities/) ·
[`pdbase storage`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/) ·
[`pdmat indexing`](/PD-LMI-package/documents/reference/pdmat/indexing-and-inspection/) ·
[`pdvar indexing`](/PD-LMI-package/documents/reference/pdvar/indexing-and-inspection/)
