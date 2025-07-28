# Processed Data Directory

## Purpose

This directory stores **intermediate processed data objects** generated from raw RNA-seq and clinical inputs. These `.rda` files are structured support multivariable analyses such as signature scoring and predicting IO therapy response using XGBoost modeling.

Each file typically includes:

- Normalized gene expression matrices (e.g., TPM)
- Clinical metadata and sample annotations
- Signature scores and associated metadata
- Combined as a `SummarizedExperiment` or `MultiAssayExperiment` object

---

## How to Generate Processed Data

To prepare the `.rda` files from raw inputs using the UV distributed pipeline, follow the steps outlined under the `data/procdata` directory in the [UV distributed pipeline](https://github.com/bhklab/PredictIO-UV-Dist) repository:

### 1. Download Raw Data

Download the raw dataset from ORCESTRA, for example:

➡️ [ICB_Gide Dataset](https://www.orcestra.ca/clinical_icb/62f29e85be1b2e72a9c177f4)

Save the file as:
```bash
data/rawdata/ICB_Gide.rds
```

### 2. Obtain Gene Signature Files

Ensure the following signature metadata files are present in `data/rawdata/`:

- `signature.rda` — curated gene signature matrix  
- `sig.info.rda` — metadata for signatures (e.g., method, category)

### 3. Set Configuration

Create or edit the center-specific configuration file to define preprocessing settings:

```bash
config/config_proc.yaml
```

This file defines paths to the raw inputs, signature sets, and output filenames.  
You can use the included `config/config_proc.yaml` as a **template** to set up new datasets.

### 4. Run Processing Script

To generate the processed data object:

```bash
Rscript workflow/scripts/runProcData.R
```

This script:

- Loads raw `.rds` data
- Converts it into a `SummarizedExperiment` or `MultiAssayExperiment` object
- Attaches gene signature scores and metadata
- Saves the result as a `.rda` file for downstream analysis

➡️ Alternatively, you can use a precompiled `.rda` file from Zenodo:  
[Zenodo DOI: 10.5281/zenodo.15832651](https://zenodo.org/records/15832652)

---

## File Naming Convention

Processed files follow this structure:

```
<study_name>__<cancer_type>__<treatment_type>.rda
```

**Example:**
```
ICB_Gide__Melanoma__PD-(L)1.rda
```

---

## Note on Treatment Harmonization

To ensure consistency across datasets with varying annotation styles:

- Treatments such as `anti-PD-1`, `anti-PD-L1`, or `anti-PD-1/anti-PD-L1` are grouped as:
  ```
  PD-(L)1 or PD-1/PD-L1
  ```

- Combination therapies involving both PD-(L)1 and CTLA4 (typically annotated with `combo`) are categorized as:
  ```
  IO+combo
  ```

This harmonization ensures consistent treatment grouping across datasets for downstream meta-analysis.

---

## Note on Cancer Type Harmonization

To ensure consistency across datasets with varying cancer type annotations:

- Each sample is assigned a standardized **OncoTree Level 1** cancer type label.

**Example:**

- Original terms like `SKCM`, or `melanoma` are all mapped to:
  ```
  Melanoma
  ```

This cancer-type harmonization enables consistent aggregation and comparison across datasets during meta-analysis.

---

## Create Train Set Files

Once all processed `.rda` files are ready, use the following R script to generate training feature matrices:

```bash
workflow/scripts/Create_train_set.r
```