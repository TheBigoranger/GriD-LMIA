---
title: Install And Download
description: Install the PD-LMI package, open the synchronized v0.3.2 manual, and verify the MATLAB/YALMIP setup.
---

The online and printable manuals describe documentation version `v0.3.2`.
Use the current `main` source snapshot for that interface. The older tagged
`v0.2.0` release remains available when an immutable historical package
snapshot is required.

## Downloads

| Item | Link |
| :--- | :--- |
| v0.3.2 manual | [Open the synchronized printable manual](/PD-LMI-package/manual.pdf) |
| Current source snapshot | [Download `main` as ZIP](https://github.com/TheBigoranger/PD-LMI-package/archive/refs/heads/main.zip) |
| GitHub repository | [TheBigoranger/PD-LMI-package](https://github.com/TheBigoranger/PD-LMI-package) |
| Version history | [Open version history](/PD-LMI-package/version-history/) |
| Historical v0.2.0 tag | [Open the immutable release](https://github.com/TheBigoranger/PD-LMI-package/releases/tag/v0.2.0) |

The project does not publish the PDF manual as a separately named release
asset, so the manual link above is explicitly the current synchronized site
snapshot.

## Requirements

- MATLAB.
- YALMIP on the MATLAB path for `pdvar`, `pdlmi`, and solver-facing examples.
- A solver supported by YALMIP. The smoke tests prefer MOSEK when available and otherwise fall back to `lmilab`.

## Path Setup

```matlab
projectRoot = "path/to/PD-LMI-package";
addpath(genpath(projectRoot));
rmpath(genpath(fullfile(projectRoot, "doc")));
```

## Verify

```matlab
results = tests.run_all();
```

## First Lookup

- [Reference lookup table](/PD-LMI-package/documents/reference-index/)
- [pdmat constructor](/PD-LMI-package/documents/reference/pdmat/constructor/)
- [pdvar constructor](/PD-LMI-package/documents/reference/pdvar/constructor/)
- [Solver smoke examples](/PD-LMI-package/examples/solver-smoke/)
