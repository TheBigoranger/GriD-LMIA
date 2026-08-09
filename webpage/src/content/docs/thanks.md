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

ROLmip, LPVTools, ROMULOC, MATLAB documentation, YALMIP examples, and TikZ-style
manuals are useful reference points for documentation structure, examples, and
notation. GriD-LMIA currently uses MATLAB, YALMIP, and a compatible solver at
runtime. Future adapters will appear explicitly in the implementation and installation contract.

## Source Boundary

The website documents public behavior from the repository code, tests, project
memory, and `doc/manual.tex`. Public source, mathematics, examples, and
maintenance history define its scope.
