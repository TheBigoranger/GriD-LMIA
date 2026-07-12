# DP-LMI Package

DP-LMI is a MATLAB/YALMIP research package for differential parameter-dependent LMIs using cell-local Bernstein polynomial storage.

The current implementation provides:

- `dpbase` as the backend parent for tensor-grid metadata, nested `LocalValues`, local Bernstein labels, and coefficient inspection.
- `dpmat` for known finite real matrix data from coefficient grids, explicit local values, or exact function handles.
- `dpvar` for continuous YALMIP-backed Bernstein decision expressions.
- `rhodiff` for discontinuous rate-vertex derivative expressions.
- `dplmi` for direct or Pólya-elevated YALMIP constraint assembly and
  `toYalmip` handoff.
- `bernsteinTable` methods on both `dpmat` and `dpvar` for command-window
  inspection of local Bernstein coefficient rows.

## Why Bernstein Form?

On each physical parameter cell, the Bernstein basis is nonnegative and sums
to one. A matrix-valued Bernstein polynomial is therefore a convex combination
of its local coefficient matrices, so coefficient-wise semidefinite
inequalities give a safe finite certificate over the whole cell. The
certificate is sufficient, not necessary: a failed coefficient test does not
by itself prove that the continuous DP-LMI is infeasible. The manual and
website background explain tensor-product storage, coefficient convolution,
derivatives, degree elevation, subdivision, and the current refinement
boundary.

## Requirements

- MATLAB.
- YALMIP on the MATLAB path for `dpvar` and `dplmi` workflows.
- An SDP solver supported by YALMIP when solving assembled constraints.

## Installation

From MATLAB, add the package root recursively and remove the documentation folder from the path:

```matlab
projectRoot = "path/to/Differential Parameter-Dependent Linear Matrix Inequality";
addpath(genpath(projectRoot));
rmpath(genpath(fullfile(projectRoot, "doc")));
```

## Verification

Run the current test suite from MATLAB:

```matlab
results = tests.run_all();
```

The test entry point covers helper utilities, `dpbase`, `dpmat`, `dpvar`, and `dplmi`. The YALMIP-backed tests require YALMIP to be available.

## Quick Start

Known scalar data:

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
T = bernsteinTable(A, "oneLine");
disp(T)
```

MATLAB output:

```text
    CellSubscript      Expression
    _____________    _______________

        {[1]}        "a*1 + (1-a)*3"
```

Inspect a YALMIP-backed decision expression:

```matlab
yalmip('clear')
P = dpvar(1, {[0 1]});
T = bernsteinTable(P, "oneLine");
disp(T)
```

The `dpmat/bernsteinTable` and `dpvar/bernsteinTable` reference pages document
the full table columns, physical-cell selectors, rate-vertex rows, and the
`"oneLine"` option.

YALMIP-backed decision expression and direct LMI assembly:

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
```

`F` can be used with ordinary YALMIP calls such as `optimize(F, objective, sdpsettings(...))`.

## Opt-in Pólya Certificate

Direct coefficient-wise assembly remains the default. `UsePolya` elevates the
stored residual by `PolyaDegree` in every parameter direction before applying
the same coefficient-wise constraints; the bare flag selects an increment of
one.

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric", Degree=2);
direct = P <= 0;
polya = direct.applyPolya(1);
```

The same selection can be supplied to `dplmi` as a bare or logical option,
for example `dplmi(P, "<=", "UsePolya")` or
`dplmi(P, "<=", UsePolya=true, PolyaDegree=1)`.
`applyPolya()` returns a new value object and rebuilds from the original
residual, so repeated calls replace rather than compound the selected
increment. This is a sufficient certificate, not an infeasibility test.

## Documentation

- Online manual: https://thebigoranger.github.io/DP-LMI-package/
- Bernstein and DP-LMI background: https://thebigoranger.github.io/DP-LMI-package/documents/math/bernstein-polynomial/
- Install and downloads: https://thebigoranger.github.io/DP-LMI-package/install/
- Version history: https://thebigoranger.github.io/DP-LMI-package/version-history/
- Solver smoke examples: https://thebigoranger.github.io/DP-LMI-package/examples/solver-smoke/
- `dpmat/plot` output examples: https://thebigoranger.github.io/DP-LMI-package/documents/reference/dpmat/plot/
- Reference lookup table: https://thebigoranger.github.io/DP-LMI-package/documents/reference-index/
- Local PDF manual: `doc/manual.pdf`
- Manual source: `doc/manual.tex`

The local manual is the most complete reference: Bernstein background appears
before setup, and each class chapter starts with lookup tables before detailed
MATLAB-style function pages. The GitHub Pages source lives in `webpage/` and is
built with npm, Astro, and Starlight.

## Current Limitations

- Direct and Pólya assembly are sufficient finite certificates;
  a failed certificate does not prove continuous DP-LMI infeasibility.
- Package-owned solver wrappers, strictness-margin diagnostics, residual
  evidence, SOS, and additional relaxation variants are future layers.
- `dpbase` is backend architecture context, not the primary modeling API.
- Function-only `dpmat` objects without explicit Bernstein evidence do not enter coefficient algebra.
