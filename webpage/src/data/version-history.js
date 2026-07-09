export const versionHistory = [];

export const historyPolicy = {
  sourceOfTruth: "doc/manual.tex",
  updateRule:
    "Change the TeX manual version first, then run npm --prefix webpage run sync:version or any webpage build.",
  appendRule:
    "Append a versionHistory entry only for intentional MINOR documentation/API snapshots, or when the user explicitly asks to record a patch release.",
};
