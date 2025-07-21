# Distributed Multivariable Predictive Modelling for Immuno-Oncology Response

**Authors:** [Farnoosh Abbas Aghababazadeh](https://github.com/RibaA), [Kewei Ni](https://github.com/Nicole9801), [Nasim Bondar Sahebi](https://github.com/sogolsahebi)

**Contact:** [farnoosh.abbasaghababazadeh@uhn.ca](mailto:farnoosh.abbasaghababazadeh@uhn.ca), [kewei.ni@uhn.ca](mailto:kewei.ni@uhn.ca), [nasim.bondarsahebi@uhn.ca](mailto:nasim.bondarsahebi@uhn.ca)

**Description:** A distributed framework for multivariable predictive modeling of Immuno-Oncology (IO) response, enabling parallelized model training across multiple datasets using Apache Spark, with strict adherence to data privacy.

--------------------------------------

[![pixi-badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json&style=flat-square)](https://github.com/prefix-dev/pixi)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json&style=flat-square)](https://github.com/astral-sh/ruff)
[![Built with Material for MkDocs](https://img.shields.io/badge/mkdocs--material-gray?logo=materialformkdocs&style=flat-square)](https://github.com/squidfunk/mkdocs-material)

![GitHub last commit](https://img.shields.io/github/last-commit/bhklab/predictio-mv-dist?style=flat-square)
![GitHub issues](https://img.shields.io/github/issues/bhklab/predictio-mv-dist?style=flat-square)
![GitHub pull requests](https://img.shields.io/github/issues-pr/bhklab/predictio-mv-dist?style=flat-square)
![GitHub contributors](https://img.shields.io/github/contributors/bhklab/predictio-mv-dist?style=flat-square)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/bhklab/predictio-mv-dist?style=flat-square)

---

## Project Overview

This repository implements a **distributed Spark-based pipeline** for multivariable analysis of immune-related RNA signatures and their predictive power for IO therapy response. Key features include:

- Center-specific training of XGBoost models with no data sharing
- Tree-based model aggregation to build a global model
- Independent model validation using public and private cohorts
- Reproducible and scalable deployment using **Pixi**, **Python**, **Apache Spark** and **R/SparkR**

---

## Spark Environment Setup

Apache Spark is required for distributed model training.

1. **Install Spark:**

   Download and extract Spark 3.2.1 with Hadoop 3.2:
   ```
   https://archive.apache.org/dist/spark/spark-3.2.1/spark-3.2.1-bin-hadoop3.2.tgz
   ```

2. **Set Spark environment in your R script (`Train_Distributed_XGBoost.r`):**

   ```r
   Sys.setenv(SPARK_HOME = "/your/local/path/spark-3.2.1-bin-hadoop3.2")
   .libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
   ```

3. **Install required R packages:**

   ```r
   install.packages("SparkR")
   ```

---

## Repository Structure

```
Distributed_XGBoost/
├── config/              # Optional YAML configs (not required for MV)
├── data/                # Raw data, processed objects, results folders
│   ├── rawdata/
│   ├── procdata/
│   └── results/
│       ├── local/
│       ├── global/
│       └── validation/
├── workflow/scripts/    # R and Python scripts for modeling
│   ├── Compute_GeneSigScore.r
│   ├── Create_train_set.r
│   ├── Train_Distributed_XGBoost.r
│   ├── Aggregate_model.py
│   └── Validate_global_model.r
├── docs/                # Markdown-based documentation
│   └── README.md        # Project overview and setup instructions 
└── pixi.toml            # Pixi environment specification
```

---

## Set Up

### Prerequisites

Pixi is required to run this project.
If you haven't installed it yet, [follow these instructions](https://pixi.sh/latest/)

---

## Getting Started

### Clone and Run

```bash
git clone https://github.com/bhklab/PredictIO-MV-Dist.git
cd PredictIO-MV-Dist
```

---

## Documentation

Full documentation will be available in the `docs/` folder or via published GitHub Pages.

Start by downloading and organizing the raw input datasets as described in [`data/rawdata/README.md`](https://github.com/bhklab/PredictIO-MV-Dist/blob/main/data/rawdata/README.md).

For data download and processing, please refer to the univariable repository:  
🔗 [https://github.com/bhklab/PredictIO-MV-Dist](https://github.com/bhklab/PredictIO-MV-Dist)
