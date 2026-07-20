// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import react from "@astrojs/react";
import { unified } from "@astrojs/markdown-remark";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";

// https://astro.build/config
export default defineConfig({
  site: "https://thebigoranger.github.io",
  base: "/PD-LMI-package",
  markdown: {
    processor: unified({
      remarkPlugins: [remarkMath],
      rehypePlugins: [rehypeKatex],
    }),
  },
  integrations: [
    react(),
    starlight({
      title: "PD-LMI Manual",
      description:
        "Reference-first manual for the PD-LMI MATLAB/YALMIP package.",
      customCss: ["./src/styles/manual.css"],
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/thebigoranger/PD-LMI-package",
        },
      ],
      components: {
        Header: "./src/components/Header.astro",
      },
      sidebar: [
        { label: "Welcome", link: "/" },
        { label: "Install", slug: "install" },
        { label: "Version History", slug: "version-history" },
        {
          label: "Documents",
          items: [
            { label: "Manual Index", slug: "documents" },
            { label: "Reference Lookup", slug: "documents/reference-index" },
            { label: "Bernstein Polynomial", slug: "documents/math/bernstein-polynomial" },
            { label: "Gridding And Bernstein Degree", slug: "documents/math/gridding-and-degree" },
            { label: "SOS Certificates On A Hypercube", slug: "documents/math/sos-certificates" },
            {
              label: "pdmat",
              items: [
                { label: "Overview", slug: "documents/reference/pdmat" },
                { label: "Constructor", slug: "documents/reference/pdmat/constructor" },
                { label: "evaluate", slug: "documents/reference/pdmat/evaluate" },
                { label: "plot", slug: "documents/reference/pdmat/plot" },
                { label: "bernsteinTable", slug: "documents/reference/pdmat/bernsteintable" },
                {
                  label: "Matrix Operations",
                  items: [
                    { label: "Overview", slug: "documents/reference/pdmat/matrix-operations" },
                    { label: "Algebra", slug: "documents/reference/pdmat/algebra" },
                    { label: "Structural Operations", slug: "documents/reference/pdmat/structural-operations" },
                    { label: "Indexing And Inspection", slug: "documents/reference/pdmat/indexing-and-inspection" },
                  ],
                },
              ],
            },
            {
              label: "pdvar",
              items: [
                { label: "Overview", slug: "documents/reference/pdvar" },
                { label: "Constructor", slug: "documents/reference/pdvar/constructor" },
                { label: "value", slug: "documents/reference/pdvar/value" },
                { label: "rhodiff", slug: "documents/reference/pdvar/rhodiff" },
                { label: "bernsteinTable", slug: "documents/reference/pdvar/bernsteintable" },
                {
                  label: "Matrix Operations",
                  items: [
                    { label: "Overview", slug: "documents/reference/pdvar/matrix-operations" },
                    { label: "Algebra", slug: "documents/reference/pdvar/algebra" },
                    { label: "Structural Operations", slug: "documents/reference/pdvar/structural-operations" },
                    { label: "Indexing And Inspection", slug: "documents/reference/pdvar/indexing-and-inspection" },
                  ],
                },
                { label: "Comparisons", slug: "documents/reference/pdvar/comparisons" },
              ],
            },
            {
              label: "pdlmi",
              items: [
                { label: "Overview", slug: "documents/reference/pdlmi" },
                { label: "Constructor", slug: "documents/reference/pdlmi/constructor" },
                { label: "toYalmip", slug: "documents/reference/pdlmi/toyalmip" },
                {
                  label: "Certificates",
                  items: [
                    { label: "Pólya", slug: "documents/reference/pdlmi/applypolya" },
                    { label: "Putinar", slug: "documents/reference/pdlmi/applyputinar" },
                    { label: "Full Box", slug: "documents/reference/pdlmi/applyfullboxpreorder" },
                  ],
                },
              ],
            },
            {
              label: "pdbase",
              items: [
                { label: "Overview", slug: "documents/reference/pdbase" },
                { label: "Storage Inspection", slug: "documents/reference/pdbase/storage-inspection" },
                { label: "Bernstein Backend Utilities", slug: "documents/reference/bernstein-utilities" },
              ],
            },
            { label: "Shared Helpers", slug: "documents/reference/shared-helpers" },
          ],
        },
        {
          label: "Examples",
          items: [
            { label: "Workflow Index", slug: "examples" },
            { label: "Solver Smoke Cases", slug: "examples/solver-smoke" },
          ],
        },
        { label: "About me", slug: "about" },
        { label: "Thanks", link: "/thanks/" },
      ],
    }),
  ],
});
