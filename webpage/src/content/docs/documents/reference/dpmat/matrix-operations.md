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

## Examples

### Addition, subtraction, and unary signs

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
B = A + 5;
B.evaluate(0.25)
Z = A - A;
(-A).evaluate(1)
(+A).evaluate(0)
```

```text
ans =
    6.5000

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
```

```text
ans =
     2     0
     0     3
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

## See Also

[`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) · [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) · [`dpvar matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/)
