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
  { key: "direct", anchor: "direct", label: "Direct", description: "The default tests every sign-normalized residual coefficient in every physical cell and stored rate row.", command: "L", exportCommand: "C = L.toYalmip();", constraintCount: "Coefficient count follows the assembled residual degree M.", boundaryNote: "The finite test is sufficient on the parameter cell; exact rate-box vertex reduction has already occurred.", formula: ["C^{(\\mathbf c)}[\\mathbf i]\\succeq0"], cardFormula: "C^{(\\mathbf c)}[\\mathbf i]\\succeq0,\\quad\\mathbf i\\in\\mathcal I_M", detailRoute: "documents/math/finite-certificates/direct-and-polya/" },
  { key: "polya", anchor: "polya", label: "Pólya", description: "Pólya elevation by increment d changes the Bernstein representation degree, not the residual polynomial.", command: "L.applyPolya(d)", exportCommand: "C = L.applyPolya(d).toYalmip();", constraintCount: "Coefficient count depends on the assembled degree M and increment d.", boundaryNote: "A failed fixed increment is inconclusive for the continuous inequality.", formula: ["\\tilde C^{(\\mathbf c)}[\\mathbf i]\\succeq0"], cardFormula: "\\tilde S^{(\\mathbf c)}(\\boldsymbol\\alpha)=S^{(\\mathbf c)}(\\boldsymbol\\alpha)\\prod_{s=1}^{\\ell}[\\alpha_s+(1-\\alpha_s)]^d", detailRoute: "documents/math/finite-certificates/direct-and-polya/" },
  {
    key: "putinar",
    anchor: "putinar",
    label: "Putinar",
    description: "In one parameter, Putinar uses the parity-specific Markov–Lukács interval form. In two or more parameters, it uses the unweighted term plus singleton box-generator terms.",
    command: "L.applyPutinar()",
    exportCommand: "C = L.applyPutinar().toYalmip();",
    constraintCount: "10 constraints: 2 cells × (2 PSD blocks + 3 identities).",
    boundaryNote: "Residual boundary handles stay shared, while each physical cell receives independent Gram blocks.",
    formula: [
      "\\ell=1:\\;\\text{Markov--Lukács},\\quad r_{\\min}=\\lfloor M/2\\rfloor",
      "\\ell\\ge2:\\;S=S_0+\\sum_s g_sS_s,\\quad r_{\\min}=\\lceil M/2\\rceil",
      "g_s=\\alpha_s(1-\\alpha_s)",
    ],
    cardFormula: "\\begin{gathered}S^{(\\mathbf c)}=S_0+\\sum_{s=1}^{\\ell}g_sS_s\\\\g_s=\\alpha_s(1-\\alpha_s),\\quad S_s\\succeq0\\end{gathered}",
    detailRoute: "documents/math/finite-certificates/markov-lukacs-and-putinar/",
  },
  {
    key: "sparseputinar",
    anchor: "sparse-putinar",
    label: "SparsePutinar",
    description: "SparsePutinar keeps Putinar's parity-specific Markov–Lukács terms in one parameter and its empty plus singleton-generator terms in higher dimensions. It replaces each dense Bernstein Gram basis by overlapping tensor windows of clique size b, and coefficient identities accumulate every overlapping contribution.",
    command: "L.applySparsePutinar()",
    exportCommand: "C = L.applySparsePutinar().toYalmip();",
    constraintCount: "For a scalar one-parameter degree-four target with order two and clique size two: 3 PSD blocks + 5 identities = 8 constraints.",
    boundaryNote: "Each physical cell, stored rate row, and column-major entrywise copy receives independent clique blocks. Symmetric inequalities use matrix-valued blocks.",
    formula: [
      "w_s=\\min(b,d_s+1),\\quad \\dim Q_{\\mathbf u}=n\\prod_s w_s",
      "N_{\\mathrm{win}}=\\prod_s(d_s-w_s+2)",
      "C[\\mathbf k]=\\sum_{q}\\sum_{\\mathbf u}\\mathcal A_{q,\\mathbf u}(Q_{q,\\mathbf u})[\\mathbf k]",
    ],
    cardFormula: "S^{(\\mathbf c)}=\\sum_{q\\in\\mathcal Q_{\\mathrm P}}g_q\\sum_{\\mathbf u}Z_{q,\\mathbf u}^{\\mathsf T}Q_{q,\\mathbf u}Z_{q,\\mathbf u},\\quad Q_{q,\\mathbf u}\\succeq0",
    detailRoute: "documents/math/finite-certificates/sparseputinar/",
  },
  {
    key: "sparsefullbox",
    anchor: "sparse-full-box",
    label: "SparseFullBox",
    description: "SparseFullBox keeps every FullBox parity or generator-mask family and exact identity while replacing each dense Gram matrix Q_J with a symmetric block-band Gram matrix Q_J^(w) of scalar bandwidth w. Bandwidth one canonicalizes to Direct; a bandwidth at least max(order + 1) canonicalizes to FullBox.",
    command: "L.applySparseFullBoxPreorder()",
    exportCommand: "C = L.applySparseFullBoxPreorder().toYalmip();",
    constraintCount: "For the one-parameter degree-two fixture, the default width two is the FullBox endpoint: 10 constraints across two cells.",
    boundaryNote: "Every physical cell, stored rate row, and column-major matrix entry receives an independent certificate; only residual boundary handles remain shared.",
    formula: [
      "w=1:\\;\\text{Direct}",
      "1<w<\\max_s(r_s+1):\\;Q_J^{(w)}\\succeq0,\\;\\text{symmetric block-band}",
      "w\\ge\\max_s(r_s+1):\\;\\text{FullBox}",
    ],
    cardFormula: "S^{(\\mathbf c)}(\\boldsymbol\\alpha)=\\sum_{J\\subseteq[\\ell]}g_J(\\boldsymbol\\alpha)Z_J(\\boldsymbol\\alpha)^{\\mathsf T}Q_J^{(w)}Z_J(\\boldsymbol\\alpha),\\quad Q_J^{(w)}\\succeq0",
    detailRoute: "documents/math/finite-certificates/sparsefullbox-and-fullbox/",
  },
  { key: "fullbox", anchor: "full-box", label: "FullBox", description: "FullBox uses every square-free product of the box generators; in one parameter it coincides with the Markov–Lukács form.", command: "L.applyFullBoxPreorder()", exportCommand: "C = L.applyFullBoxPreorder().toYalmip();", constraintCount: "Constraint count depends on dimension, assembled degree M, and absolute order r.", boundaryNote: "Putinar and FullBox coincide in one parameter; their multivariate generator families differ.", formula: ["\\ell=1:\\;S=S_0+\\alpha(1-\\alpha)S_1"], cardFormula: "S^{(\\mathbf c)}(\\boldsymbol\\alpha)=\\sum_{J\\subseteq[\\ell]}g_J(\\boldsymbol\\alpha)Z_J(\\boldsymbol\\alpha)^{\\mathsf T}Q_JZ_J(\\boldsymbol\\alpha),\\quad Q_J\\succeq0", detailRoute: "documents/math/finite-certificates/sparsefullbox-and-fullbox/" },
];
