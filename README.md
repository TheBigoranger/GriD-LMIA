# GriD-LMIA

**Gri**dding-based **D**PD-**LMI A**ssembler is a MATLAB/YALMIP package for modeling and assembling differentiable parameter-dependent linear matrix inequalities on tensor-product box grids.

## Requirements and installation

- MATLAB.
- A complete [YALMIP](https://yalmip.github.io/) installation on the MATLAB path.
- A working SDP solver visible to YALMIP. The installer checks MOSEK, COPT, SeDuMi, SDPT3, and LMILAB in that order.

For a reproducible package checkout, clone the release tag:

```sh
git clone --depth 1 --single-branch --branch v1.5.1 https://github.com/TheBigoranger/GriD-LMIA.git
```

Alternatively, download the [v1.5.1 release](https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.5.1). Make the package root the MATLAB working directory and run:

```matlab
report = install_pd_lmi();
```

The installer discovers the package location, adds only its root to the MATLAB path, checks dependencies and class resolution, and persists the path. It does not install dependencies, edit `startup.m`, or change solver defaults.

For a future Code Ocean environment, use the same pinned checkout and provide MATLAB, YALMIP, and the required solver separately. Four public examples default to SDPT3; `discrete_time_robust_stability.m` defaults to SeDuMi. Each script has an editable `solver` setting. A solver accepted by the installer does not guarantee that every unchanged example's default solver is available.

For `install_pd_lmi:PathSaveFailed` specifically, the [installation guide](https://www.ethanyxu.com/GriD-LMIA/install/) explains how to re-add the repository root for the current MATLAB session. That fallback does not persist installation; other installer errors require correction. Code Ocean execution and its Markdown rendering have not been verified.

## What changed in v1.5.1

- Zero-operand addition and subtraction preserve refined grid and rate metadata; subtracting near-equal large coefficients retains nonzero residuals.
- Bernstein evaluation, convolution, continuity checks, differentiation, spline extraction, and known-matrix certificate checks handle additional extreme-scale inputs without avoidable intermediate overflow or underflow. Explicit-degree fitting rejects degrees above 64 and ill-conditioned collocation systems; grid cell widths must be finite.
- Numeric coefficient data and arithmetic constants must be `double` or `single`. Integer grid vectors are converted to `double` and revalidated. Decision-dependence metadata is recomputed after indexing or numeric replacement.
- The public catalog contains five examples. Two examples from an unpublished delay-system manuscript remain withheld, and private source paths and local performance tools are excluded from distribution.
- Software and website sources are published on separate branches; the package includes the current printable manual.

See the [v1.5.1 Release](https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.5.1) for this immutable snapshot and the [Version History](https://www.ethanyxu.com/GriD-LMIA/version-history/) for earlier changes and migration guidance.

## Mathematical problem and workflow

Find scalar decision functions $y_1,\ldots,y_{n_y}$ such that

$$
\mathcal F(\boldsymbol{\rho},\dot{\boldsymbol{\rho}};y)
= F_0(\boldsymbol{\rho})
+\sum_{k=1}^{n_y}F_k(\boldsymbol{\rho})y_k(\boldsymbol{\rho})
+\sum_{k=1}^{n_y}\sum_{s=1}^{\ell}
T_{k,s}(\boldsymbol{\rho})\dot\rho_s
\frac{\partial y_k(\boldsymbol{\rho})}{\partial\rho_s}
\preceq0
$$

for every $(\boldsymbol{\rho},\dot{\boldsymbol{\rho}})\in\mathcal P\times\mathcal R$, where the supported parameter and rate sets are boxes:

$$
\mathcal P=\prod_{s=1}^{\ell}[\underline\rho_s,\overline\rho_s],
\qquad
\mathcal R=\prod_{s=1}^{\ell}[\underline v_s,\overline v_s].
$$

The known matrix functions $F_0$, $F_k$, and $T_{k,s}$ have compatible symmetric sizes. Matrix decisions are represented through their independent scalar entries. Setting every $T_{k,s}=0$ gives an ordinary derivative-free PD-LMI. LPV stability and induced-$L_2$-gain analysis are representative applications.

1. **Partition the parameter box.** Independent axis grids form physical cells and exactly cover the assumed box.
2. **Choose a finite decision space.** Continuous, cell-wise-differentiable piecewise Bernstein polynomials restrict the admissible decision functions. Direction-wise degrees may differ.
3. **Form the residual.** Use `pdmat` for known data, `pdvar` for decisions, and `rhodiff` for rate-weighted cell-wise derivatives. Bernstein nonnegativity and partition of unity support coefficient-based certificates; affine rate dependence reduces exactly to rate vertices.
4. **Select a sufficient certificate.** Direct coefficient inequalities or an explicit alternative replace the remaining parameter continuum by finitely many constraints. Failure of a chosen certificate does not prove infeasibility of the original problem.
5. **Solve and recover.** Export with `toYalmip`, call YALMIP's `optimize`, check the solver diagnostic, and only then recover decisions or objectives.

The [Web manual](https://www.ethanyxu.com/GriD-LMIA/) and [printable manual](doc/manual.pdf) develop the mathematics and supported boundaries.

## Main features

- Known polynomial data, affine decision expressions, and MATLAB-style matrix operations on nonuniform tensor grids.
- Anisotropic Bernstein degree $\mathbf m=(m_1,\ldots,m_\ell)$, with $\prod_{s=1}^{\ell}(m_s+1)$ coefficients per physical cell. Common-grid alignment uses exact Bernstein restriction.
- Direction-wise `Continuity` metadata, C0 decision construction by default, and higher-order spline decisions. Derivatives are taken cell-wise and retain rate-vertex rows.
- Mixed coefficient-backed `pdmat` and real affine `sdpvar` multiplication in either order. Products with decision dependence on both sides, or active rate rows on both sides, are rejected.
- Explicit certificate selection and terminal concatenation with native YALMIP constraints. YALMIP owns objectives, solver selection, optimization, and diagnostics.

### Certificate choices

Direct is the default. Calling another selector replaces the current certificate:

| Certificate | Selection | Role |
| --- | --- | --- |
| Direct | `constraint = P >= A` | Coefficient-wise Bernstein inequalities |
| Pólya | `constraint.usePolya([1 2])` | Degree elevation before coefficient tests |
| Putinar | `constraint.usePutinar([2 3])` | Box quadratic-module Gram certificate |
| SparsePutinar | `constraint.useSpPut(2, [2 3])` | Tensor windows for the Putinar Gram certificate |
| SparseFullBox | `constraint.useSpBox(2, [2 3])` | Tensor windows for full-box preordering |
| FullBox | `constraint.useFullBox([2 3])` | Dense full-box preordering |

These are box-specific, fixed-order sufficient constructions. Sparse certificates use Bernstein-label windows; they do not infer sparsity graphs or perform chordal decomposition. Function-only `pdmat` objects need explicit coefficient evidence before coefficient algebra or certificate assembly.

## Minimal example

```matlab
yalmip("clear")

grid = {[0 1], [-1 1]};
A = pdmat(grid, ...
    @(rho, eta) [1 + rho, eta; eta, 2 + eta.^2], ...
    Degree=[1 2]);
P = pdvar(2, grid, "symmetric", Degree=[1 2]);

constraint = P >= A;
F = constraint.toYalmip();
solution = optimize(F);
assert(solution.problem == 0)
```

The first parameter direction is affine and the second is quadratic: `Degree=[1 2]`. A scalar degree is uniform shorthand; explicitly using it in a multidimensional constructor emits the documented warning.

The [five-example catalog](example/README.md) includes univariate and three-parameter LPV gain analysis, discrete-time robust stability, continuous-time robust stability, and a mass-spring-damper case. Each script identifies its source, tunable settings, solver diagnostics, and numerical comparison.

## Verify a checkout

From the package root, run:

```matlab
results = tests.run_all();
assert(all([results.Passed]) && ~any([results.Incomplete]))
```

For the production-code coverage and API traceability gates:

```matlab
[results, coverage] = tests.run_coverage();
```

The examples are separate from the unit suite. Inspect their solver diagnostics and source comparisons; a script finishing is not itself evidence of a successful certificate. The second mass-spring parameter box intentionally illustrates a non-certificate outcome.

## Documentation

- [Installation and download](https://www.ethanyxu.com/GriD-LMIA/install/)
- [Web manual](https://www.ethanyxu.com/GriD-LMIA/)
- [Printable manual (PDF)](doc/manual.pdf)
- [API reference](https://www.ethanyxu.com/GriD-LMIA/documents/reference-index/)
- [Version History and migration guidance](https://www.ethanyxu.com/GriD-LMIA/version-history/)
- [Project guide and repository branches](SUMMARY.md)
- [GitHub Releases](https://github.com/TheBigoranger/GriD-LMIA/releases)

The default `main` branch contains the software package and final PDF. Website sources are maintained on the separate [`webpage` branch](https://github.com/TheBigoranger/GriD-LMIA/tree/webpage). The pinned shallow clone above avoids downloading old website history for a fresh package checkout.

## Citing GriD-LMIA

If GriD-LMIA supports published work, please cite the [software paper](https://arxiv.org/abs/2608.03175):

```bibtex
@article{xu2026gridlmia,
  title   = {GriD-LMIA: A Gridding-Based Assembler for Solving Differentiable Parameter-Dependent Linear Matrix Inequalities},
  author  = {Xu, Yicheng and Jabbari, Faryar},
  journal = {arXiv preprint arXiv:2608.03175},
  year    = {2026},
  url     = {https://arxiv.org/abs/2608.03175}
}
```
