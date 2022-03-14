# AWS Batch Pipeline using Nextflow

## Overview

Many scientific tasks are sequential, multi-step processes. The steps are dependent upon each other; that is, step 2 cannot
proceed without the output from step 1. However, there is also the need to have processes resumed and to skip a process when it's not necessary. 

This example implements one such process, consisting of three tasks. The workflow is managed with Nextflow and all data processing is carried on AWS Batch. The input files, whether BAM or Fastq, must be hosted in an S3 bucket prior to running the workflow. 

Nextflow does require a `nextflow.congif` file, included here for my set-up. You must declare the process.executor as well as any volumes to use for temporary storage during the execution. 

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

0. Upload files from local to S3 bucket 

```
aws s3 cp *.bam s3://bucket/s3prefix/
```

1. Create a sample sheet with the appropriate headers. This is managed by the script `create_sample_sheet.sh` which looks for whether the files in S3 have a fastq or bam file extension. This could be improved by using object tagging rather than base shell commands to parse the desired files.  The `create_sample_sheet.sh` script names the output by the  S3 prefix.

```
#Example for BAMs
INCLUDE=".bam"
./create_sample_sheet.sh s3://bucket s3prefix $INCLUDE

#Exmaple for fastqs. Only select the read1 fastq if paired end reads. 
INCLUDE="_R1.fq.gz"
./create_sample_sheet.sh s3://bucket s3prefix $INCLUDE
```

2. Update the nextlfow run.sh script to include the appropriate sample sheet and be sure to change the --skip_picard parameter to be true/false dependign on where in the workflow you need to start. Also update the `BASE_BUCKET` and appropriate file paths, and the  `--skip_picard` parameter. 

Note that if you have job failures with BAM file inputs, just restard the job since the `-resume` option is turned on and object caching is turned on. That way Nextflow handles which processes can be skipped since the outputs are cached and saved.  Always run the workflow inside the same directory each time to avoid nextflow from not being able to access the cache. 

```
#Run the workflow
tmux
./kallist_run.sh 
```

Best practices include running the worklfow while using `screen` or `tmux` to avoid the temrinal getting disconnected, which will cancel all remaining jobs.  

