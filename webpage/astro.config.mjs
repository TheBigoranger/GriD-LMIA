// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import react from "@astrojs/react";
import { unified } from "@astrojs/markdown-remark";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import { katexOptions } from "./src/lib/katex-options.js";
import rehypeKatexStrict from "./src/lib/rehype-katex-strict.js";
import remarkTerminologyLinks from "./src/lib/remark-terminology-links.js";

// Keep the rendered top-level manual navigation independent of nested group size.
const sidebarOrder = ["Reference", "Learn", "Examples", "Welcome", "Install", "Citing", "Version History", "About", "Thanks"];

// https://astro.build/config
export default defineConfig({
  site: "https://thebigoranger.github.io",
  base: "/GriD-LMIA",
  markdown: {
    processor: unified({
      remarkPlugins: [remarkTerminologyLinks, remarkMath],
      rehypePlugins: [[rehypeKatex, katexOptions], rehypeKatexStrict],
    }),
  },
  integrations: [
    react(),
    starlight({
      title: "GriD-LMIA Manual",
      description:
        "Reference-first manual for GriD-LMIA, the Gridding-based DPD-LMI Assembler.",
      customCss: ["katex/dist/katex.min.css", "./src/styles/manual.css"],
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/TheBigoranger/GriD-LMIA",
        },
      ],
      components: {
        Head: "./src/components/Head.astro",
        Header: "./src/components/Header.astro",
      },
      sidebar: [
        { label: "Welcome", link: "/" },
        { label: "Install", slug: "install" },
        { label: "Citing", slug: "citing" },
        { label: "Version History", slug: "version-history" },
        {
          label: "Learn",
          items: [
            { label: "Learn And Reference Portal", slug: "documents" },
            { label: "Task And Example Lookup", slug: "documents/reader-aids" },
            { label: "Notation", slug: "documents/math/notation" },
            { label: "DPD-LMI And LPV L2-Gain Model", slug: "documents/math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain" },
            { label: "Rate-Box Reduction And Interface Analysis", slug: "documents/math/modeling-and-analysis/rate-box-and-interface-analysis" },
            { label: "Gridding And Local Coordinates", slug: "documents/math/gridding-and-degree" },
            { label: "Bernstein Basis, Continuity, And Storage", slug: "documents/math/bernstein-polynomial" },
            { label: "Coefficient Algebra", slug: "documents/math/coordinates-and-bernstein/coefficient-algebra" },
            { label: "Certificate Map And Selection Guide", slug: "documents/math/sos-certificates" },
            { label: "Direct And Pólya", slug: "documents/math/finite-certificates/direct-and-polya" },
            { label: "Markov–Lukács And Putinar", slug: "documents/math/finite-certificates/markov-lukacs-and-putinar" },
            { label: "SparsePutinar Tensor Windows", slug: "documents/math/finite-certificates/sparseputinar" },
            { label: "SparseFullBox And FullBox", slug: "documents/math/finite-certificates/sparsefullbox-and-fullbox" },
          ],
        },
        {
          label: "Reference",
          items: [
            { label: "Generated API Lookup", slug: "documents/reference-index" },
            { label: "Task And Diagnostic Lookup", slug: "documents/reader-aids" },
            {
              label: "pdmat",
              items: [
                { label: "Overview", slug: "documents/reference/pdmat" },
                { label: "Constructor", slug: "documents/reference/pdmat/constructor" },
                { label: "Storage", slug: "documents/reference/pdmat/storage-and-elevation" },
                { label: "elevate", slug: "documents/reference/pdmat/elevate" },
                { label: "evaluate", slug: "documents/reference/pdmat/evaluate" },
                { label: "rhodiff", slug: "documents/reference/pdmat/rhodiff" },
                { label: "plot", slug: "documents/reference/pdmat/plot" },
                { label: "bernTable", slug: "documents/reference/pdmat/berntable" },
                { label: "Comparisons", slug: "documents/reference/pdmat/comparisons" },
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
                { label: "Storage And Evaluation", slug: "documents/reference/pdvar/storage-and-evaluation" },
                { label: "value", slug: "documents/reference/pdvar/value" },
                { label: "rhodiff", slug: "documents/reference/pdvar/rhodiff" },
                { label: "bernTable", slug: "documents/reference/pdvar/berntable" },
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
                    { label: "Pólya", slug: "documents/reference/pdlmi/usepolya" },
                    { label: "Putinar", slug: "documents/reference/pdlmi/useputinar" },
                    { label: "SparsePutinar", slug: "documents/reference/pdlmi/usespput" },
                    { label: "SparseFullBox", slug: "documents/reference/pdlmi/usespbox" },
                    { label: "FullBox", slug: "documents/reference/pdlmi/usefullbox" },
                  ],
                },
              ],
            },
            {
              label: "pdbase",
              items: [
                { label: "Overview", slug: "documents/reference/pdbase" },
                { label: "Constructor", slug: "documents/reference/pdbase/constructor" },
                { label: "Storage Inspection", slug: "documents/reference/pdbase/storage-inspection" },
                { label: "Evaluation And Elevation", slug: "documents/reference/pdbase/evaluation-and-elevation" },
                { label: "Matrix Operations", slug: "documents/reference/pdbase/matrix-operations" },
                { label: "Indexing Protocol", slug: "documents/reference/pdbase/indexing-protocol" },
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
            { label: "Certificate Selection", slug: "examples/certificate-selection" },
            { label: "Solver Smoke Cases", slug: "examples/solver-smoke" },
          ],
        },
        { label: "About", slug: "about" },
        { label: "Thanks", link: "/thanks/" },
      ].sort((left, right) => sidebarOrder.indexOf(left.label) - sidebarOrder.indexOf(right.label)),
    }),
  ],
});
