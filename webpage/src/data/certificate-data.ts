export type CertificateKey = "direct" | "polya" | "putinar" | "fullbox";

export interface CertificateSource {
  key: CertificateKey;
  anchor: "direct" | "polya" | "putinar" | "full-box";
  label: string;
  description: string;
  command: string;
  exportCommand: string;
  constraintCount: string;
  boundaryNote: string;
  formula: readonly string[];
  detailRoute: string;
}

export const certificateSources: CertificateSource[] = [
  { key: "direct", anchor: "direct", label: "Direct", description: "The default tests all three degree-two coefficients in each of the two physical cells.", command: "L", exportCommand: "C = L.toYalmip();", constraintCount: "6 constraints: 2 cells × 3 local coefficients.", boundaryNote: "The shared residual boundary handle is reused by both cells; no extra continuity constraint is generated.", formula: ["C^{(c)}[i]\\succeq0,\\quad c=1,2,\\;i=0,1,2"], detailRoute: "documents/reference/pdlmi/constructor/" },
  { key: "polya", anchor: "polya", label: "Pólya", description: "Increment one exactly elevates each cell from degree two to degree three before the direct test.", command: "L.applyPolya(1)", exportCommand: "C = L.applyPolya(1).toYalmip();", constraintCount: "8 constraints: 2 cells × 4 elevated coefficients.", boundaryNote: "Degree elevation preserves the shared residual boundary value; it does not create cross-cell certificate variables.", formula: ["\\widetilde C^{(c)}[i]\\succeq0,\\quad i=0,\\ldots,3"], detailRoute: "documents/reference/pdlmi/applypolya/" },
  {
    key: "putinar",
    anchor: "putinar",
    label: "Putinar",
    description: "For this one-parameter degree-two residual, the default order-one Markov–Lukács certificate uses two Gram blocks and three coefficient identities per cell. In two or more parameters, the Putinar module uses the unweighted term plus one axis-generator term at minimum order ceil(m/2).",
    command: "L.applyPutinar()",
    exportCommand: "C = L.applyPutinar().toYalmip();",
    constraintCount: "10 constraints: 2 cells × (2 PSD blocks + 3 identities).",
    boundaryNote: "Residual boundary handles stay shared, while each physical cell receives independent Gram blocks.",
    formula: [
      "\\ell=1:\\;\\text{Markov--Lukács}",
      "r_{\\min}=\\lfloor m/2\\rfloor",
      "\\ell\\ge2:\\;F=S_0+\\sum_s g_sS_s",
      "g_s=\\alpha_s(1-\\alpha_s),\\;r_{\\min}=\\lceil m/2\\rceil",
    ],
    detailRoute: "documents/reference/pdlmi/applyputinar/",
  },
  { key: "fullbox", anchor: "full-box", label: "Full Box", description: "In one parameter the default full-box selector is the same order-one Markov–Lukács construction as Putinar.", command: "L.applyFullBoxPreorder()", exportCommand: "C = L.applyFullBoxPreorder().toYalmip();", constraintCount: "10 constraints: 2 cells × (2 PSD blocks + 3 identities).", boundaryNote: "Putinar and Full Box coincide in one parameter; Gram blocks remain cell-local even though residual boundary handles are shared.", formula: ["\\ell=1:\\;F=S_0+\\alpha(1-\\alpha)S_1"], detailRoute: "documents/reference/pdlmi/applyfullboxpreorder/" },
];
