#!/bin/bash
set -eou
BASE_BUCKET="s3://fh-pi-meshinchi-s/SR"
NEW_BUCKET="s3://fh-pi-meshinchi-s-eco-public"


#Add nextflow to PATH
#ml Java/1.8.0_181
#export PATH=~/scripts/opt/bin:$PATH #there is now a module with Nextlfow version 19.10.0
ml nextflow/20.04.0-edge


#Execute the Kallisto nextflow workflow
#stranded can be one of None, rf-stranded, fr-stranded
nextflow run -c ~/nextflow.config kallisto.nf \
    --sample_sheet sample_sheets/BEAT_AML_sample_sheet.txt  \
    --index $BASE_BUCKET/Reference_Data/Kallisto_Index/GRCh38.v29/gencode.v29_RepBase.v24.01.idx \
    --picard_out_dir $NEW_BUCKET/BEAT_AML/RNAseq_Illumina_Data/Fastq/ \
    --kallisto_out_dir $BASE_BUCKET/BEAT_AML/RNAseq_Illumina_Data/Kallisto/  \
    --stranded "None" \
    --skip_picard FALSE \
    -work-dir $BASE_BUCKET/work \
    -with-report BEAT_AML_report.html \
    -cache TRUE \
    -resume
