# GRCh38 reference and Bismark index

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
ln -s /project/xxx/reference/GRCh38.primary_assembly.genome.fa \
  /project/xxx/reference/bismark_grch38_primary/GRCh38.primary_assembly.genome.fa
```

The symbolic link avoids a second 3 GB FASTA copy. The generated `Bisulfite_Genome` directory will be kept beside the link.

## Build through Slurm

First create `logs` in the repository directory because Slurm opens log paths before the script begins:

```bash
mkdir -p logs
```

Identify the Bismark container used by the pinned nf-core release and assign its absolute path. Then submit:

```bash
GENOME_DIR=/project/xxx/reference/bismark_grch38_primary
BISMARK_IMAGE=/project/xxx/cache/bismark-container.img

sbatch \
  --export=ALL,GENOME_DIR="$GENOME_DIR",BISMARK_IMAGE="$BISMARK_IMAGE" \
  bin/build_bismark_index.sbatch
```

The script requests four CPUs, 32 GB RAM, and 24 hours, refuses to overwrite an existing `Bisulfite_Genome`, verifies that exactly one FASTA is present, runs the same `bismark_genome_preparation --bowtie2` method used by nf-core/methylseq, and lists the generated files.

## Verify

```bash
find "$GENOME_DIR/Bisulfite_Genome" -type f | sort
```

Both `CT_conversion` and `GA_conversion` must contain Bowtie2 index files. Check the Slurm job state and peak memory with `sacct` before choosing future resource requests.

