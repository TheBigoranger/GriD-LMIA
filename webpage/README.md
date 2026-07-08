# DP-LMI Manual Website

This directory contains the GitHub Pages documentation site for the DP-LMI MATLAB/YALMIP package. The site is built with npm, Astro, and Starlight.

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
| `npm --prefix webpage run check:links` | Validate built internal links and anchors under `/DP-LMI-package/`. |

## Publishing

GitHub Actions builds this project from `webpage/` and publishes it to:

`https://thebigoranger.github.io/DP-LMI-package/`
