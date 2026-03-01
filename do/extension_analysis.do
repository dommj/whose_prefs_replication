*===============================================================================
* EXTENSION ANALYSIS: Incorporating Labor Market Institutions (ILOSTAT)
*===============================================================================

* This do-file implements the extension plan to test if union density and 
* collective bargaining coverage explain the relationship between low-SES 
* preferences and redistribution.

// Settings
set more off
clear all

// 1. Prepare ILOSTAT Data
import delimited "../data/collective_barg_union.csv", varnames(1) clear

// Rename variables for ease of use (handling Stata's 32-char limit truncation)
capture rename collectivebargainingcoveragerat cbc_rate
capture rename tradeuniondensityrate tud_rate
rename ref_area iso3
rename ref_area_label country_str

// Manual adjustments for consistency with the paper's data cleaning scripts
replace country_str = "Bosnia and Herzegovina" if iso3 == "BIH"
replace country_str = "Czech Republic" if iso3 == "CZE"
replace country_str = "Dominican Republic" if iso3 == "DOM"
replace country_str = "Palestinian Territories" if iso3 == "PSE"
replace country_str = "Korea" if iso3 == "KOR"
replace country_str = "Macedonia" if iso3 == "MKD"
replace country_str = "Taiwan" if iso3 == "TWN"
replace country_str = "Russia" if iso3 == "RUS"
replace country_str = "Slovakia" if iso3 == "SVK"
replace country_str = "Vietnam" if iso3 == "VNM"

tempfile ilo_data
save `ilo_data'

// 2. Merge with Main Dataset
use "../data/redistribution_merged.dta", clear
merge 1:1 country_str using `ilo_data'

// Restrict strictly to the sub-sample with both preferences and ILO indicators
drop if _merge != 3
drop _merge

// 3. Regression Analysis (Augmenting Table 1, Column 6)

label var cbc_rate "Coll. Bargaining Coverage"
label var tud_rate "Union Density"

// Specification: Table 1, Column 6 (Full Controls)
local base_controls lngdp lnpop dem_ANRR gini_mkt
local ses_prefs att_red_top att_red_mid att_red_bottom

eststo clear

// Column 1: Original Spec (Sub-sample only)
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls'
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test `ses_prefs' `base_controls'
	estadd scalar p_fstat = r(p)

// Column 2: Original Spec + TUD (Sub-sample only)
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' tud_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test `ses_prefs' `base_controls' tud_rate
	estadd scalar p_fstat = r(p)

// Column 3: Original Spec + CBC (Sub-sample only)
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' cbc_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test `ses_prefs' `base_controls' cbc_rate
	estadd scalar p_fstat = r(p)

// Column 4: Combined Model (Sub-sample only)
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' tud_rate cbc_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test `ses_prefs' `base_controls' tud_rate cbc_rate
	estadd scalar p_fstat = r(p)

// 4. Output Results
cd "../output"
# delimit ;
esttab m1 m2 m3 m4 using "extension_union_table.tex", replace 
    noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label 
    mgroups("Sub-sample: Countries with ILO data", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    mtitle("Baseline" "+ Union Density" "+ Barg. Coverage" "Combined")
    stats(ptopmid ptopbot pmidbot p_fstat r2 N, fmt(3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "F-stat p-val" "R-squared" "N"))
    nonotes stardetach nostar ;
# delimit cr

// Save the augmented dataset for further research
cd "../data"
save "redistribution_augmented.dta", replace
