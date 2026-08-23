# WGBS run manifest

Copy this template into private project storage for every pilot or production run. Do not commit completed manifests containing protected identifiers, internal paths, usernames, or scheduler details to the public repository.

## Run identity

- Study:
- Run type: smoke test / subset pilot / production
- Run label:
- Date started:
- Date completed:
- Operator:
- Slurm controller job ID:
- Nextflow run name:
- Repository commit:

## Software

- Nextflow version:
- nf-core/methylseq version:
- Java version:
- Container runtime and version:
- Bismark version:
- Bowtie2 version:
- Container image identifiers/digests:

## Inputs

- Samplesheet path:
- Samplesheet checksum:
- Parameter-file path:
- Parameter-file checksum:
- Number of biological samples:
- Read layout: paired-end / single-end
- Read length:
- Library protocol: directional / non-directional / PBAT / other
- UMI/barcode protocol:

For each FASTQ, record sample, mate, absolute path, byte size, read count, and checksum in a private TSV accompanying this manifest.

## Reference

- Species:
- Scientific name:
- Assembly:
- FASTA source and release:
- FASTA path:
- FASTA checksum:
- Included sequence classes:
- Chromosome naming convention:
- Bismark index path:
- Index build job or provenance:

## Execution

- Exact launch command:
- Container profile:
- Executor:
- Slurm account/partition, if applicable:
- Work directory:
- Output directory:
- Nextflow report:
- Nextflow trace:
- Nextflow timeline:
- Nextflow DAG:
- MultiQC report:

## Performance

- Total elapsed time:
- Alignment elapsed time:
- Alignment allocated CPUs:
- Alignment requested memory:
- Alignment peak RSS:
- Input bytes read:
- Output bytes written:
- Work-directory peak size:
- Final-results size:
- Scheduler accounting limitations:

## Biological and technical QC

- Raw read pairs:
- Reads after trimming:
- Mapping efficiency:
- Duplicate percentage:
- Deduplicated alignments:
- CpG methylation:
- CHG methylation:
- CHH methylation:
- Conversion-control result:
- M-bias observations:
- MultiQC warnings reviewed:

For a subset pilot, label duplication, coverage, and methylation metrics as non-final and do not use them for biological conclusions.

## Outcome

- Final state: successful / failed / partial
- Required outputs present:
- `.cov.gz` integrity checked:
- BAM integrity checked:
- Output checksums generated:
- Deviations from documented procedure:
- Failures, retries, and resolutions:
- Approved for production use by:

