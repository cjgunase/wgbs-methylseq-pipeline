# Reproducibility and provenance

Record the following for every production run:

- Repository commit ID
- Nextflow framework version
- nf-core/methylseq release
- Container identifiers or digests
- FASTQ checksums
- Reference source, release, and checksum
- Samplesheet
- Parameter YAML
- Non-sensitive site configuration
- Nextflow report, trace, timeline, and DAG
- MultiQC and Bismark reports
- Slurm resource measurements

## Version pinning

Two independent versions must be pinned:

```bash
export NXF_VER=24.10.6
nextflow run nf-core/methylseq -r 4.2.0 ...
```

The first selects Nextflow itself. The second selects the pipeline release.

## Changing versions

Do not silently update production software. Test the new combination on tiny data and the 10M pilot, compare outputs, record the change in `CHANGELOG.md`, and then adopt it deliberately.

## Public versus private records

The public repository should teach the method. A private run manifest should preserve the real paths, sample identifiers, scheduler settings, and checksums. Do not weaken provenance merely to keep the public repository sanitized; keep sensitive provenance in access-controlled storage.

