---
title: Bernstein Polynomial
description: Mathematical background for cell-local Bernstein storage and coefficient-wise DP-LMI assembly.
---

The package stores parameter-dependent matrices with cell-local Bernstein coefficients. This chapter explains the convention used by `dpmat`, `dpvar`, and `dplmi`.

## One Cell And Local Coordinates

On a scalar physical cell `[rho_k, rho_{k+1}]`, the local coordinate is

```text
alpha = (rho_{k+1} - rho) / (rho_{k+1} - rho_k),  alpha in [0, 1].
```

With this convention, local label `0` selects the left physical coefficient and local label `m` selects the right physical coefficient.

The scalar degree-`m` Bernstein basis is

```text
B_{i,m}(alpha) = nchoosek(m, i) alpha^(m-i) (1-alpha)^i,
i = 0, ..., m.
```

For one-dimensional degree-1 data,

```text
A(alpha) = B_{0,1}(alpha) A_0 + B_{1,1}(alpha) A_1.
```

This is the storage model behind a linear coefficient-backed `dpmat` and the default degree-1 `dpvar`.

## Degree Growth Under Products

Multiplication raises Bernstein degree. If

```text
P(alpha) = alpha P_0 + (1-alpha) P_1
Q(alpha) = alpha Q_0 + (1-alpha) Q_1,
```

then the product is degree 2:

```text
P Q =
  B_{0,2} P_0 Q_0
  + B_{1,2} (P_0 Q_1 + P_1 Q_0) / 2
  + B_{2,2} P_1 Q_1.
```

For scalar degrees `n` and `m`, the product coefficient with label `k` is

```text
R_k = sum_{i+j=k} P_i Q_j
      * nchoosek(n, i) * nchoosek(m, j) / nchoosek(n+m, k).
```

This coefficient convolution is implemented in the shared Bernstein utilities inherited by `dpmat` and `dpvar`.

## Tensor-Product Labels

For `ell` scheduling dimensions, the package uses tensor-product Bernstein bases:

```text
B_{i,m}(alpha) = prod_{r=1}^ell B_{i_r,m_r}(alpha_r).
```

Cell-local labels are enumerated in flat combination order over `{0, ..., m}^ell`. A two-parameter degree-1 cell has labels

```text
[0 0], [0 1], [1 0], [1 1]
```

and a three-parameter degree-1 cell has eight local labels.

## LocalValues Layout

Physical cells are stored as nested cells:

```text
LocalValues{i1}{i2}...{i_ell}
```

The selected entry is a flat cell array containing local Bernstein coefficients. For a two-parameter grid with one cell in each dimension and degree 1, the local value entry has four coefficients in tensor-product label order.

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
labels = A.lbls()
```

```text
labels =
     0     0
     0     1
     1     0
     1     1
```

## Coefficient-Wise Constraints

If a residual expression on one cell is

```text
E(alpha) = sum_i B_{i,m}(alpha) E_i,
```

then the current `dplmi` path uses the sufficient direct condition

```text
E_i <= 0 for every local coefficient i.
```

Rate-dependent derivative expressions produced by `rhodiff` may store one coefficient row for each active `rho_dot` vertex. `dplmi` expands those rows into separate YALMIP constraints.

## Relaxation Boundary

The project records a generalized Bernstein relaxation theorem, but `relaxLemma=true`, `UsePolya=true`, and `PolyaDegree>0` are currently reserved and rejected by `dplmi`. The public implemented workflow documented by this website is direct coefficient-wise assembly.
