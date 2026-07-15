---
title: Reference Lookup Table
description: Generated lookup table for implemented PD-LMI classes and methods.
---

This generated page lists implemented public classes and methods that are documented in the online manual. The source data lives in `src/data/reference-index.js`; regenerate this page with `npm --prefix webpage run generate:index`.

| Name | Type | Lookup Task |
| :--- | :--- | :--- |
| [`pdbase`](/PD-LMI-package/documents/reference/pdbase/) | Backend class | Inspect cell-local Bernstein storage shared by pdmat and pdvar. |
| [`cells`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-cells) | pdbase method | Enumerate physical tensor-grid cells. |
| [`coeffs`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-coeffs) | pdbase method | Read local Bernstein coefficient families. |
| [`lbls`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-lbls) | pdbase method | Inspect flat local Bernstein labels. |
| [`elevVals`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-elevVals) | pdbase method | Degree-elevate every cell-local coefficient family. |
| [`ncell`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-ncell) | pdbase method | Count physical cells. |
| [`ncoeff`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-ncoeff) | pdbase method | Count coefficients in one local cell. |
| [`npar`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-npar) | pdbase method | Count parameter dimensions. |
| [`size`](/PD-LMI-package/documents/reference/pdbase/storage-inspection/#pdbase-size) | pdbase method | Inspect matrix payload dimensions. |
| [`pdmat`](/PD-LMI-package/documents/reference/pdmat/) | Known-data class | Represent finite real matrix data on a parameter grid. |
| [`pdmat constructor`](/PD-LMI-package/documents/reference/pdmat/constructor/) | pdmat function | Create coefficient-backed or function-backed known-data matrices. |
| [`bernsteinTable`](/PD-LMI-package/documents/reference/pdmat/bernsteintable/) | pdmat method | Inspect coefficient rows and optional one-line expressions. |
| [`evaluate`](/PD-LMI-package/documents/reference/pdmat/evaluate/) | pdmat method | Evaluate known data at a parameter point. |
| [`plot`](/PD-LMI-package/documents/reference/pdmat/plot/) | pdmat method | Plot one- or two-parameter known data. |
| [`plus`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-plus) | pdmat method | Add coefficient-backed data or a compatible numeric constant. |
| [`minus`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-minus) | pdmat method | Subtract coefficient-backed data or a compatible numeric constant. |
| [`mtimes`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-mtimes) | pdmat method | Multiply compatible matrix data and scalar constants. |
| [`uplus`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-uplus) | pdmat method | Return coefficient-backed data unchanged. |
| [`uminus`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-uminus) | pdmat method | Negate coefficient-backed data. |
| [`transpose`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-transpose) | pdmat method | Transpose matrix payloads. |
| [`ctranspose`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-ctranspose) | pdmat method | Conjugate-transpose matrix payloads. |
| [`reshape`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-reshape) | pdmat method | Reshape matrix payloads with preserved coefficient storage. |
| [`squeeze`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-squeeze) | pdmat method | Remove singleton matrix dimensions. |
| [`vec`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-vec) | pdmat method | Vectorize matrix payloads. |
| [`diag`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-diag) | pdmat method | Extract or build diagonal matrix payloads. |
| [`trace`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-trace) | pdmat method | Compute coefficient-wise matrix traces. |
| [`sum`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-sum) | pdmat method | Sum along a matrix dimension. |
| [`mean`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-mean) | pdmat method | Average along a matrix dimension. |
| [`cumsum`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-cumsum) | pdmat method | Cumulative sum along a matrix dimension. |
| [`tril`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-tril) | pdmat method | Keep the lower triangular part. |
| [`triu`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-triu) | pdmat method | Keep the upper triangular part. |
| [`horzcat`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-horzcat) | pdmat method | Concatenate payloads horizontally. |
| [`vertcat`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-vertcat) | pdmat method | Concatenate payloads vertically. |
| [`cat`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-cat) | pdmat method | Concatenate payloads along a selected dimension. |
| [`blkdiag`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-blkdiag) | pdmat method | Build block-diagonal payloads. |
| [`repmat`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-repmat) | pdmat method | Repeat payloads by matrix dimensions. |
| [`flip`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-flip) | pdmat method | Flip payloads along a dimension. |
| [`fliplr`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-fliplr) | pdmat method | Flip payloads left to right. |
| [`flipud`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-flipud) | pdmat method | Flip payloads up to down. |
| [`rot90`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-rot90) | pdmat method | Rotate payloads by quarter turns. |
| [`subsref`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-subsref) | pdmat method | Index and inspect matrix payloads. |
| [`subsasgn`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-subsasgn) | pdmat method | Assign numeric or compatible pdmat blocks. |
| [`disp`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-disp) | pdmat method | Display a concise object summary. |
| [`display`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-display) | pdmat method | Display using MATLAB display dispatch. |
| [`isequal`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-isequal) | pdmat method | Compare normalized object metadata and evidence. |
| [`end`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-end) | pdmat method | Resolve end-index syntax. |
| [`numArgumentsFromSubscript`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-numArgumentsFromSubscript) | pdmat method | Preserve scalar MATLAB subscript results. |
| [`numel`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-numel) | pdmat method | Count payload elements. |
| [`ndims`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-ndims) | pdmat method | Report the matrix payload dimension count. |
| [`length`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-length) | pdmat method | Report the largest payload dimension. |
| [`height`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-height) | pdmat method | Report the first payload dimension. |
| [`width`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-width) | pdmat method | Report the second payload dimension. |
| [`size`](/PD-LMI-package/documents/reference/pdmat/matrix-operations/#pdmat-size) | pdmat method | Inspect matrix payload dimensions. |
| [`pdvar`](/PD-LMI-package/documents/reference/pdvar/) | Decision class | Create continuous YALMIP-backed Bernstein decision expressions. |
| [`pdvar constructor`](/PD-LMI-package/documents/reference/pdvar/constructor/) | pdvar function | Create symmetric or full continuous Bernstein decision variables. |
| [`bernsteinTable`](/PD-LMI-package/documents/reference/pdvar/bernsteintable/) | pdvar method | Inspect symbolic coefficient rows and rate vertices. |
| [`rhodiff`](/PD-LMI-package/documents/reference/pdvar/rhodiff/) | pdvar method | Build rate-vertex derivative expressions. |
| [`value`](/PD-LMI-package/documents/reference/pdvar/value/) | pdvar method | Convert assigned symbolic coefficients to known pdmat data. |
| [`plus`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-plus) | pdvar method | Add affine decision expressions and compatible constants. |
| [`minus`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-minus) | pdvar method | Subtract affine decision expressions and compatible constants. |
| [`mtimes`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-mtimes) | pdvar method | Multiply while keeping decision dependence on one side. |
| [`uminus`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-uminus) | pdvar method | Negate affine decision expressions. |
| [`uplus`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-uplus) | pdvar method | Return an affine decision expression unchanged. |
| [`transpose`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-transpose) | pdvar method | Transpose symbolic matrix payloads. |
| [`ctranspose`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-ctranspose) | pdvar method | Conjugate-transpose symbolic matrix payloads. |
| [`reshape`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-reshape) | pdvar method | Reshape symbolic matrix payloads. |
| [`squeeze`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-squeeze) | pdvar method | Remove singleton symbolic matrix dimensions. |
| [`vec`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-vec) | pdvar method | Vectorize symbolic matrix payloads. |
| [`diag`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-diag) | pdvar method | Extract or build symbolic diagonal payloads. |
| [`trace`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-trace) | pdvar method | Compute symbolic matrix traces. |
| [`sum`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-sum) | pdvar method | Sum symbolic payloads along a dimension. |
| [`mean`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-mean) | pdvar method | Average symbolic payloads along a dimension. |
| [`cumsum`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-cumsum) | pdvar method | Cumulative sum symbolic payloads. |
| [`tril`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-tril) | pdvar method | Keep the lower triangular symbolic part. |
| [`triu`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-triu) | pdvar method | Keep the upper triangular symbolic part. |
| [`horzcat`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-horzcat) | pdvar method | Concatenate symbolic payloads horizontally. |
| [`vertcat`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-vertcat) | pdvar method | Concatenate symbolic payloads vertically. |
| [`cat`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-cat) | pdvar method | Concatenate symbolic payloads along a dimension. |
| [`blkdiag`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-blkdiag) | pdvar method | Build symbolic block-diagonal payloads. |
| [`repmat`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-repmat) | pdvar method | Repeat symbolic payloads by matrix dimensions. |
| [`flip`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-flip) | pdvar method | Flip symbolic payloads along a dimension. |
| [`fliplr`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-fliplr) | pdvar method | Flip symbolic payloads left to right. |
| [`flipud`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-flipud) | pdvar method | Flip symbolic payloads up to down. |
| [`rot90`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-rot90) | pdvar method | Rotate symbolic payloads by quarter turns. |
| [`subsref`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-subsref) | pdvar method | Index and inspect symbolic matrix payloads. |
| [`subsasgn`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-subsasgn) | pdvar method | Assign numeric or compatible decision blocks. |
| [`le`](/PD-LMI-package/documents/reference/pdvar/comparisons/#pdvar-comparison-le) | pdvar comparison | Create a nonpositive pdlmi residual. |
| [`ge`](/PD-LMI-package/documents/reference/pdvar/comparisons/#pdvar-comparison-ge) | pdvar comparison | Create a nonnegative pdlmi residual. |
| [`isequal`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-isequal) | pdvar method | Compare normalized symbolic metadata and evidence. |
| [`end`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-end) | pdvar method | Resolve end-index syntax. |
| [`numArgumentsFromSubscript`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-numArgumentsFromSubscript) | pdvar method | Preserve scalar MATLAB subscript results. |
| [`numel`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-numel) | pdvar method | Count symbolic payload elements. |
| [`ndims`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-ndims) | pdvar method | Report the matrix payload dimension count. |
| [`length`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-length) | pdvar method | Report the largest payload dimension. |
| [`height`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-height) | pdvar method | Report the first payload dimension. |
| [`width`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-width) | pdvar method | Report the second payload dimension. |
| [`size`](/PD-LMI-package/documents/reference/pdvar/matrix-operations/#pdvar-size) | pdvar method | Inspect matrix payload dimensions. |
| [`pdlmi`](/PD-LMI-package/documents/reference/pdlmi/) | Constraint class | Store direct, Pólya-elevated, Putinar, or full-box YALMIP constraints. |
| [`pdlmi constructor`](/PD-LMI-package/documents/reference/pdlmi/constructor/) | pdlmi function | Select direct, Pólya-elevated, fixed-order Putinar, or fixed-order full-box assembly. |
| [`toYalmip`](/PD-LMI-package/documents/reference/pdlmi/toyalmip/) | pdlmi method | Concatenate stored constraints for YALMIP optimize calls. |
| [`applyPolya`](/PD-LMI-package/documents/reference/pdlmi/applypolya/) | pdlmi method | Rebuild a residual with a selected Pólya degree increment. |
| [`applyPutinar`](/PD-LMI-package/documents/reference/pdlmi/applyputinar/) | pdlmi method | Rebuild a residual with a fixed-order Putinar box Bernstein-Gram certificate. |
| [`applyFullBoxPreorder`](/PD-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) | pdlmi method | Rebuild a residual with a fixed-order full box Bernstein-Gram certificate. |
| [`bernElev`](/PD-LMI-package/documents/reference/bernstein-utilities/#bernElev) | pdbase backend method | Elevate Bernstein degree for compatible coefficient payloads. |
| [`bernProd`](/PD-LMI-package/documents/reference/bernstein-utilities/#bernProd) | pdbase backend method | Multiply local Bernstein coefficient families by label convolution. |
| [`mergeGrid`](/PD-LMI-package/documents/reference/bernstein-utilities/#mergeGrid) | pdbase backend method | Refine compatible physical grids before coefficient algebra. |
