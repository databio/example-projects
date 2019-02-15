# Complete RNA-Seq Project

This example will show you how to use `looper` to complete an RNA-Seq project - from raw data download to differential expression analysis - using tools that are designed for the PEP format: `geofetch`, `rnapipe`,`BiocProject`, and `DESeqPackager`.

What is PEP? [PEP](https://pepkit.github.io) (Portable Encapsulated Project) format is a way to organize metadata, which consists of samples' file paths and features such as organism, source, and extraction protocol. PEP format requires only a yaml (for project/pipeline configuration) and csv (for sample annotation), and they make a project immediately compatible with PEP tools. 

An overview of this tutorial:
1. Download RNA-Seq data from the Gene Expression Omnibus using `geofetch`, which will automatically produce a PEP project_config yaml and sample_annotation csv from the data
2. Run an RNA-Seq processing pipeline (`rnaKallisto` from the `rnapipe` repository) using `looper`
3. Format the results of `rnaKallisto` for differential expression analysis using `DESeqPackager`

## 0. Environment Setup and Required Software

First, the computing environment has to be set up with the correct environment variables for easier use of the tools (if not, then the filepaths have to be manually specified in command line arguments). Environment variables also make it easier to change the yaml, because changing an environment variable will reflect everywhere it is used.

If you are in UVA Rivanna and you have the [rivanna4 module](https://github.com/databio/modulefiles/blob/master/databioR/rivanna4) loaded, then that's all! Otherwise, in `.bash_profile` or `.profile`, add a few environment variables. It might look something like this:
```
export DATA=/path/to/sradata
export SRARAW=/path/to/sradata/sra/
export SRAMETA=/path/to/sradata/sra_meta/
export SRABAM=/path/to/sradata/sra_bam/
export PROCESSED=/path/to/processed/
```

Download software:
[geofetch](https://github.com/pepkit/geofetch)
```
git clone https://github.com/pepkit/geofetch.git
echo "/repository/user/main/public/root = \"$DATA\"" > ${HOME}/.ncbi/user-settings.mkfg
```
(the second line is to configure the data download location)

[looper](https://looper.readthedocs.io/en/latest/hello-world.html)
```
pip install --user https://github.com/pepkit/looper/zipball/master
export PATH=~/.local/bin:$PATH
```

[rnapipe](https://github.com/databio/rnapipe)
```
git clone https://github.com/databio/rnapipe.git
```

[BiocProject](http://code.databio.org/BiocProject/index.html)
```R
devtools::install_github("pepkit/BiocProject")
```

[DESeqPackager](https://github.com/databio/DESeqPackager)
```
git clone https://github.com/databio/DESeqPackager.git
```

## 1. Downloading raw data from GEO

We'll be using [GSE107655](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE107655) from the Gene Expression Omnibus (GEO). To download the data, use the tool `geofetch`:
```
cd geofetch/geofetch
python geofetch.py -i GSE107655 --pipeline_interfaces path/to/rnapipe/pipeline_interface.yaml
```
`Geofetch` downloads SRA data into `$SRARAW` and also create a PEP config file (`GSE107655_config.yaml`) and sample_annotation csv (`GSE107655_annotation`) in the `$SRAMETA/GSE107655` folder.

The first step involving `looper` will be to convert the SRA files into BAM files. `geofetch` has already set up the yaml file properly.
```
cd $SRAMETA/GSE107655
looper run GSE107655_config.yaml --sp sra_convert --lump 10
```

## 2. Running the RNA-Seq pipeline using looper

[Pipeline source code](https://github.com/databio/rnapipe)

If you already have all of the tools [required by rnaKallisto](https://github.com/databio/rnapipe/blob/master/src/rnaKallisto.yaml), then only one command is needed!
```
cd $SRAMETA/GSE107655
looper run GSE107655_config.yaml --lump 5 --single-end-defaults
```

After it is finished running, the RNA-Seq results will be in `$PROCESSED/GSE107655`.

## 3. Output a countTable for differential expression using DESeqPackager

`DESeqPackager` uses the PEP project format in R to produce a countDataSet needed for DESeq analysis. More info can be found [in the DESeqPackager repository](https://github.com/databio/DESeqPackager).

After running `rnaKallisto`, the PEP project does not know the paths to the `$PROCESSED` files. The solution to this is to add another [derived attribute](https://pepkit.github.io/docs/derived_attributes/), here called `result_source`, along with another specification in `data_sources`, here called `src`. In addition, in the sample_annotation csv, a column with header `result_source` and values of `src` will need to be added. This combination of a derived attribute and data source will essentially fill in the `src` values in the sample_annotation csv with the correct path to the `$PROCESSED` files.
```
derived_attributes: [data_source, result_source]

data_sources:
  SRA: "${SRABAM}{SRR}.bam"
  src: "${PROCESSED}/GSE107655/results_pipeline/{sample_name}/kallisto/abundance.tsv"
```
Now DESeqPackager will know where to find the `abundance.tsv` files needed for DESeq. In the future, a functionality may be added to `looper` to automatically output the location of the processed files.

The final `GSE107655_config.yaml` file now should look like the one in this repository.

Now, in R, `BiocProject` uses `DESeqPackager` and `pepr` behind the scenes to output a countDataSet!
```R
source("/path/to/DESeqPackager.R")
bpArgs = BiocProject(file="GSE107655_config.yaml")
getData(bpArgs)
# do DESeq analysis with the produced countDataSet
```
