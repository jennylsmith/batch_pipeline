# AWS Batch Example Array Job Pipeline - Only Run Kallisto


## Overview

### Task 1:

* Download the `fastq` files (produced in Task 1) from S3
* Run [kallisto](https://pachterlab.github.io/kallisto/) on them.
* Upload the output (a `fusion.txt` file) to S3.


Using AWS Batch [Array Jobs](https://docs.aws.amazon.com/batch/latest/userguide/array_jobs.html),
we can kick off any number of these tasks at once.

## Implementation

The implementation consists of several parts.

### 'Batch-side' scripts

This refers to the scripts that are run on AWS Batch (as opposed to
other scripts running on your local computer which orchestrate Batch
jobs).

Often these 'batch-side' scripts are written in the bash shell scripting
language. In this example, they are written in Python, for several reasons:

* Complexity is reduced by using a single language both on the Batch
  side and on the orchestration side.
* Bash syntax can be bewildering and finicky, even to experienced users.
  Python is readable. Even people who do not know the language can guess
  the basic gist of much Python code.

The python scripts do use the excellent [sh](https://amoffat.github.io/sh/)
package, which makes shell-script-like programming in Python very easy.

In this example, the 'batch-side' scripts are in the
[step1_picard](step1_picard/), [step2_kallisto](step2_kallisto/),
and [step3_pizzly](step3_pizzly/) directories.

### Fetch And Run

The mechanism used to run the scripts on Batch is
the [Fetch & Run](https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/)
script. This script is set as the `ENTRYPOINT` of your Docker container.
Then, when you start a Batch job, you pass (as an environment variable)
the [S3](https://aws.amazon.com/s3/) URL of your 'batch-side' script, and it is
run.

### Job Submission

This pipeline consists of one array job, running the `kallisto` step. 

We pass a list of samples to the jobs, by providing a text
file containing one sample name per line.
Assuming we passed a list of 10 samples, 10 `picard` jobs would start
right away. When one of these jobs finishes, the corresponding `kallisto`
job will begin.

These jobs are started in the [main.py](main.py) script.

This script uses the [sciluigi](https://github.com/pharmbio/sciluigi)
workflow system to define the tasks and dependencies.
`sciluigi` may be overkill for such a simple pipeline, but it illustrates
that any workflow tool may be used to orchestrate AWS Batch jobs.
Also, as the complexity of jobs increases, the use of such a tool
may be increasingly appropriate.

#### Example

Install this repository  as follows:

```
git clone https://github.com/FredHutch/batch_pipeline.git
cd batch_pipeline
```

Install [pipenv](https://docs.pipenv.org/#install-pipenv-today) if it is
not already installed. On the `rhino` systems `pipenv` is already installed
if you install a recent Python:

```
ml Python/3.6.4-foss-2016b-fh1 # always type this command at the start of a new
                               # session when working with this example.
```

On other systems, install `pipenv` yourself:

```
pip3 install --user pipenv
```


(If the pipenv command is not found, you may need to add `~/.local/bin` to your
`PATH`, environment variable as discussed
[here](https://askubuntu.com/questions/60218/how-to-add-a-directory-to-the-path)).

Install dependencies (you only need to do this once):

```
pipenv install
pipenv install luigi==2.8.0 #for compatibility
```

Activate your virtual environment:

```
pipenv shell
```


Make sure you have obtained [S3](https://teams.fhcrc.org/sites/citwiki/SciComp/Pages/Getting%20AWS%20Credentials.aspx)
credentials and the [additional permissions](https://fredhutch.github.io/aws-batch-at-hutch-docs/)
needed to run AWS Batch.

Create a text file containing the names of your samples, one per line
(they can contain the .bam suffix or not). Upload this file to S3.

You need to run some one-time steps (see the next section) which
will eventually be automated. Once those have been done, you can
submit your job:

```
python3 main.py --queue=mixed --bucket-name=<YOUR_BUCKET_NAME> --reference=GRCh38.91 \
  --pipeline-name='first-test-pipeline' --sample-list-file=s3://mybucket/mysamplelist.txt

```

Where `s3://mybucket/mysamplelist.txt` is
an S3 URL pointing to the file containing the list of samples you want to process.

This will print out some information including the job IDs of each job step.
Keep these to refer to later (see next section).

### Getting information about completed pipelines

Once a pipeline has completed, you can use the `utils.py` script to find out

* which child jobs succeeded, which failed, and what are the log
  stream names you can use to view the logs of each? (JSON output); and
* how long did the entire pipeline take for a single sample? (plain text output)

Run `utils.py` without arguments to get further help.


