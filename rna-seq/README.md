# Complete RNA-Seq Project

This example will show you how to use `Looper` to complete an RNA-Seq project, from raw data download to differential expression analysis, using tools that are designed for the PEP format: `geofetch`, `rnapipe`, and `DESeq-Packager`.

What is PEP, and what are these tools? [PEP](https://pepkit.github.io) (Portable Encapsulated Project) format is a way to organize metadata, which consists of samples' file paths and features such as organism, source, and extraction protocol. PEP format requires only a yaml (for project/pipeline configuration) and csv (for sample annotation), and they make a project immediately compatible with PEP tools. 

An overview of this tutorial:
1. Download RNA-Seq data from the Gene Expression Omnibus using __Geofetch__, which will automatically produce a PEP yaml and csv from the data
2. Modifying the yaml file with `rnaKallisto` configurations
3. Run an RNA-Seq processing pipeline (`rnaKallisto` in __rnapipe__) using `looper`
4. Format the results of `rnaKallisto` for differential expression analysis using __DESeq-Packager__

## 0. Environment Setup and Required Software

First, the computing environment has to be set up with the correct environment variables for easier use of the tools (if not, then the filepaths have to be manually specified in command line arguments). Environment variables also make it easier to change the yaml, because changing an environment variable will reflect everywhere it is used.

If you are in UVA Rivanna and you have the rivanna4 module loaded, then that's all! Otherwise, in `.bash_profile` or `.profile`, add a few environment variables. It might look something like this:
```
export DATA=/path/to/sradata
export SRARAW=/path/to/sradata/sra/
export SRAMETA=/path/to/sradata/sra_meta/
export SRABAM=/path/to/sradata/sra_bam/
export PROCESSED=/path/to/processed/
```

Download software:
[Geofetch](https://github.com/pepkit/geofetch)
```
git clone https://github.com/pepkit/geofetch.git
echo "/repository/user/main/public/root = \"$DATA\"" > ${HOME}/.ncbi/user-settings.mkfg
```
(the second line is to configure the data download location)

[Looper](https://looper.readthedocs.io/en/latest/hello-world.html)
```
pip install --user https://github.com/pepkit/looper/zipball/master
export PATH=~/.local/bin:$PATH
```

[rnapipe](https://github.com/databio/rnapipe)
```
git clone https://github.com/databio/rnapipe.git
```

[DESeq-Packager](https://github.com/databio/deseq-packager)
```
git clone https://github.com/databio/DESeq-Packager.git
```

## 1. Downloading raw data from GEO

We'll be using [GSE107655](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE107655) from the Gene Expression Omnibus (GEO). To download the data, use the tool `geofetch`:
```
cd geofetch/geofetch
python geofetch.py -i GSE107655 -pipe path/to/rnapipe/pipeline_interface.yaml
```
`Geofetch` downloads data into $SRARAW and also create a PEP yaml and csv in $SRAMETA.

The first step involving `looper` will be to convert the SRA files into BAM files. `Geofetch` has already set up the yaml file properly.
```
cd $SRAMETA
looper run GSE107655_config.yaml --sp sra_convert --lump 10
```

## 3. Running the RNA-Seq pipeline using looper

[Pipeline source code](https://github.com/databio/rnapipe)

If you already have all of the tools [required by rnaKallisto](https://github.com/databio/rnapipe/blob/master/src/rnaKallisto.yaml), then only one command is needed!
```
looper run GSE107655_config.yaml --lump 5
```

After it is finished running, the RNA-Seq results will be in `$PROCESSED/GSE107655`.

## 4. Output a countTable for differential expression using DESeq-Packager

`DESeq-Packager` uses the PEP project format in R to produce a countDataSet needed for DESeq analysis. More info can be found [in the DESeq-Packager repository](https://github.com/databio/DESeq-Packager).

After running `rnaKallisto`, the PEP project will not know the paths to the $PROCESSED files that are used for DESeq. The solution to this is to add another derived column, `result_source`, which will fill in the `src` values with the correct path to the $PROCESSED files.  In the future, a functionality may be added to `looper` to automatically output the location of the processed files.
```
derived_columns: [data_source, result_source]

data_sources:
  SRA: "${SRABAM}{SRR}.bam"
  src: "${PROCESSED}/GSE107655/results_pipeline/{sample_name}/kallisto/abundance.tsv"
```
A column with header `result_source` and values of `src` will also need to be added into the annotation csv.

The final `project_config.yaml` file now should look like the one in this repository.

Now, in R, DESeq-Packager can use the PEP format to output a countDataSet!
```
cd /path/to/DESeq-Packager
```

```R
source("DESeq_Packager.R")
p = pepr::Project(file="project_config.yaml")
countDataSet <- DESeq_Packager(p, "result_source", "target_id", "est_counts")
# do DESeq analysis with the countDataSet
```
