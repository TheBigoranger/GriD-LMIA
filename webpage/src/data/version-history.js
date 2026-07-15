export const versionHistory = [
  {
    version: "v0.3.2",
    date: "2026-07-14",
    status: "previous",
    summary:
      "Standardized the PD-LMI identity, replaced the introductory linear case with a quadratic two-cell DPD-LMI, expanded ordered Bernstein convolution, and rebuilt the Web diagrams for responsive reading.",
  },
  {
    version: "v0.3.0",
    date: "2026-07-13",
    status: "previous",
    summary:
      "Renamed the public MATLAB API to pdbase, pdmat, pdvar, and pdlmi; tightened helper ownership; and expanded the manual and website with hypercube SOS certificate mathematics.",
  },
  {
    version: "v0.2.0",
    date: "2026-07-09",
    status: "previous",
    summary:
      "Expanded the Bernstein and PD-LMI background, synchronized the TeX and online manuals, and consolidated the implemented pdmat, pdvar, and pdlmi reference surface.",
  },
];

export const historyPolicy = {
  sourceOfTruth: "doc/manual.tex",
  updateRule:
    "Change the TeX manual version first, then run npm --prefix webpage run sync:version or any webpage build.",
  appendRule:
    "Append a versionHistory entry only for intentional MINOR documentation/API snapshots, or when the user explicitly asks to record a patch release.",
};
