---
title: pdvar Matrix Operations
description: Affine algebra and structural operations for pdvar.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/pdvar/">pdvar</a>
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
| Promotion | Numeric, affine `sdpvar`, and coefficient-backed `pdmat` operands |
| Transforms | `transpose`, `ctranspose`, `reshape`, `squeeze`, `vec` |
| Matrix summaries | `diag`, `trace`, `sum`, `mean`, `cumsum`, `tril`, `triu` |
| Assembly | `horzcat`, `vertcat`, `cat`, `blkdiag`, `repmat` |
| Indexing | Two-dimensional indexing and assignment |

The family table is a navigation summary. The following anchors are the
stable per-symbol lookup targets used by the generated reference index.

- [`plus`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-plus) · [`minus`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-minus) · [`mtimes`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-mtimes)
- [`transpose`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-transpose) · [`ctranspose`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-ctranspose) · [`reshape`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-reshape) · [`squeeze`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-squeeze) · [`vec`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-vec)
- [`diag`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-diag) · [`trace`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-trace) · [`sum`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-sum) · [`mean`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-mean) · [`cumsum`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-cumsum) · [`tril`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-tril) · [`triu`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-triu)
- [`horzcat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-horzcat) · [`vertcat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-vertcat) · [`cat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-cat) · [`blkdiag`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-blkdiag) · [`repmat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-repmat)
- [`flip`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-flip) · [`fliplr`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-fliplr) · [`flipud`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-flipud) · [`rot90`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-rot90) · [`subsref`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-subsref) · [`subsasgn`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-subsasgn)
- [`le`](/DP-LMI-package/documents/reference/pdvar/comparisons/#pdvar-comparison-le) · [`ge`](/DP-LMI-package/documents/reference/pdvar/comparisons/#pdvar-comparison-ge)

## Examples

### Addition, subtraction, and unary signs

```matlab
yalmip('clear')
P = pdvar(1, {[0 1]});
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
A = pdmat({[0 1]}, {2, 3}, Degree=1);
P = pdvar(1, {[0 1]});
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
P = pdvar(2, {[0 1]}, "symmetric");
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
P = pdvar(2, {[0 1]}, "symmetric");
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
P = pdvar(1, {[0 1]});
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
P = pdvar(2, {[0 1]}, "full");
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

### <span id="pdvar-plus"></span>`plus` and `+`

Adds affine decision expressions and compatible numeric, `sdpvar`, or
coefficient-backed `pdmat` operands. Grid and matrix dimensions must align.

### <span id="pdvar-minus"></span>`minus` and `-`

Subtracts compatible affine expressions; unary minus negates every stored
coefficient.

### <span id="pdvar-mtimes"></span>`mtimes` and `*`

Multiplies matrix payloads when decision dependence occurs on at most one side.
Products with decision dependence on both sides or rate dependence on both
sides are rejected.

### <span id="pdvar-uminus"></span>`uminus` and unary `-`

Negates the affine expression while preserving rate metadata and grid storage.

### <span id="pdvar-uplus"></span>`uplus` and unary `+`

Returns the affine expression unchanged.

### <span id="pdvar-transpose"></span>`transpose` and `.'`

Transposes each symbolic coefficient matrix. `ctranspose` is numerically the
same for real payloads.

### <span id="pdvar-ctranspose"></span>`ctranspose` and `'`

Conjugate-transposes each symbolic coefficient matrix.

### <span id="pdvar-reshape"></span>`reshape`

Reshapes symbolic matrix payloads with MATLAB's size forms while preserving
the local coefficient tree.

### <span id="pdvar-squeeze"></span>`squeeze`

Removes singleton symbolic matrix dimensions.

### <span id="pdvar-vec"></span>`vec`

Vectorizes symbolic matrix payloads into a column.

### <span id="pdvar-diag"></span>`diag`

Extracts or constructs symbolic diagonals using MATLAB's optional offset `k`.

### <span id="pdvar-trace"></span>`trace`

Computes the trace of square symbolic payloads coefficient by coefficient.

### <span id="pdvar-sum"></span>`sum`, <span id="pdvar-mean"></span>`mean`, and <span id="pdvar-cumsum"></span>`cumsum`

Apply the corresponding MATLAB reduction along a matrix dimension while
preserving the parameter grid.

### <span id="pdvar-tril"></span>`tril` and <span id="pdvar-triu"></span>`triu`

Keep lower or upper triangular symbolic entries, with optional diagonal offset
`k`.

### <span id="pdvar-horzcat"></span>`horzcat`, <span id="pdvar-vertcat"></span>`vertcat`, and <span id="pdvar-cat"></span>`cat`

Concatenate compatible symbolic objects along a horizontal, vertical, or
explicit dimension.

### <span id="pdvar-blkdiag"></span>`blkdiag`

Builds a symbolic block-diagonal object from compatible operands.

### <span id="pdvar-repmat"></span>`repmat`

Repeats symbolic payloads using MATLAB's repetition-size forms.

### <span id="pdvar-flip"></span>`flip`, <span id="pdvar-fliplr"></span>`fliplr`, and <span id="pdvar-flipud"></span>`flipud`

Flip symbolic payloads along a dimension, left-to-right, or up-to-down.

### <span id="pdvar-rot90"></span>`rot90`

Rotates symbolic payloads by quarter turns using the optional integer `k`.

### <span id="pdvar-subsref"></span>`subsref` and <span id="pdvar-subsasgn"></span>`subsasgn`

Support two-dimensional indexing and numeric or compatible decision-block
assignment. The resulting object retains its grid and rate metadata.

### <span id="pdvar-isequal"></span>`isequal`

Compares normalized symbolic metadata and coefficient evidence.

### <span id="pdvar-end"></span>`end`

Resolves `end` in matrix indexing expressions.

### <span id="pdvar-numArgumentsFromSubscript"></span>`numArgumentsFromSubscript`

Keeps subscripted results scalar so MATLAB property and method dot access
continues to dispatch correctly.

### <span id="pdvar-size"></span>`size`, <span id="pdvar-numel"></span>`numel`, <span id="pdvar-ndims"></span>`ndims`, <span id="pdvar-length"></span>`length`, <span id="pdvar-height"></span>`height`, and <span id="pdvar-width"></span>`width`

Report MATLAB-style matrix payload shape and element counts. These dimensions
describe one stored symbolic matrix, not the parameter-grid cell count.

## See Also

[`pdvar constructor`](/DP-LMI-package/documents/reference/pdvar/constructor/) · [`rhodiff`](/DP-LMI-package/documents/reference/pdvar/rhodiff/) · [`pdmat matrix operations`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/)
