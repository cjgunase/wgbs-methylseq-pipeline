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

: "${GENOME_DIR:?Submit with GENOME_DIR=/absolute/path/to/bismark-reference-directory}"
: "${BISMARK_IMAGE:?Submit with BISMARK_IMAGE=/absolute/path/to/bismark-container.img}"

source /etc/profile.d/lmod.sh
module purge
module load singularity/4.0.3

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

singularity exec \
    --bind "$GENOME_DIR:$GENOME_DIR" \
    "$BISMARK_IMAGE" \
    bismark_genome_preparation --bowtie2 "$GENOME_DIR"

singularity exec "$BISMARK_IMAGE" bismark -v

find "$GENOME_DIR/Bisulfite_Genome" -type f -print | sort
