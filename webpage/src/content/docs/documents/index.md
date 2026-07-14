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
| `pdmat` | [`pdmat` overview](/DP-LMI-package/documents/reference/pdmat/) | [`constructor`](/DP-LMI-package/documents/reference/pdmat/constructor/), [`evaluate`](/DP-LMI-package/documents/reference/pdmat/evaluate/), [`plot`](/DP-LMI-package/documents/reference/pdmat/plot/), [`bernsteinTable`](/DP-LMI-package/documents/reference/pdmat/bernsteintable/), [`matrix operations`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/) |
| `pdvar` | [`pdvar` overview](/DP-LMI-package/documents/reference/pdvar/) | [`constructor`](/DP-LMI-package/documents/reference/pdvar/constructor/), [`rhodiff`](/DP-LMI-package/documents/reference/pdvar/rhodiff/), [`bernsteinTable`](/DP-LMI-package/documents/reference/pdvar/bernsteintable/), [`matrix operations`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/), [`comparisons`](/DP-LMI-package/documents/reference/pdvar/comparisons/) |
| `pdlmi` | [`pdlmi` overview](/DP-LMI-package/documents/reference/pdlmi/) | [`constructor`](/DP-LMI-package/documents/reference/pdlmi/constructor/), [`applyPolya`](/DP-LMI-package/documents/reference/pdlmi/applypolya/), [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/), [`toYalmip`](/DP-LMI-package/documents/reference/pdlmi/toyalmip/) |
| `pdbase` | [`pdbase` overview](/DP-LMI-package/documents/reference/pdbase/) | [`storage inspection`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/) |

## Function Pages

| Function or method | Page | Use when |
| :--- | :--- | :--- |
| `pdmat(...)` | [`pdmat constructor`](/DP-LMI-package/documents/reference/pdmat/constructor/) | Create known data from coefficients, local values, or a function handle. |
| `evaluate(A, rho)` | [`pdmat evaluate`](/DP-LMI-package/documents/reference/pdmat/evaluate/) | Sample a known matrix at one parameter point. |
| `plot(A, ...)` | [`pdmat plot`](/DP-LMI-package/documents/reference/pdmat/plot/) | Inspect one- or two-parameter data visually. |
| `bernsteinTable(A)` | [`pdmat bernsteinTable`](/DP-LMI-package/documents/reference/pdmat/bernsteintable/) | Inspect local Bernstein coefficient rows. |
| `pdvar(...)` | [`pdvar constructor`](/DP-LMI-package/documents/reference/pdvar/constructor/) | Create continuous YALMIP-backed Bernstein decision variables. |
| `rhodiff(P)` | [`pdvar rhodiff`](/DP-LMI-package/documents/reference/pdvar/rhodiff/) | Build rate-vertex derivative expressions. |
| `P <= 0`, `P >= 0` | [`pdvar comparisons`](/DP-LMI-package/documents/reference/pdvar/comparisons/) | Create `pdlmi` constraints from residual expressions. |
| `C.applyPolya([d])` | [`pdlmi applyPolya`](/DP-LMI-package/documents/reference/pdlmi/applypolya/) | Rebuild from the stored residual with a selected degree increment. |
| `C.applyFullBoxPreorder([r])` | [`pdlmi applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) | Select the minimum or an explicit absolute full-box order. |
| `toYalmip(C)` | [`pdlmi toYalmip`](/DP-LMI-package/documents/reference/pdlmi/toyalmip/) | Hand assembled constraints to YALMIP `optimize`. |

The generated [lookup table](/DP-LMI-package/documents/reference-index/) is produced from `src/data/reference-index.js` and checked during the build workflow.

The lookup table includes every public class method in the current `@pdbase`,
`@pdmat`, `@pdvar`, and `@pdlmi` folders. Grouped operator pages keep a
separate stable anchor for each symbol; backend and `+helper` entries are
listed explicitly as implementation context and are not recommended modeling
entry points.

## Mathematics

- [Bernstein Polynomial](/DP-LMI-package/documents/math/bernstein-polynomial/): history, the standard forward local coordinate, convex-hull certificates, tensor-product storage, derivatives, elevation, subdivision, multiplication, traversal, and refinement boundaries.
- [Gridding And Bernstein Degree](/DP-LMI-package/documents/math/gridding-and-degree/): diagram-led one- and two-parameter inputs, global coefficient-grid shapes, nested `LocalValues`, and the \(\ell\)-dimensional count rules.
- [SOS Certificates On A Hypercube](/DP-LMI-package/documents/math/sos-certificates/): full-space SOS, direct Bernstein evidence, Pólya elevation, Putinar quadratic modules, Schmüdgen preorderings, one-dimensional Markov–Lukács forms, and the exact software boundary.
- [Status And Limits](/DP-LMI-package/documents/status-and-limits/): centralized implemented-versus-reserved boundary for modeling, constraints, solvers, and refinement ideas.

The repository also contains an optional, isolated
[SOS validation suite](https://github.com/TheBigoranger/DP-LMI-package/tree/main/sos_validation).
It exchanges versioned benchmark evidence across the independent backends but
does not extend the public DP-LMI API.

## Install And Examples

- [Install And Download](/DP-LMI-package/install/): tagged release, current source/manual snapshots, and MATLAB path setup.
- [Examples](/DP-LMI-package/examples/): compact workflows.
- [Solver Smoke Cases](/DP-LMI-package/examples/solver-smoke/): two tested YALMIP examples from `+tests/+pdlmi/test_solver_smoke.m`.
- [Bernstein Backend Utilities](/DP-LMI-package/documents/reference/bernstein-utilities/): protected degree, product, and grid-refinement behavior.

## Reference Page Shape

Each class page follows the same manual pattern: Purpose, Syntax, Description, Arguments or Options, Returned Object or Outputs, Examples, Validation And Errors, Limitations, and See Also.
