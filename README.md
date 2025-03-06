# AWS Batch Pipeline using Nextflow

## Overview

Many scientific tasks are sequential, multi-step processes. The steps are dependent upon each other; that is, step 2 cannot proceed without the output from step 1. However, there is also the need to have processes resumed and to skip a process when it's not necessary. 

This example implements one such process, consisting of three tasks. The workflow is managed with Nextflow and all data processing is carried on AWS Batch. The input files, whether BAM or Fastq, must be hosted in an S3 bucket prior to running the workflow. 

Nextflow does require a `nextflow.congif` file, included a template here for my set-up. You must declare the process.executor as well as any volumes to use for temporary storage during the execution. See the references below for more information about the Fred Hutch Nextflow support. 

### Task 1:

* Download a BAM file from S3
* Run [Picard](https://broadinstitute.github.io/picard/) on it,
  producing two `fastq` files.
* Upload  `fastq` files to S3.

### Task 2:

* Download the `fastq` files (produced in Task 1) from S3
* Run [kallisto](https://pachterlab.github.io/kallisto/) on them.
* Upload the output (`abundance.txt`,`abundance.h5`, and `fusion.txt` file) to S3.

# Usage

0. Create Kallisto index. 

```
BASE_BUCKET = "s3://fh-pi-meshinchi-s-eco-public"

# Create Kallisto index
kallisto index -i gencode.v29_RepBase.v24.01.transcripts.idx gencode.v29_RepBase.v24.01.transcripts.fa.gz
```

if kallisto is not installed locally, you can use singularity or apptainer with the kallisto image to create the index. 

```
# Create Kallisto index in a singularity container
singularity exec -B $PWD/Reference_Data:/Reference_Data docker://quay.io/jennylsmith/kallisto:v0.51.1 \
    kallisto index -i gencode.v29_RepBase.v24.01.transcripts.idx /Reference_Data/gencode.v29_RepBase.v24.01.transcripts.fa.gz
```

1. Then Upload index and BAMs files from local to S3 bucket.
```
# Upload index to S3
aws s3 cp *.idx $BASE_BUCKET/Reference_Data/Kallisto_Index/GRCh38.v29/

# Upload BAMs to S3
aws s3 cp BAM/*.bam $BASE_BUCKET/TARGET_AML/RNAseq_Illumina_Data/BAM/
```

2. Create a sample sheet with the appropriate headers. This is managed by the script `create_sample_sheet.sh` which looks for whether the files in S3 have a fastq or bam file extension. This could be improved by using object tagging rather than base shell commands to parse the desired files.  The `create_sample_sheet.sh` script names the output by the  S3 prefix.

```
# Example for BAMs
INCLUDE=".bam"
./create_sample_sheet.sh s3://bucket s3prefix $INCLUDE

# Exmaple for fastqs. Only select the read1 fastq if paired end reads. 
INCLUDE="_R1.fq.gz"
./create_sample_sheet.sh s3://bucket s3prefix $INCLUDE
```

3. Update the nextlfow run.sh script to include the appropriate sample sheet and be sure to change the --skip_picard parameter to be true/false dependign on where in the workflow you need to start. Also update the `BASE_BUCKET` and appropriate file paths, and the  `--skip_picard` parameter. 

Note that if you have job failures with BAM file inputs, just restard the job since the `-resume` option is turned on and object caching is turned on. That way Nextflow handles which processes can be skipped since the outputs are cached and saved.  Always run the workflow inside the same directory each time to avoid nextflow from not being able to access the cache. 

```
# Run the workflow
tmux
./kallist_run.sh 
```

Best practices include running the worklfow while using `screen` or `tmux` to avoid the temrinal getting disconnected, which will cancel all remaining jobs.  

## References 
* [Configuration at Fred Hutch](https://sciwiki.fredhutch.org/hdc/workflows/running/on_aws/)
* [Example Template](https://github.com/FredHutch/workflow-template-nextflow)
* [Supported Workflows at Fred Hutch](https://sciwiki.fredhutch.org/hdc/workflows/workflow_catalog/)

## Author
* Jenny Leopoldina Smith


