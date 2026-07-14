---
title: pdlmi
description: Cell-local YALMIP constraints for DP-LMI expressions.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <span>pdlmi</span>
</nav>

`pdlmi` stores finite YALMIP constraints generated from square `pdvar`
residual expressions. Direct coefficient assembly is the default; Pólya
degree elevation and fixed-order full box Bernstein-Gram preordering are
explicit alternatives.

## Reference Index

### Construction and comparisons

| Reference | Task |
| :--- | :--- |
| [`pdlmi constructor`](/DP-LMI-package/documents/reference/pdlmi/constructor/) | Select direct, Pólya-elevated, or fixed-order full-box assembly. |
| [`pdvar comparisons`](/DP-LMI-package/documents/reference/pdvar/comparisons/) | Create `pdlmi` constraints with `<=` and `>=`. |
| [`applyPolya`](/DP-LMI-package/documents/reference/pdlmi/applypolya/) | Rebuild the original residual with a selected Pólya degree increment. |
| [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) | Rebuild the original residual with the minimum or a selected absolute full-box order. |

### YALMIP export and solver use

| Reference | Task |
| :--- | :--- |
| [`toYalmip`](/DP-LMI-package/documents/reference/pdlmi/toyalmip/) | Concatenate stored constraints for ordinary YALMIP `optimize` calls. |

## Current Boundary

Direct coefficient-wise assembly is the default. Pólya degree elevation is
available through constructor options and `applyPolya`. The opt-in full-box
path uses independent positive-semidefinite Gram blocks for each physical cell
and active rate row, with exact coefficient identities. It is a fixed-order
box certificate, not a general-domain SOS interface or automatic hierarchy.
Strictness margins, residual evidence, diagnostics, and package-owned solver
wrappers remain outside this slice.

The [SOS certificate map](/DP-LMI-package/documents/math/sos-certificates/)
explains how the implemented direct, Pólya, and full-box paths relate to
full-space SOS, Putinar quadratic modules, Schmüdgen preorderings, and the
one-dimensional Markov–Lukács theorem.

## See Also

[`pdlmi constructor`](/DP-LMI-package/documents/reference/pdlmi/constructor/) · [`applyPolya`](/DP-LMI-package/documents/reference/pdlmi/applypolya/) · [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) · [`SOS certificates`](/DP-LMI-package/documents/math/sos-certificates/) · [`pdvar comparisons`](/DP-LMI-package/documents/reference/pdvar/comparisons/) · [`toYalmip`](/DP-LMI-package/documents/reference/pdlmi/toyalmip/)
