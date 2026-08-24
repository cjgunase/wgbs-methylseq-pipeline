#!/usr/bin/env bash
#SBATCH --job-name=wgbs-production
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=21-00:00:00
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: sbatch bin/run_production.sbatch params/production.yaml" >&2
    exit 2
fi

PARAMS_FILE=$(realpath "$1")
[[ -f "$PARAMS_FILE" ]] || { echo "Parameter file not found: $PARAMS_FILE" >&2; exit 2; }

REPO_ROOT=${REPO_ROOT:-${SLURM_SUBMIT_DIR:-$(pwd)}}
SITE_ENV=${SITE_ENV:-$REPO_ROOT/conf/production.env}
PRODUCTION_CONFIG=${PRODUCTION_CONFIG:-$REPO_ROOT/conf/production.local.config}

[[ -f "$SITE_ENV" ]] || {
    echo "Missing production environment: $SITE_ENV" >&2
    echo "Copy conf/production.env.example to conf/production.env and edit every placeholder." >&2
    exit 2
}
[[ -f "$PRODUCTION_CONFIG" ]] || {
    echo "Missing production policy: $PRODUCTION_CONFIG" >&2
    echo "Copy conf/production.shared.config.example to conf/production.local.config and review it." >&2
    exit 2
}
source "$SITE_ENV"

: "${PROJECT:?PROJECT is required in conf/production.env}"
: "${CONTAINER_PROFILE:?CONTAINER_PROFILE is required in conf/production.env}"
: "${NEXTFLOW_VERSION:?NEXTFLOW_VERSION is required in conf/production.env}"
: "${METHYLSEQ_VERSION:?METHYLSEQ_VERSION is required in conf/production.env}"
: "${NEXTFLOW_BIN:?NEXTFLOW_BIN is required in conf/production.env}"

for value in "$PROJECT" "$NEXTFLOW_BIN"; do
    [[ "$value" != *xxx* ]] || { echo "Unresolved placeholder in production environment: $value" >&2; exit 2; }
    [[ "$value" != /absolute/path* ]] || { echo "Unresolved absolute-path placeholder in production environment: $value" >&2; exit 2; }
done
grep -Eq 'xxx|/absolute/path' "$PARAMS_FILE" && { echo "Unresolved path placeholder in: $PARAMS_FILE" >&2; exit 2; }

if [[ -r /etc/profile.d/lmod.sh ]]; then
    set +u
    source /etc/profile.d/lmod.sh
    set -u
fi
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

mkdir -p "$PROJECT/logs" "$PROJECT/results" "$NXF_HOME" "$SINGULARITY_CACHEDIR" "$NXF_TEMP"

SITE_ENV="$SITE_ENV" bash "$REPO_ROOT/bin/preflight.sh" "$PARAMS_FILE"

cd "$PROJECT"
"$NEXTFLOW_BIN" run nf-core/methylseq \
    -r "$METHYLSEQ_VERSION" \
    -profile "$CONTAINER_PROFILE" \
    -c "$REPO_ROOT/conf/slurm.config" \
    -c "$PRODUCTION_CONFIG" \
    -params-file "$PARAMS_FILE" \
    -work-dir "$PROJECT/work" \
    -resume \
    -with-report "$PROJECT/logs/${SLURM_JOB_ID}.report.html" \
    -with-trace "$PROJECT/logs/${SLURM_JOB_ID}.trace.tsv" \
    -with-timeline "$PROJECT/logs/${SLURM_JOB_ID}.timeline.html" \
    -with-dag "$PROJECT/logs/${SLURM_JOB_ID}.dag.html"
