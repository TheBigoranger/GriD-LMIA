---
title: Thanks
description: Acknowledgements and reference influences for the GriD-LMIA manual website.
---

This package and manual are built around MATLAB and YALMIP workflows. The public documentation also uses Astro and Starlight for the GitHub Pages site.

## Runtime And Documentation Tools

| Tool | Role |
| :--- | :--- |
| MATLAB | Host environment for package classes and tests. |
| YALMIP | Modeling layer and solver gateway used by `pdvar` and `pdlmi`. |
| Astro | Static-site framework for this GitHub Pages documentation. |
| Starlight | Documentation theme, sidebar, search, and page structure. |

## Comparison References

ROLmip, LPVTools, ROMULOC, MATLAB documentation, YALMIP examples, and TikZ-style manuals are useful reference points for documentation structure, examples, and notation. They are not runtime dependencies of GriD-LMIA unless a future implementation explicitly adds such an adapter.

## Source Boundary

The website documents behavior from the repository code, tests, project memory, and `doc/manual.tex`. It does not publish internal writer prompts, agent workflows, or private maintenance notes.
