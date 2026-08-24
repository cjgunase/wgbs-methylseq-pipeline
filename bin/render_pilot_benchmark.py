#!/usr/bin/env python3
"""Render the tracked WGBS pilot benchmark as a dependency-free scientific SVG."""

from __future__ import annotations

import csv
import html
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TASKS = ROOT / "benchmarks" / "pilot-task-metrics.tsv"
SUMMARY = ROOT / "benchmarks" / "pilot-summary.tsv"
OUTPUT = ROOT / "assets" / "benchmark" / "pilot-benchmark.svg"


def esc(value: object) -> str:
    return html.escape(str(value))


def label(x: float, y: float, value: object, size: int = 12, anchor: str = "start", weight: int = 400, color: str = "#202020") -> str:
    return f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" font-family="Arial,sans-serif" font-size="{size}" font-weight="{weight}" fill="{color}">{esc(value)}</text>'


with TASKS.open(encoding="utf-8", newline="") as handle:
    tasks = list(csv.DictReader(handle, delimiter="\t"))

with SUMMARY.open(encoding="utf-8", newline="") as handle:
    summary = {row["metric"]: float(row["value"]) for row in csv.DictReader(handle, delimiter="\t")}

width, height = 1200, 820
ink, muted, grid, blue, pale, paper = "#202020", "#5A5A5A", "#D5D5D5", "#2B6EA6", "#B9C3CC", "#FFFFFF"
parts: list[str] = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
    '<title id="title">Computational benchmark of WGBS processing</title>',
    '<desc id="desc">Three-panel scientific figure showing measured task runtime, linear full-sample scaling, and projected cohort makespan versus concurrency.</desc>',
    f'<rect width="{width}" height="{height}" fill="{paper}"/>',
    label(55, 42, "Computational benchmark of WGBS processing", 24, weight=700),
    label(55, 67, "10-million-read-pair pilot; nf-core/methylseq 4.2.0 with Bismark", 13, color=muted),
]

# Panel A: measured runtime by process.
ax, ay, aw = 55, 115, 545
parts += [label(ax, ay - 30, "A", 18, weight=700), label(ax + 28, ay - 30, "Measured task runtime", 16, weight=700)]
plot_x, plot_y, plot_w = ax + 185, ay, aw - 200
row_h = 49
for tick in (0, 30, 60, 90, 120):
    x = plot_x + plot_w * tick / 120
    parts.append(f'<line x1="{x:.1f}" y1="{plot_y}" x2="{x:.1f}" y2="{plot_y + row_h * len(tasks)}" stroke="{grid}" stroke-width="1"/>')
    parts.append(label(x, plot_y + row_h * len(tasks) + 22, tick, 11, anchor="middle", color=muted))

for index, row in enumerate(tasks):
    seconds = float(row["realtime_seconds"])
    minutes = seconds / 60
    y = plot_y + index * row_h
    bar_width = max(2.5, plot_w * minutes / 120)
    fill = blue if row["stage"] == "Bismark alignment" else pale
    parts.append(label(plot_x - 10, y + 17, row["stage"], 11, anchor="end"))
    parts.append(f'<rect x="{plot_x}" y="{y + 5}" width="{bar_width:.1f}" height="16" fill="{fill}"/>')
    runtime = f"{minutes:.1f} min" if minutes >= 1 else f"{seconds:.1f} s"
    parts.append(label(min(plot_x + bar_width + 6, plot_x + plot_w - 2), y + 18, runtime, 10, weight=700))

parts += [
    f'<line x1="{plot_x}" y1="{plot_y + row_h * len(tasks)}" x2="{plot_x + plot_w}" y2="{plot_y + row_h * len(tasks)}" stroke="{ink}"/>',
    label(plot_x + plot_w / 2, plot_y + row_h * len(tasks) + 48, "Real execution time (min)", 12, anchor="middle"),
]

# Panel B: measured pilot and linear full-sample projection.
bx, by, bw, bh = 665, 115, 470, 275
parts += [label(bx, by - 30, "B", 18, weight=700), label(bx + 28, by - 30, "Input-size scaling", 16, weight=700)]
px, py, pw, ph = bx + 58, by, bw - 73, bh - 45
x_max, y_max = 110, 175
for tick in (0, 25, 50, 75, 100):
    x = px + pw * tick / x_max
    parts.append(f'<line x1="{x:.1f}" y1="{py}" x2="{x:.1f}" y2="{py + ph}" stroke="{grid}"/>')
    parts.append(label(x, py + ph + 19, tick, 10, anchor="middle", color=muted))
for tick in (0, 50, 100, 150):
    y = py + ph - ph * tick / y_max
    parts.append(f'<line x1="{px}" y1="{y:.1f}" x2="{px + pw}" y2="{y:.1f}" stroke="{grid}"/>')
    parts.append(label(px - 9, y + 4, tick, 10, anchor="end", color=muted))

pilot_x = summary["pilot_compressed_input"] / 1e9
pilot_y = summary["workflow_wall_time"] / 3600
full_x = summary["full_sample_compressed_input"] / 1e9
full_y = summary["projected_full_sample_wall_time"]
x1, y1 = px + pw * pilot_x / x_max, py + ph - ph * pilot_y / y_max
x2, y2 = px + pw * full_x / x_max, py + ph - ph * full_y / y_max
parts += [
    f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{blue}" stroke-width="2" stroke-dasharray="6 5"/>',
    f'<circle cx="{x1:.1f}" cy="{y1:.1f}" r="5" fill="{blue}"/>',
    f'<circle cx="{x2:.1f}" cy="{y2:.1f}" r="6" fill="{paper}" stroke="{blue}" stroke-width="2"/>',
    label(x1 + 10, y1 - 8, "Pilot: 1.33 GB, 2.06 h", 10),
    label(x2 - 8, y2 - 10, "Projected full sample", 10, anchor="end"),
    label(x2 - 8, y2 + 5, "100.83 GB, 156.7 h", 10, anchor="end"),
    f'<line x1="{px}" y1="{py + ph}" x2="{px + pw}" y2="{py + ph}" stroke="{ink}"/>',
    f'<line x1="{px}" y1="{py}" x2="{px}" y2="{py + ph}" stroke="{ink}"/>',
    label(px + pw / 2, py + ph + 43, "Compressed paired FASTQ input (GB)", 11, anchor="middle"),
    f'<text x="{bx + 13}" y="{py + ph / 2}" transform="rotate(-90 {bx + 13} {py + ph / 2})" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="{ink}">Workflow wall time (h)</text>',
    f'<circle cx="{bx + 250}" cy="{by - 27}" r="4" fill="{blue}"/>',
    label(bx + 259, by - 23, "measured", 10, color=muted),
    f'<circle cx="{bx + 337}" cy="{by - 27}" r="5" fill="{paper}" stroke="{blue}" stroke-width="2"/>',
    label(bx + 347, by - 23, "linear projection", 10, color=muted),
]

# Panel C: projected cohort makespan as a function of concurrency.
cx, cy, cw, ch = 665, 480, 470, 255
parts += [label(cx, cy - 30, "C", 18, weight=700), label(cx + 28, cy - 30, "Projected 30-sample makespan", 16, weight=700)]
qx, qy, qw, qh = cx + 58, cy, cw - 73, ch - 45
base_days = (summary["projected_full_sample_wall_time"] / 24) * 30
points = [(n, base_days / n) for n in range(1, 11)]
for tick in (1, 3, 5, 7, 10):
    x = qx + qw * (tick - 1) / 9
    parts.append(f'<line x1="{x:.1f}" y1="{qy}" x2="{x:.1f}" y2="{qy + qh}" stroke="{grid}"/>')
    parts.append(label(x, qy + qh + 19, tick, 10, anchor="middle", color=muted))
for tick in (0, 50, 100, 150, 200):
    y = qy + qh - qh * tick / 210
    parts.append(f'<line x1="{qx}" y1="{y:.1f}" x2="{qx + qw}" y2="{y:.1f}" stroke="{grid}"/>')
    parts.append(label(qx - 9, y + 4, tick, 10, anchor="end", color=muted))

coords = [(qx + qw * (n - 1) / 9, qy + qh - qh * days / 210) for n, days in points]
parts.append('<polyline points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in coords) + f'" fill="none" stroke="{blue}" stroke-width="2"/>')
for (n, days), (x, y) in zip(points, coords):
    parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.5" fill="{blue}"/>')
    if n in (1, 3, 5, 10):
        anchor = "end" if n == 10 else "start"
        offset = -7 if n == 10 else 7
        parts.append(label(x + offset, y - 8, f"{days:.1f} d", 10, anchor=anchor))

parts += [
    f'<line x1="{qx}" y1="{qy + qh}" x2="{qx + qw}" y2="{qy + qh}" stroke="{ink}"/>',
    f'<line x1="{qx}" y1="{qy}" x2="{qx}" y2="{qy + qh}" stroke="{ink}"/>',
    label(qx + qw / 2, qy + qh + 43, "Concurrent full-sample workflows (n)", 11, anchor="middle"),
    f'<text x="{cx + 13}" y="{qy + qh / 2}" transform="rotate(-90 {cx + 13} {qy + qh / 2})" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="{ink}">Projected elapsed time (days)</text>',
]

parts += [
    f'<line x1="55" y1="760" x2="1135" y2="760" stroke="{ink}" stroke-width="0.8"/>',
    label(55, 785, "Measured pilot: 10M read pairs. Projections assume linear scaling by compressed input bytes; queue delay, retries, chunk overhead, and shared-filesystem contention are excluded.", 10, color=muted),
    label(1135, 805, "Source: benchmarks/pilot-summary.tsv; pilot-task-metrics.tsv", 9, anchor="end", color=muted),
    "</svg>",
]

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text("\n".join(parts) + "\n", encoding="utf-8")
print(OUTPUT)
