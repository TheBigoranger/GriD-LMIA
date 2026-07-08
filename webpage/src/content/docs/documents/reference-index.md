---
title: Reference Lookup Table
description: Generated lookup table for implemented DP-LMI classes and methods.
---

This generated page lists implemented public classes and methods that are documented in the online manual. The source data lives in `src/data/reference-index.js`; regenerate this page with `npm --prefix webpage run generate:index`.

| Name | Type | Lookup Task |
| :--- | :--- | :--- |
| [`dpbase`](/DP-LMI-package/documents/reference/dpbase/) | Backend class | Inspect cell-local Bernstein storage shared by dpmat and dpvar. |
| [`cells`](/DP-LMI-package/documents/reference/dpbase/#cells) | dpbase method | Enumerate physical cell subscripts. |
| [`coeffs`](/DP-LMI-package/documents/reference/dpbase/#coeffs) | dpbase method | Read local Bernstein coefficient families. |
| [`lbls`](/DP-LMI-package/documents/reference/dpbase/#lbls) | dpbase method | Inspect local Bernstein labels in flat row order. |
| [`dpmat`](/DP-LMI-package/documents/reference/dpmat/) | Known-data class | Represent finite real matrix data on a parameter grid. |
| [`evaluate`](/DP-LMI-package/documents/reference/dpmat/#evaluate) | dpmat method | Evaluate known matrix data at one parameter point. |
| [`plot`](/DP-LMI-package/documents/reference/dpmat/#display-table-and-plot) | dpmat method | Sample one- or two-parameter known data for diagnostics. |
| [`dpvar`](/DP-LMI-package/documents/reference/dpvar/) | Decision class | Create continuous YALMIP-backed Bernstein decision expressions. |
| [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/#rhodiff) | dpvar method | Build discontinuous rate-vertex derivative expressions. |
| [`le/ge`](/DP-LMI-package/documents/reference/dpvar/#comparisons) | dpvar comparison | Create dplmi constraints from dpvar residuals. |
| [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) | Constraint class | Store direct coefficient-wise YALMIP constraints. |
| [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/#toyalmip) | dplmi method | Concatenate stored constraints for YALMIP optimize calls. |
