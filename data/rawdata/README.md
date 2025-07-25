# Raw Data Directory

## Purpose

This directory is reserved for **immutable raw data files** that serve as the original input to the distributed multivariable analysis pipeline. These files are not tracked by Git and must be obtained separately to ensure full reproducibility.

---

## Data Access Instructions

**No raw data files are included in this repository.**  
To reproduce or extend the analysis in a local or remote node, you must manually download the original datasets using the links below.


### Primary Dataset: ORCESTRA Platform

All raw datasets used in this pipeline are hosted on [**ORCESTRA**](https://www.orcestra.ca/clinical_icb), a reproducible biomedical data platform that supports versioned data objects (PharmacoSets, MAEs) suitable for decentralized analysis.

Please download the curated release using the following link:

➡️ **https://www.orcestra.ca/clinical_icb/62f29e85be1b2e72a9c177f4**

This dataset includes:
- Normalized RNA-seq expression data (TPM)
- Clinical annotations for immune checkpoint blockade (ICB) cohorts
- Metadata for sample stratification (e.g., treatment, cancer type, cohort)
- Documentation of data processing steps

These files are used as node-level input for multivariable modeling and feature scoring.

Public datasets used in this section, along with their PMIDs and source links, are summarized in [Supplementary Table S1: RNA-based IO datasets](https://docs.google.com/spreadsheets/d/1qN7ix5pjFQA4I9lDW2TTGl_pM8_y4MQH/edit?gid=547447763#gid=547447763). Note that some listed datasets (e.g., Hartwig, IMmotion150) are private and require data access agreements.

---

### Private Validation datasets

In addition to the public datasets, several **private datasets** were used exclusively for **external validation** of the final global model. These datasets are not publicly available but are described in published studies. The table below summarizes these datasets:

| Dataset Name     | PMID        | Access                                                                      |
|------------------|-------------|-----------------------------------------------------------------------------|
| Hartwig     | 31645765      | [Hartwig Medical Foundation](https://www.hartwigmedicalfoundation.nl/en/data/database/)|
| IMmotion150 | 29867230      | [EGAD00001004183](https://ega-archive.org/datasets/EGAD00001004183)    |
| INSPIRE     | 30867072      | [EGAS00001003280](https://ega-archive.org/studies/EGAS00001003280) |
| OAK         | 27979383      | [EGAC00001002120](https://ega-archive.org/dacs/EGAC00001002120) |
| POPLAR      | 26970723      | [EGAC00001002120](https://ega-archive.org/dacs/EGAC00001002120) |

 **Note:** Access to these datasets may require collaboration agreements or institutional permissions. 

---

### Signature Sets: Curated Immune/TME Gene Signatures

This pipeline applies a curated compendium of RNA-based gene expression signatures relevant to the tumor microenvironment (TME), immune responsiveness, and treatment resistance, used as **predictors or covariates** in distributed multivariable models.

Available sources include:

- **IO Signatures** — [bhklab/SignatureSets](https://github.com/bhklab/SignatureSets)  
- **TME Signatures** — [IOBR Project](https://github.com/IOBR/IOBR)  
- **Precompiled `.RData` file** — [Zenodo DOI: 10.5281/zenodo.15832652](https://zenodo.org/records/15832652)

Each signature is:
- Annotated with source publication
- Categorized (e.g., IO-sensitive, IO-resistant, TME)
- Scored using GSVA, ssGSEA, or other enrichment methods prior to regression modeling

 **Note:**  
 A filtered subset of these signatures, selected based on [Distributed univariable predictive modelling for Immuno-Oncology response](https://github.com/bhklab/PredictIO-UV-Dist), is used as input for the multivariable modeling step. This ensures that only features with predictive relevance across multiple cohorts are included.

---

## Inclusion & Exclusion Criteria

Raw datasets and signature sets were selected based on:

- Availability of pre-treatment RNA-seq data
- Sufficient clinical annotation for multivariable modeling (e.g., response, survival)
- Sample size per cohort 
- Relevance to immune checkpoint blockade (ICB) therapy

Refer to the **Materials and Methods** section of the manuscript for a full description of dataset and feature inclusion criteria.

---

## Additional Notes

- Only a subset of ORCESTRA datasets was selected based on treatment relevance and data quality.
- Analyses are stratified by **cancer type** and **treatment type** to ensure consistency across studies.
- This directory is **read-only** during pipeline execution. All transformations are done downstream in `data/procdata/`.
