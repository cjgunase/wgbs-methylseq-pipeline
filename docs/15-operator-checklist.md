# Operator checklist: clone to pilot

This is the short operating guide for a new user. Follow it in order. Detailed explanations are linked at each stage. Do not start full samples until the real-data pilot has completed and been reviewed.

## 1. Clone and enter the repository

```bash
git clone https://github.com/cjgunase/wgbs-methylseq-pipeline.git
cd wgbs-methylseq-pipeline
```

Why: Git records the exact workflow and documentation version. Record `git rev-parse HEAD` in the private run manifest.

## 2. Configure this computer or cluster once

```bash
cp conf/site.env.example conf/site.env
```

Edit only `conf/site.env` with the writable project location, local Java/container module names, validated version pins, and Nextflow launcher path. This file is ignored by Git because it may contain private infrastructure paths.

On Slurm, request a compute allocation before testing Java or Nextflow. Do not run analysis on a quota-limited login node.

```bash
srun --tasks=1 --cpus-per-task=2 --mem=8G --time=02:00:00 --pty bash
bash bin/check_environment.sh
```

Expected result: every required executable is marked `OK`, and Java, the container runtime, and pinned Nextflow start successfully. Resolve every `FAIL` before continuing. See [installation](03-installation.md) and [troubleshooting](07-troubleshooting.md).

## 3. Run the tiny smoke test

```bash
mkdir -p logs
sbatch bin/run_nfcore_test.sbatch
```

Why: this quickly validates Nextflow, Slurm task submission, container downloads, nf-core/methylseq, Bismark, and result publication using tiny bundled data. It does not test the study reference or real sequencing reads.

Expected result: the controller log ends with `Pipeline completed successfully`, and the test results include `.cov.gz`, BAM/BAI, Bismark reports, FastQC, and MultiQC. Follow [the smoke-test guide](05-smoke-test.md).

## 4. Prepare and verify the species reference

Use a traceable assembly FASTA and a dedicated self-contained Bismark index directory. Record the species, assembly release, source, checksum, chromosome naming convention, and index-build provenance.

```bash
sbatch bin/build_bismark_index.sbatch \
  /absolute/path/to/reference.fa \
  /absolute/path/to/bismark_species_assembly
```

Expected result: both `CT_conversion` and `GA_conversion` contain six Bowtie2 index files, and the build log ends with `Parallel genome indexing complete`. A BWA or BWA-Meth index cannot replace a Bismark index. Follow [the reference guide](10-reference-and-bismark-index.md).

## 5. Prepare the paired samplesheet and parameters

Create a private four-column samplesheet:

```csv
sample,fastq_1,fastq_2,genome
SAMPLE_001,/absolute/path/SAMPLE_001_R1.fastq.gz,/absolute/path/SAMPLE_001_R2.fastq.gz,
```

Create a private YAML parameter file:

```yaml
input: /absolute/path/to/samplesheet.csv
outdir: /absolute/path/to/new/results
aligner: bismark
fasta: /absolute/path/to/bismark_species_assembly/reference.fa
bismark_index: /absolute/path/to/bismark_species_assembly
```

Do not add unrecognized `max_cpus`, `max_memory`, or `max_time` keys to methylseq 4.2.0 YAML. Infrastructure limits belong in a Nextflow site config. See [input preparation](04-inputs.md).

## 6. Run one 10-million-read-pair performance pilot

Create a synchronized R1/R2 subset on a compute node and verify both mates contain exactly 10,000,000 reads. Then submit:

```bash
sbatch bin/run_pilot.sbatch /absolute/path/to/pilot.params.yaml
```

Why: this tests real reads, the real reference, Bismark compatibility, runtime, memory, and storage before committing to deeply sequenced full samples. Use the same resource policy intended for production so the benchmark is meaningful.

The pilot is an engineering test. Do not use its duplication, coverage, or methylation values for biological conclusions. Follow [the pilot guide](05-pilot.md).

## 7. Preserve the run record

At submission time, copy the empty manifest and the exact submitted samplesheet and parameter file into private project storage. Record the launch commit and SHA-256 checksums.

```bash
mkdir -p /project/xxx/wgbs-pilot/run_manifests
cp assets/run-manifest.template.md /project/xxx/wgbs-pilot/run_manifests/JOB_ID.run-manifest.md
cp /absolute/path/to/samplesheet.csv /project/xxx/wgbs-pilot/run_manifests/JOB_ID.samplesheet.csv
cp /absolute/path/to/params.yaml /project/xxx/wgbs-pilot/run_manifests/JOB_ID.params.yaml
sha256sum /project/xxx/wgbs-pilot/run_manifests/JOB_ID.samplesheet.csv
sha256sum /project/xxx/wgbs-pilot/run_manifests/JOB_ID.params.yaml
```

Why: copies and checksums preserve what was actually intended at submission even if working files change later. Keep completed manifests private when they contain sample identifiers or internal paths. See [run manifests](13-run-manifests.md).

## 8. Monitor without interfering

```bash
bash bin/monitor_run.sh JOB_ID
```

The controller coordinates the workflow; separate `nf-...` Slurm jobs are FastQC, trimming, alignment, deduplication, extraction, and reporting tasks—not necessarily separate samples. The monitor is read-only.

During Bismark alignment, `0 of 1` can remain displayed until the task finishes. A long interval without controller-log updates is normal when the Slurm task remains `RUNNING` and no failure pattern appears. See [monitoring and results](06-monitoring-and-results.md).

## 9. Review the completed pilot before production

Require all of the following:

- controller log contains `Pipeline completed successfully`;
- `.cov.gz`, deduplicated BAM/BAI, Bismark reports, and MultiQC exist;
- trace/report/timeline/DAG are retained;
- mapping efficiency, trimming, duplication, conversion control, M-bias, and methylation context metrics are reviewed;
- final alignment elapsed time, CPU efficiency, peak RSS, work size, and result size are recorded;
- available storage is sufficient for all full samples plus work data and retained outputs;
- the run manifest is completed with deviations and review status.

Only then estimate production time and resources from the pilot. Do not manually split full FASTQs or BAMs unless a measured, documented limitation requires a custom workflow; Nextflow already schedules pipeline stages and retries independently.

## 10. Before full production

Use nf-core/Nextflow's built-in schema and execution checks. The repository's optional [preflight](14-production-preflight.md) adds a lightweight review of paths, pairing, reference/index presence, output collision, and storage. It is a convenience gate, not a replacement for nf-core validation or laboratory review.

Production should use a new output directory, preserved configuration snapshots, and the validated reference and software versions. Start with a small number of full samples if storage or scheduler behavior remains uncertain, then expand concurrency based on measured results.
