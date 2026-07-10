---
title: dplmi
description: Cell-local YALMIP constraints for DP-LMI expressions.
---

`dplmi` stores direct coefficient-wise constraints generated from square `dpvar` residual expressions.

## Reference Index

### Construction and comparisons

| Reference | Task |
| :--- | :--- |
| [`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) | Store direct coefficient-wise constraints from scalar or matrix residuals. |
| [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) | Create `dplmi` constraints with `<=` and `>=`. |

### YALMIP export and solver use

| Reference | Task |
| :--- | :--- |
| [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | Concatenate stored constraints for ordinary YALMIP `optimize` calls. |

## Current Boundary

Relaxation-lemma workflows, Polya assembly, strictness margins, residual evidence, diagnostics, and package-owned solver wrappers are future layers.

## See Also

[`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/)
