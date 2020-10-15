#!/usr/bin/env nextflow

// Define the input paired fastq files in a sample sheet and genome references
// for BAM channel: sample_sheet is tab separated with column names "Sample", and "BAM"
// for FASTQ channel: sample_sheet is tab separated with column names "Sample","R1","R2"
input_ch = Channel.fromPath(file(params.sample_sheet))
						.splitCsv(header: true, sep: '\t')

ref = Channel.value("$params.index").tokenize("/").get(5)
index = file("${params.index}")
stranded_type = Channel.value("$params.stranded")


//Define whether its a fastq channel or a bam channel based on the skip_picard parameter
params.skip_picard = true
(bams_ch, fqs_ch) = ( params.skip_picard
                 ? [ Channel.empty(), input_ch.map{sheet -> [sheet["Sample"], file(sheet["R1"]), file(sheet["R2"])]} ]
		 : [ input_ch.map{sheet -> [sheet["Sample"], file(sheet["BAM"])]}, Channel.empty() ])


// define the default output directory if not specified in the run script.
params.picard_out_dir = "./picard/"
params.kallisto_out_dir = "./kallisto/"


//Run Picard BAM to fastq if necessary
process picard_samtofq {

	publishDir "$params.picard_out_dir/"

	// use picard repo on docker hub.
	container "jennylsmith/picardtools:v2.13.2"
	cpus 4
	memory "32 GB"

	// if process fails, how to respond - retry or terminate (kill all the jobs)
	errorStrategy "retry"

	// declare the input types and its variable names
	input:
	tuple val(Sample), file(BAM) from bams_ch

	//define output files to save to the output_folder by publishDir command
	output:
	tuple val(Sample), file("*r1.fq.gz"), file("*r2.fq.gz") into fqs_opt_ch

	"""
	set -eou pipefail

	java -Xmx12g -Xms2g \
		-jar /picard/picard.jar SamToFastq \
	 	QUIET=true \
	 	INCLUDE_NON_PF_READS=true \
	 	VALIDATION_STRINGENCY=SILENT \
	 	MAX_RECORDS_IN_RAM=250000 \
	 	I="$BAM" F="${BAM.simpleName}_r1.fq.gz" F2="${BAM.simpleName}_r2.fq.gz"

	export Sample="$Sample"
	ls -alh
	echo $Sample

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
	val ref
	val stranded_type
	tuple val(Sample), file(R1), file(R2) from fqs_ch.mix(fqs_opt_ch)

	//define output files to save to the output_folder by publishDir command
	output:
	path "${Sample}*"

	"""
	set -eou pipefail
	echo $ref $Sample
	ls $index

	#Check for strandedness and choose flag for Kallisto psuedoalignment
	if [[ $stranded_type == "None" ]]
	then
		kallisto quant -i $index -o ${Sample}_$ref \
				-b 30 -t 4 --fusion --bias $R1 $R2

	else
		kallisto quant -i $index -o ${Sample}_$ref \
				-b 30 -t 4 --fusion --bias --"$stranded_type" $R1 $R2
	fi

	#remove the fastq files to avoid being uploaded to /work dir
	rm *.gz

	"""
}
