#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+$ ]]; then
    echo "Usage: bash bin/monitor_run.sh SLURM_CONTROLLER_JOB_ID" >&2
    exit 2
fi

JOB_ID=$1
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SITE_ENV=${SITE_ENV:-$REPO_ROOT/conf/site.env}

[[ -f "$SITE_ENV" ]] || {
    echo "FAIL Site configuration not found: $SITE_ENV" >&2
    echo "     Fix: copy conf/site.env.example to conf/site.env and edit it." >&2
    exit 2
}
source "$SITE_ENV"
: "${PROJECT:?PROJECT is required in conf/site.env}"

# Slurm resolves the relative #SBATCH output/error paths from the directory in
# which sbatch was invoked. The documented launch location is the repository
# root. RUN_LOG_DIR permits an explicit override for non-standard submission.
RUN_LOG_DIR=${RUN_LOG_DIR:-$REPO_ROOT/logs}
OUT_LOG="$RUN_LOG_DIR/wgbs-pilot.$JOB_ID.out"
ERR_LOG="$RUN_LOG_DIR/wgbs-pilot.$JOB_ID.err"

echo "WGBS run check: controller job $JOB_ID"
echo
echo "Controller"
if squeue -h -j "$JOB_ID" -o '%i %T %M %R' 2>/dev/null | grep -q .; then
    squeue -h -j "$JOB_ID" -o '  job=%i state=%T elapsed=%M location/reason=%R'
else
    echo "  Not present in squeue. It has finished or failed; verify the final log below."
fi

echo
echo "Active Nextflow tasks for $USER"
TASKS=$(squeue -h -u "$USER" -o '%i|%j|%T|%M|%R' 2>/dev/null | awk -F'|' '$2 ~ /^nf-/')
if [[ -n "$TASKS" ]]; then
    echo "$TASKS" | awk -F'|' '{printf "  job=%s state=%s elapsed=%s process=%s location/reason=%s\n", $1, $3, $4, $2, $5}'
    echo "  Each nf- job is a pipeline step, not necessarily a separate sample."
    echo "  If several workflows are running, this list can include tasks from those runs."
else
    echo "  None currently queued or running."
fi

echo
echo "Recent pipeline progress"
if [[ -f "$OUT_LOG" ]]; then
    grep -E 'executor >|\| [0-9]+ of [0-9]+|Pipeline completed|ERROR|WARN' "$OUT_LOG" | tail -n 18 || true
else
    echo "  WAIT Output log not created yet: $OUT_LOG"
fi

echo
echo "Error screen"
if [[ ! -e "$ERR_LOG" ]]; then
    echo "  WAIT Error log not created yet: $ERR_LOG"
elif [[ ! -s "$ERR_LOG" ]]; then
    echo "  OK   No controller stderr messages."
elif grep -Eiq 'ERROR|Failed process|Caused by:|OutOfMemory|out of memory|TIMEOUT|No space left|Disk quota|Killed' "$ERR_LOG"; then
    echo "  CHECK Possible failure text detected:"
    grep -Ei 'ERROR|Failed process|Caused by:|OutOfMemory|out of memory|TIMEOUT|No space left|Disk quota|Killed' "$ERR_LOG" | tail -n 12
    echo "  Do not resubmit yet; inspect the complete logs and failed work directory."
else
    echo "  INFO stderr contains messages but no recognized failure pattern."
    tail -n 5 "$ERR_LOG"
fi

echo
echo "Project filesystem"
df -h "$PROJECT" | awk 'NR == 1 || NR == 2 {print "  " $0}'

echo
if [[ -f "$OUT_LOG" ]] && grep -q 'Pipeline completed successfully' "$OUT_LOG"; then
    echo "FINAL: SUCCESS marker found. Verify .cov.gz, BAM/BAI, MultiQC, and checksums."
elif [[ -f "$OUT_LOG" ]] && grep -Eq 'ERROR ~|Execution cancelled|Pipeline failed' "$OUT_LOG"; then
    echo "FINAL: FAILURE marker found. Follow docs/07-troubleshooting.md before retrying."
else
    echo "FINAL: No terminal marker yet; the workflow is still running or needs investigation."
fi
