#!/bin/bash

#Jenny Smith
#Utility script for creating a sample sheet from an AWS S3 bucket.
#INCLUDE is optional, but should be used in all instances for fastqs to filter for only R1 (read1) Fastqs.
#since the R2 column is created by using AWK on the filename of R1.

#exit script if any commands return an error
set -eoux pipefail

#Load Modules
ml awscli/1.16.122-foss-2016b-Python-3.6.6

#define variables
BUCKET=$1 #no trailing slash /
PREFIX=${2:-""} #prefix(s) for S3 bucket. can be a single, "SR" or compound "SR/Fastqs". No trailing slash
INCLUDE=${3:-"*"} #can be an  regex for a pattern

#Parse file names to create sample sheets
files=$(aws s3 ls --recursive $BUCKET/$PREFIX | tr -s ' ' | cut -f 4 -d " " | grep -E "$INCLUDE" )
echo "$files" | awk '{OFS="\t";col1=$1; split(col1,a,"_"); ID=a[2]; col2=$1; gsub("R1", "R2", col2); print ID,$1,col2 }' | awk 'BEGIN{OFS="\t";print "Sample","R1","R2"}{print $1,$2,$3}' | sed -E  "s|	($PREFIX)|	$BUCKET/\\1|g" > $(basename $PREFIX)_sample_sheet.txt
