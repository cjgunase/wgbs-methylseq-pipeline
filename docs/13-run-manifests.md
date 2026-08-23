# Run manifests

## Why a manifest is necessary

Nextflow records extensive execution metadata, but reproducibility also requires the scientific context that a scheduler cannot infer: species, assembly, library protocol, input identity, reference checksum, operator decisions, and interpretation limits.

Every pilot and production run should have one private manifest created at submission time and completed after QC review.

## Create a private manifest

```bash
PROJECT=/project/xxx/wgbs-pilot
JOB_ID=123456

mkdir -p "$PROJECT/run_manifests"
cp assets/run-manifest.template.md \
  "$PROJECT/run_manifests/${JOB_ID}.run-manifest.md"
```

Copy the exact submission inputs beside it:

```bash
cp /absolute/path/to/samplesheet.csv \
  "$PROJECT/run_manifests/${JOB_ID}.samplesheet.csv"

cp /absolute/path/to/params.yaml \
  "$PROJECT/run_manifests/${JOB_ID}.params.yaml"
```

Why copy instead of recording only paths: a samplesheet or YAML file could be edited after submission. The private copies preserve what the run was intended to use. Nextflow's own parameter records provide an additional cross-check.

## Record immutable identifiers

```bash
git rev-parse HEAD
sha256sum "$PROJECT/run_manifests/${JOB_ID}.samplesheet.csv"
sha256sum "$PROJECT/run_manifests/${JOB_ID}.params.yaml"
```

Record the repository commit and SHA-256 checksums in the manifest. Provider-supplied MD5 values may also be retained for transfer verification, but SHA-256 is the preferred identity checksum. For references and manageable pilot subsets, record checksums directly. Hashing multi-terabyte production FASTQs is I/O-intensive; use sequencing-provider checksums when trustworthy, or schedule checksum calculation deliberately rather than burdening a shared filesystem during alignment.

## Execution artifacts

The launchers create job-specific Nextflow reports, traces, timelines, and DAGs. Reference these exact files in the manifest. Preserve the MultiQC report, Bismark reports, software-version manifest, `.cov.gz`, and final BAM/BAI according to the project's retention policy.

## Public/private boundary

Commit the empty template and generic procedure publicly. Keep completed manifests private when they contain internal paths, sample identifiers, subjects, scheduler accounts, or other controlled metadata.

Sanitized aggregate benchmarks may be added to public documentation only after confirming that they reveal no protected or institution-specific information.
