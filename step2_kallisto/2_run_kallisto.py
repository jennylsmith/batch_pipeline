#!/usr/bin/env python3
"""
a shell-script-like python script to run kallisto
in AWS batch
"""

import io
import os
import logging
import shutil
import sys
import time
import traceback
import glob
from urllib.parse import urlparse


import boto3
import sh


def get_samples(): # FIXME put in common code file
    "retrieve list of samples from s3"
    bytebuf = io.BytesIO()
    s3client = boto3.client("s3")
    url = urlparse(os.getenv("LIST_OF_SAMPLES"))
    bucket = url.netloc
    path = url.path.lstrip("/")
    s3client.download_fileobj(bucket, path, bytebuf)
    raw_sample = bytebuf.getvalue().decode("utf-8")
    samples = raw_sample.splitlines()
    samples = [x.replace(".bam", "") for x in samples]
    return samples


def is_on_aws():
    "check if we are running on aws"
    return os.getenv("HOSTNAME").startswith("ip-")

def check_vars():
    """
    Make sure all needed environment variables are set.
    Return True if this is an array job.
    """
    if not any([os.getenv("SAMPLE_NAME"), os.getenv("LIST_OF_SAMPLES")]):
        print("SAMPLE_NAME must be set for single-jobs.")
        print("LIST_OF_SAMPLES must be set for array jobs.")
        sys.exit(1)
    if os.getenv("AWS_BATCH_JOB_ARRAY_INDEX") and os.getenv("SAMPLE_NAME"):
        print("Don't set SAMPLE_NAME in an array job.")
        sys.exit(1)
    if os.getenv("AWS_BATCH_JOB_ARRAY_INDEX") and not os.getenv("LIST_OF_SAMPLES"):
        print("This is an array job but LIST_OF_SAMPLES is not set!")
        sys.exit(1)
    if not os.getenv("BUCKET_NAME"):
        print("BUCKET_NAME must be set!")
        sys.exit(1)
    if os.getenv("AWS_BATCH_JOB_ARRAY_INDEX") and os.getenv("LIST_OF_SAMPLES"):
        return True
    if os.getenv("SAMPLE_NAME") and not os.getenv("AWS_BATCH_JOB_ARRAY_INDEX"):
        return False
    print("Something is wrong with your environment variables!")
    sys.exit(1)
    return False # unreachable but makes pylint happy

def main(): # pylint: disable=too-many-locals, too-many-branches, too-many-statements
    "do the work"
    LOGGER.info("hostname is %s", os.getenv("HOSTNAME"))
    is_array_job = check_vars()
    job_id = os.getenv("AWS_BATCH_JOB_ID").replace(":", "-")
    # use a scratch directory that no other jobs on this instance will overwrite
    scratch_dir = "/scratch/{}_{}".format(job_id, os.getenv("AWS_BATCH_JOB_ATTEMPT"))
    if is_on_aws(): # no scratch when developing locally
        LOGGER.info("Using scratch directory %s", scratch_dir)
        os.makedirs(scratch_dir) # should not exist
        os.chdir(scratch_dir)
    exitcode = 0
    try:
        bucket = os.getenv("BUCKET_NAME")
        if is_array_job:
            sample_index = int(os.getenv("AWS_BATCH_JOB_ARRAY_INDEX"))
            LOGGER.info("This is an array job and the index is %d.", sample_index)
            samples = get_samples()
            # get sample from list of samples using job array index
            sample = samples[sample_index].strip()
            sample = sample.split("/")[-1] #if sample file list contains prefixes other than SR/, they need to be stripped off
        else:
            sample = os.getenv("SAMPLE_NAME").strip()
        LOGGER.info("Sample is %s.", sample)
        reference = os.getenv("REFERENCE")
        LOGGER.info("Reference is %s.", reference)


        #aws = sh.aws.bake(_iter=True, _err_to_out=True, _out_bufsize=3000)
        # get fastq files
        LOGGER.info("Downloading fastq files...")
        fastqs = []
        for i in range(1, 3):
            fastq = "{}_r{}.fq.gz".format(sample, i)
            fastqs.append(fastq)
            if not os.path.exists(fastq): # for testing TODO remove
                LOGGER.info(sh.aws("s3", "cp","--only-show-errors",
                                   "s3://{}/SR/picard_fq2/{}".format(bucket, fastq), "."))
                time.sleep(5)
        r1 = fastqs[0] # pylint: disable=invalid-name
        r2 = fastqs[1] # pylint: disable=invalid-name

        # get index file
        LOGGER.info("Downloading index file...")
        sh.aws("s3", "cp","--recursive", "--exclude", "*", "--include",  "*.idx", \
            "s3://{}/SR/{}/".format(bucket, reference), "/tmp/")
        index = glob.glob("/tmp/*.idx")[0]
        LOGGER.info("Index is %s.", index)
        time.sleep(5)

        # create output dir
        os.makedirs(sample, exist_ok=True)
        LOGGER.info("downloaded files, listing directory...")
        LOGGER.info(sh.ls("-l"))

        # run kallisto, put output in file
        # kallisto = sh.kallisto.bake(_iter=True, _err_to_out=True, _long_sep=" ")
        LOGGER.info("Running kallisto...")
        sh.kallisto('quant', "-i", index, "-o", sample, "-b",
                    30, "--fusion","--bias", "--rf-stranded", r1, r2,
                    _err_to_out=True, _out="{}/kallisto.out".format(sample))
        LOGGER.info("kallisto output:")
        for line in sh.cat("{}/kallisto.out".format(sample), _iter=True):
            LOGGER.info(line)
        # copy kallisto output to S3
        LOGGER.info("Copying all kallisto output to S3...")
        LOGGER.info(sh.aws("s3", "cp", "--only-show-errors","--sse", "AES256", "--recursive", "--include", "*",
                           sample, "s3://{}/SR/kallisto_out/{}_{}/".format(bucket,
                                                                           sample,
                                                                           reference)))
            # print(line)
        LOGGER.info("Completed without errors.")
    # handle errors
    except Exception: # pylint: disable=broad-except
        exitcode = 1
        traceback.print_exc()
        LOGGER.info("Failed!")
    finally:
        if is_on_aws():
            LOGGER.info("Removing scratch directory...")
            shutil.rmtree(scratch_dir, True)
        # exit with appropriate code so Batch knows
        # whether job SUCCEEDED or FAILED
        LOGGER.info("Exiting with exit code %s.", exitcode)
        sys.exit(exitcode)

if __name__ == "__main__":
    FORMAT = '%(asctime)-15s %(message)s'
    logging.basicConfig(format=FORMAT)
    LOGGER = logging.getLogger()
    LOGGER.setLevel(logging.INFO)
    main()
