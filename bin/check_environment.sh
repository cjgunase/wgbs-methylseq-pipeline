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

if [[ -r /etc/profile.d/lmod.sh ]]; then source /etc/profile.d/lmod.sh; fi
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
        failed=1
    fi
done

if [[ -n "$NEXTFLOW_BIN" && -x "$NEXTFLOW_BIN" ]]; then
    printf 'OK   %-12s %s\n' nextflow "$NEXTFLOW_BIN"
else
    printf 'FAIL %-12s check NEXTFLOW_BIN in conf/site.env\n' nextflow >&2
    failed=1
fi

printf '\nVersions\n'
java -version 2>&1 | head -n 2 || true
"$CONTAINER_BIN" --version || true
if [[ -n "$NEXTFLOW_BIN" && -x "$NEXTFLOW_BIN" ]]; then
    NXF_HOME="$PROJECT/nextflow_home" NXF_VER="$NEXTFLOW_VERSION" "$NEXTFLOW_BIN" -version || true
fi

case "${PROJECT:-}" in
    /home/*|'') printf '\nFAIL PROJECT is unset or under /home. Use project storage.\n' >&2; failed=1 ;;
    *) printf '\nOK   %-12s %s\n' project "$PROJECT" ;;
esac

exit "$failed"

