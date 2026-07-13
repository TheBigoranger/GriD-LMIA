---
title: Documents
description: Reference-first entry point for DP-LMI classes, methods, and mathematical background.
---

Use this page as the lookup entry for current DP-LMI behavior. The reference
pages document implemented code only, including direct, opt-in Pólya, and
opt-in full box preordering assembly. The separate `sos_validation/` tree
contains Julia, YALMIP, SOSTOOLS, and package oracles; it is not a MATLAB
runtime dependency or a replacement for the public API.

## Reference Index

| Object | Start here | Common tasks |
| :--- | :--- | :--- |
| `dpmat` | [`dpmat` overview](/DP-LMI-package/documents/reference/dpmat/) | [`constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/), [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/), [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/), [`bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/), [`matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/) |
| `dpvar` | [`dpvar` overview](/DP-LMI-package/documents/reference/dpvar/) | [`constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/), [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/), [`bernsteinTable`](/DP-LMI-package/documents/reference/dpvar/bernsteintable/), [`matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/), [`comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) |
| `dplmi` | [`dplmi` overview](/DP-LMI-package/documents/reference/dplmi/) | [`constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/), [`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/), [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/dplmi/applyfullboxpreorder/), [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) |
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
| `C.applyPolya([d])` | [`dplmi applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) | Rebuild from the stored residual with a selected degree increment. |
| `C.applyFullBoxPreorder([r])` | [`dplmi applyFullBoxPreorder`](/DP-LMI-package/documents/reference/dplmi/applyfullboxpreorder/) | Select the minimum or an explicit absolute full-box order. |
| `toYalmip(C)` | [`dplmi toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | Hand assembled constraints to YALMIP `optimize`. |

The generated [lookup table](/DP-LMI-package/documents/reference-index/) is produced from `src/data/reference-index.js` and checked during the build workflow.

The lookup table includes every public class method in the current `@dpbase`,
`@dpmat`, `@dpvar`, and `@dplmi` folders. Grouped operator pages keep a
separate stable anchor for each symbol; backend and `+helper` entries are
listed explicitly as implementation context and are not recommended modeling
entry points.

## Mathematics

- [Bernstein Polynomial](/DP-LMI-package/documents/math/bernstein-polynomial/): history, the standard forward local coordinate, convex-hull certificates, tensor-product storage, derivatives, elevation, subdivision, multiplication, traversal, and refinement boundaries.
- [Gridding And Bernstein Degree](/DP-LMI-package/documents/math/gridding-and-degree/): diagram-led one- and two-parameter inputs, global coefficient-grid shapes, nested `LocalValues`, and the \(\ell\)-dimensional count rules.
- [Status And Limits](/DP-LMI-package/documents/status-and-limits/): centralized implemented-versus-reserved boundary for modeling, constraints, solvers, and refinement ideas.

The repository also contains an optional, isolated
[SOS validation suite](https://github.com/TheBigoranger/DP-LMI-package/tree/main/sos_validation).
It exchanges versioned benchmark evidence across the independent backends but
does not extend the public DP-LMI API.

## Install And Examples

- [Install And Download](/DP-LMI-package/install/): v0.2.0 release, tagged source ZIP, current manual snapshot, and MATLAB path setup.
- [Examples](/DP-LMI-package/examples/): compact workflows.
- [Solver Smoke Cases](/DP-LMI-package/examples/solver-smoke/): two tested YALMIP examples from `+tests/+dplmi/test_solver_smoke.m`.
- [Bernstein Backend Utilities](/DP-LMI-package/documents/reference/bernstein-utilities/): protected degree, product, and grid-refinement behavior.

## Reference Page Shape

Each class page follows the same manual pattern: Purpose, Syntax, Description, Arguments or Options, Returned Object or Outputs, Examples, Validation And Errors, Limitations, and See Also.
