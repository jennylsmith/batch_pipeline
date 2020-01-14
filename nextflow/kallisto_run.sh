#!/bin/bash
set -eou
BASE_BUCKET="s3://fh-pi-meshinchi-s/SR"

#Add nextflow to PATH
ml Java/1.8.0_181
export PATH=~/scripts/opt/bin:$PATH #there is now a module with Nextlfow version 19.10.0

#Execute the Kallisto nextflow workflow
nextflow run -c ~/nextflow.config -work-dir $BASE_BUCKET/work -with-report nextflow_report.html -cache TRUE -resume kallisto.nf \
    --sample_sheet ~/scripts/batch_pipeline/sample_sheets/relapse_sample_sheet.txt \
    --index $BASE_BUCKET/GRCh38.v29/gencode.v29_RepBase.v24.01.idx \
    --picard_out_dir $BASE_BUCKET/picard_fq2/ \
    --kallisto_out_dir $BASE_BUCKET/kallisto_out/
