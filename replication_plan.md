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

## 6. Extension: Incorporating Labor Market Institutions
To address the potential omitted variable bias identified in the critique, this extension incorporates data on trade union density and collective bargaining coverage from ILOSTAT.

### Data Source
- **File**: `data/collective_barg_union.csv`
- **Variables**: 
  - `Trade union density rate` (TUD)
  - `Collective bargaining coverage rate` (CBC)
  - `ref_area` (ISO3 country code)
  - `time_TUD` / `time_CBC` (Year of observation)

### Implementation Plan
1. **Data Cleaning**:
   - Load `data/collective_barg_union.csv` into Stata.
   - Standardize country identifiers (using `kountry` or mapping `ref_area` to `country_str` used in the main dataset).
   - Since the main analysis uses a 2015 snapshot for redistribution, select the TUD and CBC observations closest to 2015 for each country.
2. **Merging**:
   - Merge the cleaned ILOSTAT data into the primary analysis dataset (`redistribution_merged.dta`) by country.
3. **New Analysis**:
   - **Baseline + Unions**: Re-run Table 1, Column 6 (full specification) while adding TUD and CBC as additional controls.
   - **Mechanism Test**: Test if the coefficient for `att_red_bottom` (Bottom 5% preferences) decreases or loses significance when labor market institutions are included. This will help determine if the "lowest SES" effect is partially mediated by institutional factors like union strength.
   - **Interaction Models**: Explore whether the influence of low-SES preferences on redistribution is stronger in countries with high collective bargaining coverage.

### Results Evaluation: Institutional Extension
Based on the execution of `extension_analysis.do`, the results offer a nuanced view of the paper's main claims:

| Variable | (1) Paper | (2) + TUD | (3) + CBC | (4) Combined |
| :--- | :---: | :---: | :---: | :---: |
| Bottom 5% Pref. | 6.052 (1.414) | 5.724 (1.808) | 5.835 (1.673) | 5.815 (1.753) |
| Collective Bargaining (CBC) | - | - | **0.111** (0.048) | 0.106 (0.063) |
| Union Density (TUD) | - | 0.127 (0.119) | - | 0.013 (0.155) |
| **N (Countries)** | **91** | **63** | **63** | **63** |
| **R-squared** | **0.529** | **0.588** | **0.605** | **0.605** |

#### Key Findings:
1.  **Robustness of Preference Effect**: The coefficient for the **Bottom 5%** remains highly significant and stable (~5.8) even when controlling for unionization and bargaining coverage. This reinforces the authors' claim that low-SES preferences are a primary predictor of redistribution.
2.  **Institutional Significance**: **Collective Bargaining Coverage (CBC)** is a significant predictor (p < 0.05) when added to the model. Its inclusion improves the R-squared from 0.529 to 0.605, suggesting that omitting labor market institutions ignores a major driver of redistribution.
3.  **Sample Size Bias**: The extension suffers from a **31% reduction in sample size** (from 91 to 63 countries). This attrition likely excludes developing countries with weaker statistical reporting, meaning the institutional result might be more representative of OECD-style economies.
4.  **Collinearity between Institutions**: Union Density (TUD) loses significance when Collective Bargaining Coverage is included (Col 4), suggesting that the legal/institutional coverage of bargaining is a more potent predictor than mere membership numbers.

**Conclusion**: The core finding is robust to institutional controls within the restricted sample, but the omission of Collective Bargaining in the original paper was a significant gap in their explanatory model.

## 7. Extension: Institutional and Cultural Moderators
To go beyond the "who" and investigate the "when," this extension explores the boundary conditions of the poor's influence on redistribution using formal interaction terms.

### Comparison with Original Analysis
The original paper addresses heterogeneity primarily through **subgroup analysis** (e.g., Table B.11 splits the sample into Democratic vs. Nondemocratic countries; Table B.17 splits by Locus of Control). 

This extension improves upon that approach in three ways:
1.  **Statistical Power**: By using formal interactions (`##`) instead of sample splits, we utilize the full variance of the dataset and avoid the loss of information that comes from binary binning.
2.  **Continuous Moderators**: We test continuous moderators like **Pre-tax Gini** and **Moral Universalism**. The original paper uses these only as controls or not at all, missing the chance to see if these factors *condition* the impact of preferences.
3.  **Formal Significance Tests**: Subgroup analysis shows whether a coefficient is significant *within* a group, but not whether the *difference* between groups is statistically significant. Interaction terms provide a direct test of this difference.

### Research Questions:
- Is the responsiveness to the Bottom 5% significantly different in democratic vs. nondemocratic regimes?
- Does high market inequality (Pre-tax Gini) amplify the political weight of the poor's preferences?
- Does a country's level of "Moral Universalism" act as a moderator for redistributive responsiveness?

### Implementation Plan
1.  **Model Specification**: 
    - Dependent Variable: `rel_red_imp`
    - Key Independent Variable: `att_red_bottom`
    - Interaction Terms: 
        - `att_red_bottom # c.dem_ANRR`
        - `att_red_bottom # c.gini_mkt`
        - `att_red_bottom # c.trust_universal`
2.  **Do-file**: `do/extension_interactions.do`
3.  **Output**: `output/extension_interactions.tex`
