# From pilot to one full sample to a production cohort

Use three deliberately separate stages. Each stage answers a different question, and each must pass before proceeding to the next.

```text
10M-read-pair pilot
        |
        | installation and performance are credible
        v
one complete sample
        |
        | complete-sample QC, outputs, runtime, memory, and storage are acceptable
        v
30-sample production cohort
```

The tiny nf-core test remains an installation smoke test before these stages. It proves that Nextflow, Slurm, containers, and the pipeline can communicate; it does not represent human WGBS performance.

## Stage 1: 10M-read-pair pilot

Follow [the pilot guide](05-pilot.md). Use synchronized R1/R2 reads from one real sample and the same reference, index, containers, and Slurm resource policy intended for production.

The pilot establishes:

- that real WGBS reads pass through the complete workflow;
- whether the reference and Bismark index are compatible;
- approximate alignment throughput and peak memory;
- whether the expected BAM, BAI, `.cov.gz`, reports, and MultiQC are produced.

The pilot does **not** establish complete-sample duplication, coverage, biological QC, final storage consumption, or exact production wall time. Do not merge independently deduplicated pilot chunks into a production result.

Proceed only after the pilot completes successfully and its required outputs and trace are retained.

## Stage 2: one complete sample qualification

Run one representative sample from its original paired FASTQs. Use a new writable project root so pilot work files, caches, results, and logs cannot be confused with the full-sample qualification.

Suggested private layout:

```text
/storage/xxx/wgbs-one-sample-production/
├── bin/
├── conf/
├── logs/
├── nextflow_home/
├── params/
├── results/
├── run_manifests/
├── samplesheets/
├── singularity_cache/
├── tmp/
└── work/
```

Keep the FASTQs in their authoritative source location; the samplesheet may reference them by absolute path. Copying approximately 100 GB of input merely to launch the workflow is unnecessary when the source filesystem is reliable and readable by compute nodes.

### Create a one-sample samplesheet

The file must contain the header and one paired-end sample:

```csv
sample,fastq_1,fastq_2,genome
SAMPLE_01,/storage/xxx/fastq/SAMPLE_01_R1.fastq.gz,/storage/xxx/fastq/SAMPLE_01_R2.fastq.gz,
```

If a validated cohort samplesheet already exists, select its header and one row rather than retyping paths:

```bash
awk -F, 'NR == 1 || $1 == "SAMPLE_01"' \
  samplesheets/cohort.csv \
  > /storage/xxx/wgbs-one-sample-production/samplesheets/SAMPLE_01.csv
```

Inspect the resulting file. It must contain exactly two lines and both FASTQs must belong to the same sample.

### Configure the private production environment

From the repository root:

```bash
cp conf/production.env.example conf/production.env
cp conf/production.shared.config.example conf/production.local.config
cp params/production.example.yaml \
  /storage/xxx/wgbs-one-sample-production/params/SAMPLE_01.yaml
```

These private files are ignored by Git. Set `PROJECT` and `NEXTFLOW_BIN` in `conf/production.env`. In the sample parameter YAML, set:

```yaml
input: /storage/xxx/wgbs-one-sample-production/samplesheets/SAMPLE_01.csv
outdir: /storage/xxx/wgbs-one-sample-production/results/SAMPLE_01

aligner: bismark
fasta: /storage/xxx/reference/bismark_species_assembly/reference.fa
bismark_index: /storage/xxx/reference/bismark_species_assembly
```

The FASTA must be the sequence used to create that exact Bismark index. `bismark_index` points to the parent containing `Bisulfite_Genome`.

### Preflight and submit

Run from a compute allocation:

```bash
SITE_ENV=conf/production.env \
  bash bin/preflight.sh \
  /storage/xxx/wgbs-one-sample-production/params/SAMPLE_01.yaml
```

Resolve every `STOP`. Review warnings, especially storage utilization. Then submit from the repository root:

```bash
mkdir -p logs
sbatch bin/run_production.sbatch \
  /storage/xxx/wgbs-one-sample-production/params/SAMPLE_01.yaml
```

The submitted `wgbs-production` job is the small Nextflow controller. Additional `nf-...` Slurm jobs are FastQC, trimming, alignment, deduplication, sorting, indexing, methylation extraction, reporting, and MultiQC tasks for the same sample. Multiple task jobs do not imply multiple samples.

Monitor without modifying the run:

```bash
squeue -u "$USER" -o "%.18i %.55j %.2t %.10M %.30R"
tail -n 60 logs/wgbs-production.JOB_ID.out
tail -n 40 logs/wgbs-production.JOB_ID.err
```

An available-Nextflow-version notice is informational when the repository intentionally pins a validated version. A run is successful only when the controller log contains `Pipeline completed successfully`; disappearance from `squeue` alone is not proof.

### Full-sample acceptance gate

Do not launch the cohort until all of the following are true:

1. Nextflow reports successful completion with no failed task.
2. The deduplicated BAM and matching BAI exist and are nonempty.
3. The Bismark `.cov.gz` exists and can be decompressed.
4. The sample-level Bismark reports and MultiQC report exist.
5. MultiQC is reviewed for raw and trimmed read quality, trimming, mapping, duplication, and methylation-extraction metrics.
6. The Nextflow trace records actual runtime, CPU use, and peak RSS for every task.
7. Total `work/` and `results/` storage are measured.
8. Samplesheet, parameter YAML, reference FASTA, workflow revision, software versions, and checksums are retained in a private run manifest.

Useful output checks:

```bash
find /storage/xxx/wgbs-one-sample-production/results/SAMPLE_01 \
  -type f \( -name '*.cov.gz' -o -name '*.bam' -o \
  -name '*.bam.bai' -o -name 'multiqc_report.html' \) -print

find /storage/xxx/wgbs-one-sample-production/results/SAMPLE_01 \
  -type f -name '*.cov.gz' -exec gzip -t {} +
```

After completion, add only sanitized aggregate QC and performance information to the public repository. Do not commit raw FASTQs, BAMs, coverage files, protected sample identifiers, private paths, or unredacted logs. A sanitized or de-identified MultiQC report may be published only after confirming that it contains no protected identifiers or infrastructure details.

## Stage 3: 30-sample production

Complete [the production storage setup](17-production-setup.md) after the large filesystem is assigned. Generate and inspect a 30-sample paired-end samplesheet using [the input guide](04-inputs.md). Re-run the preflight against the final cohort YAML.

Use `conf/production.shared.config.example` as the starting shared-cluster policy. It limits concurrent Bismark alignment tasks to ten, limits the executor queue to 30 tasks, and rate-limits submission. This is a scheduler-courtesy policy, not biological batching: each sample is still processed and deduplicated as one complete dataset.

The 10M pilot projected approximately 6.5 days per full sample and approximately 19.6 days for 30 samples with ten concurrent alignments under ideal scaling. Replace those projections with measurements from the completed full-sample qualification before scheduling the cohort. Add queue delay and operational headroom; projections are planning estimates, not guarantees.

Before cohort submission:

- confirm the production filesystem has sufficient space for inputs, `work/`, outputs, caches, and temporary files;
- decide whether the site's controller wall-time safely covers one 30-sample workflow or whether sequential waves are operationally safer;
- preserve a private launch manifest and checksums;
- submit with the same pinned workflow, reference, containers, and reviewed policy used for qualification.

Do not delete `work/` while a run may need `-resume`. Clean work data only after outputs, reports, provenance, and backups have been verified.

## Current validation checkpoint

The 10M-read-pair human WGBS pilot has completed successfully and its measured benchmark is published in [the benchmark and capacity plan](16-pilot-benchmark-and-capacity-plan.md). One complete paired-end sample has been launched through the production procedure described above. Its result remains **in progress** and is not yet a validated deliverable. After completion, this guide and the benchmark record will be updated with the full-sample MultiQC review, measured runtime, resource use, and storage consumption.
