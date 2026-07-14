---
title: Bernstein Polynomial
description: Bernstein history, tensor-product cell storage, coefficient algebra, finite matrix certificates, and refinement boundaries for DP-LMI.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <span>Bernstein Polynomial</span>
</nav>

The package stores parameter-dependent matrices with cell-local Bernstein
coefficients. This chapter explains the mathematical facts used by `pdmat`,
`pdvar`, `rhodiff`, and `pdlmi`; the [Status And Limits](/DP-LMI-package/documents/status-and-limits/)
page separates those implemented calls from research context.

For a diagram-led walkthrough of the actual one- and two-dimensional input
shapes, cell traversal, and the distinction between physical gridding and
Bernstein `Degree`, see [Gridding And Bernstein Degree](/DP-LMI-package/documents/math/gridding-and-degree/).

## From 1912 To Parameter-Dependent LMIs

Bernstein introduced the basis in 1912 for a constructive proof of the
Weierstrass approximation theorem. The same control-point form later became
the basis of Bezier curves and the de Casteljau evaluation and subdivision
algorithm. [Farouki's centennial retrospective](https://doi.org/10.1016/j.cagd.2012.03.001)
surveys that history, the basis properties, and its numerical algorithms.

The bridge to DP-LMIs is not approximation alone. On a physical parameter
cell, nonnegative basis functions that sum to one make a scalar, vector, or
matrix polynomial a convex combination of finitely many coefficient objects.
Exact coefficient multiplication, differentiation, and degree elevation then
let the package assemble local matrix expressions before `pdlmi` forms finite
sufficient constraints.

## Local Coordinate, Basis Order, And Endpoint Labels

On a scalar physical cell $[\rho_k,\rho_{k+1}]$, the package uses

$$
\alpha = \frac{\rho-\rho_k}{\rho_{k+1}-\rho_k},
\qquad \alpha \in [0,1].
$$

The scalar degree-$m$ basis is

$$
B_i^m(\alpha)
= \binom{m}{i}(1-\alpha)^{m-i}\alpha^i,
\qquad i=0,\ldots,m.
$$

Thus labels run from left to right in the standard order. Before normalization,
the ordered factor pattern is

$$
(1-\alpha)^m,\quad
(1-\alpha)^{m-1}\alpha,\quad
\ldots,\quad
\alpha^m.
$$

The normalized Bernstein basis factors include the binomial coefficients
$\binom{m}{i}$ shown in the definition above. The endpoint labels are:

- at the left endpoint $\rho=\rho_k$, $\alpha=0$ and local label `0` is selected;
- at the right endpoint $\rho=\rho_{k+1}$, $\alpha=1$ and local label `m` is selected.

For degree two,

$$
P(\rho)=(1-\alpha)^2C_0+2(1-\alpha)\alpha C_1+\alpha^2C_2.
$$

The package stores $C_0,C_1,C_2$ as coefficient matrices or expressions. It
does not treat them as arbitrary samples of a fitted curve. A function-only
`pdmat` constructed without explicit `Degree` is different: it retains its
exact function handle but does not claim Bernstein coefficient evidence.

## Nonnegativity, Unit Sum, And Convex Hulls

For $\alpha\in[0,1]$,

$$
B_i^m(\alpha)\ge 0,
\qquad
\sum_{i=0}^{m}B_i^m(\alpha)=1.
$$

Therefore

$$
P(\alpha)=\sum_i B_i^m(\alpha)P_i
$$

lies in the convex hull of its coefficients. The statement applies to several
payload types:

- scalar: $\min_i P_i\le P(\alpha)\le\max_iP_i$;
- vector: every value lies in the convex hull of the coefficient vectors;
- matrix: every value is a convex combination of the coefficient matrices.

For symmetric matrix coefficients, if every $P_i\preceq0$, then
$P(\alpha)\preceq0$ throughout the cell. Apply the scalar convex-combination
argument to $x^{\mathsf T}P(\alpha)x$ for every vector $x$. Strictly negative
coefficient matrices similarly give a strict cell-wide certificate.

The converse does not generally hold. A matrix polynomial can be negative
definite everywhere while one or more Bernstein coefficient matrices fail the
same sign test. Coefficient-wise matrix sign conditions are therefore safe
but potentially conservative; failure of the finite test does **not** prove
that the continuous DP-LMI is infeasible.

## Tensor Products On Hyperrectangles

For $\ell$ scheduling dimensions, the package uses the tensor-product basis

$$
B_{\mathbf{i}}^{\mathbf{m}}(\boldsymbol\alpha)
=\prod_{r=1}^{\ell}B_{i_r}^{m_r}(\alpha_r).
$$

The products remain nonnegative and sum to one, so the convex-hull and matrix
sign arguments hold on every physical hyperrectangle. Bernstein bases on
simplices are related, but simplex storage is not the `pdbase` convention.
Here each axis has an independent grid interval and local label.

## LocalValues, Continuity, And Boundaries

Physical cells are stored as a nested tree:

```text
LocalValues{i1}{i2}...{i_ell}
```

Each selected leaf is a flat coefficient cell in combination order over the
local labels. Grid normalization happens independently on each physical cell,
so nonuniform cell widths are supported and labels describe local basis
positions rather than global node numbers.

Continuous `pdvar` objects share symbolic coefficient handles across common
cell faces. Continuity is thus encoded in the coefficient graph rather than by
extra equality LMIs. Cell-local derivative objects are deliberately different:
their boundary rows stay separate because neighboring cells can have different
physical widths and different partial-difference data.

## Differentiation

For

$$
P(\alpha)=\sum_{i=0}^{m}P_iB_i^m(\alpha),
$$

the forward coordinate gives the physical derivative on a cell of width
$h=\rho_{k+1}-\rho_k$:

$$
\frac{dP}{d\rho}
=\frac{m}{h}\sum_{i=0}^{m-1}(P_{i+1}-P_i)B_i^{m-1}(\alpha).
$$

For several parameters,
$\dot P=\sum_r(\partial P/\partial\rho_r)\dot\rho_r$. `rhodiff` forms the
cell-local partial differences, aligns tensor degrees as required, and stores
one row for each active rate-box vertex. The
[`rhodiff` reference](/DP-LMI-package/documents/reference/pdvar/rhodiff/)
documents the supported call forms and validation rules.

## Degree Elevation For Any Target Degree

A degree-$m$ polynomial can be represented exactly at any degree $M\ge m$.
For one parameter, the package-indexed coefficients are

$$
\widehat C_k=
\sum_{i=\max(0,k-(M-m))}^{\min(m,k)}
C_i\,
\frac{\binom{m}{i}\binom{M-m}{k-i}}{\binom{M}{k}},
\qquad k=0,\ldots,M.
$$

Tensor products apply the same elevation along every parameter direction.
Elevation preserves the represented polynomial and introduces no new decision
freedom. It is used to align compatible coefficient-backed operands of
different degrees. This must not be confused with constructing a genuinely
higher-degree decision parameterization, which enlarges the search space.

## de Casteljau Evaluation And Exact Subdivision

The de Casteljau recursion repeatedly forms affine combinations:

$$
C_j^{(r)}=(1-\alpha)C_j^{(r-1)}+\alpha C_{j+1}^{(r-1)},
\qquad C_j^{(0)}=C_j.
$$

It evaluates the polynomial stably, and the two edge chains of its recursion
triangle provide the exact Bernstein coefficients on the two subintervals at
the split point. Tensor-product subdivision applies this one-dimensional
operation one axis at a time.

Subdivision is relevant to certificates because re-expressing the same
polynomial on smaller physical cells usually tightens the local coefficient
convex hulls. The package does not currently expose a general public de
Casteljau or adaptive-subdivision API; this section records background, not a
call users can make today.

## Product Degree And Coefficient Convolution

If two degree-one objects are

$$
\begin{aligned}
P(\alpha)&=B_0^1(\alpha)P_0+B_1^1(\alpha)P_1,\\
Q(\alpha)&=B_0^1(\alpha)Q_0+B_1^1(\alpha)Q_1,
\end{aligned}
$$

their product has degree two:

$$
\begin{aligned}
P(\alpha)Q(\alpha)
&=B_0^2(\alpha)R_0+B_1^2(\alpha)R_1+B_2^2(\alpha)R_2,\\
R_0&=P_0Q_0,\\
R_1&=\frac{P_0Q_1+P_1Q_0}{2},\\
R_2&=P_1Q_1.
\end{aligned}
$$

For arbitrary scalar degrees $n$ and $m$,

$$
R_k=\sum_{i+j=k}
P_iQ_j
\frac{\binom{n}{i}\binom{m}{j}}{\binom{n+m}{k}},
\qquad k=0,\ldots,n+m.
$$

For tensor-product parameters, labels add componentwise, coefficient tensors
convolve over every matching label pair, and the scale is the product of the
one-dimensional binomial ratios. Matrix multiplication order is preserved:
$P_iQ_j$ cannot generally be exchanged with $Q_jP_i$.

This direct coefficient convolution is implemented by the shared Bernstein
backend and exercised by coefficient-backed `pdmat` algebra and supported
known-data/`pdvar` products. It is representation algebra, not a relaxation.

### Weighted Value-Grid Convolution

The same product rule can be evaluated as an ordinary ordered
$\ell$-dimensional discrete convolution. Within one physical cell, reshape the
flat coefficient lists into value grids indexed by coefficient multi-indices
$\mathbf p\in\{0,\ldots,m\}^{\ell}$ and
$\mathbf q\in\{0,\ldots,n\}^{\ell}$, preserving the package's `lbls`
order. First restore the binomial weights carried by the tensor Bernstein
basis:

$$
\widetilde A_{\mathbf p}
=A_{\mathbf p}
\prod_{r=1}^{\ell}\binom{m}{p_r},
\qquad
\widetilde B_{\mathbf q}
=B_{\mathbf q}
\prod_{r=1}^{\ell}\binom{n}{q_r}.
$$

Next convolve the two weighted value grids over all componentwise label sums:

$$
\widetilde C_{\boldsymbol\kappa}
=\bigl(\widetilde A *_\ell \widetilde B\bigr)_{\boldsymbol\kappa}
=\sum_{\mathbf p+\mathbf q=\boldsymbol\kappa}
\widetilde A_{\mathbf p}\widetilde B_{\mathbf q}.
$$

Finally remove the degree-$(m+n)$ Bernstein weights to recover the stored
coefficients:

$$
C_{\boldsymbol\kappa}
=\frac{\widetilde C_{\boldsymbol\kappa}}
{\displaystyle\prod_{r=1}^{\ell}\binom{m+n}{\kappa_r}}.
$$

These three steps are algebraically equivalent to the binomial-scaled formula
above. The product has common tensor `Degree` $m+n$ and each physical cell has
$(m+n+1)^{\ell}$ coefficients. For matrix-valued grids, the convolution is
ordered: every term is
$\widetilde A_{\mathbf p}\widetilde B_{\mathbf q}$ in that left-to-right
matrix order. The coefficient labels follow the same forward-coordinate
endpoint order throughout; only binomial weights are temporarily restored and
removed.

## Hypercube Counts And Traversal

With node counts $N_1,\ldots,N_\ell$, the number of physical hypercubes is

$$
N_{\mathrm{cell}}=\prod_{r=1}^{\ell}(N_r-1).
$$

For a common local degree $m$, each hypercube stores $(m+1)^\ell$
coefficients. More generally, a degree vector $\mathbf m$ would have
$\prod_r(m_r+1)$ tensor labels. The implemented package stores one scalar
degree property and enumerates both physical cells and labels lexicographically,
with earlier dimensions varying more slowly.

```matlab
A = pdmat({[0 1 2], [10 20]}, {1 2; 3 4; 5 6}, Degree=1);
A.ncell()
A.ncoeff()
A.lbls()
A.cells()
```

```text
ans =
     2

ans =
     4

ans =
     0     0
     0     1
     1     0
     1     1

ans =
     1     1
     2     1
```

## Direct Matrix Certificates

For a residual

$$
E(\boldsymbol\alpha)=
\sum_{\mathbf i}B_{\mathbf i}^{m}(\boldsymbol\alpha)E_{\mathbf i},
$$

the implemented `pdlmi` path creates one YALMIP sign constraint for every
physical cell, local coefficient, and active rate-vertex row. Requiring all
$E_{\mathbf i}\preceq0$ is sufficient for the whole local matrix polynomial
to be nonpositive. `toYalmip` then hands the finite constraint array to
ordinary YALMIP solver calls.

The package does not currently expose a strictness-margin option. Users should
not infer numerical strictness semantics beyond the constraints actually
assembled by YALMIP.

## Fixed-Order Full Box Preordering

The opt-in [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/)
path replaces coefficient-wise sign tests with a cell-local Bernstein-Gram
representation. It uses the parity-specific Markov-Lukács form in one
parameter and every subset product of the box generators
$\alpha_s(1-\alpha_s)$ in multiple parameters. PSD Gram blocks are
independent across physical cells and rate rows, and exact identities match
the represented polynomial coefficients.

This is a fixed-order certificate on the local parameter box. It is distinct
from a general Putinar certificate, a general-domain SOS interface, or an
automatically selected hierarchy. The dedicated method page documents order
selection, constraint ordering, relation signs, examples, and errors.

## Four Different Refinements

When a direct coefficient test fails, keep these operations distinct:

1. **Pure degree elevation** re-expresses the same polynomial with different
   coefficients and no new decision variables.
2. **Physical subdivision or grid refinement** restricts and reparameterizes
   the same polynomial on smaller cells, often tightening local convex hulls.
3. **Higher decision degree** changes the decision-function parameterization
   and enlarges the search space.
4. **A relaxation hierarchy** changes the sufficient certificate, usually by
   adding multipliers, slack variables, or another positivity construction.

The current package implements degree alignment and common-grid coefficient
algebra, but does not expose an adaptive certificate-refinement workflow or a
general public subdivision command. Constructor-created `pdvar` objects accept
every finite nonnegative integer degree; supported products can raise the
stored degree further.

## Control Literature And Scope

The following references give context without becoming runtime dependencies:

- [Farouki (2012)](https://doi.org/10.1016/j.cagd.2012.03.001): historical development, basis properties, degree elevation, and de Casteljau algorithms.
- [Zettler and Garloff (1998)](https://doi.org/10.1109/9.661615): multivariate Bernstein expansion, positivity tests, and convex-hull value bounds for interval-parameter polynomial families.
- [Masubuchi, Kume, and Shimemura (1998)](https://doi.org/10.1109/CDC.1998.758549): spline-type finite conditions and parameter-partition refinement for parameter-dependent LMIs under the paper's assumptions.
- [Xu and Jabbari (2024)](https://doi.org/10.1109/CDC56724.2024.10886461): recent grid/spline LPV output-feedback synthesis and improved $L_2$-gain context.
- [Chesi (2010)](https://doi.org/10.1109/TAC.2010.2046926): a broader survey of LMI techniques for optimization over polynomials in control.

These papers motivate the representation and certificate landscape. They do
not imply that every theorem, refinement, or hierarchy in that literature is
implemented in the MATLAB/YALMIP package. In particular, general SOS
assembly, adaptive refinement, package-owned strictness or residual
certification, and diagnostics remain reserved or unsupported. The supported
SOS-family feature is the fixed-order full box preordering certificate. The
repository also includes an optional [independent SOS validation suite](https://github.com/TheBigoranger/DP-LMI-package/tree/main/sos_validation)
for cross-backend evidence; it is not a MATLAB runtime dependency.

## See Also

[`Status And Limits`](/DP-LMI-package/documents/status-and-limits/) ·
[`SOS Certificates On A Hypercube`](/DP-LMI-package/documents/math/sos-certificates/) ·
[`pdmat constructor`](/DP-LMI-package/documents/reference/pdmat/constructor/) ·
[`pdvar constructor`](/DP-LMI-package/documents/reference/pdvar/constructor/) ·
[`rhodiff`](/DP-LMI-package/documents/reference/pdvar/rhodiff/) ·
[`pdlmi constructor`](/DP-LMI-package/documents/reference/pdlmi/constructor/) ·
[`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) ·
[`Bernstein backend utilities`](/DP-LMI-package/documents/reference/bernstein-utilities/)
