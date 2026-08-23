# Reproducible WGBS processing with nf-core/methylseq

This repository is the training and operations guide for processing paired-end whole-genome bisulfite sequencing (WGBS) data with [nf-core/methylseq](https://nf-co.re/methylseq), Nextflow, Singularity, and Slurm.

It is intentionally written for scientists who are new to bioinformatics. The repository does not contain sequencing data, credentials, private server names, or institution-specific paths.

## What the workflow does

```text
paired FASTQ files
  -> read-quality assessment
  -> adapter and quality trimming
  -> Bismark alignment
  -> whole-sample duplicate removal
  -> methylation extraction
  -> coverage files and quality-control reports
```

The production workflow processes each sample as a complete paired-end dataset. A small, temporary subset may be created for installation and performance testing; it must not be interpreted as a biologically complete sample.

## Start here

1. Read [WGBS concepts](docs/01-wgbs-concepts.md).
2. Read [computing concepts](docs/02-computing-concepts.md).
3. Follow [installation and environment checks](docs/03-installation.md).
4. Prepare a samplesheet using [the input guide](docs/04-inputs.md).
5. Run the [10-million-read-pair pilot](docs/05-pilot.md).
6. Learn how to [monitor and interpret the run](docs/06-monitoring-and-results.md).
7. Consult [troubleshooting](docs/07-troubleshooting.md) when a command fails.
8. Review the sanitized [validation log](docs/09-validation-log.md) to see what has already been tested.

## Reproducibility policy

- Nextflow is pinned with `NXF_VER`.
- nf-core/methylseq is pinned with `-r`.
- Software executes in versioned containers.
- References must be identified by source, release, and checksum.
- Pipeline parameters are stored in YAML files.
- Site-specific paths and Slurm options live in an untracked local configuration.
- Nextflow trace, report, timeline, DAG, and software-version outputs are retained.

See [reproducibility and provenance](docs/08-reproducibility.md).

## Current validated environment

The initial setup was validated with:

- Nextflow launcher with framework version `24.10.6`
- Java `18.0.1.1` supplied by an environment module
- Singularity CE `4.0.3`
- SeqKit `2.8.2` executed from a Biocontainer
- Slurm as the workflow executor

These versions are documented facts from the initial setup, not permanent requirements. Changes must be tested and recorded in `CHANGELOG.md`.

## Security and privacy

Never commit:

- server hostnames or IP addresses;
- usernames, passwords, SSH keys, or tokens;
- internal email addresses;
- protected sample identifiers;
- absolute institutional storage paths;
- scheduler account or private partition names;
- job logs containing private paths.

Tracked examples use placeholders such as `/project/xxx`, `user@xxx`, and `login.xxx`.

## Status

Environment bootstrap and container execution have been validated. The next validation milestone is the 10-million-read-pair nf-core/methylseq pilot.
