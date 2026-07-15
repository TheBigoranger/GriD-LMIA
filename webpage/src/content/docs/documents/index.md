---
title: Documents
description: Reference-first entry point for PD-LMI classes, methods, and mathematical background.
---

Use this page as the lookup entry for current PD-LMI behavior. The reference
pages document implemented code only, including direct, opt-in Pólya,
fixed-order Putinar box, and fixed-order full-box preordering assembly. Validation and limitations appear
beside the constructor or method they affect.

PD-LMI means **parameter-dependent LMI**. The package represents continuous
piecewise-polynomial matrix functions on physical grid cells in a cell-local
tensor-product Bernstein basis. `pdvar` shares complete face values between
adjacent cells; differentiation remains cell-local, so the representation is
not a B-spline and does not assert global differentiability. Use **DPD-LMI**
only for a differentiable PD-LMI with explicit derivative and rate terms.

## Reference Index

| Object | Start here | Common tasks |
| :--- | :--- | :--- |
| `pdmat` | [`pdmat` overview](/PD-LMI-package/documents/reference/pdmat/) | [`constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/), [`evaluate`](/PD-LMI-package/documents/reference/pdmat/evaluate/), [`plot`](/PD-LMI-package/documents/reference/pdmat/plot/), [`bernsteinTable`](/PD-LMI-package/documents/reference/pdmat/bernsteintable/), [`matrix operations`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/) |
| `pdvar` | [`pdvar` overview](/PD-LMI-package/documents/reference/pdvar/) | [`constructor`](/PD-LMI-package/documents/reference/pdvar/constructor/), [`rhodiff`](/PD-LMI-package/documents/reference/pdvar/rhodiff/), [`bernsteinTable`](/PD-LMI-package/documents/reference/pdvar/bernsteintable/), [`matrix operations`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/), [`comparisons`](/PD-LMI-package/documents/reference/pdvar/comparisons/) |
| `pdlmi` | [`pdlmi` overview](/PD-LMI-package/documents/reference/pdlmi/) | [`constructor`](/PD-LMI-package/documents/reference/pdlmi/constructor/), [`applyPolya`](/PD-LMI-package/documents/reference/pdlmi/applypolya/), [`applyPutinar`](/PD-LMI-package/documents/reference/pdlmi/applyputinar/), [`applyFullBoxPreorder`](/PD-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/), [`toYalmip`](/PD-LMI-package/documents/reference/pdlmi/toyalmip/) |
| `pdbase` | [`pdbase` overview](/PD-LMI-package/documents/reference/pdbase/) | [`storage inspection`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/) |

## Function Pages

| Function or method | Page | Use when |
| :--- | :--- | :--- |
| `pdmat(...)` | [`pdmat constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/) | Create known data from coefficients, local values, or a function handle. |
| `evaluate(A, rho)` | [`pdmat evaluate`](/PD-LMI-package/documents/reference/pdmat/evaluate/) | Sample a known matrix at one parameter point. |
| `plot(A, ...)` | [`pdmat plot`](/PD-LMI-package/documents/reference/pdmat/plot/) | Inspect one- or two-parameter data visually. |
| `bernsteinTable(A)` | [`pdmat bernsteinTable`](/PD-LMI-package/documents/reference/pdmat/bernsteintable/) | Inspect local Bernstein coefficient rows. |
| `pdvar(...)` | [`pdvar constructor`](/PD-LMI-package/documents/reference/pdvar/constructor/) | Create continuous arbitrary-degree piecewise-polynomial Bernstein decision variables. |
| `rhodiff(P)` | [`pdvar rhodiff`](/PD-LMI-package/documents/reference/pdvar/rhodiff/) | Build rate-vertex derivative expressions. |
| `P <= 0`, `P >= 0` | [`pdvar comparisons`](/PD-LMI-package/documents/reference/pdvar/comparisons/) | Create `pdlmi` constraints from residual expressions. |
| `C.applyPolya([d])` | [`pdlmi applyPolya`](/PD-LMI-package/documents/reference/pdlmi/applypolya/) | Rebuild from the stored residual with a selected degree increment. |
| `C.applyPutinar([r])` | [`pdlmi applyPutinar`](/PD-LMI-package/documents/reference/pdlmi/applyputinar/) | Select the minimum or an explicit absolute Putinar box order. |
| `C.applyFullBoxPreorder([r])` | [`pdlmi applyFullBoxPreorder`](/PD-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) | Select the minimum or an explicit absolute full-box order. |
| `toYalmip(C)` | [`pdlmi toYalmip`](/PD-LMI-package/documents/reference/pdlmi/toyalmip/) | Hand assembled constraints to YALMIP `optimize`. |

The generated [lookup table](/PD-LMI-package/documents/reference-index/) is produced from `src/data/reference-index.js` and checked during the build workflow.

The lookup table includes every public class method in the current `@pdbase`,
`@pdmat`, `@pdvar`, and `@pdlmi` folders. Grouped operator pages keep a
separate stable anchor for each symbol; backend and `+helper` entries are
listed explicitly as implementation context and are not recommended modeling
entry points.

## Mathematics

- [Bernstein Polynomial](/PD-LMI-package/documents/math/bernstein-polynomial/): history, the standard forward local coordinate, convex-hull certificates, tensor-product storage, derivatives, elevation, subdivision, multiplication, traversal, and refinement boundaries.
- [Gridding And Bernstein Degree](/PD-LMI-package/documents/math/gridding-and-degree/): diagram-led one- and two-parameter inputs, global coefficient-grid shapes, nested `LocalValues`, and the \(\ell\)-dimensional count rules.
- [SOS Certificates On A Hypercube](/PD-LMI-package/documents/math/sos-certificates/): full-space SOS background, direct Bernstein evidence, Pólya elevation, the implemented Putinar box module, Schmüdgen preorderings, one-dimensional Markov–Lukács forms, and the exact software boundary.

## Install And Examples

- [Install And Download](/PD-LMI-package/install/): tagged release, current source/manual snapshots, and MATLAB path setup.
- [Examples](/PD-LMI-package/examples/): compact workflows.
- [Solver Smoke Cases](/PD-LMI-package/examples/solver-smoke/): two tested YALMIP examples from `+tests/+pdlmi/test_solver_smoke.m`.
- [Bernstein Backend Utilities](/PD-LMI-package/documents/reference/bernstein-utilities/): protected degree, product, and grid-refinement behavior.

## Reference Page Shape

Each class page follows the same manual pattern: Purpose, Syntax, Description, Arguments or Options, Returned Object or Outputs, Examples, Validation And Errors, Limitations, and See Also.
