---
title: Documents
description: Reference-first entry point for DP-LMI classes, methods, and mathematical background.
---

Use this page as the lookup entry for current DP-LMI behavior. The reference pages document implemented code only; reserved relaxation and Polya options are listed as limitations rather than supported workflows.

## Reference Index

| Object | Start here | Common tasks |
| :--- | :--- | :--- |
| `dpmat` | [`dpmat` overview](/DP-LMI-package/documents/reference/dpmat/) | [`constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/), [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/), [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/), [`bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/), [`matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/) |
| `dpvar` | [`dpvar` overview](/DP-LMI-package/documents/reference/dpvar/) | [`constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/), [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/), [`bernsteinTable`](/DP-LMI-package/documents/reference/dpvar/bernsteintable/), [`matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/), [`comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) |
| `dplmi` | [`dplmi` overview](/DP-LMI-package/documents/reference/dplmi/) | [`constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/), [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) |
| `dpbase` | [`dpbase` overview](/DP-LMI-package/documents/reference/dpbase/) | [`storage inspection`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/) |

## Function Pages

| Function or method | Page | Use when |
| :--- | :--- |
| `dpmat(...)` | [`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) | Create known data from coefficients, local values, or a function handle. |
| `evaluate(A, rho)` | [`dpmat evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) | Sample a known matrix at one parameter point. |
| `plot(A, ...)` | [`dpmat plot`](/DP-LMI-package/documents/reference/dpmat/plot/) | Inspect one- or two-parameter data visually. |
| `bernsteinTable(A)` | [`dpmat bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/) | Inspect local Bernstein coefficient rows. |
| `dpvar(...)` | [`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) | Create continuous YALMIP-backed Bernstein decision variables. |
| `rhodiff(P)` | [`dpvar rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) | Build rate-vertex derivative expressions. |
| `P <= 0`, `P >= 0` | [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) | Create `dplmi` constraints from residual expressions. |
| `toYalmip(C)` | [`dplmi toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | Hand assembled constraints to YALMIP `optimize`. |

The generated [lookup table](/DP-LMI-package/documents/reference-index/) is produced from `src/data/reference-index.js` and checked during the build workflow.

The lookup table includes every public class method in the current `@dpbase`,
`@dpmat`, `@dpvar`, and `@dplmi` folders. Grouped operator pages keep a
separate stable anchor for each symbol; backend and `+helper` entries are
listed explicitly as implementation context and are not recommended modeling
entry points.

## Mathematics

- [Bernstein Polynomial](/DP-LMI-package/documents/math/bernstein-polynomial/): history, reversed local coordinates, convex-hull certificates, tensor-product storage, derivatives, elevation, subdivision, multiplication, traversal, and refinement boundaries.
- [Status And Limits](/DP-LMI-package/documents/status-and-limits/): centralized implemented-versus-reserved boundary for modeling, constraints, solvers, and refinement ideas.

## Install And Examples

- [Install And Download](/DP-LMI-package/install/): v0.2.0 release, tagged source ZIP, current manual snapshot, and MATLAB path setup.
- [Examples](/DP-LMI-package/examples/): compact workflows.
- [Solver Smoke Cases](/DP-LMI-package/examples/solver-smoke/): two tested YALMIP examples from `+tests/+dplmi/test_solver_smoke.m`.
- [Bernstein Backend Utilities](/DP-LMI-package/documents/reference/bernstein-utilities/): protected degree, product, and grid-refinement behavior.

## Reference Page Shape

Each class page follows the same manual pattern: Purpose, Syntax, Description, Arguments or Options, Returned Object or Outputs, Examples, Validation And Errors, Limitations, and See Also.
