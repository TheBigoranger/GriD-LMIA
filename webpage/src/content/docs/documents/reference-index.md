---
title: Reference Lookup Table
description: Generated lookup table for implemented DP-LMI classes and methods.
---

This generated page lists implemented public classes and methods that are documented in the online manual. The source data lives in `src/data/reference-index.js`; regenerate this page with `npm --prefix webpage run generate:index`.

| Name | Type | Lookup Task |
| :--- | :--- | :--- |
| [`Status and limits`](/DP-LMI-package/documents/status-and-limits/) | Guide | Check what is implemented, reserved, or unsupported before choosing a workflow. |
| [`pdbase`](/DP-LMI-package/documents/reference/pdbase/) | Backend class | Inspect cell-local Bernstein storage shared by pdmat and pdvar. |
| [`cells`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-cells) | pdbase method | Enumerate physical tensor-grid cells. |
| [`coeffs`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-coeffs) | pdbase method | Read local Bernstein coefficient families. |
| [`lbls`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-lbls) | pdbase method | Inspect flat local Bernstein labels. |
| [`elevVals`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-elevVals) | pdbase method | Degree-elevate every cell-local coefficient family. |
| [`ncell`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-ncell) | pdbase method | Count physical cells. |
| [`ncoeff`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-ncoeff) | pdbase method | Count coefficients in one local cell. |
| [`npar`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-npar) | pdbase method | Count parameter dimensions. |
| [`size`](/DP-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-size) | pdbase method | Inspect matrix payload dimensions. |
| [`pdmat`](/DP-LMI-package/documents/reference/pdmat/) | Known-data class | Represent finite real matrix data on a parameter grid. |
| [`pdmat constructor`](/DP-LMI-package/documents/reference/pdmat/constructor/) | pdmat function | Create coefficient-backed or function-backed known-data matrices. |
| [`bernsteinTable`](/DP-LMI-package/documents/reference/pdmat/bernsteintable/) | pdmat method | Inspect coefficient rows and optional one-line expressions. |
| [`evaluate`](/DP-LMI-package/documents/reference/pdmat/evaluate/) | pdmat method | Evaluate known data at a parameter point. |
| [`plot`](/DP-LMI-package/documents/reference/pdmat/plot/) | pdmat method | Plot one- or two-parameter known data. |
| [`plus`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-plus) | pdmat method | Add coefficient-backed data or a compatible numeric constant. |
| [`minus`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-minus) | pdmat method | Subtract coefficient-backed data or a compatible numeric constant. |
| [`mtimes`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-mtimes) | pdmat method | Multiply compatible matrix data and scalar constants. |
| [`uplus`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-uplus) | pdmat method | Return coefficient-backed data unchanged. |
| [`uminus`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-uminus) | pdmat method | Negate coefficient-backed data. |
| [`transpose`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-transpose) | pdmat method | Transpose matrix payloads. |
| [`ctranspose`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-ctranspose) | pdmat method | Conjugate-transpose matrix payloads. |
| [`reshape`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-reshape) | pdmat method | Reshape matrix payloads with preserved coefficient storage. |
| [`squeeze`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-squeeze) | pdmat method | Remove singleton matrix dimensions. |
| [`vec`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-vec) | pdmat method | Vectorize matrix payloads. |
| [`diag`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-diag) | pdmat method | Extract or build diagonal matrix payloads. |
| [`trace`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-trace) | pdmat method | Compute coefficient-wise matrix traces. |
| [`sum`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-sum) | pdmat method | Sum along a matrix dimension. |
| [`mean`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-mean) | pdmat method | Average along a matrix dimension. |
| [`cumsum`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-cumsum) | pdmat method | Cumulative sum along a matrix dimension. |
| [`tril`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-tril) | pdmat method | Keep the lower triangular part. |
| [`triu`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-triu) | pdmat method | Keep the upper triangular part. |
| [`horzcat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-horzcat) | pdmat method | Concatenate payloads horizontally. |
| [`vertcat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-vertcat) | pdmat method | Concatenate payloads vertically. |
| [`cat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-cat) | pdmat method | Concatenate payloads along a selected dimension. |
| [`blkdiag`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-blkdiag) | pdmat method | Build block-diagonal payloads. |
| [`repmat`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-repmat) | pdmat method | Repeat payloads by matrix dimensions. |
| [`flip`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-flip) | pdmat method | Flip payloads along a dimension. |
| [`fliplr`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-fliplr) | pdmat method | Flip payloads left to right. |
| [`flipud`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-flipud) | pdmat method | Flip payloads up to down. |
| [`rot90`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-rot90) | pdmat method | Rotate payloads by quarter turns. |
| [`subsref`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-subsref) | pdmat method | Index and inspect matrix payloads. |
| [`subsasgn`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-subsasgn) | pdmat method | Assign numeric or compatible pdmat blocks. |
| [`disp`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-disp) | pdmat method | Display a concise object summary. |
| [`display`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-display) | pdmat method | Display using MATLAB display dispatch. |
| [`isequal`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-isequal) | pdmat method | Compare normalized object metadata and evidence. |
| [`end`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-end) | pdmat method | Resolve end-index syntax. |
| [`numArgumentsFromSubscript`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-numArgumentsFromSubscript) | pdmat method | Preserve scalar MATLAB subscript results. |
| [`numel`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-numel) | pdmat method | Count payload elements. |
| [`ndims`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-ndims) | pdmat method | Report the matrix payload dimension count. |
| [`length`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-length) | pdmat method | Report the largest payload dimension. |
| [`height`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-height) | pdmat method | Report the first payload dimension. |
| [`width`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-width) | pdmat method | Report the second payload dimension. |
| [`size`](/DP-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-size) | pdmat method | Inspect matrix payload dimensions. |
| [`pdvar`](/DP-LMI-package/documents/reference/pdvar/) | Decision class | Create continuous YALMIP-backed Bernstein decision expressions. |
| [`pdvar constructor`](/DP-LMI-package/documents/reference/pdvar/constructor/) | pdvar function | Create symmetric or full continuous Bernstein decision variables. |
| [`bernsteinTable`](/DP-LMI-package/documents/reference/pdvar/bernsteintable/) | pdvar method | Inspect symbolic coefficient rows and rate vertices. |
| [`rhodiff`](/DP-LMI-package/documents/reference/pdvar/rhodiff/) | pdvar method | Build rate-vertex derivative expressions. |
| [`value`](/DP-LMI-package/documents/reference/pdvar/value/) | pdvar method | Convert assigned symbolic coefficients to known pdmat data. |
| [`plus`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-plus) | pdvar method | Add affine decision expressions and compatible constants. |
| [`minus`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-minus) | pdvar method | Subtract affine decision expressions and compatible constants. |
| [`mtimes`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-mtimes) | pdvar method | Multiply while keeping decision dependence on one side. |
| [`uminus`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-uminus) | pdvar method | Negate affine decision expressions. |
| [`uplus`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-uplus) | pdvar method | Return an affine decision expression unchanged. |
| [`transpose`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-transpose) | pdvar method | Transpose symbolic matrix payloads. |
| [`ctranspose`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-ctranspose) | pdvar method | Conjugate-transpose symbolic matrix payloads. |
| [`reshape`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-reshape) | pdvar method | Reshape symbolic matrix payloads. |
| [`squeeze`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-squeeze) | pdvar method | Remove singleton symbolic matrix dimensions. |
| [`vec`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-vec) | pdvar method | Vectorize symbolic matrix payloads. |
| [`diag`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-diag) | pdvar method | Extract or build symbolic diagonal payloads. |
| [`trace`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-trace) | pdvar method | Compute symbolic matrix traces. |
| [`sum`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-sum) | pdvar method | Sum symbolic payloads along a dimension. |
| [`mean`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-mean) | pdvar method | Average symbolic payloads along a dimension. |
| [`cumsum`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-cumsum) | pdvar method | Cumulative sum symbolic payloads. |
| [`tril`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-tril) | pdvar method | Keep the lower triangular symbolic part. |
| [`triu`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-triu) | pdvar method | Keep the upper triangular symbolic part. |
| [`horzcat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-horzcat) | pdvar method | Concatenate symbolic payloads horizontally. |
| [`vertcat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-vertcat) | pdvar method | Concatenate symbolic payloads vertically. |
| [`cat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-cat) | pdvar method | Concatenate symbolic payloads along a dimension. |
| [`blkdiag`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-blkdiag) | pdvar method | Build symbolic block-diagonal payloads. |
| [`repmat`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-repmat) | pdvar method | Repeat symbolic payloads by matrix dimensions. |
| [`flip`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-flip) | pdvar method | Flip symbolic payloads along a dimension. |
| [`fliplr`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-fliplr) | pdvar method | Flip symbolic payloads left to right. |
| [`flipud`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-flipud) | pdvar method | Flip symbolic payloads up to down. |
| [`rot90`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-rot90) | pdvar method | Rotate symbolic payloads by quarter turns. |
| [`subsref`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-subsref) | pdvar method | Index and inspect symbolic matrix payloads. |
| [`subsasgn`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-subsasgn) | pdvar method | Assign numeric or compatible decision blocks. |
| [`le`](/DP-LMI-package/documents/reference/pdvar/comparisons/#pdvar-comparison-le) | pdvar comparison | Create a nonpositive pdlmi residual. |
| [`ge`](/DP-LMI-package/documents/reference/pdvar/comparisons/#pdvar-comparison-ge) | pdvar comparison | Create a nonnegative pdlmi residual. |
| [`isequal`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-isequal) | pdvar method | Compare normalized symbolic metadata and evidence. |
| [`end`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-end) | pdvar method | Resolve end-index syntax. |
| [`numArgumentsFromSubscript`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-numArgumentsFromSubscript) | pdvar method | Preserve scalar MATLAB subscript results. |
| [`numel`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-numel) | pdvar method | Count symbolic payload elements. |
| [`ndims`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-ndims) | pdvar method | Report the matrix payload dimension count. |
| [`length`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-length) | pdvar method | Report the largest payload dimension. |
| [`height`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-height) | pdvar method | Report the first payload dimension. |
| [`width`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-width) | pdvar method | Report the second payload dimension. |
| [`size`](/DP-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-size) | pdvar method | Inspect matrix payload dimensions. |
| [`pdlmi`](/DP-LMI-package/documents/reference/pdlmi/) | Constraint class | Store direct, Pólya-elevated, or full-box YALMIP constraints. |
| [`pdlmi constructor`](/DP-LMI-package/documents/reference/pdlmi/constructor/) | pdlmi function | Select direct, Pólya-elevated, or fixed-order full-box assembly. |
| [`toYalmip`](/DP-LMI-package/documents/reference/pdlmi/toyalmip/) | pdlmi method | Concatenate stored constraints for YALMIP optimize calls. |
| [`applyPolya`](/DP-LMI-package/documents/reference/pdlmi/applypolya/) | pdlmi method | Rebuild a residual with a selected Pólya degree increment. |
| [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) | pdlmi method | Rebuild a residual with a fixed-order full box Bernstein-Gram certificate. |
| [`bernElev`](/DP-LMI-package/documents/reference/bernstein-utilities/#bernElev) | pdbase backend method | Elevate Bernstein degree for compatible coefficient payloads. |
| [`bernProd`](/DP-LMI-package/documents/reference/bernstein-utilities/#bernProd) | pdbase backend method | Multiply local Bernstein coefficient families by label convolution. |
| [`mergeGrid`](/DP-LMI-package/documents/reference/bernstein-utilities/#mergeGrid) | pdbase backend method | Refine compatible physical grids before coefficient algebra. |
