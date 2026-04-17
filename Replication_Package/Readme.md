# Replication Package

This folder is the self-contained replication package for the project. The package is organized so that paths resolve relative to `Replication_Package/`, which makes the code more robust after a fresh GitHub download.

## Structure

- `Codes/`: analysis scripts
- `Data_GM2020/`: GM2020 source data and related code
- `Data_New/`: newly constructed data
- `Figures/`: generated figures
- `Tables/`: generated tables

## Recommended Entry Points

Run the R scripts from either location:

```bash
cd Replication_Package
Rscript Codes/Master.R
```

or

```bash
Rscript Replication_Package/Codes/Master.R
```

Run the Stata scripts from the package root:

```stata
cd "Replication_Package"
do Codes/Master.do
```

## Dependencies

### R

The R scripts use packages including `tidyverse`, `haven`, `fixest`, `knitr`, `kableExtra`, `stringr`, and `extrafont`.

### Stata

The Stata scripts expect the community packages `here` and `estout`/`esttab`. The master script installs missing packages when possible.
