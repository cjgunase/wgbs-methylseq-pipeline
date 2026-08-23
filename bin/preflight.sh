#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: bash bin/preflight.sh PARAMS.yaml [--deep]" >&2
}

[[ $# -ge 1 && $# -le 2 ]] || { usage; exit 2; }
PARAMS_FILE=$1
DEEP=0
if [[ $# -eq 2 ]]; then
    [[ $2 == --deep ]] || { usage; exit 2; }
    DEEP=1
fi

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SITE_ENV=${SITE_ENV:-$REPO_ROOT/conf/site.env}
failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'STOP  %s\n' "$*" >&2; failures=$((failures + 1)); }
human_bytes() {
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec "$1"
    else
        printf '%s bytes' "$1"
    fi
}

yaml_value() {
    local key=$1
    awk -v key="$key" '
        $0 ~ "^[[:space:]]*" key ":[[:space:]]*" {
            sub("^[[:space:]]*" key ":[[:space:]]*", "")
            sub(/[[:space:]]+#.*$/, "")
            gsub(/^[[:space:]\047\"]+|[[:space:]\047\"]+$/, "")
            print
            exit
        }
    ' "$PARAMS_FILE"
}

echo "WGBS production preflight"
echo "Parameters: $PARAMS_FILE"
echo "Mode: $([[ $DEEP -eq 1 ]] && echo deep || echo metadata)"
echo

[[ -f "$PARAMS_FILE" ]] || { fail "Parameter file not found: $PARAMS_FILE"; exit 1; }
[[ -f "$SITE_ENV" ]] || { fail "Site configuration not found: $SITE_ENV"; exit 1; }
source "$SITE_ENV"

echo "Host environment"
if bash "$REPO_ROOT/bin/check_environment.sh"; then
    pass "Host environment check passed."
else
    fail "Host environment check failed; follow the FIX messages above."
fi
echo

if grep -Eq '^[[:space:]]*max_(cpus|memory|time)[[:space:]]*:' "$PARAMS_FILE"; then
    fail "Unsupported max_* keys found in YAML. Configure resourceLimits in a Nextflow config."
fi

INPUT=$(yaml_value input)
OUTDIR=$(yaml_value outdir)
ALIGNER=$(yaml_value aligner)
FASTA=$(yaml_value fasta)
BISMARK_INDEX=$(yaml_value bismark_index)

for item in INPUT OUTDIR ALIGNER FASTA BISMARK_INDEX; do
    value=${!item:-}
    [[ -n "$value" ]] || fail "Required YAML key is missing or empty: ${item,,}"
    [[ "$value" != *xxx* ]] || fail "Placeholder xxx remains in ${item,,}: $value"
done

for item in INPUT OUTDIR FASTA BISMARK_INDEX; do
    value=${!item:-}
    [[ -z "$value" || "$value" == /* ]] || fail "Path is not absolute for ${item,,}: $value"
done

[[ "$ALIGNER" == bismark ]] || fail "This repository validates aligner: bismark; found: ${ALIGNER:-<empty>}"

if [[ -n "$OUTDIR" && -e "$OUTDIR" ]]; then
    if [[ -d "$OUTDIR" && -z "$(find "$OUTDIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        warn "Output directory exists but is empty: $OUTDIR"
    else
        fail "Output path already exists and is not empty: $OUTDIR"
    fi
else
    pass "Output path is unused: ${OUTDIR:-<missing>}"
fi
if [[ -n "$OUTDIR" ]]; then
    output_parent=$(dirname "$OUTDIR")
    if [[ -d "$output_parent" && -w "$output_parent" ]]; then
        pass "Output parent is writable: $output_parent"
    else
        fail "Output parent is missing or not writable: $output_parent"
    fi
fi

if [[ -n "$FASTA" && -s "$FASTA" ]]; then
    pass "Reference FASTA exists and is nonempty: $FASTA"
else
    fail "Reference FASTA is missing or empty: ${FASTA:-<missing>}"
fi

if [[ -n "$BISMARK_INDEX" && -d "$BISMARK_INDEX/Bisulfite_Genome" ]]; then
    index_count=$(find "$BISMARK_INDEX/Bisulfite_Genome" -type f \( -name 'BS_CT*.bt2' -o -name 'BS_CT*.bt2l' -o -name 'BS_GA*.bt2' -o -name 'BS_GA*.bt2l' \) | wc -l)
    if [[ $index_count -ge 12 ]]; then
        pass "Bismark index has $index_count Bowtie2 index files: $BISMARK_INDEX"
    else
        fail "Bismark index is incomplete ($index_count of at least 12 Bowtie2 files): $BISMARK_INDEX"
    fi
else
    fail "Bisulfite_Genome directory not found under: ${BISMARK_INDEX:-<missing>}"
fi

if [[ -n "$FASTA" && -n "$BISMARK_INDEX" && -f "$FASTA" && -d "$BISMARK_INDEX" ]]; then
    fasta_parent=$(cd "$(dirname "$FASTA")" && pwd -P)
    index_real=$(cd "$BISMARK_INDEX" && pwd -P)
    if [[ "$fasta_parent" == "$index_real" ]]; then
        pass "FASTA and Bismark index share a self-contained reference directory."
    else
        warn "FASTA is outside the Bismark index directory; verify their assembly and checksum provenance."
    fi
fi

declare -A seen_samples=()
declare -A seen_fastqs=()
fastq_count=0
sample_count=0
input_bytes=0

if [[ ! -f "$INPUT" ]]; then
    fail "Samplesheet not found: ${INPUT:-<missing>}"
else
    IFS= read -r header < "$INPUT" || true
    header=${header%$'\r'}
    if [[ "$header" == "sample,fastq_1,fastq_2,genome" ]]; then
        pass "Samplesheet header is valid."
    else
        fail "Samplesheet header must be: sample,fastq_1,fastq_2,genome"
    fi

    line_number=1
    while IFS=, read -r sample r1 r2 genome extra; do
        line_number=$((line_number + 1))
        genome=${genome%$'\r'}
        [[ -n "$sample$r1$r2$genome${extra:-}" ]] || continue
        sample_count=$((sample_count + 1))

        if [[ -n "$sample" ]]; then
            [[ -z "${seen_samples[$sample]:-}" ]] || fail "Duplicate sample name on line $line_number: $sample"
            seen_samples[$sample]=1
        else
            fail "Line $line_number has an empty sample name."
        fi
        [[ -z "${extra:-}" ]] || fail "Line $line_number has extra columns or an unquoted comma."

        for mate in "$r1" "$r2"; do
            [[ "$mate" == /* ]] || fail "FASTQ path is not absolute on line $line_number: $mate"
            if [[ -s "$mate" ]]; then
                pass "FASTQ exists: $mate"
                fastq_count=$((fastq_count + 1))
                bytes=$(stat -c '%s' "$mate")
                input_bytes=$((input_bytes + bytes))
                magic=$(od -An -tx1 -N2 "$mate" | tr -d ' \n')
                [[ "$magic" == 1f8b ]] || fail "File lacks gzip magic bytes: $mate"
                [[ -z "${seen_fastqs[$mate]:-}" ]] || fail "FASTQ path is reused: $mate"
                seen_fastqs[$mate]=1
            else
                fail "FASTQ is missing or empty: $mate"
            fi
        done

        if [[ $DEEP -eq 1 && -s "$r1" && -s "$r2" ]]; then
            gzip -t "$r1" "$r2" && pass "Full gzip validation passed for $sample." || fail "Full gzip validation failed for $sample."
            if command -v seqkit >/dev/null 2>&1; then
                r1_count=$(seqkit stats --tabular --basename "$r1" 2>/dev/null | awk 'NR == 2 {gsub(/,/, "", $4); print $4}' || true)
                r2_count=$(seqkit stats --tabular --basename "$r2" 2>/dev/null | awk 'NR == 2 {gsub(/,/, "", $4); print $4}' || true)
                [[ -n "$r1_count" && "$r1_count" == "$r2_count" ]] && pass "Paired read counts match for $sample: $r1_count" || fail "Paired read counts differ or could not be read for $sample: R1=$r1_count R2=$r2_count"
            else
                fail "Deep mode requires seqkit in PATH to compare paired read counts."
            fi
        fi
    done < <(tail -n +2 "$INPUT")
fi

[[ $sample_count -gt 0 ]] && pass "Samplesheet contains $sample_count sample(s) and $fastq_count readable FASTQ files." || fail "Samplesheet contains no data rows."

if [[ -n "${PROJECT:-}" && -d "$PROJECT" ]]; then
    available_bytes=$(df -Pk "$PROJECT" | awk 'NR == 2 {printf "%.0f", $4 * 1024}')
    minimum_bytes=$((100 * 1024 * 1024 * 1024))
    estimated_bytes=$((input_bytes * 3))
    [[ $estimated_bytes -gt $minimum_bytes ]] || estimated_bytes=$minimum_bytes
    if awk -v a="$available_bytes" -v r="$estimated_bytes" 'BEGIN {exit !(a >= r)}'; then
        pass "Free storage meets the preliminary estimate: $(human_bytes "$available_bytes") available; $(human_bytes "$estimated_bytes") required."
    else
        fail "Insufficient free storage estimate: $(human_bytes "$available_bytes") available; $(human_bytes "$estimated_bytes") required."
    fi
    used_percent=$(df -Pk "$PROJECT" | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')
    [[ $used_percent -lt 95 ]] || warn "Filesystem is ${used_percent}% used; coordinate storage before production even if the byte estimate passes."
else
    fail "PROJECT is missing or not a directory: ${PROJECT:-<missing>}"
fi

if [[ $DEEP -eq 0 ]]; then
    warn "Metadata mode does not read complete FASTQs. Schedule --deep on a compute node before production."
fi

echo
echo "Summary: $failures stop condition(s), $warnings warning(s)."
if [[ $failures -gt 0 ]]; then
    echo "PREFLIGHT FAILED — do not submit the workflow."
    exit 1
fi
echo "PREFLIGHT PASSED — review warnings before submission."
