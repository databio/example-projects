# Complete RNA-Seq Project

This example will show you how to use Looper to create an RNA-Seq project from start to finish using tools that are designed for the PEP project format: geofetch, rnapipe, and DESeq-Packager.

### Required Software

[Geofetch](https://github.com/pepkit/geofetch)

[Looper](https://looper.readthedocs.io/en/latest/hello-world.html)

## Environment Setup

First, the computing environment has to be set up with the correct environment variables to make the Looper configuration easier. If you are in UVA Rivanna and you have the rivanna4 module loaded, then great! Otherwise, in .bash_profile or .profile, add a few environment variables. It might look something like this:

```
export SRARAW=/path/to/sradata/sraraw/
export SRAMETA=/path/to/sradata/srameta/
export SRABAM=/path/to/sradata/srabam/
export PROCESSED=/path/to/processed/
```

## Geofetch

We'll be using [GSE107655](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE107655) from the Gene Expression Omnibus (GEO). To download the data:
```
python geofetch.py -i GSE107655
```
This will download the SRA files from GEO to the $SRARAW directory (make sure your prefetch variable is configured correctly, as described in the geofetch README!), and also create a PEP annotation sheet in $SRAMETA for the project.

The first step involving looper will be to convert the SRA files into BAM files. The project_config files produced by geofetch are immediately usable. Go into the $SRAMETA directory and execute
```
looper run GSE107655_config.yaml --sp sra_convert --lump 10
```
This will turn the .sra files into .bam files and put them in the $SRABAM directory.

After taking a break while sra_convert runs, we will start the RNA-Seq pipeline.

## Project Config File

All details about PEP project config files can be found at the [PEP documentation](https://pepkit.github.io/docs/home).

In the sample annotation sheet file, the entries in the `protocol` column have to be changed to the correct RNA sequencing protocol, which is `rnaKallisto` for this example.

Now we will specify the pipeline arguments for rnaKallisto in the project config file. First, add the location of the `rnapipe` pipeline_interface:
```
pipeline_interfaces: /path/to/rnapipe/pipeline_interface.yaml
```

And then add this section right after the `implied_columns` section.
```
  read_type:
    "single":
     # add default values for kallisto
       fragment_length: 200
       fragment_length_sdev: 25

pipeline_args:
  rnaKallisto.py:
    "-D": null
```

## RNA-Seq Pipeline

[Pipeline source code](https://github.com/databio/rnapipe)

If you already have all of the tools [required by rnaKallisto](https://github.com/databio/rnapipe/blob/master/src/rnaKallisto.yaml), then only one command is needed!
```
looper run GSE107655_config.yaml --lump 5
```

After it is finished running, the RNA-Seq results will be in `$PROCESSED/GSE107655`.

## DESeq-Packager

DESeq-Packager is another tool that uses the PEP project format in R to produce a countDataSet needed for DESeq analysis. More info can be found [here](https://github.com/databio/DESeq-Packager).

After running looper and the rna-seq pipeline, PEP will not know the paths to the $PROCESSED files which we will be needing for DESeq. The solution to this is to add another derived column to the yaml specifying the file path: 

```
derived_columns: [data_source, result_source]

data_sources:
  SRA: "${SRABAM}{SRR}.bam"
  src: "${PROCESSED}/GSE107655/results_pipeline/{sample_name}/kallisto/abundance.tsv"
```
(also add a column to the annotation csv with header `result_source` and values of `src`)

The final project_config file now should look like the one in this repository.
In the future, a functionality may be added to looper to automatically output the location of the processed files.

Now DESeq can use the PEP format to output a countDataSet!
```R
p = pepr::Project(file="project_config.yaml")
countDataSet <- DESeq_Packager(p, "result_source", "target_id", "est_counts")
```
