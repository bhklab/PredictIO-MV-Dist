# -----------------------------------------------------------
# Gene Signature Scoring and Feature Selection Script
# This script calculates gene signature scores, identifies common features
# across study datasets, and generates a training set for each study.
#
#   - Loads gene expression and metadata for multiple studies
#   - Calculates signature scores per sample (e.g., GSVA, ssGSEA, weighted-mean scoring)
#   - Identifies intersecting features across datasets
#   - Builds training sets per study based on shared features
# -----------------------------------------------------------
########################################################
## Load Libraries
########################################################
library(PredictioR)
library(MultiAssayExperiment)
library(reticulate)
library(dplyr)
library(GSVA)
library(pROC)
library(stringr)
library(readr)

# Load gene signature score function
source("workflow/scripts/Compute_GeneSigScore.r")
###########################################################
## Set up working directory 
###########################################################

dir_in <- 'data/rawdata'
dir_out <- 'data/procdata'  

###########################################################
## Load data and signatures
###########################################################
file_list <- list.files(path = dir_in, pattern = "\\.rda$", full.names = TRUE)
selected_signatures <- scan(file.path(dir_in, 'selected_signatures.txt'), what = character(), sep = "\n")

Prefiltered_TrainSet <- list()
study.icb <- list()
# Loop through each file to Calculate gene signature score 
for (file in file_list[1:3]) {
    load(file)
    patient_response <- data.frame(
        patientid = colData(dat$ICB)$patientid,
        response = colData(dat$ICB)$response)
    patient_response <- na.omit(patient_response)
    valid_patients <- patient_response$patientid

    if (length(valid_patients) < 25) {
        next
    }

    dat$ICB <- dat$ICB[, colnames(assay(dat$ICB)) %in% valid_patients]
    colData(dat$ICB) <- colData(dat$ICB)[colData(dat$ICB)$patientid %in% valid_patients, ]

    # Compute gene signature score
    expr <- dat$ICB
    signature <- dat$signature
    signature_info <- dat$sig.info
    geneSig.score <- compute_gene_signature_scores(expr, signature, signature_info, study.icb)
    trainVar <- geneSig.score[rownames(geneSig.score) %in% selected_signatures, , drop = FALSE]

    # Add patient response data 
    trainClin <- patient_response
    trainClin$response <- factor(trainClin$response, levels = c("NR", "R"))

    # transpose and add response column 
    trainVar <- t(trainVar)
    trainVar_df <- as.data.frame(trainVar)
    trainVar_df$patientid <- rownames(trainVar_df)
    TrainSet <- merge(trainVar_df, trainClin[, c("patientid", "response")], by = "patientid")
    TrainSet$patientid <- NULL

    #add each gene signature score and response data to the list 
    Prefiltered_TrainSet[[file]] <- TrainSet
    study.icb[[file]] <- colnames(TrainSet)
  }

###########################################################
## Find common gene signature across selected datasets
###########################################################
common_var <- Reduce(intersect, study.icb)

# Create and save training set
for (file in names(Prefiltered_TrainSet)) {
  filtered_scores <- Prefiltered_TrainSet[[file]] %>% select(all_of(common_var))
  output_file <- file.path(dir_out, paste0("train_set_", tools::file_path_sans_ext(basename(file)), "_filtered.csv"))
  write_csv(filtered_scores, output_file)
} 

################################################################################
# Checks column names across training sets to ensure consistent gene signatures
################################################################################
train_set <- list.files(path = dir_out, pattern = "\\.csv$", full.names = TRUE)

all_colnames <- lapply(train_set, function(file) {
  data <- read.csv(file)
  num_col = ncol(data)
  column_names = colnames(data)
})
