# Reusable nf-core/methylseq smoke test

## Why run it

Run this test during initial installation and after meaningful changes to Java, Nextflow, nf-core/methylseq, Singularity, Slurm configuration, or container/cache locations. It is intentionally tiny and normally completes in minutes.

The test answers: “Can this computing environment execute the complete workflow?” It does not answer: “Are my human samples or reference correct?”

## What the test does

The nf-core `test` profile supplies small public FASTQs and a small reference. The workflow automatically decompresses that reference and builds a temporary Bismark index. It does not use the laboratory's GRCh38 reference.

The test exercises:

```text
reference preparation
  -> FastQC
  -> Trim Galore
  -> Bismark alignment
  -> deduplication
  -> BAM sorting and indexing
  -> methylation extraction
  -> Bismark reports
  -> MultiQC
```

## Validated launch

After completing the one-time `conf/site.env` configuration from the zero-to-smoke-test runbook:

```bash
mkdir -p logs
sbatch bin/run_nfcore_test.sbatch
```

Monitor the returned controller job ID:

```bash
squeue -j JOB_ID
tail -n 60 logs/wgbs-test.JOB_ID.out
```

## Success criteria

The final controller output must contain:

```text
[nf-core/methylseq] Pipeline completed successfully
```

Every submitted process must succeed, including MultiQC. Confirm at least one coverage output:

```bash
find results/nfcore-test -type f -name '*.cov.gz' -print
```

Also retain:

- `logs/nfcore-test.report.html`
- `logs/nfcore-test.trace.tsv`
- `logs/nfcore-test.timeline.html`
- `results/nfcore-test/pipeline_info/`
- `results/nfcore-test/multiqc/`

## Initial validated result

On 2026-08-23, the test completed with:

| Item | Result |
|---|---|
| Nextflow | 25.10.7 |
| nf-core/methylseq | 4.2.0 |
| Java | cluster module 18.0.1.1 |
| Container runtime | Singularity CE 4.0.3 |
| Executor | Slurm |
| Tasks | 36 succeeded |
| Duration | 4 minutes 18 seconds |
| CPU usage | approximately 0.2 CPU hours |
| Coverage outputs | four `.bismark.cov.gz` files |

Runtime is not a universal benchmark because queue state, cache state, and hardware differ. The essential result is complete successful execution and expected outputs.

## When to rerun

Rerun after:

- installing on a new cluster;
- changing Java or Nextflow;
- changing the pipeline release;
- changing container runtime or cache configuration;
- changing the Slurm executor configuration;
- clearing pipeline or container caches;
- a long gap since the previous production analysis.

Do not rerun it before every sample when the environment and workflow versions are unchanged.
