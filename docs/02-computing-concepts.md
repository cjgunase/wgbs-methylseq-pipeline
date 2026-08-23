# Computing concepts

## Login node and compute nodes

The login node is for navigation, file inspection, editing, and job submission. It is not for Bismark, Nextflow, large decompression jobs, or container builds. Submit analyses to Slurm or request an interactive compute allocation.

Example interactive allocation:

```bash
srun --tasks=1 --cpus-per-task=2 --mem=8G --time=02:00:00 --pty bash
```

## CPU, memory, time, and storage

- CPUs determine how much processing can occur concurrently.
- Memory holds programs, genome indexes, and intermediate data structures.
- Wall time is the maximum elapsed duration allowed by Slurm.
- Storage holds inputs, containers, Nextflow work files, and final results.

A large compressed FASTQ is streamed rather than loaded entirely into memory. Its size primarily affects runtime and I/O. Bismark memory is influenced strongly by the reference index and number of concurrent aligner instances.

## What Nextflow does

Nextflow converts a workflow into separate tasks, submits them to Slurm, records dependencies, and resumes completed work after interruption. The small Nextflow controller job must stay alive while it coordinates compute jobs.

`-resume` works only while the original Nextflow metadata and `work` directory remain available.

## What a container does

A Singularity container packages a program and its dependencies. It improves reproducibility and avoids installing every bioinformatics program into a personal Conda environment.

Containers do not contain the sequencing data. Nextflow mounts the required project and reference paths into them.

## Why caches must not use home storage

Nextflow downloads framework JARs under `NXF_HOME`. Singularity stores images under its cache. On systems with small home quotas, defaults such as `$HOME/.nextflow` can fail with `Disk quota exceeded`. Set all large caches to project storage before the first execution.

