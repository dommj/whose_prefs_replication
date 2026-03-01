*===============================================================================
* EXTENSION ANALYSIS: Table 2 with Labor Market Institutions
*===============================================================================

* This do-file applies the union density and collective bargaining data to 
* the alternative measures of redistribution from Table 2 of the paper.

// Settings
set more off
clear all

// 1. Load Augmented Data
use "../data/redistribution_augmented.dta", clear

// 2. Re-create Redistribution Index for the Sub-sample
// Note: We follow the PCA method from the original main_tables.do
pca rel_red_imp tax socsec gini_disp, comp(1) blanks(0.3)
predict red_index, score
label var red_index "Redistribution Index"

// 3. Regression Analysis
local base_controls lngdp lnpop dem_ANRR gini_mkt
local ses_prefs att_red_top att_red_mid att_red_bottom
local union_vars tud_rate cbc_rate

eststo clear

// Loop through each dependent variable from Table 2
foreach dv in gini_disp tax socsec red_index {
	
	// A. Baseline on Sub-sample
	eststo: bootstrap, reps(1000) seed(1): reg `dv' `ses_prefs' `base_controls'
		test att_red_top = att_red_mid
		estadd scalar ptopmid = r(p)
		test att_red_top = att_red_bottom
		estadd scalar ptopbot = r(p)
		test att_red_mid = att_red_bottom
		estadd scalar pmidbot = r(p)
		test `ses_prefs' `base_controls'
		estadd scalar p_fstat = r(p)
	
	// B. Augmented with Union Vars
	eststo: bootstrap, reps(1000) seed(1): reg `dv' `ses_prefs' `base_controls' `union_vars'
		test att_red_top = att_red_mid
		estadd scalar ptopmid = r(p)
		test att_red_top = att_red_bottom
		estadd scalar ptopbot = r(p)
		test att_red_mid = att_red_bottom
		estadd scalar pmidbot = r(p)
		test `ses_prefs' `base_controls' `union_vars'
		estadd scalar p_fstat = r(p)
}

// 4. Output Results
cd "../output"
# delimit ;
esttab _all using "extension_table2_union.tex", replace 
    noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label 
    mgroups("Post-tax Gini" "Taxes" "Social Security" "Redist. Index", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    mtitle("Base" "+Unions" "Base" "+Unions" "Base" "+Unions" "Base" "+Unions")
    stats(ptopmid ptopbot pmidbot p_fstat r2 N, fmt(3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "F-stat p-val" "R-squared" "N"))
    nonotes stardetach nostar ;
# delimit cr
