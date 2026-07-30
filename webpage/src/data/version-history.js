export const versionHistory = [
  {
    version: "v1.2.0",
    date: "2026-07-29",
    status: "current and latest GitHub Release",
    summary:
      "Adds direction-wise Bernstein degrees to pdbase, pdmat, and pdvar; scalar-or-vector elevation and componentwise degree algebra; exact multivariate rhodiff alignment with zero-degree-axis support; and scalar-or-vector Pólya, Putinar, SparseFullBox, and FullBox certificate parameters. Degrees and orders are stored as row vectors, tensor counts use the product of per-axis cardinalities, and SparseFullBox retains a scalar bandwidth with anisotropic endpoint normalization.",
  },
  {
    version: "v1.1.6",
    date: "2026-07-28",
    status: "final v1.1 documentation snapshot",
    summary:
      "Unifies tensor-grid, cell, Bernstein-degree, residual, target, and Gram notation across both manuals; states SparseFullBox through Q_J^(w) for symmetric block-band Gram matrices of bandwidth w; expands the Bernstein convolution and Gram/SOS foundations; adds Math Concepts navigation plus pdmat addition, multiplication, and elevation explorers; and keeps the three-dimensional Welcome grid visible at every supported rotation. The MATLAB API is unchanged.",
  },
  {
    version: "v1.0.0",
    date: "2026-07-19",
    status: "previous · 6d19619",
    summary:
      "Marks the first stable public release of the documented package workflow. It consolidates installation and test-suite verification, the pdbase/pdmat/pdvar/pdlmi object model, continuous arbitrary-degree decision storage and rate-vertex differentiation, MATLAB-style matrix operations and indexing, and direct, Pólya, Putinar, and full-box finite certificate assembly. This milestone stabilizes the implemented and tested surface; it does not add new runtime behavior.",
  },
  {
    version: "v0.4.7",
    date: "2026-07-18",
    status: "previous · c6a2e25",
    summary:
      "Completed the v0.4 manual and Web explorer refresh around the LPV-to-cellwise-Bernstein-to-solver workflow, including installer guidance, the public API reference, mathematical cross-references, and storage-transformation examples.",
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
    "Keep the current documentation snapshot, the latest GitHub Release, and the final patch release for each earlier completed minor line, unless the user explicitly requests another history policy.",
};
