# Reference genomes and Bismark indexes

## Species support

The workflow is not limited to human data. Bismark can process WGBS from any species with a suitable assembled reference FASTA. GRCh38 is the reference used by the initial project, not a pipeline requirement.

Each species and each assembly version requires its own index. Never align reads against an index from another species or another assembly release, even when chromosome names appear similar.

An organized reference area might look like:

```text
references/
  human_GRCh38/
    GRCh38.fa
    Bisulfite_Genome/
  mouse_GRCm39/
    GRCm39.fa
    Bisulfite_Genome/
  bovine_ARS-UCD1.3/
    ARS-UCD1.3.fa
    Bisulfite_Genome/
```

For every reference, record:

- scientific and common species name;
- assembly name and release;
- authoritative download source and URL;
- download date;
- FASTA checksum;
- whether primary, alternate, decoy, organellar, or unplaced sequences are included;
- chromosome naming convention;
- Bismark and Bowtie2 versions used to build the index.

The samplesheet structure does not change between species. Change the `fasta` and `bismark_index` parameter paths to select the correct reference.

Resource requirements depend on genome size. A small microbial or model-organism genome generally needs less memory and time than human, while a large or highly fragmented assembly may require more. Benchmark a subset before setting production resources.

## Why Bismark needs a separate index

Files ending in `.amb`, `.ann`, `.bwt`, `.pac`, `.sa`, or containing `bwameth.c2t` are BWA/BWA-Meth indexes. They cannot be supplied to the Bismark/Bowtie2 workflow. A prepared Bismark reference contains:

```text
REFERENCE_DIRECTORY/
  genome.fa
  Bisulfite_Genome/
    CT_conversion/
    GA_conversion/
```

Build this once per exact FASTA and reuse it for all samples.

## Record the reference identity

```bash
md5sum /project/xxx/reference/GRCh38.primary_assembly.genome.fa
```

Store the checksum in the private run manifest. A Bismark index is valid only for the FASTA from which it was built.

## Use a dedicated directory

```bash
mkdir -p /project/xxx/reference/bismark_grch38_primary
cp /project/xxx/reference/GRCh38.primary_assembly.genome.fa \
  /project/xxx/reference/bismark_grch38_primary/GRCh38.primary_assembly.genome.fa
```

Use a normal copy, not a symbolic link. A container may mount the new reference directory without mounting the symbolic link's external target, causing Bismark to report that the FASTA does not exist. The extra FASTA copy costs storage but makes the reference directory self-contained, portable, and easier for new users to understand. The generated `Bisulfite_Genome` directory will be kept beside the FASTA.

Confirm that the copy is complete by comparing checksums:

```bash
md5sum \
  /project/xxx/reference/GRCh38.primary_assembly.genome.fa \
  /project/xxx/reference/bismark_grch38_primary/GRCh38.primary_assembly.genome.fa
```

Both checksums must be identical before index construction.

## Build through Slurm

First create `logs` in the repository directory because Slurm opens log paths before the script begins:

```bash
mkdir -p logs
```

Identify the Bismark container used by the pinned nf-core release. After a successful smoke test, find the genome-preparation task and read its recorded container path:

```bash
PROJECT=/project/xxx/wgbs-pilot

PREP_COMMAND=$(find "$PROJECT/work" -name .command.sh \
  -exec grep -l 'bismark_genome_preparation' {} + | head -n 1)

grep '^### container:' "$(dirname "$PREP_COMMAND")/.command.run"
```

Why: this reuses the exact container already tested by nf-core instead of independently guessing a Bismark image or version. Stop if `PREP_COMMAND` is empty or the container file no longer exists.

Assign the printed image path and submit:

```bash
GENOME_DIR=/project/xxx/reference/bismark_grch38_primary
BISMARK_IMAGE=/project/xxx/cache/bismark-container.img

sbatch \
  --export=ALL,GENOME_DIR="$GENOME_DIR",BISMARK_IMAGE="$BISMARK_IMAGE" \
  bin/build_bismark_index.sbatch
```

The script requests four CPUs, 32 GB RAM, and 24 hours, refuses to overwrite an existing `Bisulfite_Genome`, verifies that exactly one FASTA is present, runs the same `bismark_genome_preparation --bowtie2` method used by nf-core/methylseq, and lists the generated files.

## If index construction fails

Read both Slurm logs and preserve any partial directory for diagnosis:

```bash
cat logs/bismark-index.JOB_ID.out
cat logs/bismark-index.JOB_ID.err

mv "$GENOME_DIR/Bisulfite_Genome" \
  "$GENOME_DIR/Bisulfite_Genome.failed.JOB_ID"
```

Only run `mv` when a failed job actually created `Bisulfite_Genome`. Preserving it makes the failure auditable and lets the guarded script retry without overwriting ambiguous state. Fix the reported cause before resubmitting.

## Verify

```bash
find "$GENOME_DIR/Bisulfite_Genome" -type f | sort
```

Both `CT_conversion` and `GA_conversion` must contain Bowtie2 index files. Check the Slurm job state and peak memory with `sacct` before choosing future resource requests.
