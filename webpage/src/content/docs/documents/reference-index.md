---
title: Reference Lookup Table
description: Generated lookup table for implemented DP-LMI classes and methods.
---

This generated page lists implemented public classes and methods that are documented in the online manual. The source data lives in `src/data/reference-index.js`; regenerate this page with `npm --prefix webpage run generate:index`.

| Name | Type | Lookup Task |
| :--- | :--- | :--- |
| [`Status and limits`](/DP-LMI-package/documents/status-and-limits/) | Guide | Check what is implemented, reserved, or unsupported before choosing a workflow. |
| [`dpbase`](/DP-LMI-package/documents/reference/dpbase/) | Backend class | Inspect cell-local Bernstein storage shared by dpmat and dpvar. |
| [`cells`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-cells) | dpbase method | Enumerate physical tensor-grid cells. |
| [`coeffs`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-coeffs) | dpbase method | Read local Bernstein coefficient families. |
| [`lbls`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-lbls) | dpbase method | Inspect flat local Bernstein labels. |
| [`elevVals`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-elevVals) | dpbase method | Degree-elevate every cell-local coefficient family. |
| [`ncell`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-ncell) | dpbase method | Count physical cells. |
| [`ncoeff`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-ncoeff) | dpbase method | Count coefficients in one local cell. |
| [`npar`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-npar) | dpbase method | Count parameter dimensions. |
| [`size`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/#dpbase-size) | dpbase method | Inspect matrix payload dimensions. |
| [`dpmat`](/DP-LMI-package/documents/reference/dpmat/) | Known-data class | Represent finite real matrix data on a parameter grid. |
| [`dpmat constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/) | dpmat function | Create coefficient-backed or function-backed known-data matrices. |
| [`bernsteinTable`](/DP-LMI-package/documents/reference/dpmat/bernsteintable/) | dpmat method | Inspect coefficient rows and optional one-line expressions. |
| [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/) | dpmat method | Evaluate known data at a parameter point. |
| [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/) | dpmat method | Plot one- or two-parameter known data. |
| [`plus`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-plus) | dpmat method | Add coefficient-backed data or a compatible numeric constant. |
| [`minus`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-minus) | dpmat method | Subtract coefficient-backed data or a compatible numeric constant. |
| [`mtimes`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-mtimes) | dpmat method | Multiply compatible matrix data and scalar constants. |
| [`uplus`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-uplus) | dpmat method | Return coefficient-backed data unchanged. |
| [`uminus`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-uminus) | dpmat method | Negate coefficient-backed data. |
| [`transpose`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-transpose) | dpmat method | Transpose matrix payloads. |
| [`ctranspose`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-ctranspose) | dpmat method | Conjugate-transpose matrix payloads. |
| [`reshape`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-reshape) | dpmat method | Reshape matrix payloads with preserved coefficient storage. |
| [`squeeze`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-squeeze) | dpmat method | Remove singleton matrix dimensions. |
| [`vec`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-vec) | dpmat method | Vectorize matrix payloads. |
| [`diag`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-diag) | dpmat method | Extract or build diagonal matrix payloads. |
| [`trace`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-trace) | dpmat method | Compute coefficient-wise matrix traces. |
| [`sum`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-sum) | dpmat method | Sum along a matrix dimension. |
| [`mean`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-mean) | dpmat method | Average along a matrix dimension. |
| [`cumsum`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-cumsum) | dpmat method | Cumulative sum along a matrix dimension. |
| [`tril`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-tril) | dpmat method | Keep the lower triangular part. |
| [`triu`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-triu) | dpmat method | Keep the upper triangular part. |
| [`horzcat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-horzcat) | dpmat method | Concatenate payloads horizontally. |
| [`vertcat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-vertcat) | dpmat method | Concatenate payloads vertically. |
| [`cat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-cat) | dpmat method | Concatenate payloads along a selected dimension. |
| [`blkdiag`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-blkdiag) | dpmat method | Build block-diagonal payloads. |
| [`repmat`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-repmat) | dpmat method | Repeat payloads by matrix dimensions. |
| [`flip`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-flip) | dpmat method | Flip payloads along a dimension. |
| [`fliplr`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-fliplr) | dpmat method | Flip payloads left to right. |
| [`flipud`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-flipud) | dpmat method | Flip payloads up to down. |
| [`rot90`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-rot90) | dpmat method | Rotate payloads by quarter turns. |
| [`subsref`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-subsref) | dpmat method | Index and inspect matrix payloads. |
| [`subsasgn`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-subsasgn) | dpmat method | Assign numeric or compatible dpmat blocks. |
| [`disp`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-disp) | dpmat method | Display a concise object summary. |
| [`display`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-display) | dpmat method | Display using MATLAB display dispatch. |
| [`isequal`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-isequal) | dpmat method | Compare normalized object metadata and evidence. |
| [`end`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-end) | dpmat method | Resolve end-index syntax. |
| [`numArgumentsFromSubscript`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-numArgumentsFromSubscript) | dpmat method | Preserve scalar MATLAB subscript results. |
| [`numel`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-numel) | dpmat method | Count payload elements. |
| [`ndims`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-ndims) | dpmat method | Report the matrix payload dimension count. |
| [`length`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-length) | dpmat method | Report the largest payload dimension. |
| [`height`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-height) | dpmat method | Report the first payload dimension. |
| [`width`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-width) | dpmat method | Report the second payload dimension. |
| [`size`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/#dpmat-size) | dpmat method | Inspect matrix payload dimensions. |
| [`dpvar`](/DP-LMI-package/documents/reference/dpvar/) | Decision class | Create continuous YALMIP-backed Bernstein decision expressions. |
| [`dpvar constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/) | dpvar function | Create symmetric or full continuous Bernstein decision variables. |
| [`bernsteinTable`](/DP-LMI-package/documents/reference/dpvar/bernsteintable/) | dpvar method | Inspect symbolic coefficient rows and rate vertices. |
| [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) | dpvar method | Build rate-vertex derivative expressions. |
| [`value`](/DP-LMI-package/documents/reference/dpvar/value/) | dpvar method | Convert assigned symbolic coefficients to known dpmat data. |
| [`plus`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-plus) | dpvar method | Add affine decision expressions and compatible constants. |
| [`minus`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-minus) | dpvar method | Subtract affine decision expressions and compatible constants. |
| [`mtimes`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-mtimes) | dpvar method | Multiply while keeping decision dependence on one side. |
| [`uminus`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-uminus) | dpvar method | Negate affine decision expressions. |
| [`uplus`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-uplus) | dpvar method | Return an affine decision expression unchanged. |
| [`transpose`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-transpose) | dpvar method | Transpose symbolic matrix payloads. |
| [`ctranspose`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-ctranspose) | dpvar method | Conjugate-transpose symbolic matrix payloads. |
| [`reshape`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-reshape) | dpvar method | Reshape symbolic matrix payloads. |
| [`squeeze`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-squeeze) | dpvar method | Remove singleton symbolic matrix dimensions. |
| [`vec`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-vec) | dpvar method | Vectorize symbolic matrix payloads. |
| [`diag`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-diag) | dpvar method | Extract or build symbolic diagonal payloads. |
| [`trace`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-trace) | dpvar method | Compute symbolic matrix traces. |
| [`sum`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-sum) | dpvar method | Sum symbolic payloads along a dimension. |
| [`mean`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-mean) | dpvar method | Average symbolic payloads along a dimension. |
| [`cumsum`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-cumsum) | dpvar method | Cumulative sum symbolic payloads. |
| [`tril`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-tril) | dpvar method | Keep the lower triangular symbolic part. |
| [`triu`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-triu) | dpvar method | Keep the upper triangular symbolic part. |
| [`horzcat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-horzcat) | dpvar method | Concatenate symbolic payloads horizontally. |
| [`vertcat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-vertcat) | dpvar method | Concatenate symbolic payloads vertically. |
| [`cat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-cat) | dpvar method | Concatenate symbolic payloads along a dimension. |
| [`blkdiag`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-blkdiag) | dpvar method | Build symbolic block-diagonal payloads. |
| [`repmat`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-repmat) | dpvar method | Repeat symbolic payloads by matrix dimensions. |
| [`flip`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-flip) | dpvar method | Flip symbolic payloads along a dimension. |
| [`fliplr`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-fliplr) | dpvar method | Flip symbolic payloads left to right. |
| [`flipud`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-flipud) | dpvar method | Flip symbolic payloads up to down. |
| [`rot90`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-rot90) | dpvar method | Rotate symbolic payloads by quarter turns. |
| [`subsref`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-subsref) | dpvar method | Index and inspect symbolic matrix payloads. |
| [`subsasgn`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-subsasgn) | dpvar method | Assign numeric or compatible decision blocks. |
| [`le`](/DP-LMI-package/documents/reference/dpvar/comparisons/#dpvar-comparison-le) | dpvar comparison | Create a nonpositive dplmi residual. |
| [`ge`](/DP-LMI-package/documents/reference/dpvar/comparisons/#dpvar-comparison-ge) | dpvar comparison | Create a nonnegative dplmi residual. |
| [`isequal`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-isequal) | dpvar method | Compare normalized symbolic metadata and evidence. |
| [`end`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-end) | dpvar method | Resolve end-index syntax. |
| [`numArgumentsFromSubscript`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-numArgumentsFromSubscript) | dpvar method | Preserve scalar MATLAB subscript results. |
| [`numel`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-numel) | dpvar method | Count symbolic payload elements. |
| [`ndims`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-ndims) | dpvar method | Report the matrix payload dimension count. |
| [`length`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-length) | dpvar method | Report the largest payload dimension. |
| [`height`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-height) | dpvar method | Report the first payload dimension. |
| [`width`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-width) | dpvar method | Report the second payload dimension. |
| [`size`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/#dpvar-size) | dpvar method | Inspect matrix payload dimensions. |
| [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) | Constraint class | Store direct coefficient-wise YALMIP constraints. |
| [`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) | dplmi function | Store coefficient-wise scalar or matrix residual constraints. |
| [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) | dplmi method | Concatenate stored constraints for YALMIP optimize calls. |
| [`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) | dplmi method | Rebuild a residual with a selected Pólya degree increment. |
| [`bernElev`](/DP-LMI-package/documents/reference/bernstein-utilities/#bernElev) | dpbase backend method | Elevate Bernstein degree for compatible coefficient payloads. |
| [`bernProd`](/DP-LMI-package/documents/reference/bernstein-utilities/#bernProd) | dpbase backend method | Multiply local Bernstein coefficient families by label convolution. |
| [`mergeGrid`](/DP-LMI-package/documents/reference/bernstein-utilities/#mergeGrid) | dpbase backend method | Refine compatible physical grids before coefficient algebra. |
