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

## See Also

[`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) · [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) · [`dpmat matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/)
