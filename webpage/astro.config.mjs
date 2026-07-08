// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

// https://astro.build/config
export default defineConfig({
  site: "https://thebigoranger.github.io",
  base: "/DP-LMI-package",
  integrations: [
    starlight({
      title: "DP-LMI Manual",
      description:
        "Reference-first manual for the DP-LMI MATLAB/YALMIP package.",
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/thebigoranger/DP-LMI-package",
        },
      ],
      sidebar: [
        { label: "Welcome", link: "/" },
        {
          label: "Documents",
          items: [
            { label: "Reference Index", slug: "documents" },
            { label: "Lookup Table", slug: "documents/reference-index" },
            {
              label: "Mathematics",
              items: [
                {
                  label: "Bernstein Polynomial",
                  slug: "documents/math/bernstein-polynomial",
                },
              ],
            },
            {
              label: "Reference",
              items: [
                { label: "dpbase", slug: "documents/reference/dpbase" },
                { label: "dpmat", slug: "documents/reference/dpmat" },
                { label: "dpvar", slug: "documents/reference/dpvar" },
                { label: "dplmi", slug: "documents/reference/dplmi" },
              ],
            },
          ],
        },
        { label: "Examples", slug: "examples" },
        { label: "Thanks", slug: "thanks" },
      ],
    }),
  ],
});
