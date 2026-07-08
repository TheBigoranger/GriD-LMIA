---
title: Bernstein Polynomial
description: Mathematical background for cell-local Bernstein storage and coefficient-wise DP-LMI assembly.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <span>Bernstein Polynomial</span>
</nav>

The package stores parameter-dependent matrices with cell-local Bernstein coefficients. This chapter explains the convention used by `dpmat`, `dpvar`, and `dplmi`.

## One Cell And Local Coordinates

On a scalar physical cell with endpoints `rho_k` and `rho_{k+1}`, the local coordinate is

$$
\alpha = \frac{\rho_{k+1}-\rho}{\rho_{k+1}-\rho_k},
\qquad \alpha \in [0,1].
$$

With this convention, local label `0` selects the left physical coefficient and local label `m` selects the right physical coefficient.

The scalar Bernstein basis of degree `m` is

$$
B_{i,m}(\alpha)
= \binom{m}{i}\alpha^{m-i}(1-\alpha)^i,
\qquad i=0,\ldots,m.
$$

For one-dimensional degree-1 data,

$$
A(\alpha)=B_{0,1}(\alpha)A_0+B_{1,1}(\alpha)A_1.
$$

This is the storage model behind a linear coefficient-backed `dpmat` and the default degree-1 `dpvar`.

## Why Products Become Quadratic

The central coefficient operation is multiplication. If two scalar or matrix-valued Bernstein objects are both degree 1,

$$
\begin{aligned}
P(\alpha)
&=B_{0,1}(\alpha)P_0+B_{1,1}(\alpha)P_1,\\
Q(\alpha)
&=B_{0,1}(\alpha)Q_0+B_{1,1}(\alpha)Q_1,
\end{aligned}
$$

then the product is not degree 1. It is degree 2:

$$
\begin{aligned}
P(\alpha)Q(\alpha)
&=B_{0,2}(\alpha)R_0
 +B_{1,2}(\alpha)R_1
 +B_{2,2}(\alpha)R_2,
\end{aligned}
$$

with

$$
\begin{aligned}
R_0&=P_0Q_0,\\
R_1&=\frac{P_0Q_1+P_1Q_0}{2},\\
R_2&=P_1Q_1.
\end{aligned}
$$

The middle coefficient is averaged because

$$
\begin{aligned}
B_{1,2}(\alpha)&=2\alpha(1-\alpha),\\
\text{cross terms}
&=\alpha(1-\alpha)(P_0Q_1+P_1Q_0).
\end{aligned}
$$

For scalar degrees `n` and `m`, the product coefficient with label `k` is

$$
\begin{aligned}
R_k
&=\sum_{\substack{i+j=k}}
P_iQ_j
\frac{\binom{n}{i}\binom{m}{j}}{\binom{n+m}{k}},
\qquad k=0,\ldots,n+m.
\end{aligned}
$$

This coefficient convolution is implemented in the shared Bernstein utilities inherited by `dpmat` and `dpvar`.

## Tensor-Product Labels

For `ell` scheduling dimensions, the package uses tensor-product Bernstein bases:

$$
B_{\mathbf{i},m}(\boldsymbol{\alpha})
=\prod_{r=1}^{\ell} B_{i_r,m}(\alpha_r).
$$

Cell-local labels are enumerated in flat combination order over `{0,...,m}^ell`. A two-parameter degree-1 cell has labels

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
rho = {[0 1], [10 20]};
grid = {1, 3; 5, 7};
A = dpmat(rho, grid, Degree=1);
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

$$
E(\alpha)=\sum_i B_{i,m}(\alpha)E_i,
$$

then the current `dplmi` path uses the sufficient direct condition

$$
E_i \preceq 0
\qquad \text{for every local coefficient } i.
$$

Rate-dependent derivative expressions produced by `rhodiff` may store one coefficient row for each active `rho_dot` vertex. `dplmi` expands those rows into separate YALMIP constraints.

## Relaxation Boundary

The project records a generalized Bernstein relaxation theorem, but `relaxLemma=true`, `UsePolya=true`, and `PolyaDegree>0` are currently reserved and rejected by `dplmi`. The public implemented workflow documented by this website is direct coefficient-wise assembly.
