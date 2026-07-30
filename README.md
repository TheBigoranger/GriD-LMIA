# PD-LMI

PD-LMI is a MATLAB/YALMIP research package for modeling parameter-dependent
LMIs on tensor-product box grids. It represents known data (`pdmat`) and
continuous decision matrices (`pdvar`) in cell-local Bernstein bases, forms
rate-vertex derivatives with `rhodiff`, and exports finite certificates to
YALMIP through `pdlmi`.

Documentation and latest stable release: **v1.2.0**.

## What is new in v1.2.0

- Bernstein degree is direction-wise: `Degree=[d1 ... dell]`. A scalar remains
  shorthand and is expanded uniformly; explicitly using that shorthand in a
  multidimensional constructor emits a warning.
- Tensor coefficient counts are `prod(Degree + 1)`. Alignment uses the
  componentwise maximum, multiplication adds degrees componentwise, and
  elevation accepts direction-wise increments.
- A zero-degree axis means that the object is constant in that direction.
  `rhodiff` preserves a common tensor degree by exact elevation.
- `PolyaDegree`, `PutinarOrder`, `SparseFullBoxOrder`, and `FullBoxOrder`
  accept scalar shorthand or per-axis vectors. `BandWidth` remains scalar.

See the [v1.2.0 Release](https://github.com/TheBigoranger/PD-LMI-package/releases/tag/v1.2.0)
for the complete verification record.

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
`Degree` is stored as the row vector `[1 2]`; using `Degree=2` on this
two-parameter grid would request the uniform degree `[2 2]` and emit the
documented scalar-expansion warning.

## Certificate choices

Direct coefficient inequalities are the default. Alternative finite
certificates are explicit and replace the current certificate selection:

| Certificate | Selection | Role |
| --- | --- | --- |
| Direct | `P >= A` | Coefficient-wise Bernstein certificate |
| Pólya | `constraint.applyPolya([1 2])` | Direction-wise degree elevation before coefficient tests |
| Putinar | `constraint.applyPutinar([2 3])` | Box quadratic-module Gram certificate |
| SparseFullBox | `constraint.applySparseFullBoxPreorder(2, [2 3])` | Band-limited tensor-window Gram certificate |
| FullBox | `constraint.applyFullBoxPreorder([2 3])` | Dense full-box preordering |

These are sufficient certificates. Failure of one finite certificate does not
prove that the original continuous-domain inequality is infeasible. Always
accept solver results or recovered objectives only after checking
`solution.problem == 0`.

## Current boundaries

- Grids are tensor products of one-dimensional box partitions.
- Decision expressions are affine in YALMIP variables; products with decision
  dependence on both sides are rejected.
- Putinar, SparseFullBox, and FullBox are box-specific fixed-order
  constructions, not a general SOS parser.
- Function-only `pdmat` data need explicit Bernstein coefficient evidence
  before coefficient algebra or certificate assembly.
- YALMIP owns objectives, solver selection, optimization, and diagnostics.

## Verify a checkout

Run the complete MATLAB runtime suite from the repository root:

```matlab
results = tests.run_all();
assert(all([results.Passed]))
```

## Documentation

- [Web manual](https://thebigoranger.github.io/PD-LMI-package/)
- [Printable manual (PDF)](https://thebigoranger.github.io/PD-LMI-package/manual.pdf)
- [Install and download](https://thebigoranger.github.io/PD-LMI-package/install/)
- [Reference index](https://thebigoranger.github.io/PD-LMI-package/documents/reference-index/)
- [Version history](https://thebigoranger.github.io/PD-LMI-package/version-history/)
- [GitHub Releases](https://github.com/TheBigoranger/PD-LMI-package/releases)

The printable manual source is in `doc/`; the Astro/Starlight Web manual is in
`webpage/`.
