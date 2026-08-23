# Installation and environment validation

## 1. Work on a compute node

```bash
srun --tasks=1 --cpus-per-task=2 --mem=8G --time=02:00:00 --pty bash
```

## 2. Load validated modules

```bash
conda deactivate 2>/dev/null || true
source /etc/profile.d/lmod.sh
module purge
module load java/jdk-18.0.1.1
module load singularity/4.0.3
```

Do not assume these module versions exist elsewhere. Use `module spider java` and `module spider singularity` on a new cluster.

## 3. Configure project storage

```bash
PROJECT=/project/xxx/wgbs-pilot
mkdir -p "$PROJECT"/{bin,logs,nextflow_home,singularity_cache,tmp,work,results}

export NXF_HOME="$PROJECT/nextflow_home"
export NXF_VER=24.10.6
export NXF_SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export NXF_TEMP="$PROJECT/tmp"
```

## 4. Install the Nextflow launcher

```bash
curl -fsSL https://get.nextflow.io --output "$PROJECT/bin/nextflow"
chmod u+x "$PROJECT/bin/nextflow"
"$PROJECT/bin/nextflow" -version
```

The downloaded file is already the Nextflow launcher. It does not create another executable when run. `NXF_VER` selects the framework version; without it, the launcher may download a newer release.

## 5. Validate container execution

```bash
singularity exec \
  docker://quay.io/biocontainers/seqkit:2.8.2--h9ee0642_0 \
  seqkit version
```

Messages about OCI conversion and creation of a SIF file are normal on the first run. Success is indicated by the tool printing its version.

## 6. Run the environment checker

```bash
export NEXTFLOW="$PROJECT/bin/nextflow"
bash bin/check_environment.sh
```

