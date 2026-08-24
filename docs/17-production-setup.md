# Deferred production setup

This repository can be prepared before the final storage path exists. Production remains deliberately un-runnable until private files with real paths are created.

## Files that are ready now

- `bin/run_production.sbatch`: guarded production controller.
- `conf/production.env.example`: storage, module, version, and launcher template.
- `conf/production.shared.config.example`: selected maximum of ten concurrent Bismark alignments.
- `params/production.example.yaml`: samplesheet, output, FASTA, and Bismark-index template.
- `bin/make_samplesheet.sh`: paired FASTQ samplesheet generator.

The real `conf/production.env`, `conf/production.local.config`, and `params/production.yaml` are ignored by Git.

## Complete when production storage is assigned

From the repository root:

```bash
cp conf/production.env.example conf/production.env
cp conf/production.shared.config.example conf/production.local.config
cp params/production.example.yaml params/production.yaml
```

Edit every `/storage/xxx` and `/absolute/path` value. `PROJECT` must point to the large production filesystem. The launcher places Nextflow work data, results, logs, container cache, framework cache, and temporary files below that root. The Nextflow launcher itself may remain elsewhere if its absolute path is stable.

The reference FASTA and Bismark index may be copied into the production filesystem. Preserve and recheck the FASTA checksum after copying; the index must remain paired with that exact FASTA.

## Validate before submission

Request a compute allocation, then run:

```bash
source conf/production.env
mkdir -p "$PROJECT/results"
SITE_ENV=conf/production.env bash bin/check_environment.sh
SITE_ENV=conf/production.env bash bin/preflight.sh params/production.yaml
```

Creating the empty production root and `results/` parent is intentional; the preflight still requires the cohort-specific `outdir` itself to be unused.

Review every warning and resolve every stop condition. Also confirm the selected production config resolves as expected:

```bash
NXF_HOME=/storage/xxx/wgbs-methylseq-production/nextflow_home \
NXF_VER=25.10.7 \
/absolute/path/to/bin/nextflow \
  -c conf/slurm.config \
  -c conf/production.local.config \
  config -o flat /absolute/path/to/cached/nf-core/methylseq \
  | grep -E 'maxForks|queueSize|submitRateLimit'
```

Expected values are `maxForks = 10`, `queueSize = 30`, and `submitRateLimit = '2 sec'`.

## Submit

Submit from the repository root so Slurm controller logs are written under `logs/`:

```bash
mkdir -p logs
sbatch bin/run_production.sbatch params/production.yaml
```

The controller requests the selected site's 21-day maximum because idealized cohort completion at concurrency ten is approximately 19.6 days. Queue delay or slower samples could exceed that limit. If the controller reaches its wall-time, diagnose its state and resume with the same parameters and work directory; do not delete `work/`.

Before the actual launch, decide whether one controller run has adequate wall-time margin or whether the cohort should be divided into sequential ten-sample waves. The biological processing is unchanged either way; this is an operational reliability choice.

## Safety behavior

The launcher stops before Nextflow when:

- a private production environment or policy config is missing;
- `xxx` remains in storage or parameter paths;
- the production preflight fails;
- required software or input/reference files are unavailable.

It always uses the pinned Nextflow and methylseq versions, the private production root, the selected concurrency policy, job-specific execution reports, and `-resume`.
