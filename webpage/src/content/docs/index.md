---
title: DP-LMI Manual
description: Reference-first manual for the DP-LMI MATLAB/YALMIP package.
---

This site is the online manual for a MATLAB/YALMIP package for differential parameter-dependent LMIs. The current package slice provides cell-local Bernstein storage, known-data matrices, YALMIP-backed decision expressions, rate-vertex derivatives, and direct coefficient-wise LMI assembly.

Start with the [reference index](/DP-LMI-package/documents/) if you know the class or method name. Start with the [Bernstein polynomial chapter](/DP-LMI-package/documents/math/bernstein-polynomial/) if you need the storage model before reading the API pages.

## Current Implemented Slice

| Layer | Current behavior |
| :--- | :--- |
| `dpbase` | Backend parent for tensor-grid metadata, nested `LocalValues`, local labels, and coefficient inspection. |
| `dpmat` | Known finite real matrix data from function handles, Bernstein coefficient grids, or explicit local values. |
| `dpvar` | Continuous YALMIP-backed Bernstein decision expressions with affine algebra and structural matrix operations. |
| `rhodiff` | Discontinuous rate-vertex derivative expressions with scalar and tensor-grid rate bounds. |
| `dplmi` | Direct coefficient-wise YALMIP constraints and `toYalmip` handoff. |

## Setup Snapshot

```matlab
projectRoot = "path/to/Differential Parameter-Dependent Linear Matrix Inequality";
addpath(genpath(projectRoot));
rmpath(genpath(fullfile(projectRoot, "doc")));

results = tests.run_all();
```

For complete setup and runnable workflows, see [Examples](/DP-LMI-package/examples/).

## Scope Boundary

Relaxation-lemma assembly, Polya assembly, package-owned solver wrappers, strictness-margin diagnostics, and residual evidence are reserved future layers. The implemented solver-facing path documented here is direct coefficient-wise assembly through YALMIP constraints.
