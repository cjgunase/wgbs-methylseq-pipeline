#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: bash bin/make_samplesheet.sh FASTQ_DIRECTORY OUTPUT.csv" >&2
    exit 2
fi

FASTQ_DIR_INPUT=$1
OUTPUT=$2

[[ -d "$FASTQ_DIR_INPUT" ]] || { echo "ERROR FASTQ directory not found: $FASTQ_DIR_INPUT" >&2; exit 1; }
FASTQ_DIR=$(realpath "$FASTQ_DIR_INPUT")
[[ ! -e "$OUTPUT" ]] || { echo "ERROR Output already exists; refusing to overwrite: $OUTPUT" >&2; exit 1; }
[[ "$(basename "$OUTPUT")" != *","* ]] || { echo "ERROR Output filename contains a comma." >&2; exit 1; }

OUTPUT_PARENT=$(dirname "$OUTPUT")
mkdir -p "$OUTPUT_PARENT"
OUTPUT_PARENT=$(realpath "$OUTPUT_PARENT")
OUTPUT="$OUTPUT_PARENT/$(basename "$OUTPUT")"
TEMP_OUTPUT=$(mktemp "$OUTPUT_PARENT/.samplesheet.XXXXXX")
trap 'rm -f "$TEMP_OUTPUT"' EXIT

sample_count=0

printf 'sample,fastq_1,fastq_2,genome\n' > "$TEMP_OUTPUT"

while IFS= read -r r1; do
    filename=$(basename "$r1")
    sample=${filename%_R1.fastq.gz}
    r2="$FASTQ_DIR/${sample}_R2.fastq.gz"

    [[ -n "$sample" ]] || { echo "ERROR Empty sample name derived from: $filename" >&2; exit 1; }
    [[ "$sample" != *","* ]] || { echo "ERROR Sample name contains a comma: $sample" >&2; exit 1; }
    [[ -s "$r1" ]] || { echo "ERROR R1 is missing or empty: $r1" >&2; exit 1; }
    [[ -s "$r2" ]] || { echo "ERROR Matching R2 is missing or empty for $sample: $r2" >&2; exit 1; }
    [[ "$r1" != *","* && "$r2" != *","* ]] || { echo "ERROR FASTQ path contains a comma: $sample" >&2; exit 1; }

    sample_count=$((sample_count + 1))
    printf '%s,%s,%s,\n' "$sample" "$r1" "$r2" >> "$TEMP_OUTPUT"
done < <(find "$FASTQ_DIR" -maxdepth 1 -type f -name '*_R1.fastq.gz' -print | sort)

[[ $sample_count -gt 0 ]] || { echo "ERROR No files matching *_R1.fastq.gz were found in $FASTQ_DIR" >&2; exit 1; }

while IFS= read -r r2; do
    filename=$(basename "$r2")
    sample=${filename%_R2.fastq.gz}
    r1="$FASTQ_DIR/${sample}_R1.fastq.gz"
    [[ -s "$r1" ]] || { echo "ERROR Orphan R2 has no matching nonempty R1: $r2" >&2; exit 1; }
done < <(find "$FASTQ_DIR" -maxdepth 1 -type f -name '*_R2.fastq.gz' -print | sort)

mv "$TEMP_OUTPUT" "$OUTPUT"
trap - EXIT

echo "Created: $OUTPUT"
echo "Samples: $sample_count"
echo "FASTQs: $((sample_count * 2))"
