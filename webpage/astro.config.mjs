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
        { label: "Documents", link: "/documents/" },
        { label: "Examples", link: "/examples/" },
        { label: "Thanks", link: "/thanks/" },
      ],
    }),
  ],
});
