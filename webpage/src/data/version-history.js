export const versionHistory = [
  {
    version: "v0.2.0",
    date: "2026-07-09",
    status: "current",
    summary:
      "Expanded the Bernstein and DP-LMI background, synchronized the TeX and online manuals, and consolidated the implemented dpmat, dpvar, and dplmi reference surface.",
  },
];

export const historyPolicy = {
  sourceOfTruth: "doc/manual.tex",
  updateRule:
    "Change the TeX manual version first, then run npm --prefix webpage run sync:version or any webpage build.",
  appendRule:
    "Append a versionHistory entry only for intentional MINOR documentation/API snapshots, or when the user explicitly asks to record a patch release.",
};
