export const versionHistory = [
  {
    version: "v0.4.4",
    date: "2026-07-18",
    status: "current",
    summary:
      "Consolidated the v0.4 documentation line: reorganized the manual around the LPV-to-cellwise workflow, clarified the DPD-LMI chain rule and hypercube storage, completed the public reference and certificate guidance, refreshed figures and plotting assets, and improved the printable and Web manual navigation, typography, and release history.",
  },
  {
    version: "v0.3.6",
    date: "2026-07-16",
    status: "previous · fe74a65",
    summary:
      "Completed the renamed pdbase, pdmat, pdvar, and pdlmi reference; expanded cell-local Bernstein and solver examples; documented direct, Pólya, Putinar, and full-box certificates; and refreshed the printable and Web plotting assets across the v0.3 line.",
  },
  {
    version: "v0.2.12",
    date: "2026-07-13",
    status: "previous · 98b63e5",
    summary:
      "Published the second complete manual and Web-reference milestone across the v0.2 line, including matrix-function plotting and algebra, derivative-aware decision expressions, finite LMI assembly, and the full-box certificate interface.",
  },
  {
    version: "v0.1.0",
    date: "2026-07-03",
    status: "previous · 63c06ee",
    summary: "Introduced the pdbase foundation and the first package manual for the v0.1 line.",
  },
];

export const historyPolicy = {
  sourceOfTruth: "doc/manual.tex",
  updateRule:
    "Change the TeX manual version first, then run npm --prefix webpage run sync:version or any webpage build.",
  appendRule:
    "Keep only the final patch release for each minor line, unless the user explicitly requests another history policy.",
};
