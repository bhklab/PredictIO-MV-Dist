# Scripts Directory

## Purpose

This directory contains **modular, reusable scripts** used in the **distributed multivariable modeling pipeline** to predict immunotherapy outcomes across diverse cancer datasets using a federated, privacy-preserving approach. Scripts are implemented in R and Python and support every stage of the modeling workflow: from signature scoring to model training, aggregation, and validation.

---

## Key Scripts (`workflow/scripts/`)

- `Compute_GeneSigScore.r`  
  Defines functions to compute gene signature scores from normalized expression data using methods like GSVA, ssGSEA, or weighted mean. These scores serve as input features for modeling.

- `Create_train_set.r`  
  Generates training datasets per cohort by:
  - Loading processed `SummarizedExperiment` or `MultiAssayExperiment` objects
  - Calculating gene signature scores
  - Selecting shared features across datasets
  - Exporting harmonized training matrices as `.csv` files

- `Train_Distributed_XGBoost.r`  
  Trains local XGBoost models for each dataset using Apache Spark via SparkR:
  - Initializes Spark sessions and handles distributed resource allocation
  - Performs grid search for hyperparameter tuning
  - Saves best models and feature importance locally for each cohort

- `Aggregate_model.py`  
  Python script to merge individual XGBoost models (saved as JSON) into a global ensemble:
  - Applies tree-based bagging to aggregate decision trees from local models
  - Maintains original decision tree structures
  - Saves final global model in both `.model` and `.json` formats

- `Validate_global_model.r`  
  Tests the global model on independent validation datasets (including private cohorts):
  - Prepares and aligns validation expression matrices
  - Computes predictions using the global model
  - Evaluates classification performance (e.g., AUC, accuracy)

---

## Input Requirements

- Processed expression data (TPM or log2-transformed)
- Patient-level annotations (e.g., response)
- Curated gene signature sets
- Configuration files specifying cancer type, treatment, and dataset name. Please follow pre-processing steps at [Distributed univariable predictive modelling for Immuno-Oncology response](https://github.com/bhklab/PredictIO-UV-Dist)

---

## Notes

- Each script is designed for **modular execution** in a distributed environment.
- All models are trained **locally**, and only **summary-level model files** are shared.
- Aggregation and validation scripts are **privacy-aware**, enabling federated learning.


