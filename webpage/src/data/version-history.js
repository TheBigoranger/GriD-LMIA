export const versionHistory = [
  {
    version: "v1.3.7",
    date: "2026-08-10",
    status: "current documentation",
    summary:
      "Aligns the printable and Web manuals with the source-indexed 192-symbol public API, restores their shared generated inventory contract, and uses explicit Cartesian-product traversal for every complete local-label sum. It retains the example-led class chapters, solver-status boundaries, and mathematical appendices of v1.3.6. The MATLAB API is unchanged, and v1.3.0 remains the latest tagged GitHub Release.",
  },
  {
    version: "v1.3.0",
    date: "2026-08-08",
    status: "latest tagged GitHub Release",
    summary:
      "Introduced the v1.3 public API documentation, sparse elevation and product-kernel explanations, reusable Bernstein–Gram maps, sliding tensor-window certificates, and three interactive assembly-plan explorers.",
  },
  {
    version: "v1.2.4",
    date: "2026-08-05",
    status: "final v1.2 documentation snapshot",
    summary:
      "Retains the final v1.2 manual snapshot before the v1.3 public API cutover.",
  },
  {
    version: "v1.1.6",
    date: "2026-07-28",
    status: "final v1.1 documentation snapshot",
    summary:
      "Unifies tensor-grid, cell, Bernstein-degree, residual, target, and Gram notation across both manuals, expands the Bernstein convolution and Gram foundations, and adds the first coefficient-algebra explorers.",
  },
  {
    version: "v1.0.0",
    date: "2026-07-19",
    status: "previous · 6d19619",
    summary:
      "Marks the first stable public release of the documented package workflow. It consolidates installation and test-suite verification, the pdbase/pdmat/pdvar/pdlmi object model, continuous arbitrary-degree decision storage and rate-vertex differentiation, MATLAB-style matrix operations and indexing, and direct, Pólya, Putinar, and full-box finite certificate assembly. This milestone records the implemented and tested surface while preserving runtime behavior.",
  },
  {
    version: "v0.4.7",
    date: "2026-07-18",
    status: "previous · c6a2e25",
    summary:
      "Completed the v0.4 manual and Web explorer refresh around the LPV-to-cell-wise-Bernstein-to-solver workflow, including installer guidance, the public API reference, mathematical cross-references, and storage-transformation examples.",
  },
  {
    version: "v0.3.6",
    date: "2026-07-16",
    status: "previous · fe74a65",
    summary:
      "Completed the renamed pdbase, pdmat, pdvar, and pdlmi reference, expanded cell-wise Bernstein and solver examples, documented direct, Pólya, Putinar, and full-box certificates, and refreshed the printable and Web plotting assets across the v0.3 line.",
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
    "Keep the current documentation snapshot, the latest GitHub Release, and the final patch release for each earlier completed minor line, unless the user explicitly requests another history policy.",
};
