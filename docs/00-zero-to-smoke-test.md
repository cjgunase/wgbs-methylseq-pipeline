# Zero to a verified methylseq smoke test

This runbook takes a new user from a cluster login prompt to a verified nf-core/methylseq test result. Follow it in order. Stop whenever a checkpoint fails; do not continue and hope a later step fixes it.

The examples deliberately use placeholders. Replace `/project/xxx/wgbs-pilot` with a writable project-storage directory. Never use a small quota-limited home directory for this workflow.

## What this runbook validates

At completion, you will have proven that:

- Slurm accepts jobs and provides compute nodes;
- a compatible Java runtime works;
- Nextflow runs at the pinned version;
- Singularity can download and execute containers;
- Nextflow can submit child jobs to Slurm;
- nf-core/methylseq completes trimming, Bismark alignment, deduplication, methylation extraction, reporting, and MultiQC;
- Bismark coverage files are produced.

It does not validate your human FASTQs, GRCh38 reference, library protocol, or production resource requests.

## Before starting

You need:

- SSH access to a Linux HPC cluster using Slurm;
- a project-storage directory with several gigabytes available;
- outbound access to GitHub and container registries from either login or compute nodes;
- permission to run Singularity containers.

The validated software combination is Java 18.0.1.1, Singularity CE 4.0.3, Nextflow 25.10.7, and nf-core/methylseq 4.2.0. On another cluster, module names may differ.

## Step 1: connect to the cluster

From your own computer:

```bash
ssh YOUR_USERNAME@login.xxx
```

Why: SSH opens a terminal on the cluster's login node. The hostname is intentionally hidden in this public guide.

Expected result: a cluster shell prompt. Confirm where you are:

```bash
hostname
```

Stop if SSH fails. Authentication and network access must be fixed before pipeline setup.

## Step 2: choose project storage

Set a shell variable to a writable project path:

```bash
PROJECT=/project/xxx/wgbs-pilot
```

Why: using one variable reduces typing errors. This setting lasts only for the current shell.

Create the runtime directories:

```bash
mkdir -p "$PROJECT"/{bin,conf,logs,nextflow_home,singularity_cache,tmp,work,results}
```

Why each directory exists:

- `bin`: local Nextflow launcher and local batch scripts;
- `conf`: local scheduler configuration;
- `logs`: Slurm and Nextflow execution records;
- `nextflow_home`: framework and pipeline cache;
- `singularity_cache`: downloaded container images;
- `tmp`: temporary framework/container files;
- `work`: restartable Nextflow task data;
- `results`: final published pipeline outputs.

Confirm the directory is writable:

```bash
touch "$PROJECT/.write-test" && rm "$PROJECT/.write-test"
```

Expected result: no output. Stop on `Permission denied` or `Disk quota exceeded` and select suitable project storage.

## Step 3: clone this repository

```bash
git clone https://github.com/cjgunase/wgbs-methylseq-pipeline.git "$PROJECT/pipeline"
```

Why: this downloads the version-controlled documentation and templates. It does not download sequencing data.

Expected result: `Cloning into ...` followed by successful object unpacking.

Record the exact repository revision:

```bash
git -C "$PROJECT/pipeline" rev-parse HEAD
```

Why: the commit ID identifies the exact instructions and scripts used.

## Step 4: request a compute shell

```bash
srun --tasks=1 --cpus-per-task=2 --mem=8G --time=02:00:00 --pty bash
```

Why: login nodes are shared and may enforce strict memory limits. Java, downloads, and container conversion should be tested on an allocated compute node.

Expected result: a new prompt. Verify it:

```bash
hostname
```

The result should identify a compute node. A queued request may take time. `Ctrl-C` cancels the request.

Set `PROJECT` again if the new shell did not inherit it:

```bash
PROJECT=/project/xxx/wgbs-pilot
```

## Step 5: find supported modules

```bash
source /etc/profile.d/lmod.sh
module spider java
module spider singularity
```

Why: module names and versions are cluster-specific. Do not guess them.

For the validated environment:

```bash
conda deactivate 2>/dev/null || true
module purge
module load java/jdk-18.0.1.1
module load singularity/4.0.3
hash -r
```

Why:

- deactivating Conda prevents an unrelated Conda Java from taking precedence;
- `module purge` removes conflicting modules;
- the two `module load` commands select the validated runtimes;
- `hash -r` clears the shell's remembered executable paths.

Check them:

```bash
command -v java
java -version
command -v singularity
singularity --version
```

Expected result: Java runs without a fatal JVM error and Singularity reports version 4.0.3. Stop if either executable is missing or crashes.

## Step 6: configure caches before running Nextflow

```bash
export NXF_HOME="$PROJECT/nextflow_home"
export NXF_VER=25.10.7
export NXF_SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export NXF_TEMP="$PROJECT/tmp"
```

Why:

- `NXF_HOME` prevents large framework files from filling `$HOME/.nextflow`;
- `NXF_VER` prevents the launcher from silently selecting a different release;
- the cache variables keep container images on project storage;
- `NXF_TEMP` keeps temporary downloads away from home storage.

Confirm the important values:

```bash
printf 'NXF_HOME=%s\nNXF_VER=%s\nSINGULARITY_CACHEDIR=%s\n' \
  "$NXF_HOME" "$NXF_VER" "$SINGULARITY_CACHEDIR"
```

Stop if any printed path points under `/home`.

## Step 7: install and verify Nextflow

```bash
curl -fsSL https://get.nextflow.io --output "$PROJECT/bin/nextflow"
chmod u+x "$PROJECT/bin/nextflow"
```

Why: the URL returns the small Nextflow launcher directly. The second command permits your account to execute it.

Verify the pinned framework:

```bash
"$PROJECT/bin/nextflow" -version
```

Expected result: `version 25.10.7`. If a different version appears, confirm `NXF_VER` is exported in the current shell.

## Step 8: verify a container

```bash
singularity exec \
  docker://quay.io/biocontainers/seqkit:2.8.2--h9ee0642_0 \
  seqkit version
```

Why: this independently tests registry access, image conversion, project-scoped caching, and container execution before adding Nextflow.

Expected result: `seqkit v2.8.2`. Initial OCI download and SIF-conversion messages are normal. Some installations emit recoverable transaction rollback warnings; success is determined by the final tool output and zero exit status.

## Step 9: prepare local smoke-test files

Copy the public templates into the local runtime area:

```bash
cp "$PROJECT/pipeline/bin/run_nfcore_test.sbatch" "$PROJECT/bin/run_nfcore_test.sbatch"
cp "$PROJECT/pipeline/conf/slurm.config" "$PROJECT/conf/slurm.config"
```

Why: the tracked public files remain sanitized. The copied batch script becomes the site-specific working version.

Replace the one placeholder project path in the local copy:

```bash
sed -i "s|/project/xxx/wgbs-pilot|$PROJECT|g" "$PROJECT/bin/run_nfcore_test.sbatch"
```

Why: the batch job must know where the local Nextflow launcher, caches, configuration, work, logs, and results live.

Inspect all remaining placeholders:

```bash
grep -RIn 'xxx' "$PROJECT/bin/run_nfcore_test.sbatch" "$PROJECT/conf/slurm.config" || true
```

Expected result: no output unless the cluster requires a private account, partition, or other option. Configure those only in the local files.

Validate shell syntax:

```bash
bash -n "$PROJECT/bin/run_nfcore_test.sbatch"
```

Expected result: no output. Stop and fix any reported line before submission.

## Step 10: submit the smoke test

Return to the runtime directory:

```bash
cd "$PROJECT"
```

Why: the Slurm output paths in the batch script are relative to this directory. The `logs` directory already exists, allowing Slurm to open the files before the script starts.

Submit:

```bash
sbatch bin/run_nfcore_test.sbatch
```

Expected result:

```text
Submitted batch job JOB_ID
```

Write down `JOB_ID`. No job ID means submission failed.

## Step 11: monitor without interfering

```bash
squeue -j JOB_ID
```

Common states:

- `PD`: pending, waiting for resources;
- `R`: running;
- an empty result: the job has finished or failed quickly.

While it runs:

```bash
tail -n 60 "logs/wgbs-test.JOB_ID.out"
```

Why: the controller log shows stages and task counts. Check the matching `.err` file if the controller disappears before reporting success.

Do not cancel the controller because it uses little CPU. Its role is to coordinate the child Slurm jobs.

## Step 12: verify completion

```bash
tail -n 80 "logs/wgbs-test.JOB_ID.out"
```

Required final message:

```text
[nf-core/methylseq] Pipeline completed successfully
```

Confirm the controller exit status:

```bash
sacct -j JOB_ID --format=JobID,JobName,State,Elapsed,ExitCode
```

Expected controller state: `COMPLETED` with exit code `0:0`.

## Step 13: verify expected outputs

List final files:

```bash
find "$PROJECT/results/nfcore-test" -maxdepth 3 -type f | sort
```

Confirm Bismark coverage files at any depth:

```bash
find "$PROJECT/results/nfcore-test" -type f -name '*.cov.gz' | sort
```

Why the second command searches deeper: methylation coverage files are nested below `bismark/methylation_calls/methylation_coverage/`.

Expected outputs include:

- deduplicated BAM and BAI files;
- FastQC and Trim Galore reports;
- Bismark alignment and summary reports;
- MultiQC report;
- pipeline parameter and software-version records;
- one or more `.bismark.cov.gz` files.

## Validated reference result

The initial test completed successfully in 4 minutes 18 seconds with 36 successful tasks and approximately 0.2 CPU hours. Four Bismark `.cov.gz` files were produced. Different clusters and empty caches may take longer.

## What to do next

Do not analyze production FASTQs yet. First identify the exact human FASTA and either locate or build its matching Bismark index. Then follow the 10-million-read-pair pilot guide.

