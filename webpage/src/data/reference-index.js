import { documentationRecords } from "./documentation-contracts.js";

export const referenceGroups = [
  { id: "pdmat", label: "pdmat", description: "Function-backed known data and coefficient-backed Bernstein operations." },
  { id: "pdvar", label: "pdvar", description: "Continuous arbitrary-degree affine decisions and rate-vertex differentiation." },
  { id: "pdlmi", label: "pdlmi", description: "Direct constraints and five opt-in finite certificate families." },
  { id: "pdbase-backend", label: "pdbase", description: "Public cell-local storage, traversal, transformation, and matrix protocols." },
  { id: "shared-helpers", label: "Shared helpers", description: "Public validation, grid, degree, rate-row, and Bernstein-convolution functions." },
  { id: "setup", label: "Setup", description: "Repository installation and verification entry point." },
];

const groupFor = (owner) => ({
  pdmat: "pdmat",
  pdvar: "pdvar",
  pdlmi: "pdlmi",
  pdbase: "pdbase-backend",
  helper: "shared-helpers",
  root: "setup",
})[owner];

const typeFor = (record) => record.inherited_from
  ? `${record.kind}, inherited from ${record.inherited_from}`
  : record.kind;

export const referenceEntries = documentationRecords.map((record) => ({
  name: record.owner === "helper" ? `helper.${record.symbol}` : record.symbol,
  type: typeFor(record),
  task: record.supported_scope,
  group: groupFor(record.owner),
  href: `/GriD-LMIA${record.web_route_or_anchor}`,
  recordId: record.id,
}));
