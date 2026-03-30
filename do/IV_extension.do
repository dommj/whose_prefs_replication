*===============================================================================
* IV ANALYSIS: 2SLS WITH FORMAL IDENTIFICATION TABLE
*===============================================================================

// 1. Load the Augmented Dataset
// This dataset already contains the redistribution preferences and ILO institutional data
use "../data/redistribution_augmented.dta", clear

// 2. Prepare Variables for IV Analysis
// We use English Common Law origin as an instrument for Collective Bargaining Coverage
gen common_law = legor_uk
label var common_law "Instrument: English Common Law Origin"

// Create the endogenous interaction term: Bottom 5% Preferences x CBC Rate
gen cbc_interaction = att_red_bottom * cbc_rate
label var cbc_interaction "Bottom 5% Pref. $\times$ CBC Rate"

// Create the instrument interaction term: Bottom 5% Preferences x Common Law
gen iv_interaction = common_law * att_red_bottom
label var iv_interaction "Bottom 5% Pref. $\times$ Common Law"

// Locals for controls and preference variables
local base_controls lngdp lnpop dem_ANRR gini_mkt
local ses_prefs att_red_top att_red_mid att_red_bottom

// Define the endogenous variables and instruments
local endogenous cbc_rate cbc_interaction
local instruments common_law iv_interaction

*-------------------------------------------------------------------------------
* 1. Manual First-Stage Regressions (For the Table)
*-------------------------------------------------------------------------------
eststo clear

// First Stage for the Institutional Main Effect (CBC Rate)
eststo fs_cbc: reg cbc_rate `instruments' `ses_prefs' `base_controls', vce(robust)
    test `instruments'
    estadd scalar f_stat = r(F)

// First Stage for the Interaction Term (Bottom 5% x CBC Rate)
eststo fs_int: reg cbc_interaction `instruments' `ses_prefs' `base_controls', vce(robust)
    test `instruments'
    estadd scalar f_stat = r(F)

*-------------------------------------------------------------------------------
* 2. Second-Stage (The Main IV Result)
*-------------------------------------------------------------------------------
// We instrument for both the CBC rate and its interaction with preferences
eststo second_stage: ivregress 2sls rel_red_imp `ses_prefs' `base_controls' ///
    (`endogenous' = `instruments'), vce(robust)

    // Capture the Kleibergen-Paap rk Wald F statistic (Robust version of Cragg-Donald)
    quietly estat firststage
    matrix first = r(singleresults)
    estadd scalar kp_f = r(idstat)

*-------------------------------------------------------------------------------
* 3. Export Identification Table
*-------------------------------------------------------------------------------
# delimit ;
esttab fs_cbc fs_int second_stage using "../output/iv_identification_table.tex", replace 
    b(3) se(3) label booktabs style(tex)
    mgroups("First Stage" "Second Stage", pattern(1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span)
    mtitle("CBC Rate" "Bottom $\times$ CBC" "Redistribution")
    stats(f_stat kp_f N, fmt(2 2 0) 
          labels("F-stat (Instruments)" "K-P Rank F-stat" "N"))
    title("IV Results: Instrumenting with Legal Origins")
    interaction(" $\times$ ")  nonotes stardetach nostar ;
# delimit cr
