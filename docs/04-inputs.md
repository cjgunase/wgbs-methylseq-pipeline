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

## Generate a samplesheet from consistently named FASTQs

When each pair follows `SAMPLE_R1.fastq.gz` and `SAMPLE_R2.fastq.gz`, generate the CSV instead of typing paths manually:

```bash
bash bin/make_samplesheet.sh \
  /absolute/path/to/fastq_directory \
  /absolute/path/to/private.samplesheet.csv
```

The generator scans only the named directory, writes absolute paths, sorts samples consistently, requires a nonempty reciprocal mate for every R1 and R2, and refuses to overwrite an existing CSV. Because each sample ID is derived from a unique filename stem in one directory, one row is emitted per stem. It writes through a temporary file so a failed pairing check cannot leave a partial samplesheet at the requested path.

The naming rule is deliberate and narrow. For lane-level files or another naming convention, create a reviewed mapping rather than renaming original data during an active study.

After generation, inspect the entire CSV and confirm that each identifier represents the intended biological sample. Filename pairing cannot verify subject identity or metadata correctness.

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
