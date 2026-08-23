# Validation log

This is a sanitized engineering record. It intentionally excludes hostnames, usernames, institutional names, email addresses, and real storage paths.

## 2026-08-23: environment bootstrap

### Data preparation

- Created a temporary synchronized subset containing 10,000,000 R1 records and 10,000,000 R2 records.
- The subset is designated for performance and installation testing only.
- Production processing remains whole-sample by default.

### Java

- A Java 22 build supplied through an existing Conda environment crashed during JVM initialization.
- The failure occurred before Nextflow or WGBS processing began.
- Resolution: use an interactive compute allocation, deactivate Conda, purge modules, and load the cluster-supported Java `18.0.1.1` module.

### Nextflow

- Nextflow was not supplied as a cluster module.
- The first framework download used `$HOME/.nextflow` and failed because the home quota was exhausted. The partial JAR was invalid.
- Resolution: set `NXF_HOME` to project storage before installing or executing Nextflow.
- The URL `https://get.nextflow.io` returns the Nextflow launcher itself. Saving it as `get-nextflow.sh` does not cause it to create a second executable; it should be saved or renamed as `nextflow`.
- Without `NXF_VER`, the generic launcher selected a newer framework release.
- Resolution: set `NXF_VER=24.10.6` in every interactive session and controller script.
- Confirmed that the `24.10.6` framework JAR exists in the project-scoped cache.

### Singularity

- Singularity CE `4.0.3` was available as an environment module.
- Set both `NXF_SINGULARITY_CACHEDIR` and `SINGULARITY_CACHEDIR` to project storage.
- Successfully pulled and converted the SeqKit `2.8.2` Biocontainer.
- Singularity emitted OCI rollback warnings during conversion but recovered, created the SIF, and successfully executed `seqkit version`.

### Current checkpoint

Validated:

- compute-node interactive execution;
- cluster-supported Java;
- project-scoped Nextflow framework cache;
- explicit Nextflow version pinning;
- project-scoped Singularity cache;
- external container pull and execution;
- synchronized 10-million-read-pair pilot input.

Not yet validated:

- nf-core/methylseq tiny test profile;
- Slurm execution of nf-core child processes;
- access to the exact GRCh38 FASTA and matching Bismark index;
- end-to-end 10-million-read-pair WGBS pilot;
- measured alignment throughput, peak memory, and storage use;
- biological QC outputs.

The next action is the nf-core/methylseq tiny test, followed by the 10-million-read-pair pilot only after the reference paths have been confirmed.
