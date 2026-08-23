# WGBS concepts

## What WGBS measures

DNA contains the bases A, C, G, and T. A cytosine can carry a methyl group. In mammals, methylation is commonly studied at a cytosine followed by guanine, called a CpG site.

Bisulfite treatment changes most unmethylated cytosines into bases that are read as thymine during sequencing. Methylated cytosines are protected and remain cytosines. WGBS uses this difference to estimate methylation throughout the genome.

## Why a specialized aligner is needed

Bisulfite conversion changes many Cs to Ts, so ordinary DNA alignment assumptions no longer hold. Bismark creates bisulfite-converted representations of the reads and reference, uses Bowtie2 to align them, and then determines the methylation state of covered cytosines.

## Paired-end FASTQ files

Each biological sample normally has two files:

- `R1` contains the first read from every sequenced DNA fragment.
- `R2` contains the corresponding second read.

Record 1 in R1 must correspond to record 1 in R2. The same is true for every subsequent record. Never subset or reorder one mate without applying the equivalent operation to the other.

## Coverage and methylation percentage

Suppose eight reads cover a CpG. Six support methylation and two support the unmethylated state:

```text
methylated count     = 6
unmethylated count   = 2
total coverage       = 8
methylation percent  = 6 / 8 * 100 = 75%
```

Retain the counts, not only 75%. An estimate supported by 80 reads is more precise than the same percentage supported by four reads.

## Directional libraries

Bismark assumes a directional library unless instructed otherwise. Confirm the library-preparation protocol with the sequencing facility. Do not select non-directional mode merely because mapping is low.

## Duplicate removal

PCR can create multiple copies of the same original DNA fragment. For standard WGBS, duplicates are removed after all reads for a biological sample have been aligned. Deduplicating independently divided pieces can leave duplicates that occur in different pieces.

