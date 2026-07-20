import {
  bernsteinProduct,
  parseCoefficients,
  plotScale,
  sampleBernstein,
} from "./bernstein.ts";

export type FactorSide = "left" | "right";

export const maxMultiplicationCoefficients = 256;

export interface MultiplicationInput {
  leftText: string;
  rightText: string;
  errors: Record<FactorSide, string>;
  valid: Record<FactorSide, number[]>;
}

export const initialMultiplicationInput: MultiplicationInput = {
  leftText: "4, 2",
  rightText: "0.5, 3",
  errors: { left: "", right: "" },
  valid: { left: [4, 2], right: [0.5, 3] },
};

/** Validate one draft independently and commit only when both drafts are valid. */
export function updateMultiplicationInput(
  state: MultiplicationInput,
  side: FactorSide,
  text: string,
): MultiplicationInput {
  const next = side === "left"
    ? { ...state, leftText: text }
    : { ...state, rightText: text };
  const errors = { left: "", right: "" };
  let left: number[] | undefined;
  let right: number[] | undefined;

  for (const factor of ["left", "right"] as const) {
    try {
      const parsed = parseCoefficients(factor === "left" ? next.leftText : next.rightText);
      if (parsed.length > maxMultiplicationCoefficients) {
        errors[factor] = `Use at most ${maxMultiplicationCoefficients} coefficients per factor.`;
        continue;
      }
      if (factor === "left") left = parsed;
      else right = parsed;
    } catch (cause) {
      errors[factor] = cause instanceof Error
        ? cause.message
        : "Enter a finite coefficient list.";
    }
  }
  if (!left || !right) return { ...next, errors };

  try {
    const product = bernsteinProduct(left, right);
    const points = [
      ...sampleBernstein(left),
      ...sampleBernstein(right),
      ...sampleBernstein(product),
    ];
    plotScale(points.map((point) => point.y));
  } catch (cause) {
    const message = cause instanceof Error
      ? cause.message
      : "The coefficient pair produces non-finite derived data.";
    return { ...next, errors: { left: message, right: message } };
  }

  return { ...next, errors, valid: { left, right } };
}
