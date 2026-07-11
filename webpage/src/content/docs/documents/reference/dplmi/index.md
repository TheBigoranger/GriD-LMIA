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
| [`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) | Rebuild the original residual with a selected Pólya degree increment. |

### YALMIP export and solver use

| Reference | Task |
| :--- | :--- |
| [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | Concatenate stored constraints for ordinary YALMIP `optimize` calls. |

## Current Boundary

Direct coefficient-wise assembly is the default. Pólya degree elevation is
available through the constructor options and `applyPolya`; relaxation-lemma
workflows, strictness margins, residual evidence, diagnostics, and
package-owned solver wrappers remain outside this slice.

## See Also

[`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/)
