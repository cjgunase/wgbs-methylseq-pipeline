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
- Replaced repeated hard-coded cluster paths and module names with one ignored `conf/site.env` configuration.
- Added a Docker-based local-computer smoke-test launcher with prerequisite checks and automatic pinned Nextflow installation.
- Documented host prerequisites, installation routes for macOS, Linux, and Windows/WSL2, automatic nf-core container handling, offline clusters, and the boundary between portable workflow code and site-specific infrastructure.
- Recorded successful GRCh38 Bismark 0.25.1/Bowtie2 index construction and verification, including the reference checksum and unavailable Slurm-accounting metrics.
- Validated the portable `conf/site.env` Slurm launcher with a successful cached smoke test.
- Made smoke-test execution reports, traces, and timelines job-specific to preserve repeat-run evidence without filename collisions.
- Added actionable remediation hints to failed environment checks.
- Added a comprehensive private run-manifest template covering software, inputs, references, execution, performance, QC, output integrity, and deviations.
- Added a read-only run monitor and checkpoint guide that distinguish pipeline task jobs from biological samples and identify actionable failure signals.
- Corrected the monitor to read Slurm controller logs from the documented repository submission directory and to distinguish a missing error log from an empty one.
- Removed unsupported pilot YAML `max_*` fields after the first real-data run exposed the mismatch; production-like pilots retain nf-core requests, while an explicitly optional constrained config demonstrates `process.resourceLimits` for smaller systems.
- Made SHA-256 the preferred run-manifest checksum while retaining provider MD5 values when needed for transfer verification.
- Added a read-only production preflight gate with fast metadata checks, optional full FASTQ validation, paired-read counting, index verification, output collision protection, and an input-scaled storage estimate.
- Made environment checks safe on login nodes whose site-owned Lmod initialization references Slurm-only variables under strict shell mode.
- Prevented Java startup on quota-limited login nodes and made Java/Nextflow startup failures hard stops when checks run inside Slurm.
- Added a concise beginner operator checklist connecting installation, smoke test, reference indexing, pilot submission, provenance, monitoring, and the production decision gate.
- Published the 10M WGBS pilot as a reproducible benchmark deliverable with versioned measurements, capacity and cost projections, a GitHub-ready SVG, explicit assumptions, and the evidence-based decision to plan parallel chunk alignment with global sample-level deduplication.
- Restyled the benchmark as a publication-oriented three-panel scientific figure separating measured task runtime, linear input-size projection, and idealized cohort makespan.
- Recorded ten concurrent Bismark alignments as the selected shared-resource policy, added a reusable process-specific `maxForks` example, and extended the scientific concurrency curve through 30 samples.
