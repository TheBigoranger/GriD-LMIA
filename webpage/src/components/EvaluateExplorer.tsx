import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
  type PointerEvent,
} from "react";

import BernsteinPlot from "./BernsteinPlot.tsx";
import {
  clientXToUnit,
  evaluateBernstein,
  evaluateTensorBernstein,
  sampleBernstein,
} from "../lib/bernstein.ts";
import {
  clampPitch,
  fitProjection,
  mapProjection,
  projectPoint,
  resetRotation,
  type Point3,
} from "../lib/grid-partition.ts";

type Dimension = 1 | 2;

const cubicCoefficients = [1, 2, 1, 2];
const quadraticCoefficients = [1, 0.4, 1.8, 2, 2.4, 3.3, 0, 2.4, 3.8];
const quadraticDegree = 2;
const tensorGeometry = { width: 640, height: 360, left: 62, right: 22, top: 20, bottom: 42 };
const surfaceGeometry = { width: 640, height: 360 };
const surfaceValueRange = { min: 0, max: 4 };
const surfaceRotation = resetRotation();
const surfaceAxes = [
  { label: "ρ₁", from: [0, 0, 0] as Point3, to: [1.12, 0, 0] as Point3 },
  { label: "ρ₂", from: [0, 0, 0] as Point3, to: [0, 0, 1.12] as Point3 },
  { label: "A", from: [0, 0, 0] as Point3, to: [0, 1.12, 0] as Point3 },
];
const normalizeSurfaceValue = (value: number) => (
  (value - surfaceValueRange.min) / (surfaceValueRange.max - surfaceValueRange.min)
);
const tensorSamples = Array.from({ length: 144 }, (_, index) => {
  const column = index % 12;
  const row = Math.floor(index / 12);
  const rho1 = (column + 0.5) / 12;
  const rho2 = (row + 0.5) / 12;
  return {
    column,
    row,
    value: evaluateTensorBernstein(quadraticCoefficients, quadraticDegree, [rho1, rho2]),
  };
});
const surfaceMesh = Array.from({ length: 100 }, (_, index) => {
  const column = index % 10;
  const row = Math.floor(index / 10);
  const rho1a = column / 10;
  const rho1b = (column + 1) / 10;
  const rho2a = row / 10;
  const rho2b = (row + 1) / 10;
  const corners = [
    [rho1a, rho2a],
    [rho1b, rho2a],
    [rho1b, rho2b],
    [rho1a, rho2b],
  ] as const;
  const values = corners.map(([rho1, rho2]) => (
    evaluateTensorBernstein(quadraticCoefficients, quadraticDegree, [rho1, rho2])
  ));
  return {
    column,
    row,
    average: values.reduce((sum, item) => sum + item, 0) / values.length,
    points: corners.map(([rho1, rho2], cornerIndex) => (
      [rho1, normalizeSurfaceValue(values[cornerIndex]), rho2] as Point3
    )),
  };
});
const surfaceFitPoints: Point3[] = [
  [0, 0, 0], [1, 0, 0], [0, 0, 1], [1, 0, 1],
  ...surfaceAxes.flatMap((axis) => [axis.from, axis.to]),
  ...surfaceMesh.flatMap((cell) => cell.points),
];
const pointsAttribute = (points: readonly { x: number; y: number }[]) => (
  points.map(({ x, y }) => `${x.toFixed(2)},${y.toFixed(2)}`).join(" ")
);

function OneDimensionalEvaluation() {
  const [rho, setRho] = useState(0.5);
  const frame = useRef<number | null>(null);
  const plot = useRef<HTMLDivElement>(null);
  const value = evaluateBernstein(cubicCoefficients, rho);

  useEffect(() => () => {
    if (frame.current !== null) cancelAnimationFrame(frame.current);
  }, []);

  const selectFromPointer = (clientX: number) => {
    const bounds = plot.current?.querySelector("svg")?.getBoundingClientRect();
    if (!bounds) return;
    const next = clientXToUnit(clientX, bounds);
    if (frame.current !== null) cancelAnimationFrame(frame.current);
    // Pointer movement is transient and is coalesced to one state update per frame.
    frame.current = requestAnimationFrame(() => setRho(next));
  };

  return (
    <section aria-label="One-dimensional evaluation case">
      <div className="evaluate-expression">
        <strong>A(ρ) = 1 + 3ρ − 6ρ² + 4ρ³</strong>
        <span>Bernstein coefficients: [1, 2, 1, 2]</span>
        <output aria-live="polite">ρ = {rho.toFixed(3)} · A(ρ) = {value.toFixed(4)}</output>
      </div>
      <div
        aria-label="Evaluate A between rho zero and one"
        aria-valuemax={1}
        aria-valuemin={0}
        aria-valuenow={Number(rho.toFixed(3))}
        className="interactive-plot"
        onClick={(event) => selectFromPointer(event.clientX)}
        onKeyDown={(event) => {
          if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
            event.preventDefault();
            setRho((current) => Math.max(0, Math.min(1, current + (event.key === "ArrowRight" ? 0.025 : -0.025))));
          } else if (event.key === "Home" || event.key === "End") {
            event.preventDefault();
            setRho(event.key === "Home" ? 0 : 1);
          }
        }}
        onPointerMove={(event) => {
          if (event.pointerType === "mouse") selectFromPointer(event.clientX);
        }}
        ref={plot}
        role="slider"
        tabIndex={0}
      >
        <BernsteinPlot
          ariaLabel="Cubic A of rho with a movable evaluation marker"
          marker={{ x: rho, y: value }}
          series={[{ label: "A(ρ)", points: sampleBernstein(cubicCoefficients), tone: "first" }]}
        />
      </div>
    </section>
  );
}

function TwoDimensionalEvaluation() {
  const [rho1, setRho1] = useState(0.35);
  const [rho2, setRho2] = useState(0.65);
  const [yaw, setYaw] = useState(surfaceRotation.yaw);
  const [pitch, setPitch] = useState(surfaceRotation.pitch);
  const frame = useRef<number | null>(null);
  const plot = useRef<HTMLDivElement>(null);
  const drag = useRef<{ pointerId: number; x: number; y: number } | null>(null);
  const value = evaluateTensorBernstein(
    quadraticCoefficients,
    quadraticDegree,
    [rho1, rho2],
  );
  const innerWidth = tensorGeometry.width - tensorGeometry.left - tensorGeometry.right;
  const innerHeight = tensorGeometry.height - tensorGeometry.top - tensorGeometry.bottom;
  const markerX = tensorGeometry.left + rho1 * innerWidth;
  const markerY = tensorGeometry.top + (1 - rho2) * innerHeight;
  const surfaceProjection = useMemo(() => {
    const projectedFitPoints = surfaceFitPoints.map((point) => projectPoint(point, yaw, pitch));
    const fit = fitProjection(projectedFitPoints, surfaceGeometry, 22, 9);
    const project = (point: Point3) => mapProjection(projectPoint(point, yaw, pitch), fit);
    const cells = surfaceMesh.map((cell) => {
      const points = cell.points.map(project);
      return {
        ...cell,
        points,
        depth: points.reduce((sum, point) => sum + point.depth, 0) / points.length,
      };
    }).sort((left, right) => left.depth - right.depth);
    return {
      axes: surfaceAxes.map((axis) => ({
        ...axis,
        from: project(axis.from),
        to: project(axis.to),
      })),
      base: [[0, 0, 0], [1, 0, 0], [1, 0, 1], [0, 0, 1]].map((point) => (
        project(point as Point3)
      )),
      cells,
      marker: project([rho1, normalizeSurfaceValue(value), rho2]),
      markerBase: project([rho1, 0, rho2]),
    };
  }, [pitch, rho1, rho2, value, yaw]);

  useEffect(() => () => {
    if (frame.current !== null) cancelAnimationFrame(frame.current);
  }, []);

  const selectFromPointer = (clientX: number, clientY: number) => {
    const bounds = plot.current?.querySelector("svg")?.getBoundingClientRect();
    if (!bounds) return;
    const viewX = (clientX - bounds.left) / bounds.width * tensorGeometry.width;
    const viewY = (clientY - bounds.top) / bounds.height * tensorGeometry.height;
    const nextRho1 = Math.max(0, Math.min(1, (viewX - tensorGeometry.left) / innerWidth));
    const nextRho2 = Math.max(0, Math.min(1, 1 - (viewY - tensorGeometry.top) / innerHeight));
    if (frame.current !== null) cancelAnimationFrame(frame.current);
    frame.current = requestAnimationFrame(() => {
      setRho1(nextRho1);
      setRho2(nextRho2);
    });
  };

  const rotateSurface = (event: PointerEvent<SVGSVGElement>) => {
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
      setYaw((current) => current + dx * 0.6);
      setPitch((current) => clampPitch(current - dy * 0.6));
      return;
    }
    drag.current = null;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  };

  const rotateSurfaceFromKeyboard = (event: KeyboardEvent<SVGSVGElement>) => {
    const step = 8;
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      event.preventDefault();
      setYaw((current) => current + (event.key === "ArrowRight" ? step : -step));
    } else if (event.key === "ArrowUp" || event.key === "ArrowDown") {
      event.preventDefault();
      setPitch((current) => clampPitch(current + (event.key === "ArrowUp" ? step : -step)));
    } else if (event.key === "Home") {
      event.preventDefault();
      setYaw(surfaceRotation.yaw);
      setPitch(surfaceRotation.pitch);
    }
  };

  return (
    <section aria-label="Two-dimensional evaluation case">
      <div className="evaluate-expression">
        <strong>A(ρ₁,ρ₂) = 1 + 2ρ₁ − 1.2ρ₂ − 3ρ₁² + 2ρ₂² + 4ρ₁ρ₂ + 2ρ₁²ρ₂ − 3ρ₁ρ₂²</strong>
        <span>Tensor Bernstein degree: 2 · 3 × 3 coefficients</span>
        <output aria-live="polite">A({rho1.toFixed(2)}, {rho2.toFixed(2)}) = {value.toFixed(4)}</output>
      </div>
      <div className="evaluate-two-dimensional">
        <div className="evaluate-view">
          <p className="evaluate-view__label">Parameter plane</p>
          <div
            className="interactive-plot evaluate-surface"
            onClick={(event) => selectFromPointer(event.clientX, event.clientY)}
            onPointerMove={(event) => {
              if (event.pointerType === "mouse") selectFromPointer(event.clientX, event.clientY);
            }}
            ref={plot}
          >
            <svg viewBox={`0 0 ${tensorGeometry.width} ${tensorGeometry.height}`} role="img" aria-label="Bivariate A over rho one and rho two with a movable evaluation marker">
              {tensorSamples.map((sample) => (
                <rect
                  className="evaluate-surface__cell"
                  fill={`color-mix(in srgb, var(--diagram-result) ${18 + (sample.value - 1) / 4 * 62}%, var(--sl-color-bg))`}
                  height={innerHeight / 12 + 0.4}
                  key={`${sample.row}-${sample.column}`}
                  width={innerWidth / 12 + 0.4}
                  x={tensorGeometry.left + sample.column * innerWidth / 12}
                  y={tensorGeometry.top + (11 - sample.row) * innerHeight / 12}
                />
              ))}
              <rect className="evaluate-surface__frame" height={innerHeight} width={innerWidth} x={tensorGeometry.left} y={tensorGeometry.top} />
              <line className="evaluate-surface__guide" x1={markerX} x2={markerX} y1={tensorGeometry.top} y2={tensorGeometry.top + innerHeight} />
              <line className="evaluate-surface__guide" x1={tensorGeometry.left} x2={tensorGeometry.left + innerWidth} y1={markerY} y2={markerY} />
              <circle className="evaluate-surface__marker" cx={markerX} cy={markerY} r="7" />
              <text className="plot-axis-label" x={tensorGeometry.left} y={tensorGeometry.height - 12}>0</text>
              <text className="plot-axis-label" textAnchor="end" x={tensorGeometry.width - tensorGeometry.right} y={tensorGeometry.height - 12}>1 · ρ₁</text>
              <text className="plot-axis-label" x={18} y={tensorGeometry.top + 5}>1</text>
              <text className="plot-axis-label" x={8} y={tensorGeometry.top + innerHeight}>0 · ρ₂</text>
            </svg>
          </div>
        </div>
        <div className="evaluate-view">
          <div className="evaluate-view__heading">
            <p className="evaluate-view__label">Function surface</p>
            <button onClick={() => {
              setYaw(surfaceRotation.yaw);
              setPitch(surfaceRotation.pitch);
            }} type="button">Reset view</button>
          </div>
          <div className="evaluate-surface evaluate-surface--three-dimensional">
            <svg
              aria-label="Rotatable three-dimensional degree-two surface of A with the selected parameter point mapped to its function value"
              onKeyDown={rotateSurfaceFromKeyboard}
              onPointerCancel={rotateSurface}
              onPointerDown={rotateSurface}
              onPointerMove={rotateSurface}
              onPointerUp={rotateSurface}
              role="img"
              tabIndex={0}
              viewBox={`0 0 ${surfaceGeometry.width} ${surfaceGeometry.height}`}
            >
              <polygon
                className="evaluate-surface-3d__base"
                points={pointsAttribute(surfaceProjection.base)}
              />
              {surfaceProjection.cells.map((cell) => (
                <polygon
                  className="evaluate-surface-3d__cell"
                  fill={`color-mix(in srgb, var(--diagram-result) ${25 + normalizeSurfaceValue(cell.average) * 58}%, var(--sl-color-bg))`}
                  key={`${cell.row}-${cell.column}`}
                  points={pointsAttribute(cell.points)}
                />
              ))}
              <g className="evaluate-surface-3d__axes">
                {surfaceProjection.axes.map((axis) => (
                  <g key={axis.label}>
                    <line x1={axis.from.x} x2={axis.to.x} y1={axis.from.y} y2={axis.to.y} />
                    <text
                      dx={axis.to.x >= axis.from.x ? 7 : -7}
                      dy={axis.to.y >= axis.from.y ? 13 : -7}
                      textAnchor={axis.to.x >= axis.from.x ? "start" : "end"}
                      x={axis.to.x}
                      y={axis.to.y}
                    >
                      {axis.label}
                    </text>
                  </g>
                ))}
              </g>
              <line
                className="evaluate-surface-3d__selected-guide"
                x1={surfaceProjection.markerBase.x}
                x2={surfaceProjection.marker.x}
                y1={surfaceProjection.markerBase.y}
                y2={surfaceProjection.marker.y}
              />
              <circle className="evaluate-surface__marker" cx={surfaceProjection.marker.x} cy={surfaceProjection.marker.y} r="8" />
            </svg>
          </div>
          <p className="evaluate-surface-3d__hint">Drag to rotate · Arrow keys rotate · Home resets</p>
        </div>
        <div className="evaluate-coordinate-controls">
          <label>
            <span>ρ₁ = {rho1.toFixed(2)}</span>
            <input aria-label="rho one" max="1" min="0" onChange={(event) => setRho1(Number(event.target.value))} step="0.01" type="range" value={rho1} />
          </label>
          <label>
            <span>ρ₂ = {rho2.toFixed(2)}</span>
            <input aria-label="rho two" max="1" min="0" onChange={(event) => setRho2(Number(event.target.value))} step="0.01" type="range" value={rho2} />
          </label>
        </div>
      </div>
    </section>
  );
}

/** Compare one- and two-parameter evaluation using accessible React tabs. */
export default function EvaluateExplorer() {
  const [dimension, setDimension] = useState<Dimension>(1);
  const dimensions: Dimension[] = [1, 2];
  const selectDimension = (next: Dimension) => {
    setDimension(next);
    requestAnimationFrame(() => document.getElementById(`evaluate-${next}d-tab`)?.focus());
  };

  return (
    <figure className="diagram-frame interactive-figure">
      <div className="diagram-frame__body evaluate-explorer">
        <div aria-label="Evaluation example dimension" className="grid-partition-tabs evaluate-tabs" role="tablist">
          {dimensions.map((item) => (
            <button
              aria-controls={`evaluate-${item}d-panel`}
              aria-selected={dimension === item}
              id={`evaluate-${item}d-tab`}
              key={item}
              onClick={() => setDimension(item)}
              onKeyDown={(event) => {
                const current = dimensions.indexOf(item);
                if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
                  event.preventDefault();
                  selectDimension(dimensions[(current + (event.key === "ArrowRight" ? 1 : -1) + dimensions.length) % dimensions.length]);
                } else if (event.key === "Home" || event.key === "End") {
                  event.preventDefault();
                  selectDimension(event.key === "Home" ? dimensions[0] : dimensions[dimensions.length - 1]);
                }
              }}
              role="tab"
              tabIndex={dimension === item ? 0 : -1}
              type="button"
            >
              {item}D
            </button>
          ))}
        </div>
        <div aria-labelledby={`evaluate-${dimension}d-tab`} id={`evaluate-${dimension}d-panel`} role="tabpanel">
          {dimension === 1 ? <OneDimensionalEvaluation /> : <TwoDimensionalEvaluation />}
        </div>
      </div>
      <figcaption>
        Select 1D or 2D, then move the plot marker or use the coordinate controls to inspect the evaluated value.
      </figcaption>
    </figure>
  );
}
