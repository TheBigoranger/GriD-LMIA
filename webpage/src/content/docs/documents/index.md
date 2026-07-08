---
title: Documents
description: Reference-first entry point for DP-LMI classes, methods, and mathematical background.
---

Use this page as the lookup entry for current DP-LMI behavior. The reference pages document implemented code only; reserved relaxation and Polya options are listed as limitations rather than supported workflows.

## Reference Index

<div class="method-grid">
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpbase/"><strong>dpbase</strong><span>Shared storage contract, labels, cells, and coefficient evidence.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpmat/"><strong>dpmat</strong><span>Known parameter-dependent matrices, evaluation, display, and plotting.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dpvar/"><strong>dpvar</strong><span>YALMIP-backed Bernstein decision variables and affine expressions.</span></a>
  <a class="method-card" href="/DP-LMI-package/documents/reference/dplmi/"><strong>dplmi</strong><span>Coefficient-wise constraints and YALMIP handoff.</span></a>
</div>

## Function Pages

| Area | Pages |
| :--- | :--- |
| `dpbase` | [`storage inspection`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/) |
| `dpmat` | [`constructor`](/DP-LMI-package/documents/reference/dpmat/constructor/), [`evaluate`](/DP-LMI-package/documents/reference/dpmat/evaluate/), [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/), [`table`](/DP-LMI-package/documents/reference/dpmat/table/), [`matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/) |
| `dpvar` | [`constructor`](/DP-LMI-package/documents/reference/dpvar/constructor/), [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/), [`matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/), [`comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/) |
| `dplmi` | [`constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/), [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) |

The generated [lookup table](/DP-LMI-package/documents/reference-index/) is produced from `src/data/reference-index.js` and checked during the build workflow.

## Mathematics

- [Bernstein Polynomial](/DP-LMI-package/documents/math/bernstein-polynomial/): local coordinates, basis labels, coefficient multiplication, tensor-product storage, and coefficient-wise constraints.

## Reference Page Shape

Each class page follows the same manual pattern: Purpose, Syntax, Description, Arguments or Options, Returned Object or Outputs, Examples, Validation And Errors, Limitations, and See Also.
