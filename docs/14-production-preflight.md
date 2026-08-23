# Production preflight

## Why this gate exists

A scheduler can accept a job whose inputs, reference, output path, or storage plan are wrong. Discovering those errors after hours of alignment wastes compute time and may create ambiguous partial results. Preflight is a read-only acceptance gate run before `sbatch`.

## Fast metadata check

From the repository root on a login or compute node:

```bash
bash bin/preflight.sh /absolute/path/to/params.yaml
```

On a quota-limited login node, the checker validates executable locations but deliberately does not start Java or Nextflow. It prints a warning and requires the check to be repeated inside a Slurm allocation before submission. This prevents a login-node JVM crash from being mistaken for a broken compute environment—or, worse, being ignored as success.

The check validates:

- the configured Java, Nextflow, Slurm, and container host environment;
- required, recognized parameter values;
- the exact four-column samplesheet header;
- unique sample names and FASTQ paths;
- absolute, nonempty R1/R2 paths with gzip signatures;
- reference FASTA and at least twelve CT/GA Bowtie2 index files;
- a self-contained reference/index layout;
- an unused output path;
- preliminary free storage of at least 100 GiB or three times the compressed FASTQ bytes, whichever is larger.

The storage multiplier is an initial safety gate, not a universal capacity model. Replace it with evidence from the pilot's peak work and result sizes before production.

`STOP` means do not submit. `WARN` requires human review but is not automatically fatal. A pass is necessary but does not replace scientific review of species, assembly, library protocol, consent, or sample identity.

## Deep input check

Full gzip decompression and read counting are I/O-intensive. Request a compute node and ensure SeqKit is available, then run:

```bash
bash bin/preflight.sh /absolute/path/to/params.yaml --deep
```

Deep mode reads every compressed FASTQ and verifies that each R1/R2 pair contains the same number of records. Do not run it casually on the login node or concurrently with storage-intensive production analysis.

## Checks that still require a person

Automation cannot infer whether:

- the sample truly belongs to the stated subject or tissue;
- the library is directional, non-directional, PBAT, or uses UMIs;
- the chosen assembly and included contigs satisfy the study plan;
- a Bismark index was built from the stated FASTA merely because paths coexist;
- three times compressed input is sufficient for the local filesystem and retention policy;
- the analysis and records meet a laboratory's regulated quality system.

Record those decisions in the private run manifest and require a second-person review when the laboratory SOP calls for it.
