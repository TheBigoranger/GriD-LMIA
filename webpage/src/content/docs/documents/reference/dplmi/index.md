---
title: dplmi
description: Cell-local YALMIP constraints for DP-LMI expressions.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <span>dplmi</span>
</nav>

`dplmi` stores finite YALMIP constraints generated from square `dpvar`
residual expressions. Direct coefficient assembly is the default; Pólya
degree elevation and fixed-order full box Bernstein-Gram preordering are
explicit alternatives.

## Reference Index

### Construction and comparisons

| Reference | Task |
| :--- | :--- |
| [`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) | Select direct, Pólya-elevated, or fixed-order full-box assembly. |
| [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) | Create `dplmi` constraints with `<=` and `>=`. |
| [`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) | Rebuild the original residual with a selected Pólya degree increment. |
| [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/dplmi/applyfullboxpreorder/) | Rebuild the original residual with the minimum or a selected absolute full-box order. |

### YALMIP export and solver use

| Reference | Task |
| :--- | :--- |
| [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | Concatenate stored constraints for ordinary YALMIP `optimize` calls. |

## Current Boundary

Direct coefficient-wise assembly is the default. Pólya degree elevation is
available through constructor options and `applyPolya`. The opt-in full-box
path uses independent positive-semidefinite Gram blocks for each physical cell
and active rate row, with exact coefficient identities. It is a fixed-order
box certificate, not a general-domain SOS interface or automatic hierarchy.
Strictness margins, residual evidence, diagnostics, and package-owned solver
wrappers remain outside this slice.

## See Also

[`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) · [`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) · [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/dplmi/applyfullboxpreorder/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/)
