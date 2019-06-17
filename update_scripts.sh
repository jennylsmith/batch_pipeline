#!/bin/bash

aws s3 cp step1_picard/1_run_picard.py s3://fh-pi-meshinchi-s/SR/jlsmith3-scripts/
aws s3 cp step2_kallisto/2_run_kallisto.py s3://fh-pi-meshinchi-s/SR/jlsmith3-scripts/
aws s3 cp step3_pizzly/3_run_pizzly.py s3://fh-pi-meshinchi-s/SR/jlsmith3-scripts/
