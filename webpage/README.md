# GriD-LMIA Manual Website

This directory contains the GitHub Pages documentation site for GriD-LMIA (Gridding-based DPD-LMI Assembler), a MATLAB/YALMIP package for parameter-dependent linear matrix inequalities. The site is built with npm, Astro, and Starlight. Markdown math is rendered at build time through `remark-math` → `rehype-katex`, with KaTeX CSS and fonts bundled locally, so no client-side runtime typesetting or external asset fetch is required.

## Structure

- `src/content/docs/`: public manual pages.
- `src/data/`: curated reference metadata used by scripts and pages.
- `scripts/`: JavaScript generation and validation scripts.
- `dist/`, `.astro/`, `.vite/`, and `node_modules/`: generated or local-only folders that should not be tracked.

## Commands

Run these from the repository root:

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `npm --prefix webpage run dev` | Start the local docs server. |
| `npm --prefix webpage run build` | Run the source-authoring preparation and build the static site. |
| `npm --prefix webpage run build:publish` | Validate committed publication artifacts and build without documentation sources. |
| `npm --prefix webpage run preview` | Preview the built site locally. |
| `npm --prefix webpage run check:links` | Validate built internal links and anchors under `/GriD-LMIA/`. |

## Publishing

The source build reads `doc/manual.tex`, the documentation inventory, and the
terminology contract, then regenerates the committed Web projections and
`src/data/publication-manifest.json`. The publish build reads only the tracked
Web artifacts and `doc/manual.pdf`. It validates the manual version, SHA-256,
page count, API-record count, generated reference data, call graphs, and public
plot assets before Astro starts.

GitHub Pages selects publication mode with
`GRID_LMIA_DOC_BUILD_MODE=publish`. A direct local check may use
`npm --prefix webpage run build:publish`.

GitHub Actions builds this project from `webpage/` and publishes it to:

`https://thebigoranger.github.io/GriD-LMIA/`
