# Pilot benchmark and production capacity plan

![WGBS pilot benchmark and production capacity projection](../assets/benchmark/pilot-benchmark.svg)

**Figure 1. Computational benchmark and linear capacity projection for WGBS processing.** (A) Real execution time for each task in the 10-million-read-pair pilot. (B) Measured pilot wall time and a full-sample estimate obtained by linear scaling with compressed paired-FASTQ bytes. The filled point is measured; the open point and dashed line are projected. (C) Idealized elapsed time for 30 similar samples as workflow concurrency increases from 1 to 30. The open point and vertical dashed line mark the selected shared-resource cap of 10 simultaneous Bismark alignments. Projections exclude queue delay, retries, chunk overhead, and shared-filesystem contention.

## Executive result

The containerized nf-core/methylseq workflow successfully processed a synchronized 10-million-read-pair human WGBS pilot from FASTQ through a deduplicated BAM, BAM index, Bismark methylation coverage file, Bismark reports, and MultiQC. All ten tasks completed without retry.

Bismark alignment is the decisive bottleneck: 1 hour 45 minutes 52 seconds of the 2 hour 3 minute 44 second workflow, with 38.9 GB peak resident memory and 1,168% CPU utilization on 12 allocated CPUs. The CPU result is approximately 97% of the 1,200% theoretical maximum, indicating that the allocation was used efficiently.

The complete paired FASTQs for the benchmarked sample total 100.83 GB compressed, compared with 1.327 GB for the 10M subset. A simple compressed-byte scaling factor of 75.97 projects approximately 5.6 days for full-sample alignment and 6.5 days for the complete workflow. This is an engineering projection, not a guaranteed service level.

## Measured metrics

| Metric | Result |
|---|---:|
| Input | 10,000,000 paired 151-bp reads |
| Compressed pilot input | 1.327 GB |
| Workflow wall time | 2h 03m 44s |
| Workflow CPU consumption | 24.6 CPU-hours |
| Tasks | 10 succeeded; 0 failed; 0 retried |
| Alignment wall time | 1h 45m 52s |
| Alignment CPU utilization | 1,168.1% of 1,200% available |
| Alignment peak RSS | 38.9 GB |
| Alignment read/write I/O counters | 126.9 GB / 81.4 GB |
| Deduplicated BAM | 1.161 GB |
| Methylation coverage `.cov.gz` | 39.2 MB |
| Required-output bundle shown in benchmark | 1.205 GB |

Raw measurements are versioned in [`benchmarks/pilot-summary.tsv`](../benchmarks/pilot-summary.tsv) and [`benchmarks/pilot-task-metrics.tsv`](../benchmarks/pilot-task-metrics.tsv). The plot is regenerated with:

```bash
python3 bin/render_pilot_benchmark.py
```

The renderer uses only the Python standard library.

## Projection and assumptions

The preliminary scaling formula is:

```text
scaling factor = full compressed paired FASTQ bytes / pilot compressed paired FASTQ bytes
projected metric = measured pilot metric × scaling factor
```

For the benchmarked sample, the scaling factor is `75.974153`. Linear projection gives:

| Production measure | Projection |
|---|---:|
| Full-sample workflow wall time | 156.7 hours / 6.53 days |
| Full-sample alignment time | 134.1 hours / 5.59 days |
| Full-sample CPU consumption | 1,869 CPU-hours |
| Thirty-sample CPU consumption | 56,069 CPU-hours |
| Thirty samples, sequential | 195.8 days |
| Thirty samples, concurrency 3 | 65.3 days |
| Thirty samples, concurrency 5 | 39.2 days |
| Thirty samples, concurrency 10 | 19.6 days |
| Thirty samples, concurrency 30 | 6.5 days |

Concurrency projections assume identical samples, immediate scheduling, perfect independence, and no shared-filesystem slowdown. They show capacity demand, not promised completion dates. At concurrency 10, alignment alone may reserve approximately 120 CPUs and 720 GB of memory. Storage contention may prevent linear throughput.

## Selected shared-resource policy

The selected production cap is ten simultaneous `BISMARK_ALIGN` tasks. This provides a projected cohort turnaround of approximately 19.6 days while limiting the dominant workload to 120 CPUs and 720 GB of requested memory. The cap was chosen to preserve capacity for other users; it is a local operating decision rather than a universal nf-core recommendation.

Copy the settings from [`conf/production.shared.config.example`](../conf/production.shared.config.example) into the site's ignored `conf/site.local.config` after local HPC review. The process-specific [`maxForks = 10`](https://www.nextflow.io/docs/latest/reference/process.html#maxforks) limits alignment concurrency without unnecessarily serializing FastQC, trimming, extraction, and reporting. A larger executor queue window allows lightweight tasks to flow, while Slurm retains final control over placement and fair-share.

Reassess the policy if input sizes, node architecture, scheduler rules, or observed production performance change. Ten is a maximum, not a promise that ten alignments will always run.

Compressed bytes are a proxy for read count. The source and subset come from the same sample, which makes the ratio useful, but exact production planning should replace it with full paired-read counts when those can be obtained without burdening shared storage.

## Cost model

This public repository does not assign an institutional price because clusters bill differently. Obtain the local chargeback rates and calculate:

```text
compute cost = projected CPU-hours × CPU-hour rate
retained storage cost = retained TB × months retained × TB-month rate
temporary storage cost = peak work TB × active months × TB-month rate
total planning cost = compute + retained storage + temporary storage + applicable service or egress fees
```

Compute-rate sensitivity for the 30-sample projection:

| Illustrative CPU-hour rate | Projected compute amount |
|---:|---:|
| $0.03 | $1,682 |
| $0.05 | $2,803 |
| $0.10 | $5,607 |

These are arithmetic scenarios, not quotes. Memory-based billing, node minimums, queue policy, retries, and personnel time may materially change the total.

## Operational decision

The standard nf-core run is scientifically correct and resource-efficient for the pilot, but a single full-sample Bismark alignment task is projected to run for roughly 5.6 days and approaches the pipeline's eight-day time request. A transient node or storage failure late in that task would be expensive.

The next design phase will evaluate synchronized paired FASTQ chunks aligned in parallel, followed by one sample-wide BAM merge and one global deduplication. Methylation extraction should remain sample-wide because it required only 8 minutes 36 seconds in the pilot and is not the bottleneck.

The proposed scientific order is:

```text
paired FASTQ
→ synchronized paired chunks
→ parallel Bismark alignment
→ merge all chunk BAMs for one sample
→ deduplicate once across the complete sample
→ sort and index
→ methylation extraction
→ Bismark and MultiQC reports
```

No production chunked workflow should be released until equivalence is tested against an unsplit control for alignment counts, duplicate removal, and methylation coverage output.

## Limits of this deliverable

- One biological sample and one 10M subset were benchmarked.
- Queue time was excluded from task runtime.
- Full-sample output size and I/O were not measured directly.
- Linear scaling may change with compression, read composition, filesystem load, and scheduler placement.
- Biological QC metrics require separate review of MultiQC and Bismark reports.
- The benchmark supports engineering planning; it is not clinical validation or a production service-level commitment.
