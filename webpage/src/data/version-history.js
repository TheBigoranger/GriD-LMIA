export const versionHistory = [
  {
    version: "v0.4.1",
    date: "2026-07-16",
    status: "current",
    summary:
      "Restructured the printable manual into chapter files, unified the TeX and Web visual grammar, and revised the grid, plotting, certificate, and release-history presentations.",
  },
  {
    version: "v0.4.0",
    date: "2026-07-16",
    status: "previous · 9b8a34c",
    summary:
      "Documented one global comparison mode per inequality family, direct coefficient equality, reorganized class properties, and the three-parameter plotting slice.",
  },
  {
    version: "v0.3.5",
    date: "2026-07-16",
    status: "previous · 75d70dc",
    summary: "Published the expanded manual and interactive Web guide.",
  },
  {
    version: "v0.3.4",
    date: "2026-07-15",
    status: "previous · 2d420cc",
    summary: "Checkpointed the expanded manual and accompanying package documentation.",
  },
  {
    version: "v0.3.3",
    date: "2026-07-15",
    status: "previous · d896146",
    summary: "Added the Putinar certificate manual coverage.",
  },
  {
    version: "v0.3.2",
    date: "2026-07-14",
    status: "previous · eb5ac24",
    summary: "Published the synchronized PD-LMI manual and Web guide.",
  },
  {
    version: "v0.3.1",
    date: "2026-07-14",
    status: "previous · aa71a2a",
    summary:
      "Expanded the manual and renamed the plotting assets from the earlier dpmat spelling to pdmat.",
  },
  {
    version: "v0.3.0",
    date: "2026-07-13",
    status: "previous · 7fc820f",
    summary: "Published the first synchronized printable manual and Web reference.",
  },
  {
    version: "v0.2.0",
    date: "2026-07-09",
    status: "previous · b1e0d51",
    summary: "Published the second documentation milestone.",
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
    "Append a versionHistory entry only for intentional MINOR documentation/API snapshots, or when the user explicitly asks to record a patch release.",
};
