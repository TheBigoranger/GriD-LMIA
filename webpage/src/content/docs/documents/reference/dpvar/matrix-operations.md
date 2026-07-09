---
title: dpvar Matrix Operations
description: Affine algebra and structural operations for dpvar.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpvar/">dpvar</a>
  <span>/</span>
  <span>matrix operations</span>
</nav>

## Purpose

Operate on YALMIP-backed Bernstein decision expressions while preserving the cell-local coefficient contract.

## Supported Operations

| Family | Operations |
| :--- | :--- |
| Affine algebra | `+`, `-`, unary `-`, unary `+` |
| Products | `mtimes` with decision dependence on at most one side |
| Promotion | Numeric, affine `sdpvar`, and coefficient-backed `dpmat` operands |
| Transforms | `transpose`, `ctranspose`, `reshape`, `squeeze`, `vec` |
| Matrix summaries | `diag`, `trace`, `sum`, `mean`, `cumsum`, `tril`, `triu` |
| Assembly | `horzcat`, `vertcat`, `cat`, `blkdiag`, `repmat` |
| Indexing | Two-dimensional indexing and assignment |

The family table is a navigation summary. The following anchors are the
stable per-symbol lookup targets used by the generated reference index.

- [`plus`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-plus) · [`minus`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-minus) · [`mtimes`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-mtimes)
- [`transpose`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-transpose) · [`ctranspose`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-ctranspose) · [`reshape`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-reshape) · [`squeeze`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-squeeze) · [`vec`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-vec)
- [`diag`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-diag) · [`trace`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-trace) · [`sum`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-sum) · [`mean`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-mean) · [`cumsum`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-cumsum) · [`tril`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-tril) · [`triu`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-triu)
- [`horzcat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-horzcat) · [`vertcat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-vertcat) · [`cat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-cat) · [`blkdiag`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-blkdiag) · [`repmat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-repmat)
- [`flip`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-flip) · [`fliplr`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-fliplr) · [`flipud`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-flipud) · [`rot90`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-rot90) · [`subsref`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-subsref) · [`subsasgn`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-subsasgn)
- [`le`](/DP-LMI-package/documents/reference/dpvar/comparisons/#dpvar-comparison-le) · [`ge`](/DP-LMI-package/documents/reference/dpvar/comparisons/#dpvar-comparison-ge)

## Examples

### Addition, subtraction, and unary signs

```matlab
yalmip('clear')
P = dpvar(1, {[0 1]});
Q = P - P;
R = P + 2;
S = -P;
Q.ContainsDecision
Q.Degree
R.MatrixSize
S.MatrixSize
```

```text
ans =
  logical
   0

ans =
     0

ans =
     1     1

ans =
     1     1
```

### Known-data multiplication

```matlab
yalmip('clear')
A = dpmat({[0 1]}, {2, 3}, Degree=1);
P = dpvar(1, {[0 1]});
R = A * P;
R.MatrixSize
L = P * A;
L.MatrixSize
```

```text
ans =
     1     1

ans =
     1     1
```

### Transpose, reshape, squeeze, and vec

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
Pt = P.';
Ph = P';
r = reshape(P, [1 4]);
s = squeeze(P);
v = vec(P);
Pt.MatrixSize
r.MatrixSize
v.MatrixSize
```

```text
ans =
     2     2

ans =
     1     4

ans =
     4     1
```

For real affine decision payloads, `transpose` and `ctranspose` have the same numerical effect.

### Matrix summaries

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
D = diag(P);
tr = trace(P);
colsum = sum(P, 1);
avg = mean(P, 2);
running = cumsum(P, 2);
lo = tril(P);
hi = triu(P);
D.MatrixSize
tr.MatrixSize
colsum.MatrixSize
```

```text
ans =
     2     1

ans =
     1     1

ans =
     1     2
```

### Assembly

```matlab
yalmip('clear')
P = dpvar(1, {[0 1]});
H = horzcat(P, P);
V = vertcat(P, P);
C = cat(2, P, P);
B = blkdiag(P, P);
R = repmat(P, 2, 3);
H.MatrixSize
B.MatrixSize
R.MatrixSize
```

```text
ans =
     1     2

ans =
     2     2

ans =
     2     3
```

### Indexing and assignment

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "full");
entry = P(1, 2);
P(2, 1) = 0;
entry.MatrixSize
P.MatrixSize
```

```text
ans =
     1     1

ans =
     2     2
```

## Validation And Errors

- Products with decision dependence on both sides are rejected.
- Products with rate dependence on both sides are rejected.
- Matrix payload sizes must satisfy the corresponding MATLAB operation.
- Incompatible grids or physical bounds are rejected.

## Per-symbol reference anchors

### <span id="dpvar-plus"></span>`plus` and `+`

Adds affine decision expressions and compatible numeric, `sdpvar`, or
coefficient-backed `dpmat` operands. Grid and matrix dimensions must align.

### <span id="dpvar-minus"></span>`minus` and `-`

Subtracts compatible affine expressions; unary minus negates every stored
coefficient.

### <span id="dpvar-mtimes"></span>`mtimes` and `*`

Multiplies matrix payloads when decision dependence occurs on at most one side.
Products with decision dependence on both sides or rate dependence on both
sides are rejected.

### <span id="dpvar-uminus"></span>`uminus` and unary `-`

Negates the affine expression while preserving rate metadata and grid storage.

### <span id="dpvar-uplus"></span>`uplus` and unary `+`

Returns the affine expression unchanged.

### <span id="dpvar-transpose"></span>`transpose` and `.'`

Transposes each symbolic coefficient matrix. `ctranspose` is numerically the
same for real payloads.

### <span id="dpvar-ctranspose"></span>`ctranspose` and `'`

Conjugate-transposes each symbolic coefficient matrix.

### <span id="dpvar-reshape"></span>`reshape`

Reshapes symbolic matrix payloads with MATLAB's size forms while preserving
the local coefficient tree.

### <span id="dpvar-squeeze"></span>`squeeze`

Removes singleton symbolic matrix dimensions.

### <span id="dpvar-vec"></span>`vec`

Vectorizes symbolic matrix payloads into a column.

### <span id="dpvar-diag"></span>`diag`

Extracts or constructs symbolic diagonals using MATLAB's optional offset `k`.

### <span id="dpvar-trace"></span>`trace`

Computes the trace of square symbolic payloads coefficient by coefficient.

### <span id="dpvar-sum"></span>`sum`, <span id="dpvar-mean"></span>`mean`, and <span id="dpvar-cumsum"></span>`cumsum`

Apply the corresponding MATLAB reduction along a matrix dimension while
preserving the parameter grid.

### <span id="dpvar-tril"></span>`tril` and <span id="dpvar-triu"></span>`triu`

Keep lower or upper triangular symbolic entries, with optional diagonal offset
`k`.

### <span id="dpvar-horzcat"></span>`horzcat`, <span id="dpvar-vertcat"></span>`vertcat`, and <span id="dpvar-cat"></span>`cat`

Concatenate compatible symbolic objects along a horizontal, vertical, or
explicit dimension.

### <span id="dpvar-blkdiag"></span>`blkdiag`

Builds a symbolic block-diagonal object from compatible operands.

### <span id="dpvar-repmat"></span>`repmat`

Repeats symbolic payloads using MATLAB's repetition-size forms.

### <span id="dpvar-flip"></span>`flip`, <span id="dpvar-fliplr"></span>`fliplr`, and <span id="dpvar-flipud"></span>`flipud`

Flip symbolic payloads along a dimension, left-to-right, or up-to-down.

### <span id="dpvar-rot90"></span>`rot90`

Rotates symbolic payloads by quarter turns using the optional integer `k`.

### <span id="dpvar-subsref"></span>`subsref` and <span id="dpvar-subsasgn"></span>`subsasgn`

Support two-dimensional indexing and numeric or compatible decision-block
assignment. The resulting object retains its grid and rate metadata.

### <span id="dpvar-isequal"></span>`isequal`

Compares normalized symbolic metadata and coefficient evidence.

### <span id="dpvar-end"></span>`end`

Resolves `end` in matrix indexing expressions.

### <span id="dpvar-numArgumentsFromSubscript"></span>`numArgumentsFromSubscript`

Keeps subscripted results scalar so MATLAB property and method dot access
continues to dispatch correctly.

### <span id="dpvar-size"></span>`size`, <span id="dpvar-numel"></span>`numel`, <span id="dpvar-ndims"></span>`ndims`, <span id="dpvar-length"></span>`length`, <span id="dpvar-height"></span>`height`, and <span id="dpvar-width"></span>`width`

Report MATLAB-style matrix payload shape and element counts. These dimensions
describe one stored symbolic matrix, not the parameter-grid cell count.

## See Also

[`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) · [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) · [`dpmat matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/)
