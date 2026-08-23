# Install and test on your own computer

## Scope

This path is for learning, validating the repository, and running the tiny nf-core test. Deep human WGBS requires far more storage and compute than a typical laptop; run production samples on HPC or suitable cloud infrastructure.

The pipeline's bioinformatics programs are already defined as containers by nf-core/methylseq. You install only the host prerequisites: Git, curl, Java 17 or newer, Nextflow, and Docker. You do not install Bismark, Bowtie2, FastQC, Trim Galore, Samtools, or MultiQC individually.

## macOS

1. Install Git and curl through Apple Command Line Tools if they are absent:

   ```bash
   xcode-select --install
   ```

2. Install Java 21 with Homebrew:

   ```bash
   brew install openjdk@21
   ```

   Follow Homebrew's printed instructions if Java is not immediately visible in `PATH`.

3. Install and start [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/). Docker Desktop requires a supported macOS release and at least 4 GB RAM; more memory is preferable for this smoke test.

4. Verify:

   ```bash
   git --version
   curl --version
   java -version
   docker version
   docker run --rm hello-world
   ```

## Ubuntu or Debian Linux workstation

1. Install the basic host tools and Java:

   ```bash
   sudo apt update
   sudo apt install -y git curl openjdk-21-jre-headless
   ```

2. Install Docker Engine by following the current [official Docker Engine installation guide](https://docs.docker.com/engine/install/). Docker's repository and signing instructions change over time, so do not copy an old third-party installation snippet.

3. Follow Docker's [Linux post-installation guide](https://docs.docker.com/engine/install/linux-postinstall/) if you want to run Docker without `sudo`. Understand that membership in the `docker` group grants root-equivalent privileges.

4. Verify with the same commands shown for macOS.

## Windows

Use WSL2 with an Ubuntu distribution plus Docker Desktop's WSL2 integration. Nextflow requires a POSIX-compatible environment; do not run this Bash workflow directly in classic Command Prompt. Follow the [Docker Desktop Windows installation guide](https://docs.docker.com/desktop/setup/install/windows-install/).

## Clone and run the local smoke test

```bash
git clone https://github.com/cjgunase/wgbs-methylseq-pipeline.git
cd wgbs-methylseq-pipeline
bash bin/run_local_smoke_test.sh
```

The script:

1. checks for Java, Git, curl, and a running Docker service;
2. creates an ignored `.runtime` directory inside the clone;
3. downloads the pinned Nextflow launcher when absent;
4. pins Nextflow 25.10.7 and nf-core/methylseq 4.2.0;
5. runs the complete tiny test with `-profile test,docker`;
6. retains results, work data, execution reports, and caches under `.runtime`.

Repeated runs receive timestamped report, trace, and timeline filenames, so prior validation evidence is not overwritten.

Success requires:

```text
[nf-core/methylseq] Pipeline completed successfully
```

Find coverage outputs:

```bash
find .runtime/results/nfcore-test -type f -name '*.cov.gz' -print
```

If a prerequisite is missing, the script stops and names it. Install that prerequisite, verify it independently, and rerun the same script; `-resume` reuses completed work.

## Laptop resource expectations

The tiny test downloads multiple images and may use several gigabytes of disk. Docker Desktop must have enough memory assigned. Do not point this local test at full WGBS FASTQs unless the machine is intentionally provisioned with sufficient CPU, memory, and multi-terabyte storage.
