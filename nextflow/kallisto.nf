#!/usr/bin/env nextflow

// Define the input paired fastq files in a sample sheet and genome references
// sample_sheet is tab separated with column names "Sample","R1","R2"
fqs_ch = Channel.fromPath(file(params.sample_sheet))
						.splitCsv(header: true, sep: '\t')
						.map { sample -> [sample["Sample"], file(sample["R1"]), file(sample["R2"])]}
index = file("${params.index}")

// define the output directory .
params.output_folder = "./kallisto/"


//Run Picard BAM to fastq if necessary if necessary
process picard_samtofq {

	publishDir "$params.output_folder/"

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








//Run Kallisto quant on all fastq pairs and save output with the sample ID
process kallisto_quant {

	publishDir "$params.output_folder/"

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