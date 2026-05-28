# -----------------------------------------------------------
# Global Model Validation Script
# This script evaluates the aggregated global XGBoost model on 
# multiple external test datasets and benchmarks its performance 
# against local models and pan-cancer PredictIO signature models.
#
#   - Loads independent external validation datasets
#   - Applies the distributed XGBoost model to each dataset
#   - Compares performance with local models and the pan-cancer PredictIO signature
#   - Computes discrimination performance metrics (e.g., AUC)
#   - Performs calibration analyses using calibration curves,
#     Brier scores, and calibration slopes
#   - Generates publication-quality ROC and calibration plots
# -----------------------------------------------------------
##############################################################
## Load libraries
##############################################################
library(data.table)
library(xgboost)
library(magick)
library(dplyr)
library(ggplot2)
library(readr)
library(pROC)
library(CalibrationCurves)

source("workflow/scripts/Compute_GeneSigScore.r")
#############################################################
## Set up working directory 
#############################################################
dir_model_in <- 'data/results/global'
dir_data_in <- 'data/procdata/validation' 
dir_sig_in <- 'data/results/validation/score'
dir_pred_in <- 'data/results/validation/pred'
dir_out <- 'data/results/validation'

#############################################################
## Load the global model and validation data
#############################################################
global_model <- xgb.load(file.path(dir_model_in, 'global_xgb_model.model'))

# load data and computed signature score 
data_files <- list.files(dir_data_in, pattern = "^testData.*\\.rda$", full.names = TRUE) 
score_files <- list.files(dir_sig_in, pattern = "^testData.*\\.rda$", full.names = TRUE) 


figure_titles <- c(
    "testDataINSPIRE" = "INSPIRE: Pan-Cancer (N = 60)",
    "testDataIMmotion150" = "IMmotion150: Kidney (N = 54)",
    "testDataPOPLAR" = "POPLAR: Lung (N = 70)",
    "testDataHartwig" = "Hartwig: Pan-Cancer (N = 145)",
    "testDataHartwig_Bladder" = "Hartwig: Bladder (N = 38)",
    "testDataHartwig_Melanoma" = "Hartwig: Melanoma (N = 66)",
    "testDataRittmeyer_Lung" = "Rittmeyer: Lung (N = 274)"
  )


run_validation <- function(data_file, score_file, results_dir) {
  
  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE)
  }  
  study.icb <- tools::file_path_sans_ext(basename(data_file))
  
  load(data_file)
  load(score_file)

  testClin <- data.frame(colData(dat$testData))
  testClin <- testClin[!is.na(testClin$response), ]
  expr <- assay(dat$testData)
  expr <- expr[, testClin$patientid]
  sig <- dat$PredictIOSig

  # Global model prediction
  predMV <- predict(global_model, newdata = testExpr)
  rocMV <- roc(testClin$response, predMV)
  ciMV <- ci.auc(rocMV, method = "bootstrap", boot.n = 1000)

  # PredictIO signature prediction
  geneSig <- geneSigPredictIO(dat.icb = expr,
                               sig = sig,
                               sig.name = "PredictIO",
                               missing.perc = 0.5,
                               const.int = 0.001,
                               n.cutoff = 15,
                               sig.perc = 0.8,
                               study = study.icb)

  group <- ifelse(testClin$response %in% "R", 0, ifelse(testClin$response %in% "NR", 1, NA))
  fit <- glm(group ~ geneSig, family = binomial(link = "logit"))
  predPredictIO <- predict(fit, type = "response")
  rocPredictIO <- roc(group, predPredictIO)
  ciPredictIO <- ci.auc(rocPredictIO, method = "bootstrap", boot.n = 1000)

  # Load all local models
  model_files <- list.files(path = "data/results/local/", pattern = "^XGB.*\\.rds$", full.names = TRUE)

  roc_results <- list()
  for (model_file in model_files){
    local_model <- readRDS(model_file)

    model_features <- local_model$feature_names
    test_features <- colnames(testExpr)
    
    testExpr_fixed <- as.data.frame(testExpr)

   # Add any missing columns the model expects
   missing <- setdiff(model_features, colnames(testExpr_fixed))
   for (m in missing) {
        testExpr_fixed[[m]] <- 0}
   testExpr_fixed <- testExpr_fixed[, model_features, drop = FALSE]
   testExpr_fixed <- as.matrix(testExpr_fixed)

    predMV_local <- predict(local_model, newdata = testExpr_fixed)
    roc_local <- roc(testClin$response, predMV_local)
    roc_results[[model_file]] <- roc_local
  }

  spec_seq <- seq(0, 1, length.out = 150)
  sens_matrix <- matrix(NA, nrow = length(spec_seq), ncol = length(roc_results))
  for (i in seq_along(roc_results)) {
    interp_sens <- coords(roc_results[[i]], x = spec_seq, input = "specificity", ret = "sensitivity", transpose = FALSE)[, 1]
    sens_matrix[, i] <- interp_sens
  }

  mean_sens <- rowMeans(sens_matrix, na.rm = TRUE)
  sd_sens <- apply(sens_matrix, 1, sd, na.rm = TRUE)

  auc_local_mean <- mean(sapply(roc_results, auc), na.rm = TRUE)
  ci_local <- quantile(sapply(roc_results, auc), probs = c(0.025, 0.975), na.rm = TRUE)

  auc_xgb <- auc(rocMV)
  auc_predictio <- auc(rocPredictIO)

  label_local <- paste0("Local XGBoost Mean AUC: ", round(auc_local_mean, 2))
  label_xgb <- paste0("Distributed XGBoost AUC: ", round(auc_xgb, 2))
  label_predictio <- paste0("PredictIO AUC: ", round(auc_predictio, 2))

  # Prepare data for ggplot
  df_mean_roc <- data.frame(
    specificity = spec_seq,
    sensitivity = mean_sens,
    sens_upper = pmin(mean_sens + sd_sens, 1),
    sens_lower = pmax(mean_sens - sd_sens, 0),
    model = label_local
  )
  df_xgb <- data.frame(
    specificity = rev(rocMV$specificities),
    sensitivity = rev(rocMV$sensitivities),
    model = label_xgb
  )
  df_predictio <- data.frame(
    specificity = rev(rocPredictIO$specificities),
    sensitivity = rev(rocPredictIO$sensitivities),
    model = label_predictio
  )
  
  df_all_roc <- bind_rows(df_mean_roc, df_xgb, df_predictio)

  ########## Plot ##########
  color_map <- setNames(c("#B8860B", "#733a4d", "#204035FF"),
                        c(label_local, label_xgb, label_predictio))
  
  output_file <- file.path(results_dir, paste0(study.icb, "_roc_curve_withLocal.jpeg"))

  roc_plot <- ggplot() +
    geom_ribbon(data = df_mean_roc,
                aes(x = 1 - specificity, ymin = sens_lower, ymax = sens_upper),
                fill = "grey80", alpha = 0.5) +
    geom_line(data = df_all_roc,
              aes(x = 1 - specificity, y = sensitivity, color = model),
              linewidth = 1.3) +
    scale_color_manual(values = color_map) +
    geom_segment(aes(x = 0, xend = 1, y = 0, yend = 1),
                 color = "#8E949FFF", linetype = "dashed", linewidth = 1.3) +
    xlab("1 - Specificity") +
    ylab("Sensitivity") +
    ggtitle(figure_titles[study.icb]) +
    theme_minimal(base_size = 12) +
    theme(
      axis.text.x = element_text(size = 10, face = "bold"), 
      axis.title = element_text(size = 12, face = "bold"),
      axis.text.y = element_text(size = 10, face = "bold"),
      plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
      panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
      panel.background = element_blank(), plot.background = element_blank(), 
      axis.line = element_line(colour = "black"),
      legend.position = "none"
    ) +
    annotate("text", x = 0.7, y = 0.20, size = 3.5,
             label = paste0("Local XGBoost Mean AUC: ", round(auc_local_mean, 2), " [", round(ci_local[1], 2), "-", round(ci_local[2], 2), "]"),
             color = "#B8860B") +
    annotate("text", x = 0.7, y = 0.15, size = 3.5,
             label = paste0(label_xgb, " [", round(ciMV[1], 2), "-", round(ciMV[2], 2), "]"),
             color = "#733a4d") +
    annotate("text", x = 0.7, y = 0.10, size = 3.5,
             label = paste0(label_predictio, " [", round(ciPredictIO[1], 2), "-", round(ciPredictIO[2], 2), "]"),
             color = "#204035FF")

  ggsave(filename = output_file, plot = roc_plot, width = 6, height = 6, dpi = 600)

  ### Also return key AUCs as a list
  return(list(
    "Study" = study.icb,
    "LocalModelAUCs" = sapply(roc_results, auc),
    "DistributedXGBoostAUC" = auc_xgb,
    "PredictIOAUC" = auc_predictio
  ))
}

##########################################################################
# Run validation for one dataset
##########################################################################
run_validation(data_file = 'data/procdata/validation/testDataHartwig_Bladder.rda',
                   score_file = 'data/results/validation/score/testDataHartwig_Bladder.rda',
                   results_dir = dir_out)

# Run validation for all datasets
all_aucs <- list()
for (i in seq_along(data_files)) {
  result <- run_validation(data_file = data_files[i], score_file = score_files[i], results_dir = dir_out)
  all_aucs[[result$Study]] <- result
}
auc_df <- bind_rows(lapply(all_aucs, function(res) {
  tibble(
    Study = res$Study,
    Model = c(rep("Local Model", length(res$LocalModelAUCs)), 
              "Distributed XGBoost", 
              "PredictIO"),
    AUC = c(res$LocalModelAUCs, 
            res$DistributedXGBoostAUC, 
            res$PredictIOAUC)
  )
}))

##########################################################################
# Run callibration analyses 
##########################################################################
files <- list.files(dir_pred_in)

res <- lapply(1:length(files), function(k){
read.csv(file = file.path(dir_pred_in, files[k]))
})
res <- do.call(rbind, res)

res$prob_distributed <- pmin(pmax(res$prob_distributed, 1e-8),1 - 1e-8)
cohorts <- unique(res$study_name)

for(cohort in cohorts){

  tmp <- res %>%
    filter(study_name == cohort)

  calibration_df <- tmp %>%
    mutate(bin = ntile(prob_distributed, 5)) %>%
    group_by(bin) %>%
    summarise(
      mean_pred = mean(prob_distributed),
      obs_rate = mean(true_label),
      .groups = "drop"
    )

  calPerf <- val.prob.ci.2(
    p = tmp$prob_distributed,
    y = tmp$true_label
  )

  auc <- round(calPerf$stats["C (ROC)"], 2)
  brier <- round(calPerf$stats["Brier"], 2)
  slope <- round(calPerf$stats["Slope"], 2)

  n_patients <- nrow(tmp)

  p <- ggplot(
    calibration_df,
    aes(
      x = mean_pred,
      y = obs_rate
    )
  ) + geom_smooth(
      method = "loess",
      se = TRUE,
      color = "#B22222",
      fill = "#F4A6A6",
      linewidth = 1.2
    ) + geom_abline(
      intercept = 0,
      slope = 1,
      linetype = "dashed",
      color = "grey60",
      linewidth = 0.8
    ) + coord_equal() +
    xlim(0, 1) +
    ylim(0, 1) +
    annotate(
      "text",
      x = 0.65,
      y = 0.18,
      hjust = 0,
      size = 2,
      label = paste0(
        "AUC = ", auc,
        "\nBrier = ", brier,
        "\nSlope = ", slope
      )
    ) + labs(
      title = paste0(
        gsub("_", ": ", cohort),
        " (N = ", n_patients, ")"
      ),
      x = "Predicted Probability",
      y = "Observed Rate"
    ) + theme(
      axis.text.x = element_text(size = 6),
      axis.text.y = element_text(size = 6),
      axis.title = element_text(size = 7),
      plot.title = element_text(
        hjust = 0.5,
        size = 7,
        face = "bold"
      ),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_blank(),
      plot.background = element_blank(),
      axis.line = element_line(colour = "black"),
      legend.position = "none"
    )

 # clean file names
file_name_pdf <- paste0(
  gsub(" ", "_", cohort),
  "_calibration_plot.pdf"
)

file_name_jpeg <- paste0(
  gsub(" ", "_", cohort),
  "_calibration_plot.jpeg"
)

# save PDF
ggsave(
  filename = file.path(dir_out, file_name_pdf),
  plot = p,
  width = 2.5,
  height = 2.5
)

# save JPEG
ggsave(
  filename = file.path(dir_out, file_name_jpeg),
  plot = p,
  width = 2.5,
  height = 2.5,
  dpi = 300
)

print(p)

}
