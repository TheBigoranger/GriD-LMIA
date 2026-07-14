---
title: Install And Download
description: Download the v0.2.0 release, install DP-LMI, and verify the MATLAB/YALMIP package.
---

Use the tagged `v0.2.0` release for a reproducible package snapshot. The
`main` branch and its manual remain useful as the current development snapshot.

## Downloads

| Item | Link |
| :--- | :--- |
| v0.2.0 release | [Open the GitHub release](https://github.com/TheBigoranger/DP-LMI-package/releases/tag/v0.2.0) |
| v0.2.0 source archive | [Download the tagged ZIP](https://github.com/TheBigoranger/DP-LMI-package/archive/refs/tags/v0.2.0.zip) |
| Current manual snapshot | [Open the printable manual](/DP-LMI-package/manual.pdf) |
| Current source snapshot | [Download `main` as ZIP](https://github.com/TheBigoranger/DP-LMI-package/archive/refs/heads/main.zip) |
| GitHub repository | [TheBigoranger/DP-LMI-package](https://github.com/TheBigoranger/DP-LMI-package) |
| Version history | [Open version history](/DP-LMI-package/version-history/) |

The release page is the stable download entry. The project does not currently
publish the PDF manual as a separately named release asset, so the manual link
above is explicitly the current `main` snapshot.

## Requirements

- MATLAB.
- YALMIP on the MATLAB path for `pdvar`, `pdlmi`, and solver-facing examples.
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
- [pdmat constructor](/DP-LMI-package/documents/reference/pdmat/constructor/)
- [pdvar constructor](/DP-LMI-package/documents/reference/pdvar/constructor/)
- [Solver smoke examples](/DP-LMI-package/examples/solver-smoke/)
