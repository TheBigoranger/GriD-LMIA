import {
  parseCoefficients,
  plotScale,
  sampleBernstein,
} from "./bernstein.ts";
import { elevateBernstein } from "./manual-explorers.ts";

export type AddendSide = "left" | "right";

export const maxAdditionCoefficients = 256;

export interface AlignedAddition {
  left: number[];
  right: number[];
  sum: number[];
}

export interface AdditionInput {
  leftText: string;
  rightText: string;
  errors: Record<AddendSide, string>;
  valid: Record<AddendSide, number[]>;
}

export const initialAdditionInput: AdditionInput = {
  leftText: "1, 2",
  rightText: "10, 20, 30",
  errors: { left: "", right: "" },
  valid: { left: [1, 2], right: [10, 20, 30] },
};

/** Elevate both normalized Bernstein rows to one degree and add labelwise. */
export function alignAndAdd(
  left: readonly number[],
  right: readonly number[],
): AlignedAddition {
  validateAddends(left, right);
  const targetLength = Math.max(left.length, right.length);
  const alignedLeft = elevateToLength(left, targetLength);
  const alignedRight = elevateToLength(right, targetLength);
  const sum = alignedLeft.map((value, index) => value + alignedRight[index]);
  if (sum.some((value) => !Number.isFinite(value))) {
    throw new RangeError("Bernstein addition produced non-finite coefficients.");
  }
  return { left: alignedLeft, right: alignedRight, sum };
}

/** Validate both drafts and replace plotted coefficients only as one atomic pair. */
export function updateAdditionInput(
  state: AdditionInput,
  side: AddendSide,
  text: string,
): AdditionInput {
  const next = side === "left"
    ? { ...state, leftText: text }
    : { ...state, rightText: text };
  const errors = { left: "", right: "" };
  let left: number[] | undefined;
  let right: number[] | undefined;

  for (const addend of ["left", "right"] as const) {
    try {
      const parsed = parseCoefficients(addend === "left" ? next.leftText : next.rightText);
      if (parsed.length > maxAdditionCoefficients) {
        errors[addend] = `Use at most ${maxAdditionCoefficients} coefficients per addend.`;
        continue;
      }
      if (addend === "left") left = parsed;
      else right = parsed;
    } catch (cause) {
      errors[addend] = cause instanceof Error
        ? cause.message
        : "Enter a finite coefficient list.";
    }
  }
  if (!left || !right) return { ...next, errors };

  try {
    const aligned = alignAndAdd(left, right);
    const points = [
      ...sampleBernstein(aligned.left),
      ...sampleBernstein(aligned.right),
      ...sampleBernstein(aligned.sum),
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

/** Reuse the tested one-dimensional elevation step for arbitrary input degrees. */
function elevateToLength(coeffs: readonly number[], targetLength: number): number[] {
  let elevated = [...coeffs];
  while (elevated.length < targetLength) {
    // The shared primitive accepts increments through eight; chunking preserves exactness.
    elevated = elevateBernstein(elevated, Math.min(8, targetLength - elevated.length));
  }
  return elevated;
}

/** Reject malformed coefficient rows before alignment. */
function validateAddends(left: readonly number[], right: readonly number[]): void {
  if (left.length === 0 || right.length === 0
      || left.some((value) => !Number.isFinite(value))
      || right.some((value) => !Number.isFinite(value))) {
    throw new TypeError("Both addends require finite coefficients.");
  }
}
