---
title: Documents
description: Reference-first entry point for DP-LMI classes, methods, and mathematical background.
---

Use this page as the lookup entry for current DP-LMI behavior. The reference pages document implemented code only; reserved relaxation and Polya options are listed as limitations rather than supported workflows.

## Reference Index

| Name | Kind | Primary use |
| :--- | :--- | :--- |
| [`dpbase`](/DP-LMI-package/documents/reference/dpbase/) | Backend class | Understand shared tensor-grid metadata and cell-local Bernstein storage. |
| [`dpmat`](/DP-LMI-package/documents/reference/dpmat/) | Known-data class | Construct, evaluate, display, plot, and combine known parameter-dependent matrices. |
| [`dpvar`](/DP-LMI-package/documents/reference/dpvar/) | Decision-expression class | Create continuous YALMIP-backed Bernstein decision variables and affine expressions. |
| [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/#rhodiff) | `dpvar` method | Form rate-vertex derivative expressions from `dpvar` objects. |
| [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) | Constraint class | Store coefficient-wise DP-LMI constraints for YALMIP. |
| [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/#toyalmip) | `dplmi` method | Concatenate stored constraints before `optimize`. |

The generated [lookup table](/DP-LMI-package/documents/reference-index/) is produced from `src/data/reference-index.js` and checked during the build workflow.

## Mathematics

- [Bernstein Polynomial](/DP-LMI-package/documents/math/bernstein-polynomial/): local coordinates, basis labels, coefficient multiplication, tensor-product storage, and coefficient-wise constraints.

## Reference Page Shape

Each class page follows the same manual pattern: Purpose, Syntax, Description, Arguments or Options, Returned Object or Outputs, Examples, Validation And Errors, Limitations, and See Also.
