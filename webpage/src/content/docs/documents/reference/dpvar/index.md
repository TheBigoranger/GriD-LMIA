---
title: dpvar
description: Continuous YALMIP-backed Bernstein decision expressions.
---

`dpvar` creates gridded YALMIP-backed Bernstein decision expressions. It is method-superior to `dpmat` and `sdpvar`, so mixed known, numeric, symbolic, and decision algebra dispatches through `dpvar`.

<div class="method-grid">
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpvar/constructor/"><strong>Constructor</strong><span>Create continuous degree-0 or degree-1 decision expressions.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpvar/rhodiff/"><strong>rhodiff</strong><span>Build discontinuous rate-vertex derivative expressions.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpvar/matrix-operations/"><strong>Matrix operations</strong><span>Affine algebra, products, structural transforms, indexing, and assignment.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpvar/comparisons/"><strong>Comparisons</strong><span>Create dplmi constraints with <= and >=.</span></a>
</div>

## Scope Boundary

`dpvar` represents expressions. It does not choose solvers or call `optimize`; solver handoff begins with [`dplmi`](/DP-LMI-package/documents/reference/dplmi/).

## See Also

[`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) · [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) · [`dplmi`](/DP-LMI-package/documents/reference/dplmi/)
