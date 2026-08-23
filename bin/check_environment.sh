#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SITE_ENV=${SITE_ENV:-$REPO_ROOT/conf/site.env}
[[ -f "$SITE_ENV" ]] || {
    echo "Missing site configuration: $SITE_ENV" >&2
    echo "Copy conf/site.env.example to conf/site.env and edit it." >&2
    exit 2
}
source "$SITE_ENV"

if [[ -r /etc/profile.d/lmod.sh ]]; then
    # Site-owned module initialization may reference Slurm variables that are
    # unset on a login node. Limit relaxed unset-variable handling to that file.
    set +u
    source /etc/profile.d/lmod.sh
    set -u
fi
if command -v module >/dev/null 2>&1; then
    module purge
    [[ -n "${JAVA_MODULE:-}" ]] && module load "$JAVA_MODULE"
    [[ -n "${CONTAINER_MODULE:-}" ]] && module load "$CONTAINER_MODULE"
fi

CONTAINER_BIN=${CONTAINER_PROFILE:-singularity}
NEXTFLOW_BIN=${NEXTFLOW_BIN:-}
required=(java "$CONTAINER_BIN" sbatch squeue git curl)
failed=0

for program in "${required[@]}"; do
    if command -v "$program" >/dev/null 2>&1; then
        printf 'OK   %-12s %s\n' "$program" "$(command -v "$program")"
    else
        printf 'FAIL %-12s not found in PATH\n' "$program" >&2
        case "$program" in
            java) echo "     Fix: set JAVA_MODULE to a Java 17+ module in conf/site.env." >&2 ;;
            singularity|apptainer) echo "     Fix: set CONTAINER_MODULE and CONTAINER_PROFILE correctly, or ask the HPC administrator to install the runtime." >&2 ;;
            sbatch|squeue) echo "     Fix: run on a Slurm cluster/login node or ask the scheduler administrator." >&2 ;;
            git|curl) echo "     Fix: load a site module or ask the administrator to install this basic host tool." >&2 ;;
        esac
        failed=1
    fi
done

if [[ -n "$NEXTFLOW_BIN" && -x "$NEXTFLOW_BIN" ]]; then
    printf 'OK   %-12s %s\n' nextflow "$NEXTFLOW_BIN"
else
    printf 'FAIL %-12s check NEXTFLOW_BIN in conf/site.env\n' nextflow >&2
    echo "     Fix: download the pinned launcher as described in docs/00-zero-to-smoke-test.md, then update NEXTFLOW_BIN." >&2
    failed=1
fi

printf '\nVersions\n'
"$CONTAINER_BIN" --version || true
if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    if java_output=$(java -version 2>&1); then
        printf '%s\n' "$java_output" | head -n 2
    else
        echo "FAIL java starts unsuccessfully inside Slurm." >&2
        echo "     Fix: select a compatible Java module and inspect any hs_err_pid log." >&2
        failed=1
    fi

    if [[ -n "$NEXTFLOW_BIN" && -x "$NEXTFLOW_BIN" ]]; then
        if ! NXF_HOME="$PROJECT/nextflow_home" NXF_VER="$NEXTFLOW_VERSION" "$NEXTFLOW_BIN" -version; then
            echo "FAIL nextflow starts unsuccessfully inside Slurm." >&2
            echo "     Fix: resolve Java and NXF_HOME errors before submission." >&2
            failed=1
        fi
    fi
else
    echo "SKIP Java and Nextflow startup tests: no Slurm allocation detected."
    echo "     Run this check once on a compute node before analysis."
fi

case "${PROJECT:-}" in
    /home/*|'')
        printf '\nFAIL PROJECT is unset or under /home.\n' >&2
        echo "     Fix: set PROJECT in conf/site.env to writable project or scratch storage." >&2
        failed=1
        ;;
    *) printf '\nOK   %-12s %s\n' project "$PROJECT" ;;
esac

exit "$failed"
