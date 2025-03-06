#!/bin/bash
set -eou

#Add nextflow to PATH
ml nextflow/20.06.0-edge
DATE="$(date "+%Y-%m-%d)"

#Execute the Kallisto nextflow workflow
#stranded can be one of None, rf-stranded (our BCCA data is rf-stranded), fr-stranded
nextflow run -c ./nextflow.config \
    kallisto.nf \
    -with-report  nextflow_report_${DATE}.html \
    -cache TRUE \
    -resume
