# Containers and portability

## What is already containerized

nf-core/methylseq declares versioned containers for its workflow processes. Depending on the chosen aligner and options, these provide Bismark, Bowtie2, FastQC, Trim Galore, Samtools, MultiQC, and supporting utilities. Nextflow pulls the required image when a process first needs it, mounts its working files, runs the command, and reuses the cached image later.

Users do not rebuild these images and do not install the contained bioinformatics tools manually.

## What must exist on the host

Every execution environment needs:

- a POSIX shell and Git;
- Java 17 or newer for Nextflow;
- the pinned Nextflow launcher;
- one supported container engine;
- sufficient storage for inputs, work data, results, and images.

Nextflow officially requires [Java 17 or later](https://nextflow.io/). The repository pins the Nextflow and methylseq releases independently so a launcher update cannot silently change the scientific pipeline.

For Slurm HPC, use Singularity or Apptainer because they are designed for shared systems and do not require a per-user Docker daemon. Container-runtime installation and security configuration are normally administrator responsibilities. If neither command is available through `module spider`, ask the HPC administrators rather than attempting an unreviewed privileged installation. See the official [SingularityCE installation guide](https://docs.sylabs.io/guides/latest/admin-guide/installation.html) for administrator requirements.

For a personal macOS, Windows, or Linux workstation, use Docker. Singularity cannot run natively on macOS or Windows without a Linux VM.

## One-time site configuration

```bash
cp conf/site.env.example conf/site.env
cp conf/site.local.config.example conf/site.local.config
```

Edit `conf/site.env` once:

```bash
PROJECT=/project/xxx/wgbs-pilot
JAVA_MODULE=java/xxx
CONTAINER_MODULE=singularity/xxx
CONTAINER_PROFILE=singularity
NEXTFLOW_VERSION=25.10.7
METHYLSEQ_VERSION=4.2.0
NEXTFLOW_BIN=/project/xxx/wgbs-pilot/bin/nextflow
```

Use `CONTAINER_PROFILE=apptainer` and the matching module when that is the site's installed runtime. Leave a module value empty when the executable is already in `PATH`.

Use `conf/site.local.config` for a required Slurm account, partition, or other non-public scheduler setting. Both files are ignored by Git.

## Network-restricted clusters

The first run normally downloads the pipeline, plugins, test data, and containers. When compute nodes cannot access the internet, coordinate with administrators to pre-pull containers into a shared cache or use a supported transfer node. Do not repeatedly launch tasks that cannot reach registries.

Preserve the container cache between runs. Deleting it forces large downloads and weakens operational reproducibility unless the images are re-fetched by the same immutable identifiers.

## Portability boundary

The workflow and tool environments are portable. These values are intentionally site-specific and cannot be safely guessed:

- storage paths;
- module names;
- Slurm accounts and partitions;
- maximum wall times and job counts;
- internet and bind-mount policies;
- reference-genome locations.

Therefore, “clone and run” means clone, complete the one-time site configuration, pass the smoke test, and then run. It does not mean that every cluster has identical infrastructure.
