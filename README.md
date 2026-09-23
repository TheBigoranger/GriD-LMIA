# GriD-LMIA

**Gri**dding-based **D**PD-**LMI A**ssembler (GriD-LMIA) is a MATLAB/YALMIP
research package for modeling parameter-dependent LMIs on tensor-product box
grids. It represents known data (`pdmat`) and decision matrices
(`pdvar`) in cell-wise Bernstein bases, forms
rate-vertex derivatives with `rhodiff`, and exports finite certificates to
YALMIP through `pdlmi`.

Current source and documentation: **v1.5.0**. Latest tagged GitHub Release:
**v1.5.0**.

## What changed in v1.5.0

- `Continuity` records a direction-wise continuity lower bound, with `-1`
  denoting no C0 guarantee and `Inf` denoting a global polynomial in that
  direction. Constructors accept scalar shorthand or one order per direction.
  The public `pdmat` and `pdvar` constructors require nonnegative orders or `Inf`.
  `IsContinuous` is derived from these orders.
- Decision construction retains C0 as the default and supports higher-order
  continuity through spline controls and cell-wise Bernstein extraction.
  These controls generally are not function values at grid nodes.
- Known coefficient data infer continuity, while an explicit order requests a
  verified lower bound. Differentiation, algebra, indexing, and numeric recovery
  now carry the corresponding direction-wise continuity information.
- Common-grid alignment restricts existing coefficients to each target cell.
  This preserves discontinuities without fitting across a source-cell boundary.
  Affine derivative combinations and degree-zero-factor products also use
  specialized assembly paths.
- Both manuals explain the supported forms, examples, and limitations against
  the current source. The v1.5.0 release includes the accepted printable manual.

## What changed in v1.4.3

- The runtime suite now contains 809 tests in 141 files, with at least three
  distinct cases per file. It checks composed tensor-grid workflows, affine
  variable identities, certificate replacement, and invalid-use boundaries.
- Function-only `pdmat` operands reject coefficient-dependent arithmetic,
  including zero products and cancellation. Exact evaluation, inspection,
  and plotting remain available; explicitly degree-validated function sources
  retain supported coefficient arithmetic.
- Products of two operands with active rate rows are rejected even when their
  values are zero. Evaluation with one fixed rate row returns a `1x1` cell,
  consistently with the rate-row output contract.
- `bernTable` accepts multiple physical-cell selectors in a numeric or cell
  array, preserves their requested order, and removes later duplicates.
  `coeffs` continues to select one physical cell.
- Both manuals explain these boundaries. Web displays preserve native script
  proportions and scale complete formulas to no less than 85% on narrow
  screens, with formula-local scrolling when needed.

## What changed in v1.4.2

- Scalar `pdlmi` wrappers can be concatenated horizontally or vertically with
  other wrappers and native YALMIP `constraint` or `lmi` lists. Concatenation
  exports each wrapper in written order and returns a terminal YALMIP list.
- Certificate selection remains a wrapper operation and must occur before
  concatenation. Unsupported operands, logical known-data certificates, and
  nonscalar wrapper arrays fail with `pdlmi:InvalidConcatenation`.
- The root [`example/`](example/) catalog provides seven source-grounded cases
  from the GriD-LMIA software paper, a delay-system paper, ROLMIP, and a control
  systems textbook. Each script records its source, settings, tunable values,
  solver diagnostics, and numerical comparison.
- Example filenames now use problem-oriented semantic names. Authors, years,
  publication numbering, certificate choices, and tunable numerical settings
  remain in the script headers and catalog rather than the paths.
- The printable and Web manuals document the new API and examples. The public
  inventory now contains 194 symbols.

The earlier tagged v1.4.0 release introduced the mixed `sdpvar`/`pdmat`
multiplication feature described in its release notes.

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
- A zero-degree axis makes each cell polynomial constant in that direction.
  Known nested data may still jump between cells. Decision construction shares
  that constant across the direction to satisfy its continuity requirement.
  `rhodiff` preserves a common tensor degree by exact elevation.
- `PolyaDegree`, `PutinarOrder`, `SparseFullBoxOrder`, and `FullBoxOrder`
  accept scalar shorthand or per-axis vectors. `BandWidth` remains scalar.

See the [v1.5.0 Release](https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.5.0)
for the latest immutable package snapshot. The v1.4.3, v1.3.8, and v1.2.4
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
- Function-only `pdmat` reports unknown continuity and rejects an explicit
  `Continuity` request. Known-data seam checks use a numerical tolerance.
- YALMIP owns objectives, solver selection, optimization, and diagnostics.

## Verify a checkout

Run the complete MATLAB runtime suite from the repository root:

```matlab
results = tests.run_all();
assert(all([results.Passed]) && ~any([results.Incomplete]))
```

The v1.5.0 source gate passed 848 runtime tests with zero failures and zero
incompletes, including the traceability gate for 171 public API entries.
`tests.run_coverage()` also passed the same 848 tests and measured
3626/3746 statements (96.80%) and 1853/1964 decisions (94.35%), above the
unchanged percentage baselines of 3325/3442 and 1671/1782. Feasible solver
checks used MOSEK and required `diagnostic.problem == 0`, finite values, and
independent normalized residuals no greater than `1e-7`. Infeasible controls
were also retained. These correctness checks do not establish a speedup for
every workload.

Run the independent MATLAB SOS validation from the repository root:

```matlab
run("sos_validation/matlab/tests/run_tests.m")
```

Run the independent Julia/SumOfSquares validation with:

```text
julia --project=sos_validation/julia sos_validation/julia/run_all.jl
```

The earlier release gate passed 54 MATLAB SOS tests and 231 Julia SOS tests.
These optional external comparisons were not run again for v1.5.0. On a
Windows system that blocks cached Julia extension DLLs, use the same command
with `--compiled-modules=no` after `julia`.

## Documentation

- [Web manual](https://thebigoranger.github.io/GriD-LMIA/)
- [Printable manual (PDF)](https://thebigoranger.github.io/GriD-LMIA/manual.pdf)
- [Install and download](https://thebigoranger.github.io/GriD-LMIA/install/)
- [Reference index](https://thebigoranger.github.io/GriD-LMIA/documents/reference-index/)
- [Version history](https://thebigoranger.github.io/GriD-LMIA/version-history/)
- [GitHub Releases](https://github.com/TheBigoranger/GriD-LMIA/releases)

The public repository delivers the printable manual at `doc/manual.pdf`; its
TeX sources remain in the local-complete development worktree. The
Astro/Starlight Web manual source is in `webpage/`.

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
