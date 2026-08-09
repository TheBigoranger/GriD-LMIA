export type CertificateKey = "direct" | "polya" | "putinar" | "sparseputinar" | "sparsefullbox" | "fullbox";

export interface CertificateSource {
  key: CertificateKey;
  anchor: "direct" | "polya" | "putinar" | "sparse-putinar" | "sparse-full-box" | "full-box";
  label: string;
  description: string;
  command: string;
  exportCommand: string;
  constraintCount: string;
  boundaryNote: string;
  formula: readonly string[];
  cardFormula: string;
  detailRoute: string;
}

export const certificateSources: CertificateSource[] = [
  { key: "direct", anchor: "direct", label: "Direct", description: "The default tests every sign-normalized residual coefficient in every physical cell and stored rate row.", command: "L", exportCommand: "C = L.toYalmip();", constraintCount: "Coefficient count follows the assembled residual degree vector M.", boundaryNote: "The finite test is sufficient on the parameter cell; exact rate-box vertex reduction has already occurred.", formula: ["C^{(\\vect c)}[\\vect i]\\succeq0"], cardFormula: "C^{(\\vect c)}[\\vect i]\\succeq0,\\quad\\vect i\\in\\mathcal I_{\\vect M}", detailRoute: "documents/math/finite-certificates/direct-and-polya/" },
  { key: "polya", anchor: "polya", label: "Pólya", description: "Pólya elevation by increment vector d changes the Bernstein representation degree, not the residual polynomial.", command: "L.usePolya(d)", exportCommand: "C = L.usePolya(d).toYalmip();", constraintCount: "Coefficient count depends on the assembled degree vector M and increment vector d.", boundaryNote: "A failed fixed increment is inconclusive for the continuous inequality.", formula: ["\\tilde C^{(\\vect c)}[\\vect i]\\succeq0"], cardFormula: "\\tilde S^{(\\vect c)}(\\vect\\alpha)=S^{(\\vect c)}(\\vect\\alpha)\\prod_{s=1}^{\\ell}[\\alpha_s+(1-\\alpha_s)]^{d_s}", detailRoute: "documents/math/finite-certificates/direct-and-polya/" },
  {
    key: "putinar",
    anchor: "putinar",
    label: "Putinar",
    description: "In one parameter, Putinar uses the parity-specific Markov–Lukács interval form. In two or more parameters, it uses the unweighted term plus singleton box-generator terms.",
    command: "L.usePutinar()",
    exportCommand: "C = L.usePutinar().toYalmip();",
    constraintCount: "10 constraints: 2 cells × (2 PSD blocks + 3 identities).",
    boundaryNote: "Residual boundary handles stay shared, while each physical cell receives independent Gram blocks.",
    formula: [
      "\\ell=1:\\;\\vect M=(M_1),\\;\\vect r=(r_1),\\quad r_{1,\\min}=\\lfloor M_1/2\\rfloor",
      "\\ell\\ge2:\\;S=S_0+\\sum_s g_sS_s,\\quad \\vect r_{\\min}=\\lceil \\vect M/2\\rceil",
      "g_s=\\alpha_s(1-\\alpha_s)",
    ],
    cardFormula: "\\begin{gathered}S^{(\\vect c)}=S_0+\\sum_{s=1}^{\\ell}g_sS_s\\\\g_s=\\alpha_s(1-\\alpha_s),\\quad S_s\\succeq0\\end{gathered}",
    detailRoute: "documents/math/finite-certificates/markov-lukacs-and-putinar/",
  },
  {
    key: "sparseputinar",
    anchor: "sparse-putinar",
    label: "SparsePutinar",
    description: "SparsePutinar keeps Putinar's parity-specific Markov–Lukács terms in one parameter and its empty plus singleton-generator terms in higher dimensions. It replaces each dense Bernstein Gram basis by overlapping tensor windows whose side is the CliqueSize value b, and coefficient identities accumulate every overlapping contribution.",
    command: "L.useSpPut()",
    exportCommand: "C = L.useSpPut().toYalmip();",
    constraintCount: "For a scalar one-parameter degree-four target with order two and CliqueSize two: 3 PSD blocks + 5 identities = 8 constraints.",
    boundaryNote: "Each physical cell, stored rate row, and column-major entrywise copy receives independent tensor-window blocks. Symmetric inequalities use matrix-valued blocks.",
    formula: [
      "w_s=\\min(b,d_s+1),\\quad \\dim Q_{\\vect u}=n\\prod_s w_s",
      "N_{\\mathrm{win}}=\\prod_s(d_s-w_s+2)",
      "C[\\vect k]=\\sum_{q}\\sum_{\\vect u}\\mathcal A_{q,\\vect u}(Q_{q,\\vect u})[\\vect k]",
    ],
    cardFormula: "S^{(\\vect c)}=\\sum_{q\\in\\mathcal Q_{\\mathrm P}}g_q\\sum_{\\vect u}Z_{q,\\vect u}^{\\mathsf T}Q_{q,\\vect u}Z_{q,\\vect u},\\quad Q_{q,\\vect u}\\succeq0",
    detailRoute: "documents/math/finite-certificates/sparseputinar/",
  },
  {
    key: "sparsefullbox",
    anchor: "sparse-full-box",
    label: "SparseFullBox",
    description: "SparseFullBox keeps every FullBox parity or generator-mask family and exact identity while replacing each dense tensor basis by overlapping windows of side length w. Side length one canonicalizes to Direct, while a side that spans every active basis axis canonicalizes to FullBox.",
    command: "L.useSpBox()",
    exportCommand: "C = L.useSpBox().toYalmip();",
    constraintCount: "For the one-parameter degree-two fixture, the default width two is the FullBox endpoint: 10 constraints across two cells.",
    boundaryNote: "Every physical cell, stored rate row, and column-major matrix entry receives an independent certificate; only residual boundary handles remain shared.",
    formula: [
      "w=1:\\;\\text{Direct}",
      "1<w<\\max_s(r_s+1):\\;Q_{J,\\vect u}\\succeq0,\\;\\text{sliding tensor windows}",
      "w\\ge\\max_s(r_s+1):\\;\\text{FullBox}",
    ],
    cardFormula: "S^{(\\vect c)}(\\vect\\alpha)=\\sum_{J\\subseteq[\\ell]}g_J(\\vect\\alpha)\\sum_{\\vect u}Z_{J,\\vect u}^{\\mathsf T}Q_{J,\\vect u}Z_{J,\\vect u},\\quad Q_{J,\\vect u}\\succeq0",
    detailRoute: "documents/math/finite-certificates/sparsefullbox-and-fullbox/",
  },
  { key: "fullbox", anchor: "full-box", label: "FullBox", description: "FullBox uses every square-free product of the box generators; in one parameter it coincides with the Markov–Lukács form.", command: "L.useFullBox()", exportCommand: "C = L.useFullBox().toYalmip();", constraintCount: "Constraint count depends on dimension, assembled degree vector M, and absolute order vector r.", boundaryNote: "Putinar and FullBox coincide in one parameter; their multivariate generator families differ.", formula: ["\\ell=1:\\;S=S_0+\\alpha(1-\\alpha)S_1"], cardFormula: "S^{(\\vect c)}(\\vect\\alpha)=\\sum_{J\\subseteq[\\ell]}g_J(\\vect\\alpha)Z_J(\\vect\\alpha)^{\\mathsf T}Q_JZ_J(\\vect\\alpha),\\quad Q_J\\succeq0", detailRoute: "documents/math/finite-certificates/sparsefullbox-and-fullbox/" },
];
