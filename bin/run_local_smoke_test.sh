#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RUNTIME=${RUNTIME:-$REPO_ROOT/.runtime}
NEXTFLOW_VERSION=${NEXTFLOW_VERSION:-25.10.7}
METHYLSEQ_VERSION=${METHYLSEQ_VERSION:-4.2.0}
NEXTFLOW_BIN=${NEXTFLOW_BIN:-$RUNTIME/bin/nextflow}

for program in java git curl docker; do
    command -v "$program" >/dev/null 2>&1 || {
        echo "Missing prerequisite: $program" >&2
        exit 2
    }
done

docker info >/dev/null 2>&1 || {
    echo "Docker is installed but the Docker service is not running." >&2
    exit 2
}

mkdir -p "$RUNTIME"/{bin,nextflow_home,tmp,work,results,logs}
export NXF_HOME="$RUNTIME/nextflow_home"
export NXF_TEMP="$RUNTIME/tmp"
export NXF_VER="$NEXTFLOW_VERSION"

if [[ ! -x "$NEXTFLOW_BIN" ]]; then
    curl -fsSL https://get.nextflow.io --output "$NEXTFLOW_BIN"
    chmod u+x "$NEXTFLOW_BIN"
fi

"$NEXTFLOW_BIN" -version

"$NEXTFLOW_BIN" run nf-core/methylseq \
    -r "$METHYLSEQ_VERSION" \
    -profile test,docker \
    --outdir "$RUNTIME/results/nfcore-test" \
    -work-dir "$RUNTIME/work" \
    -resume \
    -with-report "$RUNTIME/logs/nfcore-test.report.html" \
    -with-trace "$RUNTIME/logs/nfcore-test.trace.tsv" \
    -with-timeline "$RUNTIME/logs/nfcore-test.timeline.html"

