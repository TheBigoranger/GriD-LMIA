# PD-LMI Manual Website

This directory contains the GitHub Pages documentation site for the PD-LMI (parameter-dependent LMI) MATLAB/YALMIP package. The site is built with npm, Astro, and Starlight; Markdown math is rendered at build time through `remark-math` → `rehype-katex`, with KaTeX CSS and fonts bundled locally, so no client-side runtime typesetting or external asset fetch is required.

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
| `npm --prefix webpage run build` | Generate the reference index and build the static site. |
| `npm --prefix webpage run preview` | Preview the built site locally. |
| `npm --prefix webpage run check:links` | Validate built internal links and anchors under `/PD-LMI-package/`. |

## Publishing

GitHub Actions builds this project from `webpage/` and publishes it to:

`https://thebigoranger.github.io/PD-LMI-package/`
