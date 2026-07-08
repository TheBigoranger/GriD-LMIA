---
title: Install And Download
description: Setup skeleton, source download, and manual download links for DP-LMI.
---

This page is a stable installation and download entry. It is intentionally short until the package has tagged releases.

## Downloads

| Item | Link |
| :--- | :--- |
| Source archive | [Download `main` as ZIP](https://github.com/TheBigoranger/DP-LMI-package/archive/refs/heads/main.zip) |
| PDF manual | [Download `doc/manual.pdf`](https://github.com/TheBigoranger/DP-LMI-package/raw/main/doc/manual.pdf) |
| GitHub repository | [TheBigoranger/DP-LMI-package](https://github.com/TheBigoranger/DP-LMI-package) |

## Requirements

- MATLAB.
- YALMIP on the MATLAB path for `dpvar`, `dplmi`, and solver-facing examples.
- A solver supported by YALMIP. The smoke tests prefer MOSEK when available and otherwise fall back to `lmilab`.

## Path Setup

```matlab
projectRoot = "path/to/DP-LMI-package";
addpath(genpath(projectRoot));
rmpath(genpath(fullfile(projectRoot, "doc")));
```

## Verify

```matlab
results = tests.run_all();
```

## First Lookup

- [Reference lookup table](/DP-LMI-package/documents/reference-index/)
- [dpmat constructor](/DP-LMI-package/documents/reference/dpmat/constructor/)
- [dpvar constructor](/DP-LMI-package/documents/reference/dpvar/constructor/)
- [Solver smoke examples](/DP-LMI-package/examples/solver-smoke/)
