// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import { unified } from "@astrojs/markdown-remark";
import remarkMath from "remark-math";
import rehypeMathjax from "rehype-mathjax";

// https://astro.build/config
export default defineConfig({
  site: "https://thebigoranger.github.io",
  base: "/DP-LMI-package",
  markdown: {
    processor: unified({
      remarkPlugins: [remarkMath],
      rehypePlugins: [rehypeMathjax],
    }),
  },
  integrations: [
    starlight({
      title: "DP-LMI Manual",
      description:
        "Reference-first manual for the DP-LMI MATLAB/YALMIP package.",
      customCss: ["./src/styles/manual.css"],
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/thebigoranger/DP-LMI-package",
        },
      ],
      sidebar: [
        { label: "Welcome", link: "/" },
        { label: "Install", slug: "install" },
        { label: "Version History", slug: "version-history" },
        {
          label: "Documents",
          items: [
            { label: "Manual Index", slug: "documents" },
            { label: "Lookup Table", slug: "documents/reference-index" },
            { label: "Bernstein Polynomial", slug: "documents/math/bernstein-polynomial" },
            {
              label: "dpmat",
              items: [
                { label: "Overview", slug: "documents/reference/dpmat" },
                { label: "Constructor", slug: "documents/reference/dpmat/constructor" },
                { label: "evaluate", slug: "documents/reference/dpmat/evaluate" },
                { label: "plot", slug: "documents/reference/dpmat/plot" },
                { label: "table", slug: "documents/reference/dpmat/table" },
                { label: "Matrix Operations", slug: "documents/reference/dpmat/matrix-operations" },
              ],
            },
            {
              label: "dpvar",
              items: [
                { label: "Overview", slug: "documents/reference/dpvar" },
                { label: "Constructor", slug: "documents/reference/dpvar/constructor" },
                { label: "rhodiff", slug: "documents/reference/dpvar/rhodiff" },
                { label: "Matrix Operations", slug: "documents/reference/dpvar/matrix-operations" },
                { label: "Comparisons", slug: "documents/reference/dpvar/comparisons" },
              ],
            },
            {
              label: "dplmi",
              items: [
                { label: "Overview", slug: "documents/reference/dplmi" },
                { label: "Constructor", slug: "documents/reference/dplmi/constructor" },
                { label: "toYalmip", slug: "documents/reference/dplmi/toyalmip" },
              ],
            },
            {
              label: "dpbase",
              items: [
                { label: "Overview", slug: "documents/reference/dpbase" },
                { label: "Storage Inspection", slug: "documents/reference/dpbase/storage-inspection" },
              ],
            },
          ],
        },
        {
          label: "Examples",
          items: [
            { label: "Workflow Index", slug: "examples" },
            { label: "Solver Smoke Cases", slug: "examples/solver-smoke" },
          ],
        },
        { label: "Thanks", link: "/thanks/" },
      ],
    }),
  ],
});
