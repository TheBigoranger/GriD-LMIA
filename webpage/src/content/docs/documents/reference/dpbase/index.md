---
title: dpbase
description: Backend parent class for DP-LMI cell-local Bernstein objects.
---

`dpbase` is the backend parent for `dpmat` and `dpvar`. Ordinary users should model with `dpmat` and `dpvar`; this page explains inherited storage and inspection behavior.

<div class="method-grid">
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpbase/storage-inspection/"><strong>Storage and inspection</strong><span>Grid metadata, LocalValues, cells, coeffs, labels, and size helpers.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/math/bernstein-polynomial/"><strong>Bernstein background</strong><span>Local coordinates, labels, convolution, and coefficient-wise constraints.</span></a>
</div>

## Current Boundary

Do not treat `dpbase` as a primary modeling API or solver API. Rate-dependent algebra and LMI assembly belong to `dpvar` and `dplmi`.

## See Also

[`dpmat`](/DP-LMI-package/documents/reference/dpmat/) · [`dpvar`](/DP-LMI-package/documents/reference/dpvar/)
