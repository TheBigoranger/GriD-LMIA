import {
  useId,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
  type PointerEvent,
} from "react";
import {
  KNOT_MAX,
  KNOT_MIN,
  clampPitch,
  enumerateCells,
  fitProjection,
  getCellBounds,
  mapProjection,
  projectPoint,
  resetRotation,
  type Point3,
} from "../lib/grid-partition.ts";

type Dimension = 1 | 2 | 3;

const dimensions: Dimension[] = [1, 2, 3];
const defaults: Record<Dimension, number[]> = {
  1: [0.35],
  2: [0.4, 0.25],
  3: [0.3, 0.55, 0.75],
};

const axisLabels = ["ρ₁", "ρ₂", "ρ₃"];
const initialRotation = resetRotation();
const cubeViewBox = { width: 420, height: 300 };
const cubePadding = 12;
const selectionRadius = 7;
const cubeCorners: Point3[] = [
  [0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 1, 1],
  [1, 0, 0], [1, 0, 1], [1, 1, 0], [1, 1, 1],
];

function formatNumber(value: number): string {
  return Number(value.toFixed(2)).toString();
}

function labelCell(cell: readonly number[]): string {
  return `(${cell.map((index) => index + 1).join(", ")})`;
}

function Grid1D({ knots, selected }: { knots: number[]; selected: number[] }) {
  return (
    <div className="partition-one" aria-label="One-dimensional nonuniform partition">
      <div
        className="partition-one__cells"
        style={{ gridTemplateColumns: `${knots[0]}fr ${1 - knots[0]}fr` }}
      >
        {[0, 1].map((index) => (
          <span className={selected[0] === index ? "is-selected" : ""} key={index}>
            Cell {index + 1}
          </span>
        ))}
      </div>
      <div className="partition-one__axis" aria-hidden="true">
        <span>0</span><span>{formatNumber(knots[0])}</span><span>1</span>
      </div>
    </div>
  );
}

function Grid2D({ knots, selected }: { knots: number[]; selected: number[] }) {
  const cells = enumerateCells(knots);
  return (
    <div className="partition-two" aria-label="Two-dimensional nonuniform tensor partition">
      <div className="partition-two__y" aria-hidden="true"><span>1</span><span>{formatNumber(knots[1])}</span><span>0</span></div>
      <div
        className="partition-two__cells"
        style={{
          gridTemplateColumns: `${knots[0]}fr ${1 - knots[0]}fr`,
          gridTemplateRows: `${1 - knots[1]}fr ${knots[1]}fr`,
        }}
      >
        {cells.map((cell) => (
          <span
            className={cell.every((index, axis) => index === selected[axis]) ? "is-selected" : ""}
            key={cell.join("-")}
            style={{ gridColumn: cell[0] + 1, gridRow: cell[1] === 0 ? 2 : 1 }}
          >
            {labelCell(cell)}
          </span>
        ))}
      </div>
      <div className="partition-two__x" aria-hidden="true"><span>0</span><span>{formatNumber(knots[0])}</span><span>1</span></div>
    </div>
  );
}

interface Segment {
  from: Point3;
  to: Point3;
}

function cubeSegments(knots: number[]): Segment[] {
  const levels = [[0, knots[0], 1], [0, knots[1], 1], [0, knots[2], 1]];
  const segments: Segment[] = [];

  // Each axis gets the complete tensor set of straight grid lines.
  for (const y of levels[1]) for (const z of levels[2]) {
    segments.push({ from: [0, y, z], to: [1, y, z] });
  }
  for (const x of levels[0]) for (const z of levels[2]) {
    segments.push({ from: [x, 0, z], to: [x, 1, z] });
  }
  for (const x of levels[0]) for (const y of levels[1]) {
    segments.push({ from: [x, y, 0], to: [x, y, 1] });
  }
  return segments;
}

function Grid3D({
  knots,
  selected,
  yaw,
  pitch,
  onDrag,
}: {
  knots: number[];
  selected: number[];
  yaw: number;
  pitch: number;
  onDrag: (event: PointerEvent<SVGSVGElement>) => void;
}) {
  const projectedCorners = useMemo(
    () => cubeCorners.map((point) => projectPoint(point, yaw, pitch)),
    [yaw, pitch],
  );
  const fit = useMemo(
    () => fitProjection(projectedCorners, cubeViewBox, cubePadding, selectionRadius),
    [projectedCorners],
  );
  const lines = useMemo(() => cubeSegments(knots).map((segment) => {
    const from = projectPoint(segment.from, yaw, pitch);
    const to = projectPoint(segment.to, yaw, pitch);
    return {
      from: mapProjection(from, fit),
      to: mapProjection(to, fit),
      depth: (from.depth + to.depth) / 2,
    };
  }).sort((a, b) => a.depth - b.depth), [fit, knots, yaw, pitch]);
  const bounds = getCellBounds(knots, selected);
  const center = mapProjection(
    projectPoint(
      bounds.map(([lower, upper]) => (lower + upper) / 2) as [number, number, number],
      yaw,
      pitch,
    ),
    fit,
  );

  return (
    <svg
      aria-label={`Rotatable three-dimensional tensor grid. Selected cell ${labelCell(selected)}.`}
      className="partition-cube"
      onPointerCancel={onDrag}
      onPointerDown={onDrag}
      onPointerMove={onDrag}
      onPointerUp={onDrag}
      role="img"
      tabIndex={0}
      viewBox={`0 0 ${cubeViewBox.width} ${cubeViewBox.height}`}
    >
      {lines.map((line, index) => (
        <line
          className="partition-cube__line"
          key={`${index}-${line.depth}`}
          x1={line.from.x}
          x2={line.to.x}
          y1={line.from.y}
          y2={line.to.y}
        />
      ))}
      <circle
        aria-hidden="true"
        className="partition-cube__selection"
        cx={center.x}
        cy={center.y}
        r={selectionRadius}
      />
    </svg>
  );
}

/** Explore one independently movable internal knot on each active parameter axis. */
export default function GridPartitionExplorer() {
  const [dimension, setDimension] = useState<Dimension>(1);
  const [knots, setKnots] = useState<Record<Dimension, number[]>>({
    1: [...defaults[1]],
    2: [...defaults[2]],
    3: [...defaults[3]],
  });
  const [selected, setSelected] = useState<Record<Dimension, number[]>>({
    1: [0],
    2: [0, 0],
    3: [0, 0, 0],
  });
  const [yaw, setYaw] = useState(initialRotation.yaw);
  const [pitch, setPitch] = useState(initialRotation.pitch);
  const tabs = useRef<Array<HTMLButtonElement | null>>([]);
  const drag = useRef<{ pointerId: number; x: number; y: number } | null>(null);
  const uid = useId();
  const activeKnots = knots[dimension];
  const activeCell = selected[dimension];
  const cells = enumerateCells(activeKnots);
  const bounds = getCellBounds(activeKnots, activeCell);

  const selectDimension = (next: Dimension, focus = false) => {
    setDimension(next);
    if (focus) tabs.current[dimensions.indexOf(next)]?.focus();
  };

  const moveTab = (event: KeyboardEvent<HTMLButtonElement>, index: number) => {
    let next = index;
    if (event.key === "ArrowLeft") next = (index + dimensions.length - 1) % dimensions.length;
    else if (event.key === "ArrowRight") next = (index + 1) % dimensions.length;
    else if (event.key === "Home") next = 0;
    else if (event.key === "End") next = dimensions.length - 1;
    else return;
    event.preventDefault();
    selectDimension(dimensions[next], true);
  };

  const updateKnot = (axis: number, value: number) => {
    setKnots((current) => ({
      ...current,
      [dimension]: current[dimension].map((knot, index) => index === axis ? value : knot),
    }));
  };

  const handleDrag = (event: PointerEvent<SVGSVGElement>) => {
    if (event.type === "pointerdown") {
      event.currentTarget.setPointerCapture(event.pointerId);
      drag.current = { pointerId: event.pointerId, x: event.clientX, y: event.clientY };
      return;
    }
    if (!drag.current || drag.current.pointerId !== event.pointerId) return;
    if (event.type === "pointermove") {
      const dx = event.clientX - drag.current.x;
      const dy = event.clientY - drag.current.y;
      drag.current = { pointerId: event.pointerId, x: event.clientX, y: event.clientY };
      setYaw((value) => value + dx * 0.6);
      setPitch((value) => clampPitch(value - dy * 0.6));
      return;
    }
    drag.current = null;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  };

  const rotate = (yawStep: number, pitchStep: number) => {
    setYaw((value) => value + yawStep);
    setPitch((value) => clampPitch(value + pitchStep));
  };

  return (
    <figure className="diagram-frame interactive-figure grid-partition-explorer">
      <div className="diagram-frame__body">
        <div aria-label="Grid dimensions" className="grid-partition-tabs" role="tablist">
          {dimensions.map((item, index) => (
            <button
              aria-controls={`${uid}-panel`}
              aria-selected={dimension === item}
              id={`${uid}-tab-${item}`}
              key={item}
              onClick={() => selectDimension(item)}
              onKeyDown={(event) => moveTab(event, index)}
              ref={(element) => { tabs.current[index] = element; }}
              role="tab"
              tabIndex={dimension === item ? 0 : -1}
              type="button"
            >
              {item}D
            </button>
          ))}
        </div>

        <section
          aria-labelledby={`${uid}-tab-${dimension}`}
          className="grid-partition-panel"
          id={`${uid}-panel`}
          role="tabpanel"
        >
          <div className="grid-partition-controls">
            <fieldset>
              <legend>Move one internal knot per axis</legend>
              {activeKnots.map((knot, axis) => (
                <label key={axis}>
                  <span>{axisLabels[axis]} knot <output>{formatNumber(knot)}</output></span>
                  <input
                    max={KNOT_MAX}
                    min={KNOT_MIN}
                    onChange={(event) => updateKnot(axis, Number(event.currentTarget.value))}
                    step="0.01"
                    type="range"
                    value={knot}
                  />
                </label>
              ))}
            </fieldset>
            <fieldset>
              <legend>Select a physical cell</legend>
              <div className="grid-cell-controls">
                {cells.map((cell) => (
                  <button
                    aria-pressed={cell.every((index, axis) => index === activeCell[axis])}
                    key={cell.join("-")}
                    onClick={() => setSelected((current) => ({ ...current, [dimension]: cell }))}
                    type="button"
                  >
                    {labelCell(cell)}
                  </button>
                ))}
              </div>
            </fieldset>
          </div>

          <div className="grid-partition-visual">
            {dimension === 1 && <Grid1D knots={activeKnots} selected={activeCell} />}
            {dimension === 2 && <Grid2D knots={activeKnots} selected={activeCell} />}
            {dimension === 3 && (
              <>
                <Grid3D knots={activeKnots} onDrag={handleDrag} pitch={pitch} selected={activeCell} yaw={yaw} />
                <div aria-label="Rotate three-dimensional grid" className="grid-rotation-controls">
                  <button onClick={() => rotate(-10, 0)} type="button">Rotate left</button>
                  <button onClick={() => rotate(10, 0)} type="button">Rotate right</button>
                  <button onClick={() => rotate(0, 10)} type="button">Tilt up</button>
                  <button onClick={() => rotate(0, -10)} type="button">Tilt down</button>
                  <button onClick={() => {
                    const reset = resetRotation();
                    setYaw(reset.yaw);
                    setPitch(reset.pitch);
                  }} type="button">Reset view</button>
                </div>
              </>
            )}
          </div>

          <p aria-live="polite" className="grid-partition-readout">
            <strong>Cell {labelCell(activeCell)}:</strong>{" "}
            {bounds.map(([lower, upper], axis) => (
              <span key={axis}>{axisLabels[axis]} ∈ [{formatNumber(lower)}, {formatNumber(upper)}]{axis < bounds.length - 1 ? "; " : ""}</span>
            ))}
          </p>
        </section>
      </div>
      <figcaption>
        The tensor grid exactly partitions the box. Moving a knot changes the
        physical cells independently along each axis; the modeling approximation
        comes from restricting the decision-function space on those cells.
      </figcaption>
    </figure>
  );
}
