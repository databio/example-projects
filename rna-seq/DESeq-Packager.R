#' Packages RNA sequencing results from multiple data files in PEP format into one data table for DESeq analysis
#' (read more about the PEP format at https://pepkit.github.io/)
#'
#' @param p the pepr project
#' @param data_source name of the column in the sample annotation sheet with the path to the files
#' @param gene_names name of the column in each sample data file with gene names
#' @param gene_counts name of the column in each sample data file with the count data for DESeq
#' @return countDataSet, the data frame needed for DESeq
#' @export
DESeq_Packager <- function(p, data_source, gene_names, gene_counts){
  #checking for data table dependency
  if(!requireNamespace("devtools"))
    install.packages("devtools", dependencies=TRUE)
  if(!requireNamespace("pepr"))
    devtools::install_github("pepkit/pepr", dependencies=TRUE)
  if (!requireNamespace("data.table"))
    install.packages("data.table", dependencies=TRUE)
  library(data.table)
  
  sample_frame <- pepr::samples(p)
  sample_names <- sample_frame[["sample_name"]]
  files <- sample_frame[ , data_source]
  
  
  print("reading in tables...")
  
  #create a table for a sample, then put it into a list
  dt_list <- vector(mode="list",length=length(files))
  for(i in 1:length(files)){
    sampleTable <- fread(files[i])
    sampleTable <- sampleTable[, c(gene_names, gene_counts), with=FALSE]
    sampleTable[[gene_counts]] <- lapply(sampleTable[[gene_counts]], as.integer)
    colnames(sampleTable)[1] <- gene_names
    colnames(sampleTable)[2] <- sample_names[i]
    dt_list[[i]] <- sampleTable
  }
  
  print("merging samples into one table...")
  
  #join each sample table from the list
  countDataSet <- merge(dt_list[[1]], dt_list[[2]])
  for(i in 3:length(dt_list)){
    countDataSet <- merge(countDataSet, dt_list[[i]])
  }
  
  #set the row names as the gene names, then remove the gene name column
  row.names(countDataSet) <- countDataSet[[1]]
  countDataSet[,1] <- NULL
  
  print("packaged!")
  return(countDataSet)
}