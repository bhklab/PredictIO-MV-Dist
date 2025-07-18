## Results Directory

This directory contains the output files from all stages of the **distributed multivariable analysis pipeline**, including:

- Signature scoring outputs (e.g., GSVA, ssGSEA)
- Multivariable model training results (e.g., XGBoost models)
- Feature importance rankings
- Evaluation metrics (e.g., AUC, ROC)
- Model validation results across external datasets

The result files are organized based on their role in the distributed pipeline and reflect different stages of model development and validation.

---

## Directory Structure

```console
/results/
├── local/            # Results from individual centers (trained XGBoost models)
│   └── local_json/
│
├── global/           # Aggregated global model from local models
│   ├── global_xgb_model.json
│   └── global_xgb_model.model
│
└── validation/       # Independent validation results on private cohorts and figures
    └── score/
  
```

---

## Notes

- `local/` folders contain individually trained models per dataset using SparkR + XGBoost with grid search.
- `global/` contains the aggregated model using tree-based bagging across local models.
- `validation/` includes model performance on independent, private datasets not used in training. 
- No patient-level data is included; all outputs are de-identified and suitable for sharing and publication.
