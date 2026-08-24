#!/usr/bin/env python3
"""Render the tracked WGBS pilot benchmark as a dependency-free SVG."""

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


with TASKS.open(encoding="utf-8", newline="") as handle:
    tasks = list(csv.DictReader(handle, delimiter="\t"))

with SUMMARY.open(encoding="utf-8", newline="") as handle:
    summary = {row["metric"]: float(row["value"]) for row in csv.DictReader(handle, delimiter="\t")}

width, height = 1200, 780
navy, blue, teal, orange = "#16324F", "#2878B5", "#2A9D8F", "#E76F51"
ink, muted, grid, paper = "#17212B", "#5D6B78", "#DCE3E8", "#FFFFFF"
parts: list[str] = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
    '<title id="title">WGBS 10-million-read-pair pilot benchmark and production projection</title>',
    '<desc id="desc">Bismark alignment dominates pilot runtime. Linear scaling projects about 6.5 days per full sample and 56 thousand CPU-hours for thirty similar samples.</desc>',
    f'<rect width="{width}" height="{height}" fill="{paper}"/>',
    f'<text x="55" y="52" font-family="Arial,sans-serif" font-size="28" font-weight="700" fill="{navy}">WGBS pilot benchmark → production capacity plan</text>',
    f'<text x="55" y="80" font-family="Arial,sans-serif" font-size="15" fill="{muted}">10M paired reads · nf-core/methylseq 4.2.0 · Bismark · measured values separated from projections</text>',
]

# Left panel: task runtime.
lx, ly, lw, lh = 55, 125, 675, 500
parts += [
    f'<text x="{lx}" y="{ly}" font-family="Arial,sans-serif" font-size="19" font-weight="700" fill="{ink}">Measured pilot task runtime</text>',
    f'<text x="{lx}" y="{ly + 24}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">Minutes of real execution time; tasks under one minute remain visible</text>',
]
plot_x, plot_y, plot_w = lx + 190, ly + 48, lw - 205
row_h = 39
max_minutes = max(float(row["realtime_seconds"]) / 60 for row in tasks)
for tick in (0, 30, 60, 90, 120):
    x = plot_x + plot_w * tick / 120
    parts.append(f'<line x1="{x:.1f}" y1="{plot_y - 8}" x2="{x:.1f}" y2="{plot_y + row_h * len(tasks)}" stroke="{grid}" stroke-width="1"/>')
    parts.append(f'<text x="{x:.1f}" y="{plot_y + row_h * len(tasks) + 22}" text-anchor="middle" font-family="Arial,sans-serif" font-size="12" fill="{muted}">{tick}</text>')

for index, row in enumerate(tasks):
    minutes = float(row["realtime_seconds"]) / 60
    y = plot_y + index * row_h
    bar_width = max(3, plot_w * minutes / 120)
    color = orange if row["stage"] == "Bismark alignment" else blue
    parts.append(f'<text x="{plot_x - 10}" y="{y + 17}" text-anchor="end" font-family="Arial,sans-serif" font-size="12" fill="{ink}">{esc(row["stage"])}</text>')
    parts.append(f'<rect x="{plot_x}" y="{y + 4}" width="{bar_width:.1f}" height="18" fill="{color}" rx="2"/>')
    label = f'{minutes:.1f} min' if minutes >= 1 else f'{float(row["realtime_seconds"]):.1f} s'
    parts.append(f'<text x="{min(plot_x + bar_width + 7, plot_x + plot_w - 2):.1f}" y="{y + 18}" font-family="Arial,sans-serif" font-size="12" font-weight="700" fill="{ink}">{label}</text>')

parts.append(f'<text x="{plot_x + plot_w / 2:.1f}" y="{plot_y + row_h * len(tasks) + 46}" text-anchor="middle" font-family="Arial,sans-serif" font-size="12" fill="{muted}">Real execution time (minutes)</text>')

# Right panel: headline evidence and capacity scenarios.
rx = 775
factor = summary["full_to_pilot_scaling_factor"]
full_days = summary["projected_full_sample_wall_time"] / 24
cpu_30 = summary["projected_30_sample_cpu_time"]
parts += [
    f'<text x="{rx}" y="{ly}" font-family="Arial,sans-serif" font-size="19" font-weight="700" fill="{ink}">Evidence and production projection</text>',
    f'<text x="{rx}" y="{ly + 48}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">Measured</text>',
    f'<text x="{rx}" y="{ly + 78}" font-family="Arial,sans-serif" font-size="25" font-weight="700" fill="{navy}">2h 03m 44s</text>',
    f'<text x="{rx + 180}" y="{ly + 78}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">pilot wall time</text>',
    f'<text x="{rx}" y="{ly + 114}" font-family="Arial,sans-serif" font-size="25" font-weight="700" fill="{navy}">38.9 GB</text>',
    f'<text x="{rx + 145}" y="{ly + 114}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">alignment peak RSS</text>',
    f'<text x="{rx}" y="{ly + 150}" font-family="Arial,sans-serif" font-size="25" font-weight="700" fill="{navy}">97%</text>',
    f'<text x="{rx + 78}" y="{ly + 150}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">12-CPU alignment utilization</text>',
    f'<line x1="{rx}" y1="{ly + 176}" x2="1145" y2="{ly + 176}" stroke="{grid}"/>',
    f'<text x="{rx}" y="{ly + 208}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">Projected from {factor:.1f}× compressed-byte scaling</text>',
    f'<text x="{rx}" y="{ly + 240}" font-family="Arial,sans-serif" font-size="25" font-weight="700" fill="{orange}">{full_days:.1f} days</text>',
    f'<text x="{rx + 135}" y="{ly + 240}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">per full sample</text>',
    f'<text x="{rx}" y="{ly + 276}" font-family="Arial,sans-serif" font-size="25" font-weight="700" fill="{orange}">{cpu_30:,.0f}</text>',
    f'<text x="{rx + 125}" y="{ly + 276}" font-family="Arial,sans-serif" font-size="13" fill="{muted}">CPU-hours for 30 samples</text>',
    f'<text x="{rx}" y="{ly + 326}" font-family="Arial,sans-serif" font-size="15" font-weight="700" fill="{ink}">30-sample elapsed time by concurrency</text>',
]

scenarios = [(1, 195.8), (3, 65.3), (5, 39.2), (10, 19.6)]
sx, sy, sw = rx + 52, ly + 350, 300
for idx, (concurrency, days) in enumerate(scenarios):
    y = sy + idx * 42
    bw = sw * days / scenarios[0][1]
    parts.append(f'<text x="{sx - 12}" y="{y + 16}" text-anchor="end" font-family="Arial,sans-serif" font-size="12" fill="{ink}">{concurrency} at once</text>')
    parts.append(f'<rect x="{sx}" y="{y + 3}" width="{bw:.1f}" height="19" fill="{teal}" rx="2"/>')
    parts.append(f'<text x="{sx + bw + 7:.1f}" y="{y + 17}" font-family="Arial,sans-serif" font-size="12" font-weight="700" fill="{ink}">{days:.1f} d</text>')

parts += [
    f'<line x1="55" y1="665" x2="1145" y2="665" stroke="{grid}"/>',
    f'<text x="55" y="696" font-family="Arial,sans-serif" font-size="16" font-weight="700" fill="{orange}">Decision: standard whole-sample alignment is operationally slow; design parallel chunk alignment with one global sample-level deduplication.</text>',
    f'<text x="55" y="724" font-family="Arial,sans-serif" font-size="12" fill="{muted}">Projection assumes linear scaling from compressed input size and excludes queue delay, storage contention, retries, and chunk overhead.</text>',
    f'<text x="55" y="746" font-family="Arial,sans-serif" font-size="12" fill="{muted}">Cost model: projected CPU-hours × local CPU-hour rate + retained TB-months × storage rate + any scheduler or egress charges.</text>',
    f'<text x="1145" y="760" text-anchor="end" font-family="Arial,sans-serif" font-size="11" fill="{muted}">Source: benchmarks/pilot-summary.tsv and pilot-task-metrics.tsv</text>',
    '</svg>',
]

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text("\n".join(parts) + "\n", encoding="utf-8")
print(OUTPUT)
