#!/bin/bash
set -eou
BASE_BUCKET="s3://fh-pi-meshinchi-s-eco-public"


#Add nextflow to PATH
ml nextflow/20.06.0-edge

#Execute the Kallisto nextflow workflow
#stranded can be one of None, rf-stranded (our BCCA data is rf-stranded), fr-stranded
nextflow run -c ~/nextflow.config kallisto.nf \
    --sample_sheet sample_sheets/CellLines_Sample_Sheet.txt  \
    --index $BASE_BUCKET/Reference_Data/Kallisto_Index/GRCh38.v29/gencode.v29_RepBase.v24.01.idx \
    --create_md5 TRUE \
    --picard_out_dir $BASE_BUCKET/TARGET_AML/RNAseq_Illumina_Data/Fastq \
    --kallisto_out_dir $BASE_BUCKET/TARGET_AML/RNAseq_Illumina_Data/Kallisto  \
    --stranded "rf-stranded" \
    --skip_picard FALSE \
    -with-report remission_APL_JMML_MDA_report.html \
    -cache TRUE \
    -resume
