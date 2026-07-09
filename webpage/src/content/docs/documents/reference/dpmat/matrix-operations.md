---
title: dpmat Matrix Operations
description: Coefficient-backed algebra and structural operations for dpmat.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dpmat/">dpmat</a>
  <span>/</span>
  <span>matrix operations</span>
</nav>

## Purpose

Apply matrix and coefficient operations to known parameter-dependent matrix data.

## Supported Operations

| Family | Operations |
| :--- | :--- |
| Algebra | `+`, `-`, unary `-`, unary `+`, `mtimes` |
| Transforms | `transpose`, `ctranspose`, `reshape`, `squeeze`, `vec` |
| Matrix summaries | `diag`, `trace`, `sum`, `mean`, `cumsum`, `tril`, `triu` |
| Assembly | `horzcat`, `vertcat`, `cat`, `blkdiag`, `repmat` |
| Indexing | Two-dimensional `subsref` and numeric or `dpmat` block assignment |
| Shape inspection | `size`, `length`, `height`, `width`, `numel`, `ndims` |
| Equality | `isequal` over normalized Bernstein coefficient evidence |

The family table is a navigation summary. The following anchors are the
stable per-symbol lookup targets used by the generated reference index.

- [`plus`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-plus) · [`minus`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-minus) · [`mtimes`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-mtimes)
- [`transpose`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-transpose) · [`ctranspose`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-ctranspose) · [`reshape`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-reshape) · [`squeeze`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-squeeze) · [`vec`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-vec)
- [`diag`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-diag) · [`trace`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-trace) · [`sum`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-sum) · [`mean`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-mean) · [`cumsum`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-cumsum) · [`tril`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-tril) · [`triu`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-triu)
- [`horzcat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-horzcat) · [`vertcat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-vertcat) · [`cat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-cat) · [`blkdiag`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-blkdiag) · [`repmat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-repmat)
- [`flip`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-flip) · [`fliplr`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-fliplr) · [`flipud`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-flipud) · [`rot90`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-rot90) · [`subsref`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-subsref) · [`subsasgn`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-subsasgn)
- [`disp`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-disp) · [`display`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-display) · [`isequal`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-isequal) · [`end`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-end) · [`size`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-size) · [`numel`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-numel) · [`ndims`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-ndims) · [`length`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-length) · [`height`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-height) · [`width`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-width)

## Examples

### Addition, subtraction, and unary signs

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
B = A + 5;
B.evaluate(0.25)
T = bernsteinTable(B);
T(:, ["TermIndex", "LocalIndex", "Basis", "Value"])
Z = A - A;
(-A).evaluate(1)
(+A).evaluate(0)
```

```text
ans =
    6.5000

ans =
  2x4 table

    TermIndex    LocalIndex     Basis     Value
    _________    __________    _______    _____

        1          {[0]}       "a"        {[6]}
        2          {[1]}       "(1-a)"    {[8]}

ans =
    -3

ans =
     1
```

### Matrix multiplication

```matlab
A = dpmat({[0 1]}, {[1 0; 0 2], [2 0; 0 3]}, Degree=1);
B = A * eye(2);
B.evaluate(1)
T = bernsteinTable(B);
T(:, ["TermIndex", "LocalIndex", "Value"])
```

```text
ans =
     2     0
     0     3

ans =
  2x3 table

    TermIndex    LocalIndex       Value
    _________    __________    ____________

        1          {[0]}       {2x2 double}
        2          {[1]}       {2x2 double}
```

### Transpose, reshape, squeeze, and vec

```matlab
A = dpmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
At = A.';
Ah = A';
r = reshape(A, [1 4]);
s = squeeze(A);
v = vec(A);
At.MatrixSize
r.MatrixSize
v.MatrixSize
```

```text
ans =
     2     2

ans =
     1     4

ans =
     4
```

For real coefficient payloads, `transpose` and `ctranspose` have the same numerical effect.

### Matrix summaries

```matlab
A = dpmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
D = diag(A);
tr = trace(A);
colsum = sum(A, 1);
avg = mean(A, 2);
running = cumsum(A, 2);
lo = tril(A);
hi = triu(A);
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
A = dpmat({[0 1]}, {1, 2}, Degree=1);
H = horzcat(A, A);
V = vertcat(A, A);
C = cat(2, A, A);
B = blkdiag(A, A);
R = repmat(A, 2, 3);
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
A = dpmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
entry = A(1, 2);
A(2, 1) = dpmat({[0 1]}, {9, 10}, Degree=1);
entry.MatrixSize
A.evaluate(1)
```

```text
ans =
     1     1

ans =
     5     6
    10     8
```

### Shape inspection and equality

```matlab
A = dpmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
size(A)
height(A)
width(A)
numel(A)
isequal(A, A)
```

```text
ans =
     2     2

ans =
     2

ans =
     2

ans =
     4     1

ans =
  logical
   1
```

## Validation And Errors

- Function-only objects without coefficient evidence are rejected by coefficient algebra and most structural coefficient operations.
- Mixed physical bounds must be compatible before common-refinement algebra can proceed.
- Matrix payload sizes must satisfy the corresponding MATLAB operation.

## Per-symbol reference anchors

### <span id="dpmat-plus"></span>`plus` and `+`

Adds two coefficient-backed `dpmat` objects after grid/degree alignment, or
adds a compatible numeric constant. Scalar numeric constants are promoted to
the matrix payload size.

### <span id="dpmat-minus"></span>`minus` and `-`

Subtracts two compatible objects or a numeric constant. Unary minus is
documented separately below.

### <span id="dpmat-mtimes"></span>`mtimes` and `*`

Performs matrix multiplication coefficient by coefficient, with Bernstein
degree growth handled by the shared backend. Numeric scalar and matrix
operands follow the implemented MATLAB-compatible forms.

### <span id="dpmat-uminus"></span>`uminus` and unary `-`

Negates every stored coefficient while preserving grid, degree, and source
metadata.

### <span id="dpmat-uplus"></span>`uplus` and unary `+`

Returns a coefficient-backed object with the same represented data.

### <span id="dpmat-transpose"></span>`transpose` and `.'`

Transposes each coefficient matrix. For real data this is the same numerical
operation as `ctranspose`.

### <span id="dpmat-ctranspose"></span>`ctranspose` and `'`

Conjugate-transposes each coefficient matrix.

### <span id="dpmat-reshape"></span>`reshape`

Reshapes each coefficient matrix using MATLAB's size forms; the number of
payload elements must be preserved.

### <span id="dpmat-squeeze"></span>`squeeze`

Removes singleton payload dimensions while retaining parameter metadata.

### <span id="dpmat-vec"></span>`vec`

Vectorizes every coefficient matrix into a column payload.

### <span id="dpmat-diag"></span>`diag`

Extracts a diagonal or creates a diagonal matrix according to the implemented
`diag` call form and offset `k`.

### <span id="dpmat-trace"></span>`trace`

Computes a coefficient-wise trace of square matrix payloads.

### <span id="dpmat-sum"></span>`sum`

Sums coefficient matrices along a requested matrix dimension.

### <span id="dpmat-mean"></span>`mean`

Computes coefficient-wise means along a requested matrix dimension.

### <span id="dpmat-cumsum"></span>`cumsum`

Computes cumulative sums along a requested matrix dimension.

### <span id="dpmat-tril"></span>`tril`

Keep the lower triangular coefficient entries, with the optional diagonal
offset `k` following MATLAB's convention.

### <span id="dpmat-triu"></span>`triu`

Keep the upper triangular coefficient entries, with the optional diagonal
offset `k` following MATLAB's convention.

### <span id="dpmat-horzcat"></span>`horzcat`, <span id="dpmat-vertcat"></span>`vertcat`, and <span id="dpmat-cat"></span>`cat`

Concatenate compatible coefficient-backed payloads horizontally, vertically,
or along an explicit dimension. Physical grids and coefficient degrees must
be compatible.

### <span id="dpmat-blkdiag"></span>`blkdiag`

Builds a block-diagonal coefficient matrix from compatible `dpmat` operands.

### <span id="dpmat-repmat"></span>`repmat`

Repeats coefficient payloads using MATLAB's repetition-size forms.

### <span id="dpmat-flip"></span>`flip`, <span id="dpmat-fliplr"></span>`fliplr`, and <span id="dpmat-flipud"></span>`flipud`

Flip coefficient payloads along a dimension, left-to-right, or up-to-down.

### <span id="dpmat-rot90"></span>`rot90`

Rotates matrix payloads by quarter turns using the optional integer `k`.

### <span id="dpmat-subsref"></span>`subsref` and <span id="dpmat-subsasgn"></span>`subsasgn`

Support two-dimensional indexing and compatible block assignment. Assignment
must preserve the grid and matrix-shape contract; use the constructor page for
creating a new grid or source object.

### <span id="dpmat-disp"></span>`disp` and <span id="dpmat-display"></span>`display`

Print a concise object summary and dispatch MATLAB's display behavior. These
methods are inspection conveniences; they do not print every local coefficient
unless `bernsteinTable` is requested.

### <span id="dpmat-isequal"></span>`isequal`

Compares normalized grid, metadata, payload shape, and coefficient evidence.

### <span id="dpmat-end"></span>`end`

Resolves `end` in matrix indexing expressions.

### <span id="dpmat-numArgumentsFromSubscript"></span>`numArgumentsFromSubscript`

Keeps subscripted results scalar so MATLAB property and method dot access
continues to dispatch correctly.

### <span id="dpmat-size"></span>`size`, <span id="dpmat-numel"></span>`numel`, <span id="dpmat-ndims"></span>`ndims`, <span id="dpmat-length"></span>`length`, <span id="dpmat-height"></span>`height`, and <span id="dpmat-width"></span>`width`

Report MATLAB-style matrix payload shape and element counts. These dimensions
refer to the stored matrix at one parameter location, not the tensor-grid
cell count.

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) · [`dpvar matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/)
