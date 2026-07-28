export const KNOT_MIN = 0.1;
export const KNOT_MAX = 0.9;
export const PITCH_LIMIT = 70;

export type Point3 = readonly [number, number, number];

export interface ProjectedPoint {
  x: number;
  y: number;
  depth: number;
}

export interface Rotation {
  yaw: number;
  pitch: number;
}

/** Return a fresh copy of the documented default 3D view. */
export function resetRotation(): Rotation {
  return { yaw: 35, pitch: 25 };
}

/** Validate one to three internal knots and keep both neighboring cells visible. */
export function normalizeKnots(knots: readonly number[]): number[] {
  if (knots.length < 1 || knots.length > 3) {
    throw new RangeError("Provide one to three internal grid knots.");
  }
  if (knots.some((knot) => !Number.isFinite(knot))) {
    throw new TypeError("Every grid knot must be finite.");
  }
  return knots.map((knot) => Math.min(KNOT_MAX, Math.max(KNOT_MIN, knot)));
}

/** Enumerate binary cell indices with the last parameter axis varying fastest. */
export function enumerateCells(knots: readonly number[]): number[][] {
  const valid = normalizeKnots(knots);
  return valid.reduce<number[][]>(
    (cells) => cells.flatMap((cell) => [[...cell, 0], [...cell, 1]]),
    [[]],
  );
}

/** Return physical [lower, upper] intervals for one selected tensor-grid cell. */
export function getCellBounds(
  knots: readonly number[],
  cell: readonly number[],
): [number, number][] {
  const valid = normalizeKnots(knots);
  if (cell.length !== valid.length) {
    throw new RangeError("The cell index must have the same dimension as the knot list.");
  }
  if (cell.some((index) => index !== 0 && index !== 1)) {
    throw new RangeError("Every cell index must be 0 or 1.");
  }
  return valid.map((knot, axis) => cell[axis] === 0 ? [0, knot] : [knot, 1]);
}

/** Bound pitch away from the edge-on view that collapses the cube projection. */
export function clampPitch(pitch: number): number {
  if (!Number.isFinite(pitch)) throw new TypeError("Pitch must be finite.");
  return Math.min(PITCH_LIMIT, Math.max(-PITCH_LIMIT, pitch));
}

/** Rotate a unit-cube point and return an orthographic projection with depth. */
export function projectPoint(
  point: Point3,
  yaw: number,
  pitch: number,
): ProjectedPoint {
  if (point.some((coordinate) => !Number.isFinite(coordinate))
    || !Number.isFinite(yaw)
    || !Number.isFinite(pitch)) {
    throw new TypeError("Projection inputs must be finite.");
  }

  const yawRad = yaw * Math.PI / 180;
  const pitchRad = clampPitch(pitch) * Math.PI / 180;
  const [px, py, pz] = point.map((coordinate) => coordinate - 0.5) as [number, number, number];

  const yawX = px * Math.cos(yawRad) + pz * Math.sin(yawRad);
  const yawZ = -px * Math.sin(yawRad) + pz * Math.cos(yawRad);
  const pitchY = py * Math.cos(pitchRad) - yawZ * Math.sin(pitchRad);
  const pitchZ = py * Math.sin(pitchRad) + yawZ * Math.cos(pitchRad);

  return { x: yawX, y: pitchY, depth: pitchZ + 2 };
}
