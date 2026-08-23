# Ten-million-read-pair pilot

## Purpose

The pilot tests installation and estimates throughput without waiting for a complete deeply sequenced WGBS sample. It is an engineering benchmark, not a complete biological analysis.

Run it only after the smoke test succeeds and a matching Bismark index has been verified. The pilot uses real reads and the real species reference, so it tests performance and compatibility that the tiny smoke test cannot.

## Create a synchronized subset

Take the same number of records from R1 and R2:

```bash
seqkit head --number 10000000 SAMPLE_R1.fastq.gz \
  --out-file SAMPLE_10M_R1.fastq.gz

seqkit head --number 10000000 SAMPLE_R2.fastq.gz \
  --out-file SAMPLE_10M_R2.fastq.gz
```

Run this through Slurm, not on a login node. Confirm both outputs contain 10,000,000 reads with `seqkit stats` and validate them with `gzip -t`.

Why take the first records rather than random samples: applying the same record count to ordered R1 and R2 preserves pairing without requiring both complete FASTQs in memory. The subset must contain exactly the same number of reads in both mates.

Example verification:

```bash
seqkit stats SAMPLE_10M_R1.fastq.gz SAMPLE_10M_R2.fastq.gz
gzip -t SAMPLE_10M_R1.fastq.gz SAMPLE_10M_R2.fastq.gz
```

Expected result: both files report 10,000,000 sequences of the expected read length, and `gzip -t` prints nothing.

## Configure

```bash
cp samplesheets/pilot.example.csv samplesheets/pilot.private.csv
cp params/pilot.example.yaml params/site.local.yaml
cp conf/site.env.example conf/site.env
cp conf/site.local.config.example conf/site.local.config
```

Replace every `xxx` with a valid local value. These local files are ignored by Git. Configure project paths and modules once in `conf/site.env`; do not edit the tracked batch scripts.

The pilot parameter file should contain:

```yaml
input: /project/xxx/wgbs-pilot/samplesheets/pilot.private.csv
outdir: /project/xxx/wgbs-pilot/results/pilot-10m

aligner: bismark
fasta: /project/xxx/reference/bismark_species_assembly/genome.fa
bismark_index: /project/xxx/reference/bismark_species_assembly
```

Why both reference parameters are supplied: nf-core validates the FASTA together with a prebuilt Bismark index. `bismark_index` points to the directory containing `Bisulfite_Genome`, not to `Bisulfite_Genome` itself.

Why `cytosine_report` is omitted: standard Bismark extraction already produces the `.cov.gz` required by this project. The optional genome-wide cytosine report adds processing and storage and is not needed for this performance pilot. It may be enabled later if a downstream analysis explicitly requires it.

## Pilot resource policy

For a performance pilot, use the same site resource policy intended for production. This makes elapsed time, parallelism, and memory behavior informative for planning the full run. methylseq 4.2.0 assigns Bismark alignment its `process_high` defaults of 12 CPUs and 72 GB, with a process-specific maximum time of eight days. The time is a termination ceiling, not an expected runtime.

Define infrastructure-wide maximums in the ignored `conf/site.local.config` using the modern [`resourceLimits` process directive](https://www.nextflow.io/docs/latest/reference/process.html#resourcelimits), as recommended by the [nf-core system-configuration guide](https://nf-co.re/docs/running/configuration/nextflow-for-your-system). These limits should represent what a node and local policy can actually supply, not an arbitrary attempt to make every task small.

Do not place `max_cpus`, `max_memory`, or `max_time` in this pipeline's parameter YAML. methylseq 4.2.0 does not declare those legacy parameters, so they may be ignored.

### Optional constrained compatibility test

`conf/pilot.constrained.config.example` contains:

```groovy
process.resourceLimits = [
    cpus: 8,
    memory: 32.GB,
    time: 12.h
]
```

Use it only when the target machine cannot satisfy the normal requests. Copy it to an ignored local file and add it explicitly to a separate constrained test. It is not loaded by `run_pilot.sbatch`. A constrained run may be slower, may fail from insufficient memory, and must not be used directly to estimate production throughput.

Resource limits are ceilings, not fixed allocations. Inspect the generated Slurm task and final trace to learn the requested and actual resources. Select production resources from the successful pilot's peak RSS, CPU efficiency, elapsed time, retries, and site policy, with reasonable headroom.

## Run the tiny nf-core test first

After configuring `conf/site.env` for the cluster:

```bash
mkdir -p logs
sbatch bin/run_nfcore_test.sbatch
```

## Run the 10M pilot

```bash
sbatch bin/run_pilot.sbatch params/site.local.yaml
```

Save the job ID printed by `sbatch`.

Monitor the controller:

```bash
bash bin/monitor_run.sh JOB_ID
```

The helper is read-only. It explains the controller, child task jobs, recent progress, error screen, and storage state. See [monitoring and results](06-monitoring-and-results.md) for the checkpoints and stop conditions. An empty `squeue` result means the controller ended; it does not by itself prove success.

## Success criteria

The controller output must end with:

```text
[nf-core/methylseq] Pipeline completed successfully
```

Confirm the principal outputs:

```bash
find results/pilot-10m -type f -name '*.cov.gz' -print
find results/pilot-10m -type f -name '*.bam' -print
find results/pilot-10m -type f -name 'multiqc_report.html' -print
```

Also retain the job-specific Nextflow report, trace, timeline, and DAG from `logs/`.

## Measure performance

Inspect the trace header before selecting columns because trace formats can change:

```bash
head -n 1 logs/JOB_ID.trace.tsv
```

Record at least:

- subset read pairs and compressed bytes;
- total workflow duration;
- Bismark alignment duration;
- alignment CPUs and peak resident memory;
- mapping efficiency;
- duplicate percentage, labeled as subset-only;
- result and work-directory sizes.

Use Slurm accounting for the controller and child job IDs:

```bash
sacct -j JOB_ID \
  --format=JobID,JobName,State,Elapsed,AllocCPUS,ReqMem,MaxRSS,ExitCode
```

## Interpretation limits

The subset is useful for software validation, alignment rate, peak memory, and throughput. It is not suitable for final duplication rate, genome coverage, CpG coverage distribution, or biological methylation conclusions.

Estimate full alignment time as:

```text
pilot alignment time * complete sample read pairs / 10,000,000
```

Add headroom for trimming, deduplication, extraction, queue delays, and non-linear storage performance.

Do not interpret subset duplication, coverage, or methylation as final biology. Whole-sample deduplication is required for production results.
