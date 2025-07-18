
# Usage Guide – Distributed Multivariable Pipeline

This guide outlines how to run the multivariable biomarker discovery pipeline across distributed datasets using Spark and XGBoost.

---

## Overview

This pipeline supports distributed model training using Spark and script-based aggregation and validation. The primary components include:

- Gene signature score computation
- Train set generation
- Distributed XGBoost training
- Model aggregation
- Final validation

---

## Required Scripts

All scripts are located in `workflow/scripts/`:

- **`Compute_GeneSigScore.r`**  
  Computes gene signature scores (e.g., GSVA, ssGSEA, weighted mean) for each dataset.

- **`Create_train_set.r`**  
  Prepares training matrices by merging signature scores and patient responses for each dataset.  
  ➜ Output: `.csv` files saved in `data/procdata/`

- **`Train_Distributed_XGBoost.r`**  
  Trains local XGBoost models on each dataset using Spark. Performs grid search for hyperparameter tuning.  
  ➜ Output: `.rds` models and `.csv` feature importance files saved in `data/results/local/`

- **`Aggregate_model.py`**  
  Merges all local XGBoost models into a single global model using a tree-based bagging strategy.  
  ➜ Output: `.model` and `.json` files saved in `data/results/global/`

- **`Validate_global_model.r`**  
  Evaluates the final global model on external validation datasets (private).  
  ➜ Output: Prediction metrics saved in `data/results/validation/`

---

## Input Preparation

Processed input `.rda` files must be generated **before** running the multivariable pipeline.  
These files can be created using the univariable pipeline or downloaded directly.

> For full preprocessing instructions, visit:  
> 🔗 [`PredictIO-UV-Dist`](https://github.com/bhklab/PredictIO-UV-Dist)

Required files in `data/rawdata/`:

- Dataset files: `*.rda`
- Signature metadata:
  - `signature.rda`
  - `sig.info.rda`
  - Or: [Zenodo Precompiled Signatures](https://zenodo.org/records/15832652)

---

## Steps to Run the Pipeline

### Step 1: Compute Signature Scores

```bash
Rscript workflow/scripts/Compute_GeneSigScore.r
```

### Step 2: Create Train Sets

```bash
Rscript workflow/scripts/Create_train_set.r
```

### Step 3: Train Local Models with Spark

```bash
Rscript workflow/scripts/Train_Distributed_XGBoost.r
```

> 💡 Spark must be configured locally. Make sure `SPARK_HOME`, `HADOOP_HOME`, and `winutils.exe` are correctly set.

### Step 4: Aggregate Local Models

```bash
python workflow/scripts/Aggregate_model.py
```

### Step 5: Validate Global Model

```bash
Rscript workflow/scripts/Validate_global_model.r
```

---

## Output Directory Structure

```bash
/data/results/
├── local/         # Per-dataset model outputs
├── global/        # Final aggregated model
└── validation/    # Results from external validation cohorts
```

---

## Additional Notes

- This is a **federated analysis pipeline**: no raw data sharing between centers.
- External validation is performed using **private cohorts**.
- All outputs are de-identified and summarized for model integration and evaluation.

