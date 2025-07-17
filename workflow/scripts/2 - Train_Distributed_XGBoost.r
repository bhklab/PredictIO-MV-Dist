# Set the path to the folder with spark installation
Sys.setenv(SPARK_HOME = "/Users/nicole/spark/spark-3.2.1-bin-hadoop3.2/")
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)

# Create a Spark session
sparkR.session(
  master = "local[*]",
  sparkConfig = list(
    spark.driver.memory = "4g",
    spark.r.command = "/usr/local/bin/Rscript"
  )
)


# Load data files
train_data_dir <- "Training_set/"
model_out_dir <- "Local_model/"

data_files <- list.files(path = train_data_dir, pattern = "*.csv", full.names = TRUE)


# Define hyperparameter grid
hyperparam_grid <- expand.grid(
  nrounds = seq(from = 10, to = 300, by = 50),  # Number of boosting iterations
  eta = seq(0.01, 0.3, length.out = 5),       # Learning rate (10 equally spaced values)
  max_depth = c(3, 6, 9),                      # Maximum tree depth
  gamma = c(0, 0.1, 0.5, 1),                # Minimum loss reduction for splits
  colsample_bytree = c(0.6, 0.8, 1),           # Fraction of columns sampled
  subsample = c(0.6, 0.8, 1)                   # Subsampling ratio
)

# function to train xgboost with grid search, save the best model, hyperparameters and training metrics in RDA file

train_xgboost_model <- function(file_path, seed = 135) {
  sparkR.session(
    master = "local[*]",
    sparkConfig = list(spark.driver.memory = "4g")
  )

  suppressPackageStartupMessages({
    library(SparkR)
    library(xgboost)
    library(pROC)
    })

  start_time <- Sys.time()  #

  set.seed(seed)
  
  data_name <- tools::file_path_sans_ext(basename(file_path))

  # Load data as a Spark DataFrame
  rdf <- read.df(file_path, source = "csv", header = TRUE, inferSchema = "true")
  local_df <- collect(rdf) 

  # Response encoding: 0 = Responder (R), 1 = Non-Responder (NR)
  train_response <- ifelse(local_df$response == "R", 0, 1)
  train_features <- as.matrix(local_df[, -ncol(local_df)])
  train_features <- apply(train_features, 2, as.numeric)
  dtrain <- xgb.DMatrix(data = train_features, label = train_response)

  # Train model with grid search
  best_model <- NULL
  best_auc <- -Inf
  best_params <- NULL

  for (i in 1:nrow(hyperparam_grid)) {
    params <- hyperparam_grid[i, ]

    # Train XGBoost model
    bst_model <- xgboost(
      data = dtrain,
      max_depth = params$max_depth,
      eta = params$eta,
      nrounds = params$nrounds,
      subsample = params$subsample,
      colsample_bytree = params$colsample_bytree,
      objective = "binary:logistic",
      eval_metric = "auc",
      verbose = 0
    )

    train_probs <- predict(bst_model, dtrain)
    roc_curve <- roc(train_response, train_probs, quiet = TRUE)
    auc_value <- as.numeric(auc(roc_curve))

    if (auc_value > best_auc) {
      best_auc <- auc_value
      best_model <- bst_model
      best_params <- params
    }
  }

  best_nrounds <- best_params$nrounds
  final_model <- xgboost(
    data = dtrain,
    max_depth = best_params$max_depth,
    eta = best_params$eta,
    nrounds = best_nrounds,
    subsample = best_params$subsample,
    colsample_bytree = best_params$colsample_bytree,
    objective = "binary:logistic",
    eval_metric = "auc",
    verbose = 0
  )

  # Feature importance
  importance_matrix <- xgb.importance(colnames(train_features), model = final_model)

  # Find the optimal threshold for the best model
  train_probs <- predict(final_model, dtrain)
  roc_curve <- roc(train_response, train_probs, quiet = TRUE)
  best_threshold <- mean(coords(roc_curve, "best", best.method = "youden")[, "threshold"])

  # Save the best model
  best_model_path <- file.path(model_out_dir, paste0("XGB_", data_name, ".rds"))
  saveRDS(final_model, best_model_path)

  # Save feature importance
  feature_importance_path <- file.path(model_out_dir, paste0("Importance_", data_name, ".csv"))
  write.csv(importance_matrix, feature_importance_path, row.names = FALSE)


  end_time <- Sys.time() 

  return(list(
    dataset = data_name,
    best_model_path = best_model_path,
    best_params = best_params,
    best_auc = round(best_auc, 4),
    best_threshold = round(best_threshold, 4),
    training_start_time = start_time
  ))
}


#results <- spark.lapply(data_files, train_xgboost_model)

results <- spark.lapply(seq_along(data_files), function(i) {
  train_xgboost_model(data_files[[i]], seed = 135 + i)
})

print(sapply(results, function(x) x$training_start_time))


sparkR.session.stop()


# Convert the saved XGBoost models to JSON format
local_model_files <- list.files(path = model_out_dir, pattern = "XGB_train_set.*\\.rds", full.names = TRUE)

for (file in local_model_files) {
    model <- readRDS(file)
    model <- xgb.Booster.complete(model)
    model_json <- xgb.save.raw(model, raw_format = "json")
    
    json_file <- file.path("Local_model/Local_model_json/", paste0(tools::file_path_sans_ext(basename(file)), ".json"))
    write(rawToChar(model_json), json_file)
    
    message("Converted ", file, " to ", json_file)
}

