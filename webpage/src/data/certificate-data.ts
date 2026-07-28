export type CertificateKey = "direct" | "polya" | "putinar" | "sparsefullbox" | "fullbox";

export interface CertificateSource {
  key: CertificateKey;
  anchor: "direct" | "polya" | "putinar" | "sparse-full-box" | "full-box";
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
  { key: "polya", anchor: "polya", label: "Pólya", description: "Pólya elevation by increment d changes the Bernstein representation degree, not the residual polynomial.", command: "L.applyPolya(d)", exportCommand: "C = L.applyPolya(d).toYalmip();", constraintCount: "Coefficient count depends on the assembled degree M and increment d.", boundaryNote: "A failed fixed increment is inconclusive for the continuous inequality.", formula: ["\\widetilde C^{(\\mathbf c)}[\\mathbf i]\\succeq0"], cardFormula: "\\widetilde S^{(\\mathbf c)}(\\boldsymbol\\alpha)=S^{(\\mathbf c)}(\\boldsymbol\\alpha)\\prod_{s=1}^{\\ell}[\\alpha_s+(1-\\alpha_s)]^d", detailRoute: "documents/math/finite-certificates/direct-and-polya/" },
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
    key: "sparsefullbox",
    anchor: "sparse-full-box",
    label: "SparseFullBox",
    description: "SparseFullBox keeps every FullBox parity or generator-mask family and exact identity while restricting Gram support to a band-limited form, realized by overlapping axis-aligned tensor-window PSD cliques. Bandwidth one canonicalizes to Direct; a width at least order + 1 canonicalizes to FullBox.",
    command: "L.applySparseFullBoxPreorder()",
    exportCommand: "C = L.applySparseFullBoxPreorder().toYalmip();",
    constraintCount: "For the one-parameter degree-two fixture, the default width two is the FullBox endpoint: 10 constraints across two cells.",
    boundaryNote: "Every physical cell, stored rate row, and column-major matrix entry receives an independent certificate; only residual boundary handles remain shared.",
    formula: [
      "b=1:\\;\\text{Direct}",
      "1<b<r+1:\\;\\text{band-limited Gram support}",
      "b\\ge r+1:\\;\\text{FullBox}",
    ],
    cardFormula: "\\begin{gathered}S^{(\\mathbf c)}=\\sum_{J}\\sum_{\\mathbf t}g_JS_{J,\\mathbf t}\\\\\\operatorname{supp}S_{J,\\mathbf t}\\subseteq\\prod_a\\{t_a,\\ldots,t_a+b-1\\}\\end{gathered}",
    detailRoute: "documents/math/finite-certificates/sparsefullbox-and-fullbox/",
  },
  { key: "fullbox", anchor: "full-box", label: "FullBox", description: "FullBox uses every square-free product of the box generators; in one parameter it coincides with the Markov–Lukács form.", command: "L.applyFullBoxPreorder()", exportCommand: "C = L.applyFullBoxPreorder().toYalmip();", constraintCount: "Constraint count depends on dimension, assembled degree M, and absolute order r.", boundaryNote: "Putinar and FullBox coincide in one parameter; their multivariate generator families differ.", formula: ["\\ell=1:\\;S=S_0+\\alpha(1-\\alpha)S_1"], cardFormula: "\\begin{gathered}S^{(\\mathbf c)}=\\sum_{J\\subseteq[\\ell]}g_{J}S_{J}\\\\g_{J}=\\prod_{s\\in J}\\alpha_s(1-\\alpha_s),\\quad S_{J}\\succeq0\\end{gathered}", detailRoute: "documents/math/finite-certificates/sparsefullbox-and-fullbox/" },
];
