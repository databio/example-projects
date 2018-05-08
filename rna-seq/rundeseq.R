source("PATH/TO/.../DESeq-Packager.R")
if(!requireNamespace("devtools"))
    install.packages("devtools", dependencies=TRUE)
if(!requireNamespace("pepr"))
  devtools::install_github("pepkit/pepr", dependencies=TRUE)

p <- pepr::Project(file = "project_config.yaml")
countDataSet <- DESeq_Packager(p, "result_source", "target_id", "est_counts")
save("countDataSet", file=".RData")
