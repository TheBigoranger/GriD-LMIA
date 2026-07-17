export const versionHistory = [
  {
    version: "v0.4.2",
    date: "2026-07-17",
    status: "current",
    summary:
      "Reorganized the manual around the path from LPV models to cellwise constraints, clarified the DPD-LMI chain rule and hypercube storage model, consolidated the public reference, and repaired the matrix and Bernstein figures. The Web guide now uses the same five-stage workflow.",
  },
  {
    version: "v0.3.6",
    date: "2026-07-16",
    status: "previous · fe74a65",
    summary:
      "Completed the renamed pdbase, pdmat, pdvar, and pdlmi reference; expanded cell-local Bernstein and solver examples; documented direct, Pólya, Putinar, and full-box certificates; and refreshed the printable and Web plotting assets.",
  },
  {
    version: "v0.2.12",
    date: "2026-07-13",
    status: "previous · 98b63e5",
    summary:
      "Published the second complete manual and Web-reference milestone, including matrix-function plotting and algebra, derivative-aware decision expressions, finite LMI assembly, and the full-box certificate interface.",
  },
  {
    version: "v0.1.0",
    date: "2026-07-03",
    status: "previous · 63c06ee",
    summary: "Introduced the pdbase foundation and the first package manual.",
  },
];

export const historyPolicy = {
  sourceOfTruth: "doc/manual.tex",
  updateRule:
    "Change the TeX manual version first, then run npm --prefix webpage run sync:version or any webpage build.",
  appendRule:
    "Keep only the final patch release for each minor line, unless the user explicitly requests another history policy.",
};
