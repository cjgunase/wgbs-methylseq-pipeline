# Monitoring and understanding results

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

