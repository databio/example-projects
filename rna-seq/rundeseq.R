source("DESeq-Packager.R")
if(!requireNamespace("devtools"))
    install.packages("devtools", dependencies=TRUE)
if(!requireNamespace("pepr"))
  devtools::install_github("pepkit/pepr", dependencies=TRUE)
yaml <- "project_config.yaml"
p <- pepr::Project(file = yaml)
countDataSet <- DESeq_Packager(p, "result_source", "target_id", "est_counts")
save("countDataSet", file=".RData")
