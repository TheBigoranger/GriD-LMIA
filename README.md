# GriD-LMIA

**Gri**dding-based **D**PD-**LMI A**ssembler (GriD-LMIA) is a MATLAB/YALMIP
research package for modeling parameter-dependent LMIs on tensor-product box
grids. It represents known data (`pdmat`) and
continuous decision matrices (`pdvar`) in cell-local Bernstein bases, forms
rate-vertex derivatives with `rhodiff`, and exports finite certificates to
YALMIP through `pdlmi`.

Current source, documentation, and tagged GitHub Release: **v1.3.0**.

## What changed in v1.3.0

- Public method names now follow one compact vocabulary. Bernstein tables use
  `bernTable`, degree elevation uses `elevate`, and certificate selectors use
  the `use*` methods listed below.
- Elevation and product assembly reuse numeric plans across compatible cells
  and rate rows. Numeric products use tensor convolution after Bernstein
  scaling. Known-by-affine products use a planned block contraction, while
  other supported payloads use planned coefficient pairs.
- Direct, Pólya, and Bernstein-Gram assembly preallocate ordered outputs and
  reuse numeric coefficient maps. Each matrix entry, cell, rate row, and Gram
  block still receives fresh YALMIP decision variables.
- SparsePutinar and SparseFullBox use overlapping axis-aligned tensor-basis
  windows with independent PSD blocks and accumulated coefficient identities.

The optimized paths preserve represented functions, existing YALMIP variables,
certificate families, constraint order, PSD block dimensions, and cone
partition, apart from ordinary floating-point summation differences. This
release does not make timing claims.

## Migration from v1.2

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

See the [v1.3.0 Release](https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.3.0)
for the complete migration and verification record. The v1.2.4 manual remains
the final v1.2 documentation snapshot in the version history.

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

The v1.3.0 release gate passed 424 runtime tests, including solver smoke tests
whose successful cases required `diagnostic.problem == 0`.

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
