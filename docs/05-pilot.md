# Ten-million-read-pair pilot

## Purpose

The pilot tests installation and estimates throughput without waiting for a complete deeply sequenced WGBS sample. It is an engineering benchmark, not a complete biological analysis.

## Create a synchronized subset

Take the same number of records from R1 and R2:

```bash
seqkit head --number 10000000 SAMPLE_R1.fastq.gz \
  --out-file SAMPLE_10M_R1.fastq.gz

seqkit head --number 10000000 SAMPLE_R2.fastq.gz \
  --out-file SAMPLE_10M_R2.fastq.gz
```

Run this through Slurm, not on a login node. Confirm both outputs contain 10,000,000 reads with `seqkit stats` and validate them with `gzip -t`.

## Configure

```bash
cp samplesheets/pilot.example.csv samplesheets/pilot.private.csv
cp params/pilot.example.yaml params/site.local.yaml
cp conf/site.local.config.example conf/site.local.config
```

Replace every `xxx` with a valid local value. These three local files are ignored by Git.

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

## Interpretation limits

The subset is useful for software validation, alignment rate, peak memory, and throughput. It is not suitable for final duplication rate, genome coverage, CpG coverage distribution, or biological methylation conclusions.

Estimate full alignment time as:

```text
pilot alignment time * complete sample read pairs / 10,000,000
```

Add headroom for trimming, deduplication, extraction, queue delays, and non-linear storage performance.

