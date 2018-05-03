# Complete RNA-Seq Project

This RNA-Seq folder will show you how to use geofetch, rnapipe, and DESeq-Packager to create a data table for differential expression analysis.
It is assumed that the user is on the Databio Rivanna server or all environment variables are correctly configured, and the rnapipe and geofetch repositories are already cloned.

## Geofetch

To download publicly available Sequence Read data from the Gene Expression Omnibus (GEO), you can use the tool geofetch.
Each data set has a GSE accession. For our example projects, we will be using GSE107655 and GSE108003.
Follow [this link](https://github.com/pepkit/geofetch) to learn how to use the geofetch tool and download the data into BAM format.
Example SRA_convert config files are also in this repository.

After it is downloaded, we will need to make some adjustments to the annotation sheet and create a project_config file.
First, copy the sample annotation sheet from the SRAMETA folder into your home project folder.
It will also help to make a clone of this on your local machine so it will be easier to modify columns in the csv file.

The entries in the protocol column have to be changed to the correct RNA sequencing protocol.
We will be using rnaKallisto for this example.
The entries in the data_source column should also be changed to BAM for clarity.
Your sample annotation sheet should look like the ones provided in this repository.

## Project Config File
The example yamls are in this repository (ignore the result_source derived column for now, it will be needed later).
The metadata section contains the output_dir, sample_annotation, and pipeline_interfaces attributes. 
The derived_columns section contains the derived column data_source, in which we changed all of the values into "BAM" earlier.
Thus, the data_sources section should contain `BAM: "${SRABAM}{SRR}.bam"`.
The implied_columns section contains the transcriptome column that is dependent on the value in the Sample_organism_ch1 column.

Now we are ready for RNA-Seq using the lab's rnaKallisto pipeline.

## RNA-Seq Pipeline

The lab's RNA-Seq pipeline is available in [this](https://github.com/databio/rnapipe) Git repository.

With the project_config file fully configured, you should only need the `looper run project_config.yaml` command.
After it is finished running, the kallisto results should be in `$PROCESSED/rnaseq_example/results_pipeline/{sample_name}/kallisto`.

## DESeq-Packager

DESeq-Packager is another tool that uses the PEP project format, but in R to produce a countDataSet needed for DESeq analysis. More info can be found [here](https://github.com/databio/DESeq-Packager).
You can copy the DESeq-Packager.R file into this folder and also create a rundeseq.R file, which contains a few lines of R code to install necessary packages, call the DESeq_Packager function, and save the result into an .RData file.

Right now the PEP does not know the exact paths to the output tsv files which we will be combining into one table for DESeq.
The (current) solution to this is to add another derived column to the yaml file, which will construct a column for the file paths.
The final project_config file now should look like the one in this repository.
In the future, a functionality may be added to Looper to output the location of the processed files.

I ran the rundeseq.R file using `R < rundeseq.R --no-save` on the command line, but there are multiple other ways to run the R script to your liking.
After the script is done running, the countDataSet will be saved to .RData, and can be copied to another file for further DESeq analysis!
