#!/usr/bin/env bash
set -euo pipefail

required=(java singularity sbatch squeue)
failed=0

for program in "${required[@]}"; do
    if command -v "$program" >/dev/null 2>&1; then
        printf 'OK   %-12s %s\n' "$program" "$(command -v "$program")"
    else
        printf 'FAIL %-12s not found in PATH\n' "$program" >&2
        failed=1
    fi
done

if [[ -n "${NEXTFLOW:-}" && -x "${NEXTFLOW}" ]]; then
    printf 'OK   %-12s %s\n' nextflow "$NEXTFLOW"
elif command -v nextflow >/dev/null 2>&1; then
    NEXTFLOW="$(command -v nextflow)"
    printf 'OK   %-12s %s\n' nextflow "$NEXTFLOW"
else
    printf 'FAIL %-12s set NEXTFLOW to the executable path\n' nextflow >&2
    failed=1
fi

printf '\nVersions\n'
java -version 2>&1 | head -n 2 || true
singularity --version || true
if [[ -n "${NEXTFLOW:-}" && -x "${NEXTFLOW}" ]]; then
    "$NEXTFLOW" -version || true
fi

if [[ "${NXF_HOME:-}" == /home/* || -z "${NXF_HOME:-}" ]]; then
    printf '\nWARN NXF_HOME is unset or points under /home. Use project storage.\n' >&2
fi

if [[ "${SINGULARITY_CACHEDIR:-}" == /home/* || -z "${SINGULARITY_CACHEDIR:-}" ]]; then
    printf 'WARN SINGULARITY_CACHEDIR is unset or points under /home. Use project storage.\n' >&2
fi

exit "$failed"

