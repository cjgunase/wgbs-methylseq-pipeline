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
cp conf/site.local.config.example conf/site.local.config
```

Replace every `xxx` with a valid local value. These three local files are ignored by Git.

The pilot parameter file should contain:

```yaml
input: /project/xxx/wgbs-pilot/samplesheets/pilot.private.csv
outdir: /project/xxx/wgbs-pilot/results/pilot-10m

aligner: bismark
fasta: /project/xxx/reference/bismark_species_assembly/genome.fa
bismark_index: /project/xxx/reference/bismark_species_assembly

max_cpus: 8
max_memory: 32.GB
max_time: 12.h
```

Why both reference parameters are supplied: nf-core validates the FASTA together with a prebuilt Bismark index. `bismark_index` points to the directory containing `Bisulfite_Genome`, not to `Bisulfite_Genome` itself.

Why `cytosine_report` is omitted: standard Bismark extraction already produces the `.cov.gz` required by this project. The optional genome-wide cytosine report adds processing and storage and is not needed for this performance pilot. It may be enabled later if a downstream analysis explicitly requires it.

Why the resource values are ceilings: nf-core assigns resources per process up to these limits. They do not mean every process receives 32 GB or eight CPUs. The trace and Slurm accounting will show actual use.

## Run the tiny nf-core test first

After adapting the tracked Slurm script to the local project path:

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
squeue -j JOB_ID
tail -n 60 logs/wgbs-pilot.JOB_ID.out
```

An empty `squeue` result means the controller ended. It does not by itself prove success; inspect the final output and error logs.

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
