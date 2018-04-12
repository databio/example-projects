# Complete RNA-Seq Project

This RNA-Seq folder will show you how to use geofetch, rnapipe, and DESeq-Packager to create a data table for differential expression analysis. It is assumed that the user is on the Databio Rivanna server or all environment variables are correctly configured, and the rnapipe and geofetch repositories are already cloned.

## Geofetch

To download publicly available Sequence Read data from the Gene Expression Omnibus (GEO), you can use the tool geofetch.
Each data set has a GSE accession. For our example projects, we will be using GSE107655 and GSE108003.
Follow [this link]("https://github.com/pepkit/geofetch") to learn how to use the geofetch tool and download the data into BAM format.

After it is downloaded, we will need to make some adjustments to the annotation sheet and create a project_config file.
First, move the sample annotation sheet from the SRAMETA folder into your home project folder.
It will also help to make a clone of this on your local machine so it will be easier to modify columns in the csv file.

The entries in the protocol column have to be changed to the correct RNA sequencing protocol.
We will be using rnaKallisto for this example.
The entries in the data_source column should also be changed to BAM for clarity.
Your sample annotation sheet should look like the final one provided in this repository.

Next, we will create the project_config file.


## RNA-Seq Pipeline

The lab's RNA-Seq pipeline is available in [this]("https://github.com/databio/rnapipe") Git repository.
