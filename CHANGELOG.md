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
