---
title: Shared Helper Utilities
description: Current backend-only +helper utilities shared across the package.
---

<nav class="manual-trail"><a href="/GriD-LMIA/documents/">Documents</a><span>/</span><span>shared helpers</span></nav>

The `+helper` namespace contains validation, grid, tensor-order, degree, rate-row, and Bernstein-convolution utilities.
They are documented as maintainer-facing support APIs. `bernTbl`,
`mapVals`, and `matSubs` are protected `pdbase` methods and therefore belong
on the [protected backend utilities](/GriD-LMIA/documents/reference/bernstein-utilities/)
page.

## <span id="helper-cellget"></span>`helper.cellGet`

**Syntax:** `leaf = helper.cellGet(values,cellSubscripts)`.

Returns one nested physical-cell leaf. The caller supplies a validated tree and
one subscript per parameter axis. ordinary MATLAB cell-access errors surface
for malformed internal use.

## <span id="helper-chk"></span>`helper.chk`

**Syntax:** `value = helper.chk(value,errorId,message,tags...,Name,Value)`.

Returns the unchanged value after common predicates pass. Supported tags cover
numeric/real/cell/struct type, emptiness, scalar/vector/matrix shape, finite
integer sign, strict increase, and row bounds. size/count/range options add
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
`pdmat` placeholder remains distinct from coefficient zero evidence. Bad modes and arity use
`helper:InvalidZeroMode` or `helper:InvalidZeroCall`.

## <span id="helper-mkgrid"></span>`helper.mkGrid`

**Syntax:** `info = helper.mkGrid(grid)` or
`info = helper.mkGrid(grid,owner)`.

Validates a nonempty cell array of finite, real, strictly increasing vectors
with at least two nodes. Returns `Vectors`, tensor-product `Points`, `Bounds`,
and `NumNodes`. Errors use `<owner>:InvalidGrid` or
`<owner>:InvalidGridVector`. the default owner is `pdbase`.

## <span id="helper-mknest"></span>`helper.mkNest`

**Syntax:** `values = helper.mkNest(cellCounts,makeLeaf)`.

Constructs `values{i1}{i2}...{i_npar}` and calls `makeLeaf` once for each
physical-cell subscript row. Inputs are internal validated values. allocation
or callback failures propagate.

## <span id="helper-normdeg"></span>`helper.normDeg`

**Syntax:** `degree = helper.normDeg(value,nPar,errorId,label)`.

Accepts one finite nonnegative integer scalar shorthand or an `nPar`-element
direction-wise vector. A scalar expands uniformly, a column vector is reshaped,
and every accepted result is a `1 × nPar` double row. Empty, nonnumeric,
complex, nonfinite, noninteger, negative, or incorrectly sized input raises the
caller-owned `errorId`. `label` supplies the public option name in the message
and defaults to `"Degree"`.

```matlab
degree = helper.normDeg([0; 2; 1], 3, ...
    "demo:InvalidDegree", "Degree")
```

```text
degree =
     0     2     1
```

## <span id="helper-normmode"></span>`helper.normMode`

**Syntax:** `mode = helper.normMode(value,owner)`.

**Arguments:** `value` is a nonempty character row or nonmissing string scalar.
`owner` is the class or package stem used in the error identifier.

**Output and shape:** `mode` is the lowercase string scalar `"fast"` or
`"strict"`.

**Validation:** Other text, missing strings, nonscalar text, and nontext input
raise `<owner>:InvalidValidationMode`.

**Limitations:** The mode is transient internal validation policy for one call
and preserves mathematical meaning.

**See Also:** [`pdbase constructor`](/GriD-LMIA/documents/reference/pdbase/constructor/) · [`pdlmi constructor`](/GriD-LMIA/documents/reference/pdlmi/constructor/)

## <span id="helper-rateverts"></span>`helper.rateVerts`

**Syntax:** `vertices = helper.rateVerts(rateBounds)`.

**Arguments:** `rateBounds` is an already normalized `ell × 2` lower/upper
table.

**Output and shape:** `vertices` is `N × ell`, with the last axis varying
fastest. A fixed lower-equals-upper axis contributes one value. Thus `[3 3]`
returns one row and `[1 1; -3 5]` returns two distinct rows. Empty bounds
return an empty row table.

**Validation:** This backend helper assumes its caller has validated the bounds
shape, finiteness, and lower/upper order.

**Limitations:** It enumerates box vertices. Rate-model validation and
coefficient storage belong to the owning APIs.

**See Also:** [`rhodiff`](/GriD-LMIA/documents/reference/pdvar/rhodiff/) · [`pdbase storage`](/GriD-LMIA/documents/reference/pdbase/storage-inspection/)

## <span id="helper-bernconvratios"></span>`helper.bernConvRatios`

**Syntax:** `ratios = helper.bernConvRatios(lhsLabels,lhsDegree,rhsLabels,rhsDegree)`
or `ratios = helper.bernConvRatios(...,outputLabels,outputDegree)`.

**Arguments:** Both label tables are row aligned and have `ell` columns. The
degree inputs are normalized `1 × ell` rows. The four-input form infers summed
labels and degrees. The six-input form accepts explicit row-aligned outputs,
including generator-shifted Gram labels.

**Output and shape:** `ratios` is an `N × 1` stable binomial-ratio vector, one
value per input label-pair row.

**Validation:** Bad arity, mismatched row counts, nonnormalized degrees,
out-of-range labels, or nonfinite values raise
`helper:InvalidBernConvRatios`.

**Limitations:** Inputs must already be paired in the intended plan order. The
helper receives pre-enumerated pairs and returns their plan weights. Owning kernels multiply coefficient payloads.

**See Also:** [`helper.bernConvWeights`](#helper-bernconvweights) · [Coefficient Algebra](/GriD-LMIA/documents/math/coordinates-and-bernstein/coefficient-algebra/)

## <span id="helper-bernconvweights"></span>`helper.bernConvWeights`

**Syntax:** `weights = helper.bernConvWeights(labels,degree)`.

**Arguments:** `labels` is an `N × ell` table of nonnegative integer Bernstein
labels. `degree` is a normalized `1 × ell` nonnegative integer row, and every
each label component is less than or equal to its degree component.

**Output and shape:** `weights` is `N × 1`. Row `q` contains the normalized
product binomial weight
`prod_s nchoosek(degree(s),labels(q,s)) / 2^sum(degree)`.

**Validation:** Empty, complex, nonfinite, noninteger, mis-sized, or
out-of-range inputs raise `helper:InvalidBernConvWeights`.

**Limitations:** The recurrence is designed to keep high-degree normalized
weights finite. It returns weights for the owning convolution kernel.

**See Also:** [`helper.bernConvRatios`](#helper-bernconvratios) · [`pdbase prodVals`](/GriD-LMIA/documents/reference/bernstein-utilities/#pdbase-prodvals)

## <span id="helper-chkcont"></span>`helper.chkCont`

**Syntax:** `tf = helper.chkCont(values,cellCounts,degree)`.

**Arguments:** `values` is a normalized nested coefficient tree.
`cellCounts` and `degree` are normalized `1 × ell` rows.

**Output and shape:** `tf` is one logical scalar. It is true only when every
pair of neighboring physical cells has matching coefficients on the complete
shared face and on every stored row.

**Validation:** The helper classifies and preserves existing internal storage.
Numeric faces use the scale-aware tolerance
`1e-9*max(1,norm(lhs,'fro'),norm(rhs,'fro'))`. Affine `sdpvar` faces compare
their complete bases exactly.

**Limitations:** Inputs are assumed structurally valid. The function returns
false at the first mismatch and preserves the input coefficients. Constructors
own continuity enforcement.

**See Also:** [`pdmat constructor`](/GriD-LMIA/documents/reference/pdmat/constructor/) · [`pdvar value`](/GriD-LMIA/documents/reference/pdvar/value/)

## <span id="helper-fitvals"></span>`helper.fitVals`

**Syntax:** `values = helper.fitVals(info,degree,matrixSize,evalFcn,owner)` or
`[values,labels] = helper.fitVals(...)`.

**Arguments:** `info` is normalized grid metadata. `degree` is scalar shorthand
or one entry per parameter axis. `matrixSize` is the common sample shape.
`evalFcn` accepts one physical parameter row. `owner` supplies the degree-error
identifier stem.

**Output and shape:** `values` is the nested physical-cell tree. Each leaf is
a `1 × prod(degree+1)` coefficient row obtained by sampling the tensor
Bernstein nodes of that cell. Optional `labels` is the corresponding
`prod(degree+1) × ell` last-axis-fastest label table.

**Validation:** Degree normalization uses `helper.normDeg`. Invalid grid
metadata, callback output, or matrix shape surfaces through the caller's
construction and arithmetic checks.

**Limitations:** The helper fits samples on the tensor Bernstein nodes and
provides fitted coefficient evidence. Callers own exact representability checks
and public diagnostics.

**See Also:** [`helper.normDeg`](#helper-normdeg) · [`pdmat constructor`](/GriD-LMIA/documents/reference/pdmat/constructor/) · [`helper.mkNest`](#helper-mknest)

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

[`protected pdbase utilities`](/GriD-LMIA/documents/reference/bernstein-utilities/) ·
[`pdbase storage`](/GriD-LMIA/documents/reference/pdbase/storage-inspection/) ·
[`pdmat indexing`](/GriD-LMIA/documents/reference/pdmat/indexing-and-inspection/) ·
[`pdvar indexing`](/GriD-LMIA/documents/reference/pdvar/indexing-and-inspection/)
