---
title: pdmat Matrix Operations
description: Coefficient-backed algebra and structural operations for pdmat.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/pdmat/">pdmat</a>
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
| Indexing | Two-dimensional `subsref` and numeric or `pdmat` block assignment |
| Shape inspection | `size`, `length`, `height`, `width`, `numel`, `ndims` |
| Equality | `isequal` over normalized Bernstein coefficient evidence |

The family table is a navigation summary. The following anchors are the
stable per-symbol lookup targets used by the generated reference index.

- [`plus`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-plus) · [`minus`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-minus) · [`mtimes`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-mtimes)
- [`transpose`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-transpose) · [`ctranspose`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-ctranspose) · [`reshape`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-reshape) · [`squeeze`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-squeeze) · [`vec`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-vec)
- [`diag`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-diag) · [`trace`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-trace) · [`sum`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-sum) · [`mean`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-mean) · [`cumsum`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-cumsum) · [`tril`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-tril) · [`triu`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-triu)
- [`horzcat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-horzcat) · [`vertcat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-vertcat) · [`cat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-cat) · [`blkdiag`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-blkdiag) · [`repmat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-repmat)
- [`flip`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-flip) · [`fliplr`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-fliplr) · [`flipud`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-flipud) · [`rot90`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-rot90) · [`subsref`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-subsref) · [`subsasgn`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-subsasgn)
- [`disp`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-disp) · [`display`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-display) · [`isequal`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-isequal) · [`end`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-end) · [`size`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-size) · [`numel`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-numel) · [`ndims`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-ndims) · [`length`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-length) · [`height`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-height) · [`width`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-width)

## Examples

### Numeric scalar promotion

```matlab
A = pdmat({[0 1]}, {1, 3}, Degree=1);
B = A + 5;
B.evaluate(0.25)
```

```text
ans =
    6.5000
```

### Degree elevation before addition

```matlab
A = pdmat({[0 1]}, {1, 2}, Degree=1);
B = pdmat({[0 1]}, {10, 20, 30}, Degree=2);
S = A + B;
cS = S.coeffs(1);
S.Degree
disp([cS{:}])
```

```text
ans =
     2

   11.0000   21.5000   32.0000
```

### Subtraction and unary signs

```matlab
A = pdmat({[0 1]}, {1, 3}, Degree=1);
Z = A - A;
Z.Degree
(-A).evaluate(1)
(+A).evaluate(0)
```

```text
ans =
     0

ans =
    -3

ans =
     1
```

### Common refinement on different grid densities

Coefficient-backed operands with the same physical bounds may use different
interior nodes. The operation forms their sorted-union grid, re-expresses both
operands on its physical cells, and then combines the aligned coefficients.
This is independent of degree elevation, numeric promotion, and product degree
growth.

```matlab
A = pdmat({[0 1]}, {1, 2}, Degree=1);
B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
S = A + B;
c1 = S.coeffs(1);
c2 = S.coeffs(2);
fprintf('Merged grid:\n');
disp(S.GridInfo.Vectors{1})
fprintf('Degree: %d\n', S.Degree);
fprintf('Cell 1 coefficients:\n');
disp([c1{:}])
fprintf('Cell 2 coefficients:\n');
disp([c2{:}])
```

```text
Merged grid:
         0    0.5000    1.0000
Degree: 1
Cell 1 coefficients:
   11.0000   21.5000
Cell 2 coefficients:
   21.5000   32.0000
```

### Numeric matrix multiplication

```matlab
A = pdmat({[0 1]}, {[1 0; 0 2], [2 0; 0 3]}, Degree=1);
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

### Two-dimensional tensor Bernstein multiplication

This example isolates multiplication of two parameter-dependent operands on a
two-axis tensor grid. Two degree-one factors produce common tensor degree two,
so the single physical cell stores $(2+1)^2=9$ coefficients in `lbls` order.

```matlab
grid = {[0 1], [10 20]};
A = pdmat(grid, {1 2; 3 4}, Degree=1);
B = pdmat(grid, {5 6; 7 8}, Degree=1);
K = A * B;
cK = K.coeffs([1 1]);
fprintf('Tensor product degree: %d\n', K.Degree);
fprintf('Tensor labels:\n');
disp(K.lbls())
fprintf('Tensor coefficients:\n');
disp([cK{:}])
```

```text
Tensor product degree: 2
Tensor labels:
     0     0
     0     1
     0     2
     1     0
     1     1
     1     2
     2     0
     2     1
     2     2

Tensor coefficients:
     5     8    12    11    15    20    21    26    32
```

### Transpose, reshape, squeeze, and vec

```matlab
A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
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
A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
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
A = pdmat({[0 1]}, {1, 2}, Degree=1);
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
A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
entry = A(1, 2);
A(2, 1) = pdmat({[0 1]}, {9, 10}, Degree=1);
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
A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
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

### <span id="pdmat-plus"></span>`plus` and `+`

Adds two coefficient-backed `pdmat` objects after grid/degree alignment, or
adds a compatible numeric constant. Scalar numeric constants are promoted to
the matrix payload size.

### <span id="pdmat-minus"></span>`minus` and `-`

Subtracts two compatible objects or a numeric constant. Unary minus is
documented separately below.

### <span id="pdmat-mtimes"></span>`mtimes` and `*`

Performs a binomial-normalized, ordered tensor Bernstein convolution over
cell-local coefficient labels. Label multi-indices add componentwise, and the
output degree is the sum of the operand degrees on every parameter axis.
Matrix-product order is preserved in each term: a left coefficient multiplies
the matching right coefficient, not the reverse. Numeric scalar and matrix
operands follow the implemented MATLAB-compatible forms.

### <span id="pdmat-uminus"></span>`uminus` and unary `-`

Negates every stored coefficient while preserving grid, degree, and source
metadata.

### <span id="pdmat-uplus"></span>`uplus` and unary `+`

Returns a coefficient-backed object with the same represented data.

### <span id="pdmat-transpose"></span>`transpose` and `.'`

Transposes each coefficient matrix. For real data this is the same numerical
operation as `ctranspose`.

### <span id="pdmat-ctranspose"></span>`ctranspose` and `'`

Conjugate-transposes each coefficient matrix.

### <span id="pdmat-reshape"></span>`reshape`

Reshapes each coefficient matrix using MATLAB's size forms; the number of
payload elements must be preserved.

### <span id="pdmat-squeeze"></span>`squeeze`

Removes singleton payload dimensions while retaining parameter metadata.

### <span id="pdmat-vec"></span>`vec`

Vectorizes every coefficient matrix into a column payload.

### <span id="pdmat-diag"></span>`diag`

Extracts a diagonal or creates a diagonal matrix according to the implemented
`diag` call form and offset `k`.

### <span id="pdmat-trace"></span>`trace`

Computes a coefficient-wise trace of square matrix payloads.

### <span id="pdmat-sum"></span>`sum`

Sums coefficient matrices along a requested matrix dimension.

### <span id="pdmat-mean"></span>`mean`

Computes coefficient-wise means along a requested matrix dimension.

### <span id="pdmat-cumsum"></span>`cumsum`

Computes cumulative sums along a requested matrix dimension.

### <span id="pdmat-tril"></span>`tril`

Keep the lower triangular coefficient entries, with the optional diagonal
offset `k` following MATLAB's convention.

### <span id="pdmat-triu"></span>`triu`

Keep the upper triangular coefficient entries, with the optional diagonal
offset `k` following MATLAB's convention.

### <span id="pdmat-horzcat"></span>`horzcat`, <span id="pdmat-vertcat"></span>`vertcat`, and <span id="pdmat-cat"></span>`cat`

Concatenate compatible coefficient-backed payloads horizontally, vertically,
or along an explicit dimension. Physical grids and coefficient degrees must
be compatible.

### <span id="pdmat-blkdiag"></span>`blkdiag`

Builds a block-diagonal coefficient matrix from compatible `pdmat` operands.

### <span id="pdmat-repmat"></span>`repmat`

Repeats coefficient payloads using MATLAB's repetition-size forms.

### <span id="pdmat-flip"></span>`flip`, <span id="pdmat-fliplr"></span>`fliplr`, and <span id="pdmat-flipud"></span>`flipud`

Flip coefficient payloads along a dimension, left-to-right, or up-to-down.

### <span id="pdmat-rot90"></span>`rot90`

Rotates matrix payloads by quarter turns using the optional integer `k`.

### <span id="pdmat-subsref"></span>`subsref` and <span id="pdmat-subsasgn"></span>`subsasgn`

Support two-dimensional indexing and compatible block assignment. Assignment
must preserve the grid and matrix-shape contract; use the constructor page for
creating a new grid or source object.

### <span id="pdmat-disp"></span>`disp` and <span id="pdmat-display"></span>`display`

Print a concise object summary and dispatch MATLAB's display behavior. These
methods are inspection conveniences; they do not print every local coefficient
unless `bernsteinTable` is requested.

### <span id="pdmat-isequal"></span>`isequal`

Compares normalized grid, metadata, payload shape, and coefficient evidence.

### <span id="pdmat-end"></span>`end`

Resolves `end` in matrix indexing expressions.

### <span id="pdmat-numArgumentsFromSubscript"></span>`numArgumentsFromSubscript`

Keeps subscripted results scalar so MATLAB property and method dot access
continues to dispatch correctly.

### <span id="pdmat-size"></span>`size`, <span id="pdmat-numel"></span>`numel`, <span id="pdmat-ndims"></span>`ndims`, <span id="pdmat-length"></span>`length`, <span id="pdmat-height"></span>`height`, and <span id="pdmat-width"></span>`width`

Report MATLAB-style matrix payload shape and element counts. These dimensions
refer to the stored matrix at one parameter location, not the tensor-grid
cell count.

## See Also

[`pdmat constructor`](/DP-LMI-package/documents/reference/pdmat/constructor/) · [`evaluate`](/DP-LMI-package/documents/reference/pdmat/evaluate/) · [`pdvar matrix operations`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/)
