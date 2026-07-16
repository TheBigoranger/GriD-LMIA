export type CertificateKey = "direct" | "polya" | "putinar" | "fullbox";

export interface CertificateSource {
  key: CertificateKey;
  anchor: "direct" | "polya" | "putinar" | "full-box";
  label: string;
  description: string;
  command: string;
  formula: readonly string[];
  detailRoute: string;
}

export const certificateSources: CertificateSource[] = [
  { key: "direct", anchor: "direct", label: "Direct", description: "The default test constrains every local Bernstein coefficient of the residual.", command: "L", formula: ["C^{(\\mathbf c)}[\\mathbf i]\\succeq0"], detailRoute: "documents/reference/pdlmi/constructor/" },
  { key: "polya", anchor: "polya", label: "Pólya", description: "Exact degree elevation changes the coefficient representation before the direct test.", command: "L.applyPolya(d)", formula: ["\\widetilde C^{(\\mathbf c)}[\\mathbf i]\\succeq0"], detailRoute: "documents/reference/pdlmi/applypolya/" },
  {
    key: "putinar",
    anchor: "putinar",
    label: "Putinar",
    description: "In one parameter this selector uses the parity-specific Markov–Lukács form with minimum floor(m/2). In two or more parameters it uses the unweighted-plus-singleton-axis module with minimum ceil(m/2).",
    command: "L.applyPutinar(r)",
    formula: [
      "\\ell=1:\\;\\text{Markov--Lukács}",
      "r_{\\min}=\\lfloor m/2\\rfloor",
      "\\ell\\ge2:\\;F=S_0+\\sum_s g_sS_s",
      "g_s=\\alpha_s(1-\\alpha_s),\\;r_{\\min}=\\lceil m/2\\rceil",
    ],
    detailRoute: "documents/reference/pdlmi/applyputinar/",
  },
  { key: "fullbox", anchor: "full-box", label: "Full Box", description: "The full box preorder adds Gram terms for every subset product of the axis generators.", command: "L.applyFullBoxPreorder(r)", formula: ["F=\\sum_{J\\subseteq\\{1,\\ldots,\\ell\\}}g_J S_J"], detailRoute: "documents/reference/pdlmi/applyfullboxpreorder/" },
];
