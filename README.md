# PD-LMI Package

PD-LMI is a MATLAB/YALMIP research package for parameter-dependent LMIs.
It represents continuous piecewise-polynomial decision matrices in cell-local
tensor-product Bernstein bases on a user grid. Derivative- and rate-bearing
models are called differentiable parameter-dependent LMIs (DPD-LMIs).

Current release: **v1.1.0**.

The current implementation provides:

- `pdbase` as the backend parent for tensor-grid metadata, nested `LocalValues`, local Bernstein labels, coefficient inspection, and the shared matrix protocols and operations inherited by `pdmat` and `pdvar`.
- `pdmat` for known finite real matrix data from coefficient grids, explicit local values, or exact function handles.
- `pdvar` for arbitrary-degree continuous YALMIP-backed Bernstein decision
  expressions whose neighboring cells share boundary values.
- `rhodiff` for discontinuous rate-vertex derivative expressions.
- `pdlmi` for direct equality constraints and direct, Pólya-elevated, Putinar
  box, SparseFullBox tensor-window, or dense full-box-preordering inequality
  assembly with `toYalmip` handoff.
- `bernsteinTable` methods on both `pdmat` and `pdvar` for command-window
  inspection of local Bernstein coefficient rows.

## Why Bernstein Form?

On each physical parameter cell, the Bernstein basis is nonnegative and sums
to one. A matrix-valued Bernstein polynomial is therefore a convex combination
of its local coefficient matrices, so coefficient-wise semidefinite
inequalities give a safe finite certificate over the whole cell. The
certificate is sufficient, not necessary: a failed coefficient test does not
by itself prove that the continuous PD-LMI is infeasible. The manual and
website background explain tensor-product storage, coefficient convolution,
derivatives, degree elevation, subdivision, and the current refinement
boundary.

## Requirements

- MATLAB.
- A complete YALMIP installation already on the current MATLAB path.
- One working SDP solver visible to YALMIP. The installer probes MOSEK,
  COPT, SeDuMi, SDPT3, then LMILAB in that order; it does not download
  dependencies or obtain solver licenses.

## Installation

From MATLAB with YALMIP already on the path, run the one-shot installer:

```matlab
report = install_pd_lmi();
```

The report records `PackageRoot`, `YALMIPRoot`, the working `Solver`, newly
`AddedPaths`, and whether the path was `Persisted`. Installation stops without
saving any path change when YALMIP is missing or incomplete, no supported SDP
solver completes its bounded probe, another PD-LMI class shadows this package,
or `savepath` fails. The installer never edits `startup.m` or changes your
solver defaults. It adds only the repository root at the end of the MATLAB
path; MATLAB resolves the class, package, and private directories from that
root, so the installer does not recursively traverse documentation, Web, or
dependency trees. Repeated calls are idempotent.

## Verification

Run the current test suite from MATLAB:

```matlab
results = tests.run_all();
```

The test entry point covers installer behavior, helper utilities, `pdbase`,
`pdmat`, `pdvar`, and `pdlmi`. Its solver smoke tests use the same
commercial-first working-solver policy as `install_pd_lmi`.

## Quick Start

Known scalar data:

```matlab
A = pdmat({[0 1]}, {1, 3}, Degree=1);
T = bernsteinTable(A, "oneLine");
disp(T)
```

MATLAB output:

```text
    CellSubscript      Expression
    _____________    _______________

        {[1]}        "(1-alpha)*1 + alpha*3"
```

Inspect a YALMIP-backed decision expression:

```matlab
yalmip('clear')
P = pdvar(1, {[0 1]});
T = bernsteinTable(P, "oneLine");
disp(T)
```

The `pdmat/bernsteinTable` and `pdvar/bernsteinTable` reference pages document
the full table columns, physical-cell selectors, rate-vertex rows, and the
`"oneLine"` option.

YALMIP-backed decision expression and direct LMI assembly:

```matlab
yalmip('clear')
P = pdvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
```

`F` can be used with ordinary YALMIP calls such as `optimize(F, objective, sdpsettings(...))`.

## Comparison Semantics

For `P >= Q` and `P <= Q`, PD-LMI inspects every original coefficient in
every physical cell and active rate row. The complete relation is
semidefinite only when all coefficients are square and Hermitian; otherwise,
the complete relation is entry-wise and emits
`pdlmi:ElementwiseInequality`. Entry-wise inequalities support direct, Pólya,
Putinar, SparseFullBox, and full-box certificates, with independent scalar
certificates in MATLAB column-major entry order. Numeric comparisons include
the boundary at the package tolerance of `1e-10`.

`P == Q` creates direct coefficient equalities. Rectangular and non-Hermitian
matrices are supported, and compatible derivative expressions compare every
matching rate row. Equality does not accept certificate selectors or
`applyPolya`, `applyPutinar`, `applySparseFullBoxPreorder`, or
`applyFullBoxPreorder`; `P == P` exports an empty constraint collection. Use
`isequal(P,Q)` when the intent is structural object comparison rather than
constraint construction.

Incompatible equality row structures raise `pdvar:InvalidEqualityRows`, and
any equality certificate request raises `pdlmi:UnsupportedEqualityCertificate`.

```matlab
yalmip('clear')
X = pdvar([2 3], {[0 1]}, "full");
entrywise = X >= 0;
equalities = X == zeros(2, 3);
F = [entrywise.toYalmip(), equalities.toYalmip()];
```

See the online [`pdvar` comparison reference](https://thebigoranger.github.io/PD-LMI-package/documents/reference/pdvar/comparisons/)
and [`pdlmi` reference](https://thebigoranger.github.io/PD-LMI-package/documents/reference/pdlmi/)
for constraint counts, certificate behavior, validation errors, and derivative-row rules.

## Opt-in Pólya Certificate

Direct coefficient-wise assembly remains the default. `UsePolya` elevates the
stored residual by `PolyaDegree` in every parameter direction before applying
the same coefficient-wise constraints; the bare flag selects an increment of
one.

```matlab
yalmip('clear')
P = pdvar(2, {[0 1]}, "symmetric", Degree=2);
direct = P <= 0;
polya = direct.applyPolya(1);
```

The same selection can be supplied to `pdlmi` as a bare or logical option,
for example `pdlmi(P, "<=", "UsePolya")` or
`pdlmi(P, "<=", UsePolya=true, PolyaDegree=1)`.
`applyPolya()` returns a new value object and rebuilds from the original
residual, so repeated calls replace rather than compound the selected
increment. This is a sufficient certificate, not an infeasibility test.

## Opt-in Putinar Box Certificate

`applyPutinar([order])` replaces direct, Pólya, SparseFullBox, or full-box
assembly with a cell-local quadratic-module certificate for every physical
cell and active rate row. At absolute tensor order `r`, it represents the
sign-normalized target as

```text
S0 + sum_s alpha_s(1-alpha_s) Ss
```

using an order-`r` Bernstein Gram basis for `S0` and an order-`r-e_s` basis
for each `Ss`. Coefficients are matched exactly at tensor degree `2*r`. The
one-parameter default and minimum is `floor(Residual.Degree/2)`, using the
parity-specific Markov–Lukács form. For two or more parameters, the default
and minimum is `ceil(Residual.Degree/2)`. The method adds no implicit
positivity margin and does not call a solver.

```matlab
yalmip('clear')
P = pdvar(2, {[0 1]}, "symmetric", Degree=3);
direct = P >= 0;
putinar = direct.applyPutinar(2);
F = putinar.toYalmip();
```

The constructor forms `pdlmi(P, ">=", "UsePutinar")`,
`pdlmi(P, ">=", UsePutinar=true, PutinarOrder=2)`, and
`pdlmi(P, ">=", PutinarOrder=2)` select the same certificate family. A new
Pólya, Putinar, SparseFullBox, or full-box selection always rebuilds from the
original residual and replaces the previous family.

## Opt-in SparseFullBox Hierarchy

`applySparseFullBoxPreorder([bandWidth[, order]])` interpolates between the
direct coefficient certificate and the dense Full Box certificate with free
PSD tensor-window cliques. The no-argument form uses `BandWidth=2` and the
same dimension-dependent absolute order as Full Box. Every window contribution
is embedded and matched exactly in the cell-local Bernstein basis; matrix
entries, physical cells, and active rate rows receive independent
certificates.

```matlab
yalmip('clear')
P = pdvar(2, {[0 1]}, "symmetric", Degree=4);
direct = P >= 0;
sparse = direct.applySparseFullBoxPreorder(2, 2);
F = sparse.toYalmip();
```

The constructor forms
`pdlmi(P, ">=", "UseSparseFullBoxPreorder")`,
`pdlmi(P, ">=", BandWidth=2)`, and
`pdlmi(P, ">=", BandWidth=2, SparseFullBoxOrder=2)` select the same family.
Width one normalizes to actual Direct state. A width at least `order+1`
normalizes to actual dense Full Box state. Only intermediate widths retain
`UseSparseFullBoxPreorder=true`, `SparseFullBoxOrder`, and `BandWidth`.
SparseFullBox is a box-specific sufficient certificate, not a generic sparse
SOS parser or an automatic solver-selection layer.

## Opt-in Full Box Preordering

`applyFullBoxPreorder([order])` replaces direct, Pólya, Putinar, or
SparseFullBox assembly with a cell-local dense Bernstein–Gram certificate for
every physical cell and active rate row. In one parameter it uses the
parity-specific Markov–Lukács form; in multiple parameters it includes every
subset product of the box generators `alpha_s(1-alpha_s)` at the selected
absolute order. It is not a general SOS parser and adds no implicit strictness
margin.

```matlab
yalmip('clear')
P = pdvar(2, {[0 1]}, "symmetric", Degree=2);
direct = P >= 0;
preorder = direct.applyFullBoxPreorder();
F = preorder.toYalmip();
```

## Documentation

- Online manual: https://thebigoranger.github.io/PD-LMI-package/
- Bernstein and PD-LMI background: https://thebigoranger.github.io/PD-LMI-package/documents/math/bernstein-polynomial/
- Install and downloads: https://thebigoranger.github.io/PD-LMI-package/install/
- Release v1.1.0: https://github.com/TheBigoranger/PD-LMI-package/releases/tag/v1.1.0
- Version history: https://thebigoranger.github.io/PD-LMI-package/version-history/
- Solver smoke examples: https://thebigoranger.github.io/PD-LMI-package/examples/solver-smoke/
- `applyPutinar` reference: https://thebigoranger.github.io/PD-LMI-package/documents/reference/pdlmi/applyputinar/
- `applySparseFullBoxPreorder` reference: https://thebigoranger.github.io/PD-LMI-package/documents/reference/pdlmi/applysparsefullboxpreorder/
- `pdvar` comparisons: https://thebigoranger.github.io/PD-LMI-package/documents/reference/pdvar/comparisons/
- `pdlmi` reference: https://thebigoranger.github.io/PD-LMI-package/documents/reference/pdlmi/
- `pdmat/plot` output examples: https://thebigoranger.github.io/PD-LMI-package/documents/reference/pdmat/plot/
- Reference lookup table: https://thebigoranger.github.io/PD-LMI-package/documents/reference-index/
- Local PDF manual: `doc/manual.pdf`
- Manual source: `doc/manual.tex`

The local manual is the most complete reference: Bernstein background appears
before setup, and each class chapter starts with lookup tables before detailed
MATLAB-style function pages. The GitHub Pages source lives in `webpage/` and is
built with npm, Astro, and Starlight.

## Scope Boundaries

- Direct, Pólya, Putinar, SparseFullBox, and full-box assembly are sufficient
  finite certificates; a failed certificate does not prove continuous PD-LMI
  infeasibility.
- Package-owned solver wrappers, strictness-margin diagnostics, residual
  evidence, general-domain generator parsing, and general SOS hierarchies
  remain future layers. The implemented Putinar, SparseFullBox, and full-box
  certificates are box-specific fixed-order assemblies and are cross-validated
  outside the ordinary runtime suite.
- `pdbase` is backend architecture context, not the primary modeling API.
  Centralized matrix-operation implementations remain fully documented as
  public `pdmat` and `pdvar` behavior.
- Function-only `pdmat` objects without explicit Bernstein evidence do not enter coefficient algebra.
