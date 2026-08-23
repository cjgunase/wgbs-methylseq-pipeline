#!/usr/bin/env bash
#SBATCH --job-name=wgbs-pilot
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=12:00:00
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: sbatch bin/run_pilot.sbatch params/pilot.yaml" >&2
    exit 2
fi

PARAMS_FILE=$(realpath "$1")
[[ -f "$PARAMS_FILE" ]] || { echo "Parameter file not found: $PARAMS_FILE" >&2; exit 2; }

REPO_ROOT=${REPO_ROOT:-${SLURM_SUBMIT_DIR:-$(pwd)}}
SITE_ENV=${SITE_ENV:-$REPO_ROOT/conf/site.env}
[[ -f "$SITE_ENV" ]] || {
    echo "Missing site configuration: $SITE_ENV" >&2
    echo "Copy conf/site.env.example to conf/site.env and edit it." >&2
    exit 2
}
source "$SITE_ENV"

: "${PROJECT:?PROJECT is required in conf/site.env}"
: "${CONTAINER_PROFILE:?CONTAINER_PROFILE is required in conf/site.env}"
: "${NEXTFLOW_VERSION:?NEXTFLOW_VERSION is required in conf/site.env}"
: "${METHYLSEQ_VERSION:?METHYLSEQ_VERSION is required in conf/site.env}"
: "${NEXTFLOW_BIN:?NEXTFLOW_BIN is required in conf/site.env}"

if [[ -r /etc/profile.d/lmod.sh ]]; then source /etc/profile.d/lmod.sh; fi
if command -v module >/dev/null 2>&1; then
    module purge
    [[ -n "${JAVA_MODULE:-}" ]] && module load "$JAVA_MODULE"
    [[ -n "${CONTAINER_MODULE:-}" ]] && module load "$CONTAINER_MODULE"
fi

export NXF_HOME="$PROJECT/nextflow_home"
export NXF_VER="$NEXTFLOW_VERSION"
export NXF_SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export SINGULARITY_CACHEDIR="$PROJECT/singularity_cache"
export NXF_APPTAINER_CACHEDIR="$PROJECT/singularity_cache"
export APPTAINER_CACHEDIR="$PROJECT/singularity_cache"
export NXF_TEMP="$PROJECT/tmp"

mkdir -p "$PROJECT/logs" "$NXF_HOME" "$SINGULARITY_CACHEDIR" "$NXF_TEMP"
cd "$PROJECT"

CONFIG_ARGS=(-c "$REPO_ROOT/conf/slurm.config")
[[ -f "$REPO_ROOT/conf/site.local.config" ]] && CONFIG_ARGS+=(-c "$REPO_ROOT/conf/site.local.config")
CONFIG_ARGS+=(-c "$REPO_ROOT/conf/pilot.config")

"$NEXTFLOW_BIN" run nf-core/methylseq \
    -r "$METHYLSEQ_VERSION" \
    -profile "$CONTAINER_PROFILE" \
    "${CONFIG_ARGS[@]}" \
    -params-file "$PARAMS_FILE" \
    -work-dir "$PROJECT/work" \
    -resume \
    -with-report "$PROJECT/logs/${SLURM_JOB_ID}.report.html" \
    -with-trace "$PROJECT/logs/${SLURM_JOB_ID}.trace.tsv" \
    -with-timeline "$PROJECT/logs/${SLURM_JOB_ID}.timeline.html" \
    -with-dag "$PROJECT/logs/${SLURM_JOB_ID}.dag.html"
