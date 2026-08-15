# GriD-LMIA

**Gri**dding-based **D**PD-**LMI A**ssembler (GriD-LMIA) is a MATLAB/YALMIP
research package for modeling parameter-dependent LMIs on tensor-product box
grids. It represents known data (`pdmat`) and continuous decision matrices
(`pdvar`) in cell-wise Bernstein bases, forms
rate-vertex derivatives with `rhodiff`, and exports finite certificates to
YALMIP through `pdlmi`.

Current source, documentation, and tagged GitHub Release: **v1.4.0**.

## What changed in v1.4.0

- A real affine two-dimensional `sdpvar` may multiply coefficient-backed
  `pdmat` in either order when the matrix dimensions are compatible. The mixed
  product returns `pdvar` and supports scalar broadcasting and rectangular
  matrix products.
- The mixed path preserves the known grid, Bernstein degree, continuity,
  `RateBounds`, active known-data rate rows, and existing YALMIP variable
  identities. It does not allocate additional decisions.
- `RateBounds` without stored rate rows is ordinary metadata and no longer
  causes a supported product to be rejected. Products with active rate rows on
  both sides remain outside the affine rate model.
- The printable and Web manuals document the new forms and failure boundaries
  while retaining the existing 192-symbol public inventory.

This release adds no public conversion method. The class-restricted adapter at
the MATLAB/YALMIP dispatch boundary remains an implementation detail.

## Historical migration from v1.2

The removed names have no compatibility aliases.

| Removed API | v1.3.0 API |
| --- | --- |
| `bernsteinTable` | `bernTable` |
| `applyPolya` | `usePolya` |
| `applyPutinar` | `usePutinar` |
| `applySparsePutinar` | `useSpPut` |
| `applySparseFullBoxPreorder` | `useSpBox` |
| `applyFullBoxPreorder` | `useFullBox` |
| `elevVals` | `elevate` |
| `normalizeDegree` | `normDeg` |

Constructor option and selected-state names remain unchanged. Existing code
may continue to use names such as `UsePolya`, `PutinarOrder`, and
`UseSparseFullBoxPreorder`.

## Direction-wise degree model

- Bernstein degree is direction-wise: `Degree=[d1 ... dell]`. A scalar remains
  shorthand and is expanded uniformly. Explicitly using that shorthand in a
  multidimensional constructor emits a warning.
- Tensor coefficient counts are `prod(Degree + 1)`. Alignment uses the
  componentwise maximum, multiplication adds degrees componentwise, and
  elevation accepts direction-wise increments.
- A zero-degree axis means that the object is constant in that direction.
  `rhodiff` preserves a common tensor degree by exact elevation.
- `PolyaDegree`, `PutinarOrder`, `SparseFullBoxOrder`, and `FullBoxOrder`
  accept scalar shorthand or per-axis vectors. `BandWidth` remains scalar.

See the [v1.4.0 Release](https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.4.0)
for the current behavior and verification record. The v1.3.8 and v1.2.4
manuals remain the final documentation snapshots of their completed minor
lines in the version history.

## Requirements and installation

- MATLAB
- A complete YALMIP installation on the MATLAB path
- A working SDP solver visible to YALMIP

Clone or download a tagged release, make it the MATLAB working directory, and
run:

```matlab
report = install_pd_lmi();
```

The installer adds only the repository root, checks YALMIP and a supported
solver, and does not edit `startup.m` or change solver defaults.

## Minimal anisotropic example

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

Here the first parameter direction is affine and the second is quadratic.
`Degree` is stored as the row vector `[1 2]`. Using `Degree=2` on this
two-parameter grid would request the uniform degree `[2 2]` and emit the
documented scalar-expansion warning.

## Certificate choices

Direct coefficient inequalities are the default. Alternative finite
certificates are explicit and replace the current certificate selection:

| Certificate | Selection | Role |
| --- | --- | --- |
| Direct | `P >= A` | Coefficient-wise Bernstein certificate |
| Pólya | `constraint.usePolya([1 2])` | Direction-wise degree elevation before coefficient tests |
| Putinar | `constraint.usePutinar([2 3])` | Box quadratic-module Gram certificate |
| SparsePutinar | `constraint.useSpPut(2, [2 3])` | Sliding tensor-window decomposition of the Putinar Gram certificate |
| SparseFullBox | `constraint.useSpBox(2, [2 3])` | Sliding tensor-window decomposition of the full-box preordering |
| FullBox | `constraint.useFullBox([2 3])` | Dense full-box preordering |

These are sufficient certificates. Failure of one finite certificate does not
prove that the original continuous-domain inequality is infeasible. Always
accept solver results or recovered objectives only after checking
`solution.problem == 0`.

## Current boundaries

- Grids are tensor products of one-dimensional box partitions.
- Decision expressions are affine in YALMIP variables. Products with decision
  dependence on both sides are rejected.
- Coefficient-backed `pdmat` may multiply a compatible real affine
  two-dimensional `sdpvar` in either order. The result is `pdvar`.
- Active rate-row tables may occur on at most one product side. Compatible
  metadata-only `RateBounds` does not create rate dependence.
- Putinar, SparsePutinar, SparseFullBox, and FullBox are box-specific fixed-order
  constructions, not a general SOS parser.
- SparsePutinar and SparseFullBox use tensor windows over Bernstein basis
  labels. They do not infer a sparsity graph, compute a chordal completion, or
  implement structural-matrix chordal decomposition.
- Function-only `pdmat` data need explicit Bernstein coefficient evidence
  before coefficient algebra or certificate assembly.
- YALMIP owns objectives, solver selection, optimization, and diagnostics.

## Verify a checkout

Run the complete MATLAB runtime suite from the repository root:

```matlab
results = tests.run_all();
assert(all([results.Passed]) && ~any([results.Incomplete]))
```

The v1.4.0 release gate passed 435 runtime tests with zero failures and zero
incompletes. Production coverage was 3325/3442 statements (96.60%) and
1671/1782 decisions (93.77%). Solver smoke tests accepted results only when
`diagnostic.problem == 0`.

Run the independent MATLAB SOS validation from the repository root:

```matlab
run("sos_validation/matlab/tests/run_tests.m")
```

Run the independent Julia/SumOfSquares validation with:

```text
julia --project=sos_validation/julia sos_validation/julia/run_all.jl
```

The release gate passed 54 MATLAB SOS tests and 231 Julia SOS tests. On a
Windows system that blocks cached Julia extension DLLs, use the same command
with `--compiled-modules=no` after `julia`.

## Documentation

- [Web manual](https://thebigoranger.github.io/GriD-LMIA/)
- [Printable manual (PDF)](https://thebigoranger.github.io/GriD-LMIA/manual.pdf)
- [Install and download](https://thebigoranger.github.io/GriD-LMIA/install/)
- [Reference index](https://thebigoranger.github.io/GriD-LMIA/documents/reference-index/)
- [Version history](https://thebigoranger.github.io/GriD-LMIA/version-history/)
- [GitHub Releases](https://github.com/TheBigoranger/GriD-LMIA/releases)

The printable manual source is in `doc/`. The Astro/Starlight Web manual is in
`webpage/`.

## Citing GriD-LMIA

If GriD-LMIA supports published work, please cite the software paper:

```bibtex
@article{xu2026gridlmia,
  title   = {GriD-LMIA: A Gridding-Based Assembler for Solving Differentiable Parameter-Dependent Linear Matrix Inequalities},
  author  = {Xu, Yicheng and Jabbari, Faryar},
  journal = {arXiv preprint arXiv:2608.03175},
  year    = {2026},
  url     = {https://arxiv.org/abs/2608.03175}
}
```

Paper: [arXiv:2608.03175](https://arxiv.org/abs/2608.03175).
