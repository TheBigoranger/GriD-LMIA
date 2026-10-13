# GriD-LMIA Project Guide

GriD-LMIA is a MATLAB/YALMIP package for assembling parameter-dependent linear
matrix inequalities on parameter grids using cell-wise Bernstein representations.

## Start here

- [Installation and download](https://www.ethanyxu.com/GriD-LMIA/install/)
- [Package overview and setup](README.md)
- [Runnable MATLAB examples](example/README.md)
- [MATLAB test suite](+tests/run_all.m)
- [Printable manual](doc/manual.pdf)
- [Web manual](https://www.ethanyxu.com/GriD-LMIA/)
- [API reference index](https://www.ethanyxu.com/GriD-LMIA/documents/reference-index/)
- [Version history](https://www.ethanyxu.com/GriD-LMIA/version-history/)
- [GitHub Releases](https://github.com/TheBigoranger/GriD-LMIA/releases)

## Repository branches

| Branch | Contents | Intended use |
| --- | --- | --- |
| [`main`](https://github.com/TheBigoranger/GriD-LMIA/tree/main) | MATLAB package, examples, tests, and `doc/manual.pdf` | Download or install the package |
| [`webpage`](https://github.com/TheBigoranger/GriD-LMIA/tree/webpage) | Astro/Starlight website sources, generated documentation data, PDF, and deployment workflow | Inspect or build the website |

The website sources are available under
[`webpage/` on the `webpage` branch](https://github.com/TheBigoranger/GriD-LMIA/tree/webpage/webpage).
GitHub Actions builds that branch and deploys the web manual. The default branch
remains `main`; its current checkout and ZIP download do not contain website sources.

## Download only the current package snapshot

Use [Download ZIP for main](https://github.com/TheBigoranger/GriD-LMIA/archive/refs/heads/main.zip)
or make a shallow, single-branch clone:

```sh
git clone --depth 1 --single-branch --branch main --no-tags https://github.com/TheBigoranger/GriD-LMIA.git
```

An ordinary clone still downloads Git history from remote branches, including
website objects. Selecting only `main` without limiting history can also download
older website files formerly tracked on `main`. The command above avoids both
when creating a new package checkout. Existing tags and release archives retain
their original contents.
