#!/bin/bash
set -eou
BASE_BUCKET="s3://fh-pi-meshinchi-s/SR"

#Add nextflow to PATH
ml Java/1.8.0_181
export PATH=~/scripts/opt/bin:$PATH #there is now a module with Nextlfow version 19.10.0

#Execute the Kallisto nextflow workflow
nextflow run -c ~/nextflow.config \
    --sample_sheet sample_sheets/XXXXXX  \
    --index $BASE_BUCKET/Reference_Data/Kallisto_Index/GRCh38.v29/gencode.v29_RepBase.v24.01.idx \
    --picard_out_dir $BASE_BUCKET/BEAT_AML/RNAseq_Illumina_Data/Fastq/ \
    --kallisto_out_dir $BASE_BUCKET/BEAT_AML/RNAseq_Illumina_Data/Kallisto/  \
    --stranded "None", #can be one of None, rf-stranded, fr-stranded
    --skip_picard FALSE \
    -work-dir $BASE_BUCKET/work \
    -with-report BEAT_AML_report.html \
    -cache TRUE \
    -resume
