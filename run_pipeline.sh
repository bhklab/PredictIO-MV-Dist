#!/bin/bash
# run_pipeline.sh — Execute full PredictIO-MV-Dist pipeline

set -e  # Exit on error

# Step 1: Create training datasets
Rscript workflow/scripts/Create_train_set.r

# Step 2: Train local XGBoost models
Rscript workflow/scripts/Train_Distributed_XGBoost.r

# Step 3: Aggregate local models into a global model
python workflow/scripts/Aggregate_model.py

# Step 4: Validate the global model
Rscript workflow/scripts/Validate_global_model.r

echo "Pipeline complete."
