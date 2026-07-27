---
title: Protected pdbase Backend Utilities
description: Nine protected Bernstein, storage, indexing, and reconstruction methods owned by pdbase.
---

<nav class="manual-trail"><a href="/PD-LMI-package/documents/">Documents</a><span>/</span><a href="/PD-LMI-package/documents/reference/pdbase/">pdbase</a><span>/</span><span>protected backend utilities</span></nav>

These nine methods are `protected` `pdbase` implementation utilities. They are
documented for maintainers and API ownership clarity, but they are not callable
public modeling API. Use the linked `pdmat`, `pdvar`, and `pdlmi` paths instead.

## <span id="pdbase-bernelev"></span>`bernElev`

**Backend syntax:** `out = pdbase.bernElev(coeffs,fromDeg,toDeg,nPar)`.
Elevates a compatible coefficient family exactly. Degrees must be finite
nonnegative integers, `toDegree >= fromDegree`, and the cell width must match
the tensor label count. Errors use `pdbase:InvalidDegree`,
`pdbase:InvalidDegreeElevation`, or `pdbase:InvalidCoefficientCell`.

## <span id="pdbase-bernprod"></span>`bernProd`

**Backend syntax:** `out = bernProd(obj,lhs,lhsDegree,rhs,rhsDegree)`.
Forms the normalized tensor Bernstein convolution while preserving written
matrix-product order. Public `pdmat` and `pdvar` `mtimes` own operand and
affinity validation.

## <span id="pdbase-berntbl"></span>`bernTbl`

**Backend syntax:** `tbl = bernTbl(obj,errId,valFcn,exprFcn,rateVerts,...)`.
Builds detailed coefficient rows or a one-line Bernstein expression for the
public `bernsteinTable` methods. Optional cell selectors and `"oneLine"` are
validated with the caller-owned error identifier.

## <span id="pdbase-elevlocalvalues"></span>`elevLocalValues`

**Backend syntax:** `vals = pdbase.elevLocalValues(vals,fromDeg,toDeg,grid)`.
Traverses every physical cell and independently elevates every ordinary or
rate-dependent coefficient row. It preserves the nested tree and rate-row
ordering.

## <span id="pdbase-mapvals"></span>`mapVals`

**Backend syntax:** `vals = pdbase.mapVals(vals,fcn,grid)`.
Returns a new nested tree after applying one function to every coefficient
payload. Callback errors propagate. Public structural operations reach this
utility through `unOp`.

## <span id="pdbase-matsubs"></span>`matSubs`

**Backend syntax:** `[rows,cols] = pdbase.matSubs(subs,sz,errId)`.
Normalizes exactly two `:`, logical, or finite in-range positive-integer matrix
subscripts. The caller-owned identifier keeps `pdmat` and `pdvar` validation
class-specific.

## <span id="pdbase-mergegrid"></span>`mergeGrid`

**Backend syntax:** `grid = mergeGrid(obj,errorId,otherGrid1,otherGrid2,...)`.
Requires the same parameter dimension and exact endpoint bounds on every axis,
then returns the sorted union of interior nodes. Public coefficient algebra
re-expresses each operand on this common refinement.

## <span id="pdbase-mkunop"></span>`mkUnOp`

**Backend syntax:** `out = mkUnOp(obj,values,matrixSize)`.
Rebuilds the transformed value as the same dynamic class. The reconstruction
preserves derived properties and metadata rather than collapsing a `pdmat` or
`pdvar` to `pdbase`.

## <span id="pdbase-unop"></span>`unOp`

**Backend syntax:** `out = unOp(obj,functionHandle)` or
`out = unOp(obj,functionHandle,matrixSize)`. Maps the operation over every
cell, coefficient, and rate row, then delegates class-preserving
reconstruction to `mkUnOp`. Function-only `pdmat` data raises the dynamic
`pdmat:FunctionOnlyAlgebra` boundary.

## Public-path example

```matlab
A = pdmat({[0 1]}, {1, 2}, Degree=1);
B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
C = A + B;
commonGrid = C.GridInfo.Vectors{1}
productDegree = (A * A).Degree
```

```text
commonGrid =
         0    0.5000    1.0000

productDegree =
     2
```

The example exercises `mergeGrid`, degree alignment, `bernProd`, and
class-preserving reconstruction without calling protected methods directly.

## See Also

[`pdbase matrix operations`](/PD-LMI-package/documents/reference/pdbase/matrix-operations/) ·
[`pdmat algebra`](/PD-LMI-package/documents/reference/pdmat/algebra/) ·
[`pdvar algebra`](/PD-LMI-package/documents/reference/pdvar/algebra/) ·
[`six shared helpers`](/PD-LMI-package/documents/reference/shared-helpers/)
