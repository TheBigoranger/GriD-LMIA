export const versionHistory = [
  {
    version: "v1.5.1",
    date: "2026-10-13",
    status: "current documentation snapshot and latest tagged GitHub Release",
    summary: "Hardens coefficient arithmetic, decision-dependence metadata, and floating-point boundaries while retaining the v1.5.0 public API and 197-symbol documentation inventory.",
    changes: [
      "Accepts double and single numeric coefficient payloads, algebra constants, and assignment values; converts integer grid coordinates to double and rejects nodes that collapse during conversion.",
      "Clears ContainsDecision when slicing or overwriting removes the last affine decision contribution; preserves small nonzero known-data differences and grid/rate metadata in zero addition and subtraction.",
      "Stabilizes high-degree Bernstein evaluation and binomial ratios, combines coefficient/rate/width scaling in numeric and affine derivatives, and rejects unstable explicit-degree fits and nonfinite interval widths.",
      "Rescales large finite continuity faces, retains exact zero derivatives at tiny cell widths, normalizes overflowing full-axis spline spans, and halves known matrices before symmetrization.",
      "Publishes five source-grounded examples, reorganizes README around installation and current changes, and documents a release-pinned clone for future Code Ocean setup.",
      "Passes 886/886 runtime tests in both the full-suite and coverage runs, including the 171-entry API gate. Production coverage is 3751/3874 statements (96.82%) and 1929/2042 decisions (94.47%); the README example and all five public scripts pass their documented acceptance checks.",
    ],
    compatibility: "Convert integer coefficient payloads and constants explicitly with double or single. Constructor syntax and certificate families are unchanged. These fixes address floating-point intermediates and do not provide arbitrary-precision arithmetic.",
    evidence: { label: "v1.5.1 Release", href: "https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.5.1" },
  },
  {
    version: "v1.5.0",
    date: "2026-09-22",
    status: "preceding tagged GitHub Release",
    summary: "Adds direction-wise Continuity lower bounds, verified known-data seam orders, and higher-order spline decisions with zero auxiliary continuity equalities. Differentiation propagates contributing directional orders, numeric recovery reclassifies coefficients, and common-grid algebra uses exact Bernstein restriction. The manuals cover 197 public symbols. The historical v1.5.0 gate passed 848 cases and 171 API entries, with 96.80% statement and 94.35% decision coverage.",
    changes: ["Introduces direction-wise Continuity bounds and higher-order spline decisions with zero auxiliary continuity equalities.", "Uses exact Bernstein restriction for common-grid algebra and propagates contributing directional orders through differentiation and numeric recovery."],
    compatibility: "Default decision construction remains C0. Higher-order spline controls generally differ from physical-node values. The 848-test and coverage figures above describe this historical release only.",
    evidence: { label: "v1.5.0 Release", href: "https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.5.0" },
  },
  {
    version: "v1.4.3",
    date: "2026-09-04",
    status: "final v1.4 source and documentation snapshot",
    summary: "Expands 141 test files to 809 cases, verifies 169 API entries, rejects function-only arithmetic shortcuts and two active-rate products even when zero, and preserves the 1-by-1 cell container for a fixed rate vertex. The manuals clarify these boundaries and fit complete formulas with native script proportions.",
    changes: ["Expands tensor, affine, rejection, and certificate regressions to 809 cases across 141 files.", "Keeps function-only zero/cancellation arithmetic unsupported and preserves a one-row cell container for a fixed rate vertex."],
    compatibility: "Two active rate-row operands cannot multiply, including all-zero operands. This source/documentation snapshot is not a tagged Release.",
    evidence: { label: "Published source snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/952a9039376ccccf022df23827b414a9650411b2" },
  },
  {
    version: "v1.4.2",
    date: "2026-08-31",
    status: "prior documentation snapshot",
    summary:
      "Documents terminal pdlmi constraint concatenation, records seven source-grounded examples at stable problem-oriented paths, and separates source-authoring builds from PDF-only publication builds. The synchronized manuals index 194 public API records.",
    changes: ["Adds terminal horizontal and vertical pdlmi concatenation with YALMIP constraints and lists, retaining operand order and the empty-list identity.", "Renames the seven examples present at that snapshot by problem semantics and introduces separate source and PDF-only publication builds."],
    compatibility: "Bracket composition returns YALMIP constraints; apply certificate selectors before concatenation. Seven is the historical example count, not the current catalog size.",
    evidence: { label: "Published source snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/8a8be2c849293016b7c8bd18a2836f6d1328b545" },
  },
  {
    version: "v1.4.0",
    date: "2026-08-14",
    status: "earlier tagged GitHub Release",
    summary:
      "Adds dimension-compatible multiplication between a real affine two-dimensional sdpvar and coefficient-backed pdmat in either order. The mixed product returns pdvar and reuses the existing decisions, preserves known grid and rate metadata, and distinguishes metadata-only RateBounds from active rate rows. The synchronized printable and Web manuals retain the 192-symbol public inventory.",
    changes: ["Adds affine sdpvar-by-pdmat products in either order, including scalar broadcasting and compatible rectangular matrices.", "Retains known grid, degree, continuity, and rate metadata without introducing new YALMIP decisions."],
    compatibility: "Ordinary RateBounds with zero stored rows is metadata. Nonlinear or complex symbolic factors remain unsupported; certificate families are unchanged.",
    evidence: { label: "v1.4.0 Release", href: "https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.4.0" },
  },
  {
    version: "v1.3.8",
    date: "2026-08-10",
    status: "final v1.3 documentation snapshot",
    summary:
      "Consolidates the v1.3 public API, product and certificate-plan explanations, and sliding tensor-window certificates, then repairs printable and Web layout at narrow or page-boundary conditions and aligns both mathematical appendices with the main manual style.",
    changes: ["Consolidates the public bernTable, elevate, normDeg, and use* names with reusable elevation, product, Direct, Pólya, and Bernstein–Gram plans.", "Documents SparsePutinar and SparseFullBox tensor windows and repairs narrow-screen and printable appendix layouts."],
    compatibility: "Cumulative migration from v1.2: these names changed during the v1.3 line and are collected at its final documentation snapshot. Removed names have no compatibility aliases. This row does not imply a v1.3.8 tag or that every rename occurred in this patch.",
    migration: [
      ["bernsteinTable", "bernTable"],
      ["applyPolya", "usePolya"],
      ["applyPutinar", "usePutinar"],
      ["applySparsePutinar", "useSpPut"],
      ["applySparseFullBoxPreorder", "useSpBox"],
      ["applyFullBoxPreorder", "useFullBox"],
      ["elevVals", "elevate"],
      ["normalizeDegree", "normDeg"],
    ],
    migrationNote: "Constructor-option and selected-state names remain unchanged, including UsePolya, PutinarOrder, and UseSparseFullBoxPreorder. Update callable names while preserving those options and inspectable properties.",
    evidence: { label: "Published v1.3.8 documentation snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/1f07ab91e8d68d0d6e7d815ec08f2b70bc3eba80" },
  },
  {
    version: "v1.2.4",
    date: "2026-08-05",
    status: "final v1.2 documentation snapshot",
    summary:
      "Retains the final v1.2 manual snapshot before the v1.3 public API cutover.",
    changes: ["Adds SparsePutinar tensor windows, overlapping coefficient accumulation, canonical endpoints, and validation guidance.", "Expands Gram/SOS background and the software-paper citation."],
    compatibility: "This final v1.2 documentation snapshot predates the cumulative v1.3 API renames listed above and is not a tagged Release.",
    evidence: { label: "Published documentation snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/c152d7642c493b352d94a3dddfa1784fb8a3c3b2" },
  },
  {
    version: "v1.1.6",
    date: "2026-07-28",
    status: "final v1.1 documentation snapshot",
    summary:
      "Unifies tensor-grid, cell, Bernstein-degree, residual, target, and Gram notation across both manuals, expands the Bernstein convolution and Gram foundations, and adds the first coefficient-algebra explorers.",
    changes: ["Aligns tensor-grid, cell, degree, residual, target, and Gram notation across both manuals.", "Adds coefficient-algebra explorers and expands Bernstein convolution and Gram foundations."],
    compatibility: "This retained documentation milestone does not change the MATLAB API. It is not represented as a tagged Release.",
    evidence: { label: "Published v1.1.6 documentation snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/8ee81ccf9f501f231e7eb4213a9e39a738425dd0" },
  },
  {
    version: "v1.0.0",
    date: "2026-07-19",
    status: "previous · 6d19619",
    summary:
      "Marks the first stable public release of the documented package workflow. It consolidates installation and test-suite verification, the pdbase/pdmat/pdvar/pdlmi object model, continuous arbitrary-degree decision storage and rate-vertex differentiation, MATLAB-style matrix operations and indexing, and direct, Pólya, Putinar, and full-box finite certificate assembly. This milestone records the implemented and tested surface while preserving runtime behavior.",
    changes: ["Consolidates the four-class object model, continuous decision storage, rate vertices, matrix operations, and finite certificates.", "Documents installation, suite verification, affine-expression limits, tensor-box geometry, certificate sufficiency, and solver ownership."],
    compatibility: "The first stable release records the implemented and tested surface. Later API migrations are documented in the v1.3.8 entry.",
    evidence: { label: "v1.0.0 Release", href: "https://github.com/TheBigoranger/GriD-LMIA/releases/tag/v1.0.0" },
  },
  {
    version: "v0.4.7",
    date: "2026-07-18",
    status: "historical source snapshot",
    summary:
      "Completed the v0.4 manual and Web explorer refresh around the LPV-to-cell-wise-Bernstein-to-solver workflow, including installer guidance, the public API reference, mathematical cross-references, and storage-transformation examples.",
    changes: ["Refreshes the manual and Web explorers around LPV modeling, cell-wise Bernstein data, and solver export.", "Adds installer guidance, mathematical links, and storage-transformation examples."],
    compatibility: "Historical snapshot; use current installation and API pages for supported calls.",
    evidence: { label: "Published source snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/428d35be85c65c2bd60e46fca09c3fb19059c798" },
  },
  {
    version: "v0.3.6",
    date: "2026-07-16",
    status: "previous · fe74a65",
    summary:
      "Completed the renamed pdbase, pdmat, pdvar, and pdlmi reference, expanded cell-wise Bernstein and solver examples, documented direct, Pólya, Putinar, and full-box certificates, and refreshed the printable and Web plotting assets across the v0.3 line.",
    changes: ["Completes the pdbase, pdmat, pdvar, and pdlmi naming transition and forward Bernstein coordinates.", "Adds Putinar and FullBox certificate documentation, independent SOS checks, and entry-wise inequality boundaries."],
    compatibility: "Historical names and validation evidence belong to this snapshot; current APIs are indexed in the reference manual.",
    evidence: { label: "Published source snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/fe74a65ce3b9f8275a5fb626d226d6b773a2bdf5" },
  },
  {
    version: "v0.2.12",
    date: "2026-07-13",
    status: "previous · 98b63e5",
    summary:
      "Published the second complete manual and Web-reference milestone across the v0.2 line, including matrix-function plotting and algebra, derivative-aware decision expressions, finite LMI assembly, and the full-box certificate interface.",
    changes: ["Completes the known-data, decision-expression, and LMI layers with rate-aware differentiation and finite assembly.", "Adds matrix-function plotting, structural algebra, Pólya selection, and deterministic reference examples."],
    compatibility: "Historical API snapshot predating the completed public rename.",
    evidence: { label: "Published source snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/98b63e53a157fa4dfc954d4a02181368ae906383" },
  },
  {
    version: "v0.1.0",
    date: "2026-07-03",
    status: "previous · 63c06ee",
    summary: "Introduced the pdbase foundation and the first package manual for the v0.1 line.",
    changes: ["Introduces the original grid/storage foundation, Bernstein traversal, validation, and helper contracts.", "Provides the first package manual."],
    compatibility: "Historical foundation snapshot, not the current modeling interface.",
    evidence: { label: "Published source snapshot", href: "https://github.com/TheBigoranger/GriD-LMIA/commit/63c06ee09559f6c44e7ff7da43f995c61856012c" },
  },
];

export const historyPolicy = {
  sourceOfTruth: "doc/manual.tex",
  updateRule:
    "Change the TeX manual version first, then run the source-mode webpage build to refresh generated publication data.",
  appendRule:
    "Keep the current documentation snapshot, the latest GitHub Release, and the final patch release for each earlier completed minor line, unless the user explicitly requests another history policy.",
};
