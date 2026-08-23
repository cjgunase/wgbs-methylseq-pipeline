#!/usr/bin/env bash
#SBATCH --job-name=bismark-index
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err

set -euo pipefail

REPO_ROOT=${REPO_ROOT:-${SLURM_SUBMIT_DIR:-$(pwd)}}
SITE_ENV=${SITE_ENV:-$REPO_ROOT/conf/site.env}
[[ -f "$SITE_ENV" ]] || {
    echo "Missing site configuration: $SITE_ENV" >&2
    echo "Copy conf/site.env.example to conf/site.env and edit it." >&2
    exit 2
}
source "$SITE_ENV"

: "${GENOME_DIR:?Submit with GENOME_DIR=/absolute/path/to/bismark-reference-directory}"
: "${BISMARK_IMAGE:?Submit with BISMARK_IMAGE=/absolute/path/to/bismark-container.img}"

if [[ -r /etc/profile.d/lmod.sh ]]; then source /etc/profile.d/lmod.sh; fi
if command -v module >/dev/null 2>&1; then
    module purge
    [[ -n "${CONTAINER_MODULE:-}" ]] && module load "$CONTAINER_MODULE"
fi

CONTAINER_BIN=${CONTAINER_PROFILE:-singularity}
command -v "$CONTAINER_BIN" >/dev/null 2>&1 || {
    echo "Container command not found: $CONTAINER_BIN" >&2
    exit 1
}

[[ -d "$GENOME_DIR" ]] || { echo "Genome directory not found: $GENOME_DIR" >&2; exit 1; }
[[ -f "$BISMARK_IMAGE" ]] || { echo "Bismark container not found: $BISMARK_IMAGE" >&2; exit 1; }

fasta_count=$(find "$GENOME_DIR" -maxdepth 1 \( -type f -o -type l \) | grep -Ec '\.(fa|fasta)$' || true)
[[ "$fasta_count" -eq 1 ]] || {
    echo "Expected exactly one .fa or .fasta in $GENOME_DIR; found $fasta_count" >&2
    exit 1
}

if [[ -d "$GENOME_DIR/Bisulfite_Genome" ]]; then
    echo "Refusing to overwrite existing index: $GENOME_DIR/Bisulfite_Genome" >&2
    exit 1
fi

"$CONTAINER_BIN" exec \
    --bind "$GENOME_DIR:$GENOME_DIR" \
    "$BISMARK_IMAGE" \
    bismark_genome_preparation --bowtie2 "$GENOME_DIR"

"$CONTAINER_BIN" exec "$BISMARK_IMAGE" bismark -v

find "$GENOME_DIR/Bisulfite_Genome" -type f -print | sort
