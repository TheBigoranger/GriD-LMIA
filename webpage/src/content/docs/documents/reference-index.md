---
title: Reference Lookup Table
description: Generated lookup table for implemented DP-LMI classes and methods.
---

This generated page lists implemented public classes and methods that are documented in the online manual. The source data lives in `src/data/reference-index.js`; regenerate this page with `npm --prefix webpage run generate:index`.

| Name | Type | Lookup Task |
| :--- | :--- | :--- |
| [`dpbase`](/DP-LMI-package/documents/reference/dpbase/) | Backend class | Inspect cell-local Bernstein storage shared by dpmat and dpvar. |
| [`cells`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#cells) | dpbase method | Enumerate physical cell subscripts. |
| [`coeffs`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#coeffs) | dpbase method | Read local Bernstein coefficient families. |
| [`lbls`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#lbls) | dpbase method | Inspect local Bernstein labels in flat row order. |
| [`dpmat`](/DP-LMI-package/documents/reference/dpmat/) | Known-data class | Represent finite real matrix data on a parameter grid. |
| [`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) | dpmat function | Create coefficient-backed or function-backed known-data matrices. |
| [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) | dpmat method | Evaluate known matrix data at one parameter point. |
| [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/) | dpmat method | Sample one- or two-parameter known data for diagnostics. |
| [`bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/) | dpmat method | Inspect Bernstein coefficient rows as a MATLAB table. |
| [`dpmat matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/) | dpmat methods | Use coefficient-backed algebra, transforms, summaries, assembly, and indexing. |
| [`dpvar`](/DP-LMI-package/documents/reference/dpvar/) | Decision class | Create continuous YALMIP-backed Bernstein decision expressions. |
| [`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) | dpvar function | Create symmetric or full continuous Bernstein decision variables. |
| [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) | dpvar method | Build discontinuous rate-vertex derivative expressions. |
| [`dpvar matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/) | dpvar methods | Use affine algebra, known-data products, transforms, summaries, assembly, and indexing. |
| [`le/ge`](/DP-LMI-package/documents/reference/dpvar/comparisons/) | dpvar comparison | Create dplmi constraints from dpvar residuals. |
| [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) | Constraint class | Store direct coefficient-wise YALMIP constraints. |
| [`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) | dplmi function | Store coefficient-wise scalar or matrix residual constraints. |
| [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | dplmi method | Concatenate stored constraints for YALMIP optimize calls. |
