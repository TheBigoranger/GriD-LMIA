# GriD-LMIA Website Publication

This branch contains the reviewed Astro/Starlight web-manual publication snapshot.
For the MATLAB package, use the [main branch](https://github.com/TheBigoranger/GriD-LMIA/tree/main).
The live manual is at https://www.ethanyxu.com/GriD-LMIA/.

## Build this branch

Use Node.js 24. From the repository root:

```sh
npm --prefix webpage ci
npm --prefix webpage run build:publish
npm --prefix webpage test
npm --prefix webpage run audit:docs -- --mode=publish
npm --prefix webpage run check:visual
npm --prefix webpage run check:links
```

For browser geometry checks, install the Playwright Chromium browser matching the
lockfile if it is unavailable, then run `npm --prefix webpage run check:geometry`.

Use `build:publish` in this checkout. The default source build requires private
development inputs and is intentionally not used here. Publish mode validates
the committed generated documentation and the SHA-256/page count of
`doc/manual.pdf`, then copies the PDF into the built website.

## Maintenance

Author changes in the complete development worktree. Generate and review source
outputs there, commit the approved snapshot, then synchronize only `webpage/`,
`doc/manual.pdf`, `LICENSE`, this README, the deployment workflow, and required Git metadata
into this publication branch. Never merge the development or package branch here.
Dependencies, build output, TeX sources, MATLAB sources, and local skills are not
publication inputs. Preserve this branch-specific README during synchronization.

Push the local `webpage-publish` branch explicitly to remote `webpage` after
validation. GitHub Actions builds `webpage/` in publish mode and deploys the
artifact; the repository default branch stays `main`. Pushes to this branch
trigger deployment when website sources, the PDF, workflow, or line-ending
configuration change. The workflow is kept off `main`; do not rely on a default-
branch manual-dispatch entry to publish it. Re-run an existing branch workflow
run when a deployment retry is needed.

## License

The original GriD-LMIA website content and source are licensed under the
[MIT License](LICENSE), copyright (c) 2026 Yicheng Xu. Third-party dependencies
and reproduced material retain their own licenses and notices. The accompanying
manual is also covered by the project's MIT License; scholarly citation is optional.
