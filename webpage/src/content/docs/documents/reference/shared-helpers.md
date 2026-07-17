---
title: Shared Helper Utilities
description: Backend-only +helper utilities used by pdmat, pdvar, pdlmi, and pdbase.
---

<nav class="manual-trail"><a href="/PD-LMI-package/documents/">Documents</a><span>/</span><span>shared helpers</span></nav>

The `+helper` namespace contains implementation utilities, not the primary modeling API. They are documented so maintainers can inspect storage, validation, and ordering contracts. Protected Bernstein methods such as `bernElev`, `bernProd`, and `mergeGrid` remain on the separate [Bernstein backend utilities](/PD-LMI-package/documents/reference/bernstein-utilities/) page.

## <span id="helper-berntbl"></span>`helper.bernTbl`

**Syntax:** `T = helper.bernTbl(obj, errId, valFcn, exprFcn, rateVerts, [cellSubs], ["oneLine"])`

**Output:** a detailed coefficient table, or one expression row per cell/rate vertex in `"oneLine"` mode.

**Boundary and errors:** accepts at most one physical-cell selector and the `"oneLine"` text option; selector and rate-row failures use caller-owned `errId`.

**Consumers:** `pdmat.bernsteinTable` and `pdvar.bernsteinTable`.

## <span id="helper-cellget"></span>`helper.cellGet`

**Syntax:** `leaf = helper.cellGet(vals, subs)`

**Output:** the flat coefficient leaf or rate-row table at nested physical-cell subscript `subs`.

**Boundary and errors:** assumes the tree and one index per level were validated by the caller; ordinary MATLAB cell-index errors surface for malformed access.

**Consumers:** storage traversal, coefficient access, and `helper.mapVals`.

## <span id="helper-chk"></span>`helper.chk`

**Syntax:** `value = helper.chk(value, errId, message, tags..., Name, Value)`

**Output:** the unchanged value after validation. Supported tags are `numeric`, `real`, `cell`, `struct`, `nonempty`, `scalar`, `vector`, `matrix`, `finite`, `integer`, `positive`, `nonnegative`, `increasing`, and `rowbounds`; options are `Size`, `Numel`, `MinNumel`, `Min`, and `Max`.

**Boundary and errors:** a failed predicate raises the caller-owned `errId`; an unknown tag or malformed validator option raises `helper:InvalidValidatorCall`.

**Consumers:** constructors and public-method argument validation across the package.

## <span id="helper-combrows"></span>`helper.combRows`

**Syntax:** `rows = helper.combRows(vecs)`

**Output:** Cartesian-product rows with earlier tensor axes varying more slowly.

**Boundary and errors:** `vecs` is expected to contain one vector per axis; callers validate element types and nonempty dimensions.

**Consumers:** grid points, physical-cell traversal, local labels, and rate vertices.

## <span id="helper-iszero"></span>`helper.isZero`

**Syntax:** `tf = helper.isZero(value,"num")`, `tf = helper.isZero(value,"add",matrixSize)`, `tf = helper.isZero(value,"vals")`, or `tf = helper.isZero(obj,"obj")`.

**Output:** true only when the selected evidence rule proves zero. Function-only `pdmat` placeholders are not zero evidence.

**Boundary and errors:** unsupported modes raise `helper:InvalidZeroMode`; the wrong number of extra inputs raises `helper:InvalidZeroCall`.

**Consumers:** additive identities, zero residual elimination, and equality assembly.

## <span id="helper-mapvals"></span>`helper.mapVals`

**Syntax:** `mapped = helper.mapVals(vals, fcn, grid)`

**Output:** a new nested tree with the same physical-cell layout and `fcn` applied to every coefficient payload.

**Boundary and errors:** relies on a validated grid and matching `LocalValues` tree; mapping-function errors propagate.

**Consumers:** coefficient-wise algebra and structural transformations.

## <span id="helper-matsubs"></span>`helper.matSubs`

**Syntax:** `[rows, cols] = helper.matSubs(subs, size, errId)`

**Output:** normalized positive row and column index vectors.

**Boundary and errors:** requires exactly two subscripts; accepts `:`, a matching logical vector, or finite in-range positive integers. Violations raise caller-owned `errId`.

**Consumers:** `pdmat` and `pdvar` `subsref`/`subsasgn`.

## <span id="helper-mkgrid"></span>`helper.mkGrid`

**Syntax:** `info = helper.mkGrid(grid)` or `info = helper.mkGrid(grid, owner)`

**Output:** `GridInfo` with `Vectors`, Cartesian `Points`, axis `Bounds`, and `NumNodes`.

**Boundary and errors:** requires a nonempty cell array of finite, real, strictly increasing vectors with at least two nodes. Errors use `<owner>:InvalidGrid` or `<owner>:InvalidGridVector`; the default owner is `pdbase`.

**Consumers:** `pdbase`-derived constructors.

## <span id="helper-mknest"></span>`helper.mkNest`

**Syntax:** `vals = helper.mkNest(nCell, mkLeaf)`

**Output:** `vals{i1}{i2}...{i_ell}`, with `mkLeaf` called once per physical-cell subscript row.

**Boundary and errors:** `nCell` and `mkLeaf` are internal validated inputs; callback or cell-allocation failures propagate. The optional recursion prefix is package-internal.

**Consumers:** constructors, grid conversion, and `helper.mapVals`.

## See Also

[`pdbase storage inspection`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/) · [`Bernstein backend utilities`](/PD-LMI-package/documents/reference/bernstein-utilities/) · [`pdmat indexing and inspection`](/PD-LMI-package/documents/reference/pdmat/indexing-and-inspection/) · [`pdvar indexing and inspection`](/PD-LMI-package/documents/reference/pdvar/indexing-and-inspection/)
