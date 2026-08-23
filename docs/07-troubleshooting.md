# Troubleshooting

## Java crashes before Nextflow starts

Symptoms may include a fatal JVM error in `g1PageBasedVirtualSpace.cpp`.

Likely causes include an unsuitable Conda Java build or an overly restrictive login-node memory limit. Request a compute allocation, deactivate Conda, purge modules, and load a cluster-supported Java module.

## `Disk quota exceeded` under `$HOME/.nextflow`

Nextflow used its default framework cache before `NXF_HOME` was set. Remove only the identified incomplete JAR, create a project-storage cache, export `NXF_HOME`, and retry.

```bash
export NXF_HOME=/project/xxx/wgbs-pilot/nextflow_home
export NXF_VER=25.10.7
```

Do not delete an entire shared cache without inspecting it.

## The downloaded `get-nextflow.sh` runs but no `nextflow` file appears

The URL returns the launcher itself. If it was saved as `get-nextflow.sh`, rename it:

```bash
mv get-nextflow.sh nextflow
chmod u+x nextflow
```

## Nextflow prints an unexpected version

The launcher selects the latest release unless `NXF_VER` is set:

```bash
export NXF_VER=25.10.7
nextflow -version
```

Set this inside every controller batch script.

For nf-core/methylseq 4.2.0, Nextflow 24.10.6 was too old for `nf-schema` 2.5.1, while Nextflow 26.04.6 introduced a repository-layout incompatibility with the pipeline's legacy revision cache. Nextflow 25.10.7 is the validated version for this repository.

## Singularity shows OCI transaction rollback messages

Some Singularity/OCI combinations emit rollback warnings during conversion and then recover. Judge the command by its final exit status and whether the requested program executes. In the validated setup, the image completed conversion and `seqkit version` succeeded.

## No Slurm log appears

Create the log directory before submission and capture the job ID:

```bash
mkdir -p logs
sbatch script.sbatch
sacct --starttime today --user "$USER" \
  --format=JobID,JobName,State,Elapsed,ExitCode,Reason
```

Slurm must open output paths before the script body can create them.

## A workflow task fails

Do not delete `work`. Read the controller log, `.nextflow.log`, and task `.command.err`. Correct the underlying problem and launch the identical command with `-resume`.
