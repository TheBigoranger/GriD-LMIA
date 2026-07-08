export const versionHistory = [
  {
    version: "current",
    status: "manual-synced",
    date: "2026-07-08",
    summary:
      "Reference-first manual site for the current DP-LMI v0 slice. The displayed current version is synchronized from doc/manual.tex during the webpage build.",
  },
];

export const historyPolicy = {
  sourceOfTruth: "doc/manual.tex",
  updateRule:
    "Change the TeX manual version first, then run npm --prefix webpage run sync:version or any webpage build.",
  appendRule:
    "Append a versionHistory entry whenever a public manual/API behavior snapshot is intentionally rolled forward.",
};
