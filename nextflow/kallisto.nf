#!/usr/bin/env nextflow

// Define the input paired fastq files in a sample sheet and genome references
// sample_sheet is tab separated with column names "Sample", and "BAM"
bams_ch = Channel.fromPath(file(params.sample_sheet))
						.splitCsv(header: true, sep: '\t')
						.map { sample -> [sample["Sample"], file(sample["BAM"])]}
index = file("${params.index}")

// define the default output directory if not specified in the run script.
params.output_folder = "./kallisto/"


//Run Picard BAM to fastq if necessary if necessary
process picard_samtofq {

	publishDir "$params.picard_out_dir/"

	// use picard repo on docker hub.
	container "jennylsmith/picardtools:v2.13.2"
	cpus 4
	memory "32 GB"

	// if process fails, retry running it
	errorStrategy "terminate"

	// declare the input types and its variable names
	input:
	tuple val(Sample), file(BAM) from bams_ch

	//define output files to save to the output_folder by publishDir command
	output:
	tuple val(Sample), file("*r1.fq.gz"), file("*r2.fq.gz") into fqs_ch

	"""
	set -eou pipefail
	ls -alh

	java -Xmx12g -Xms2g \
		-jar /picard/picard.jar SamToFastq \
	 	QUIET=true \
	 	INCLUDE_NON_PF_READS=true \
	 	VALIDATION_STRINGENCY=SILENT \
	 	MAX_RECORDS_IN_RAM=250000 \
	 	I="$BAM" F="${BAM.simpleName}_r1.fq.gz" F2="${BAM.simpleName}_r2.fq.gz"

	export Sample="$Sample"

	"""
}


//Run Kallisto quant on all fastq pairs and save output with the sample ID
process kallisto_quant {

	publishDir "$params.kallisto_out_dir/"

	// use Kallisto repo on docker hub.
	container "jennylsmith/kallistov45.0:nextflow"
	cpus 4
	memory "30 GB"

	// if process fails, retry running it
	errorStrategy "retry"

	// declare the input types and its variable names
	input:
	file index
	tuple val(Sample), file(R1), file(R2) from fqs_ch

	//define output files to save to the output_folder by publishDir command
	output:
	path "${Sample}"

	"""
	set -eou pipefail
	ls -alh
	ls $index

	kallisto quant -i $index -o $Sample -b 30 -t 4 \
	   --fusion --bias --rf-stranded  $R1 $R2
	"""
}
