#!/usr/bin/env bash
#SBATCH --job-name=wgbs-pilot
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=12:00:00
#SBATCH --chdir=/project/xxx/wgbs-pilot
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: sbatch bin/run_pilot.sbatch params/pilot.yaml" >&2
    exit 2
fi

source /etc/profile.d/lmod.sh
module purge
module load java/jdk-18.0.1.1
module load singularity/4.0.3

PROJECT=/project/xxx/wgbs-pilot
export NXF_HOME="$PROJECT/nextflow_home"
export NXF_VER=25.10.7
export NXF_SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export NXF_TEMP="$PROJECT/tmp"
NEXTFLOW="$PROJECT/bin/nextflow"

mkdir -p "$PROJECT/logs" "$NXF_HOME" "$SINGULARITY_CACHEDIR" "$NXF_TEMP"

"$NEXTFLOW" run nf-core/methylseq \
    -r 4.2.0 \
    -profile singularity \
    -c "$PROJECT/conf/slurm.config" \
    -params-file "$1" \
    -work-dir "$PROJECT/work" \
    -resume \
    -with-report "$PROJECT/logs/${SLURM_JOB_ID}.report.html" \
    -with-trace "$PROJECT/logs/${SLURM_JOB_ID}.trace.tsv" \
    -with-timeline "$PROJECT/logs/${SLURM_JOB_ID}.timeline.html" \
    -with-dag "$PROJECT/logs/${SLURM_JOB_ID}.dag.html"
