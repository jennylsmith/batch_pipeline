# AWS Batch Example Array Job Pipeline

## Overview


Many scientific tasks are sequential, multi-step processes.
The steps are dependent upon each other; that is, step 2 cannot
proceed without the output from step 1.

This example implements one such process, consisting of three tasks. The workflow is managed with Nextflow and all data processing is carried on AWS Batch. 

### Task 1:

* Download a BAM file from S3
* Run [Picard](https://broadinstitute.github.io/picard/) on it,
  producing two `fastq` files.
* Upload  `fastq` files to S3.

### Task 2:

* Download the `fastq` files (produced in Task 1) from S3
* Run [kallisto](https://pachterlab.github.io/kallisto/) on them.
* Upload the output (a `fusion.txt` file) to S3.

### Task 3:

* Download the `fusion.txt` file (produced in Task 2) from S3.
* Run [pizzly](https://github.com/pmelsted/pizzly) on it.
* Upload the output (??) to S3.


Using AWS Batch [Array Jobs](https://docs.aws.amazon.com/batch/latest/userguide/array_jobs.html),
we can kick off any number of these tasks at once.

