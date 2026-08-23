# Changelog

## 0.1.0 - 2026-08-23

- Added beginner-oriented WGBS and computing documentation.
- Added sanitized Slurm, Nextflow, Singularity, and pilot examples.
- Recorded successful Singularity CE 4.0.3 container validation.
- Pinned the validated combination of Nextflow 25.10.7 and nf-core/methylseq 4.2.0.
- Documented home-quota and Java-selection failure modes discovered during setup.
- Documented the successful 36-task nf-core smoke test and expected outputs.
- Added a linear, beginner-oriented runbook from SSH login through verified coverage outputs, with the purpose, expected result, and stop condition for every step.
- Added a guarded Slurm Bismark index builder and explained why BWA/BWA-Meth indexes cannot be reused by Bismark.
- Documented multi-species operation and the requirement for a separate, traceable Bismark index for every species and assembly.
- Changed reference staging from a symbolic link to a self-contained FASTA copy after validating that external symlink targets may be unavailable inside the container mount.
- Added explicit instructions for locating the exact nf-core Bismark container and preserving partial indexes after a failed build.
- Added automated repository checks for script syntax, whitespace, and executable permissions.
- Expanded the real-data pilot guide with paired-subset validation, parameter rationale, success criteria, performance capture, and limits on biological interpretation.
- Disabled the optional genome-wide cytosine report in the default pilot because standard Bismark `.cov.gz` output satisfies the project requirement with less processing and storage.
