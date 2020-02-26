#!/bin/bash

#Jenny Smith
#Utility script for creating a sample sheet from an AWS S3 bucket.
#INCLUDE is optional, but should be used in all instances for fastqs to filter for only R1 (read1) Fastqs.
#since the R2 column is created by using AWK on the filename of R1.

#exit script if any commands return an error
set -eou pipefail

#Load Modules
#ml awscli/1.16.122-foss-2016b-Python-3.6.6
ml awscli/1.16.293-foss-2016b-Python-3.7.4


#define variables
BUCKET=$1 #no trailing slash /
PREFIX=${2:-""} #prefix(s) for S3 bucket. can be a single, "SR" or compound "SR/Fastqs". No trailing slash
INCLUDE=${3:-"*"} #can be an  regex for a pattern

#Parse file names to create sample sheets
files=$(aws s3 ls --recursive $BUCKET/$PREFIX | tr -s ' ' | cut -f 4 -d " " | grep -E "$INCLUDE" )
outfile=$(basename $PREFIX)_sample_sheet.txt

if echo "$files"  | grep -Eq "_R[0-9].+gz"
then
  read2="R2"
else
  read2="r2"
fi

#Use awk and Sed to create sample sheet with full file URI
if echo "$files" | grep -Eq ".bam"
then
  echo "$files" | awk 'BEGIN{OFS="\t";print "Sample","BAM"}{OFS="\t"; split($1,array,"/");ID=array[3]; gsub(/.bam/,"", ID); print ID,$1}' | sed -E  "s|\t($PREFIX)|\t$BUCKET/\\1|g" > $outfile
else
  echo "$files" | awk -v r2="$read2" 'BEGIN{OFS="\t";print "Sample","R1","R2"}{OFS="\t"; split($1,array,"/");ID=array[3]; gsub(/_[Rr][12].+$/,"", ID); col2=$1; gsub("[Rr]1", r2, col2); print ID,$1,col2 }' | sed -E  "s|\t($PREFIX)|\t$BUCKET/\\1|g" > $outfile
fi
