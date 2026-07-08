---
title: Documents
description: Reference-first entry point for DP-LMI classes, methods, and mathematical background.
---

Use this page as the lookup entry for current DP-LMI behavior. The reference pages document implemented code only; reserved relaxation and Polya options are listed as limitations rather than supported workflows.

## Reference Index

| Object | Start here | Common tasks |
| :--- | :--- | :--- |
| `dpmat` | [`dpmat` overview](/DP-LMI-package/documents/reference/dpmat/) | [`constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/), [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/), [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/), [`table`](/DP-LMI-package/documents/reference/dpmat/table/), [`matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/) |
| `dpvar` | [`dpvar` overview](/DP-LMI-package/documents/reference/dpvar/) | [`constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/), [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/), [`matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/), [`comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) |
| `dplmi` | [`dplmi` overview](/DP-LMI-package/documents/reference/dplmi/) | [`constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/), [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) |
| `dpbase` | [`dpbase` overview](/DP-LMI-package/documents/reference/dpbase/) | [`storage inspection`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/) |

## Function Pages

| Function or method | Page | Use when |
| :--- | :--- |
| `dpmat(...)` | [`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) | Create known data from coefficients, local values, or a function handle. |
| `evaluate(A, rho)` | [`dpmat evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) | Sample a known matrix at one parameter point. |
| `plot(A, ...)` | [`dpmat plot`](/DP-LMI-package/documents/reference/dpmat/plot/) | Inspect one- or two-parameter data visually. |
| `table(A)` | [`dpmat table`](/DP-LMI-package/documents/reference/dpmat/table/) | Inspect local Bernstein coefficient rows. |
| `dpvar(...)` | [`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) | Create continuous YALMIP-backed Bernstein decision variables. |
| `rhodiff(P)` | [`dpvar rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) | Build rate-vertex derivative expressions. |
| `P <= 0`, `P >= 0` | [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) | Create `dplmi` constraints from residual expressions. |
| `toYalmip(C)` | [`dplmi toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | Hand assembled constraints to YALMIP `optimize`. |

The generated [lookup table](/DP-LMI-package/documents/reference-index/) is produced from `src/data/reference-index.js` and checked during the build workflow.

## Mathematics

- [Bernstein Polynomial](/DP-LMI-package/documents/math/bernstein-polynomial/): local coordinates, basis labels, coefficient multiplication, tensor-product storage, and coefficient-wise constraints.

## Install And Examples

- [Install And Download](/DP-LMI-package/install/): setup skeleton, source ZIP, and PDF manual links.
- [Examples](/DP-LMI-package/examples/): compact workflows.
- [Solver Smoke Cases](/DP-LMI-package/examples/solver-smoke/): two tested YALMIP examples from `+tests/+dplmi/test_solver_smoke.m`.

## Reference Page Shape

Each class page follows the same manual pattern: Purpose, Syntax, Description, Arguments or Options, Returned Object or Outputs, Examples, Validation And Errors, Limitations, and See Also.
