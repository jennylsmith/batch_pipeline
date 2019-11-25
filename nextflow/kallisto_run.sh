#!/bin/bash
set -e
BASE_BUCKET="s3://fh-pi-meshinchi-s/SR"


#Add nextflow to PATH
export PATH=~/scripts/opt/bin:$PATH

#Execute the Kallisto nextflow workflow
nextflow run -c ~/nextflow.config kallisto.nf \
    --sample_sheet swog_sample_sheet.txt \
    --index $BASE_BUCKET/GRCh38.v29/gencode.v29_RepBase.v24.01.idx \
    --output_folder  $BASE_BUCKET/SWOG/kallisto_out \
    -with-report nextflow_report.html \
    -work-dir $BASE_BUCKET/work \
    -cache  TRUE \
    -resume
