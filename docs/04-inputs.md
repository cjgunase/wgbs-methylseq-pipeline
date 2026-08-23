# Preparing inputs

## Samplesheet

The first four columns are:

```csv
sample,fastq_1,fastq_2,genome
SAMPLE_001,/project/xxx/fastq/SAMPLE_001_R1.fastq.gz,/project/xxx/fastq/SAMPLE_001_R2.fastq.gz,
```

- `sample` is a unique biological-sample identifier.
- `fastq_1` is the absolute R1 path.
- `fastq_2` is the matching R2 path.
- `genome` may be empty when the reference is supplied in the parameter file.

Use fictional identifiers in public examples.

## Input checks

Before processing:

1. Confirm R1 and R2 exist and are nonempty.
2. Confirm both are gzip-valid.
3. Confirm both contain the same number of records.
4. Confirm the library protocol and reference build.
5. Record checksums for the original files.

Do not rename, modify, or move the original FASTQs during an active workflow.

## Reference requirements

Record the FASTA source, release, checksum, chromosome naming convention, and inclusion of alternate or decoy sequences. A Bismark index must match that exact FASTA. Supply the directory containing `Bisulfite_Genome`, not the `Bisulfite_Genome` directory itself.

