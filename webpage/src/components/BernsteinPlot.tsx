import type { PlotPoint } from "../lib/bernstein.ts";
import { bernsteinPlotGeometry, plotScale } from "../lib/bernstein.ts";

interface Series {
  label: string;
  points: PlotPoint[];
  tone: "first" | "second" | "result";
}

interface Props {
  ariaLabel: string;
  marker?: PlotPoint;
  series: Series[];
}

const { width, height, margin } = bernsteinPlotGeometry;

/** Render sampled series with a dedicated HTML legend outside the SVG plot. */
export default function BernsteinPlot({ ariaLabel, marker, series }: Props) {
  const values = series.flatMap((item) => item.points.map((point) => point.y));
  const range = plotScale(values);
  const xMap = (x: number) => margin.left + x * (width - margin.left - margin.right);
  const yMap = (y: number) => margin.top
    + (range.max - y) / (range.max - range.min) * (height - margin.top - margin.bottom);
  const makePath = (points: PlotPoint[]) => points
    .map((point, index) => `${index === 0 ? "M" : "L"}${xMap(point.x).toFixed(2)} ${yMap(point.y).toFixed(2)}`)
    .join(" ");

  return (
    <div className="plot-block">
      <div className="plot-legend" aria-label="Plot legend">
        {series.map((item) => (
          <span className={`plot-legend__item plot-tone--${item.tone}`} key={item.label}>
            <i aria-hidden="true" />{item.label}
          </span>
        ))}
      </div>
      <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label={ariaLabel}>
        <line className="plot-axis" x1={margin.left} y1={height - margin.bottom} x2={width - margin.right} y2={height - margin.bottom} />
        <line className="plot-axis" x1={margin.left} y1={margin.top} x2={margin.left} y2={height - margin.bottom} />
        <text className="plot-axis-label" x={margin.left} y={height - 12}>0</text>
        <text className="plot-axis-label" x={width - margin.right} y={height - 12} textAnchor="end">1 · ρ</text>
        {series.map((item) => <path className={`plot-line plot-tone--${item.tone}`} d={makePath(item.points)} key={item.label} />)}
        {marker ? (
          <g className="plot-marker">
            <line x1={xMap(marker.x)} y1={margin.top} x2={xMap(marker.x)} y2={height - margin.bottom} />
            <circle cx={xMap(marker.x)} cy={yMap(marker.y)} r="6" />
          </g>
        ) : null}
      </svg>
    </div>
  );
}
