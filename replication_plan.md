# Replication Plan: Whose Preferences Matter for Redistribution?

This document outlines the steps required to replicate the main tables (Table 1 and Table 2) from the paper "Whose Preferences Matter for Redistribution? Cross-Country Evidence" by Maréchal, Cohn, Yusof, and Fisman.

## 1. Prerequisites
- **Software**: Stata (Version 15 or higher recommended).
- **Stata Packages**: The following packages must be installed in Stata:
  - `ssc install estout` (for `esttab`)
  - `ssc install egenmore`
  - `ssc install kountry`

## 2. Directory Structure
The provided replication scripts assume a specific directory structure. It is recommended to organize the files as follows:

```
project_root/
├── code/               # All .do files
├── data/               # All .dta, .csv, .xls, .xlsx files
└── output/             # Where the tables and figures will be saved
```

### Setup Instructions:
1. Create the `code/`, `data/`, and `output/` directories.
2. Move all `.do` files from `dataverse_files/` to the `code/` directory.
3. Move all other files (data files) from `dataverse_files/` to the `data/` directory.

## 3. Data Preparation
Before running the analysis, the raw data must be processed and merged.

1. Open Stata and set the working directory to the `code/` folder.
2. Run the master data preparation script:
   ```stata
   do prepare_data.do
   ```
   *Note: This script calls several other scripts (`prepare_data_wvs.do`, `prepare_data_issp.do`, etc.) to clean and merge data from the World Values Survey (WVS), SWIID, IMF, and other sources.*
3. The primary output of this step is `redistribution_merged.dta`, which will be saved in the `data/` directory.

## 4. Replicating Main Tables
Once the data is prepared, you can generate the tables.

1. In Stata, run the script for the main tables:
   ```stata
   do main_tables.do
   ```
2. **Table 1: Attitudes and Relative Redistribution**
   - This table is generated using OLS regressions with bootstrapped standard errors (1000 replications).
   - The output will be saved as `table1.tex` in the `output/` directory.
3. **Table 2: Alternative Measures of Redistribution**
   - This table explores alternative dependent variables: Post-tax Gini, Taxes, Social Security, and a Redistribution Index.
   - The output will be saved as `table2.tex` in the `output/` directory.

## 5. Verification
- Compare the generated `table1.tex` and `table2.tex` with the tables on pages 10 and 16 of the paper.
- Ensure that the number of observations (N) and the coefficients match the published results.
