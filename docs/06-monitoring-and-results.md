# Monitoring and understanding results

## One-command health check

Run the read-only helper with the controller job ID returned by `sbatch`:

```bash
bash bin/monitor_run.sh JOB_ID
```

It reports the controller state, active `nf-...` task jobs, recent Nextflow progress, recognizable failure messages, project-filesystem usage, and whether a terminal success or failure marker is present. It never cancels, retries, or changes a job.

Submit from the repository root as documented because Slurm resolves the relative controller-log paths from the submission directory. For a non-standard submission directory, set `RUN_LOG_DIR=/absolute/path/to/logs` when invoking the helper.

One biological sample still creates many Slurm jobs. Nextflow submits FastQC, trimming, alignment, deduplication, sorting, indexing, methylation extraction, and reporting as separate tasks. Simultaneous task job IDs therefore do not imply that the samplesheet contains multiple samples.

The active-task list is user-wide because Slurm does not provide the Nextflow parent relationship in `squeue`. If the same user runs multiple workflows simultaneously, correlate tasks with the controller log before drawing conclusions.

## Recommended checkpoints

1. **Two to five minutes after submission:** confirm the controller is running and at least one expected task appears. Check stderr for configuration, container, or missing-file errors.
2. **After trimming:** confirm FastQC and Trim Galore have check marks and Bismark alignment starts. Failure here usually indicates malformed FASTQ input, pairing problems, or container/storage trouble.
3. **During alignment:** confirm the alignment task remains running and the filesystem has safe free space. A long alignment without new controller text is normal; the task reports completion only when it exits.
4. **After alignment:** confirm deduplication, sorting, indexing, and methylation extraction begin in order. Do not expect chromosome splitting in the standard nf-core workflow.
5. **At controller exit:** an empty `squeue` result is not proof of success. Require the `Pipeline completed successfully` marker and verify the principal result files.

Stop and investigate when the helper reports a failure pattern, Slurm reports `OUT_OF_MEMORY`, `TIMEOUT`, or `FAILED`, storage approaches the site safety threshold, or expected task jobs repeatedly start and disappear without progress. Do not immediately resubmit: Nextflow normally preserves the failed task's command and logs for diagnosis, and a corrected run can often use `-resume`.

An available-version notice from Nextflow is informational. Keep using the repository's validated pinned version until a newer Nextflow and nf-core/methylseq combination has passed the smoke test and pilot.

## Slurm

```bash
squeue -u "$USER"
```

After completion:

```bash
sacct -j JOB_ID \
  --format=JobID,JobName,State,Elapsed,AllocCPUS,ReqMem,MaxRSS,ExitCode
```

`PENDING` means a job is waiting. `RUNNING` means it has resources. `COMPLETED` means Slurm observed a successful exit. `FAILED`, `TIMEOUT`, and `OUT_OF_MEMORY` require investigation.

## Nextflow

The controller log reports process names, task states, retries, and the final workflow status. The trace file records runtime, CPU use, and memory for individual tasks.

## Principal biological outputs

- MultiQC report: project-wide summary.
- Bismark alignment report: read counts and mapping efficiency.
- Deduplication report: duplicate removal.
- M-bias report: position-dependent methylation bias.
- Deduplicated BAM: retained alignments used for extraction.
- `.cov.gz`: chromosome, position, methylation percent, methylated count, and unmethylated count.
- Cytosine report: stranded per-cytosine information when enabled.

Do not treat every FastQC warning as failure. Interpret QC collectively and in the context of WGBS and the library protocol.
