export const referenceEntries = [
  {
    name: "dpbase",
    type: "Backend class",
    task: "Inspect cell-local Bernstein storage shared by dpmat and dpvar.",
    href: "/DP-LMI-package/documents/reference/dpbase/",
  },
  {
    name: "cells",
    type: "dpbase method",
    task: "Enumerate physical cell subscripts.",
    href: "/DP-LMI-package/documents/reference/dpbase/#cells",
  },
  {
    name: "coeffs",
    type: "dpbase method",
    task: "Read local Bernstein coefficient families.",
    href: "/DP-LMI-package/documents/reference/dpbase/#coeffs",
  },
  {
    name: "lbls",
    type: "dpbase method",
    task: "Inspect local Bernstein labels in flat row order.",
    href: "/DP-LMI-package/documents/reference/dpbase/#lbls",
  },
  {
    name: "dpmat",
    type: "Known-data class",
    task: "Represent finite real matrix data on a parameter grid.",
    href: "/DP-LMI-package/documents/reference/dpmat/",
  },
  {
    name: "evaluate",
    type: "dpmat method",
    task: "Evaluate known matrix data at one parameter point.",
    href: "/DP-LMI-package/documents/reference/dpmat/#evaluate",
  },
  {
    name: "plot",
    type: "dpmat method",
    task: "Sample one- or two-parameter known data for diagnostics.",
    href: "/DP-LMI-package/documents/reference/dpmat/#display-table-and-plot",
  },
  {
    name: "dpvar",
    type: "Decision class",
    task: "Create continuous YALMIP-backed Bernstein decision expressions.",
    href: "/DP-LMI-package/documents/reference/dpvar/",
  },
  {
    name: "rhodiff",
    type: "dpvar method",
    task: "Build discontinuous rate-vertex derivative expressions.",
    href: "/DP-LMI-package/documents/reference/dpvar/#rhodiff",
  },
  {
    name: "le/ge",
    type: "dpvar comparison",
    task: "Create dplmi constraints from dpvar residuals.",
    href: "/DP-LMI-package/documents/reference/dpvar/#comparisons",
  },
  {
    name: "dplmi",
    type: "Constraint class",
    task: "Store direct coefficient-wise YALMIP constraints.",
    href: "/DP-LMI-package/documents/reference/dplmi/",
  },
  {
    name: "toYalmip",
    type: "dplmi method",
    task: "Concatenate stored constraints for YALMIP optimize calls.",
    href: "/DP-LMI-package/documents/reference/dplmi/#toyalmip",
  },
];
