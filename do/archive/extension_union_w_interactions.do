*===============================================================================
* EXTENSION ANALYSIS: Interaction Effects & Marginal Effects Visualization
*===============================================================================

// [Data Preparation Block - Standardized]
set more off
clear all

// Load and Clean ILO data
import delimited "../data/collective_barg_union.csv", varnames(1) clear
capture rename collectivebargainingcoveragerat cbc_rate
capture rename tradeuniondensityrate tud_rate
rename ref_area iso3
rename ref_area_label country_str

// Manual recoding for merge consistency
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

// Merge
use "../data/redistribution_merged.dta", clear
merge 1:1 country_str using `ilo_data'
drop if _merge != 3
drop _merge

*===============================================================================
* ANALYSIS SETTINGS
*===============================================================================
local base_controls lngdp lnpop dem_ANRR gini_mkt
local ses_prefs att_red_top att_red_mid att_red_bottom

*===============================================================================
* 1. TRADE UNION DENSITY (TUD) INTERACTIONS
*===============================================================================
eststo clear

// Models
eststo t1_m1: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' tud_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo t1_m2: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' tud_rate c.att_red_top##c.tud_rate att_red_mid att_red_bottom
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test c.att_red_top#c.tud_rate = 0
	estadd scalar pint_top = r(p)
eststo t1_m3: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' tud_rate att_red_top att_red_mid c.att_red_bottom##c.tud_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test c.att_red_bottom#c.tud_rate = 0
	estadd scalar pint_bot = r(p)
eststo t1_m4: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.(`ses_prefs')##c.tud_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test c.att_red_top#c.tud_rate = 0
	estadd scalar pint_top = r(p)
	test c.att_red_mid#c.tud_rate = 0
	estadd scalar pint_mid = r(p)
	test c.att_red_bottom#c.tud_rate = 0
	estadd scalar pint_bot = r(p)

// Table Output
# delimit ;
esttab t1_m1 t1_m2 t1_m3 t1_m4 using "../output/interaction_tud_table.tex", replace 
    noobs b(3) aux(se 3) style(tex) booktabs label 
    mgroups("Dep Var: Relative Redistribution", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span)
    mtitle("Linear" "Int: Top" "Int: Bottom" "Full Int.")
    stats(ptopmid ptopbot pmidbot pint_top pint_mid pint_bot p r2 N, fmt(3 3 3 3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "p-val Int. Top" "p-val Int. Middle" "p-val Int. Bottom" "F-stat p-val" "R-squared" "N"))
    interaction(" $\times$ ")  nonotes stardetach nostar ;
# delimit cr

// Marginal Effects Visualization (using the Full Model T1_M4)
// Note: We run the regression once without bootstrap to allow 'margins' to work correctly with default VCE
quietly reg rel_red_imp `base_controls' c.(`ses_prefs')##c.tud_rate

// Calculate marginal effects of preferences across the observed range of TUD
margins, dydx(att_red_top att_red_bottom) at(tud_rate=(0(10)100))

marginsplot, recast(line) recastci(rarea) ciopts(color(%30)) ///
    title("Marginal Effect of SES Preferences by Union Density") ///
    xtitle("Trade Union Density Rate (%)") ///
    ytitle("Marginal Effect on Redistribution") ///
    legend(order(3 "Top SES" 4 "Bottom SES")) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(tud_margins, replace)

graph export "../output/margins_tud_plot.pdf", as(pdf) replace


*===============================================================================
* 2. COLLECTIVE BARGAINING COVERAGE (CBC) INTERACTIONS
*===============================================================================
eststo clear

// Models
eststo t2_m1: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' cbc_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo t2_m2: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' cbc_rate c.att_red_top##c.cbc_rate att_red_mid att_red_bottom
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test c.att_red_top#c.cbc_rate = 0
	estadd scalar pint_top = r(p)
eststo t2_m3: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' cbc_rate att_red_top att_red_mid c.att_red_bottom##c.cbc_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test c.att_red_bottom#c.cbc_rate = 0
	estadd scalar pint_bot = r(p)
eststo t2_m4: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.(`ses_prefs')##c.cbc_rate
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
	test c.att_red_top#c.cbc_rate = 0
	estadd scalar pint_top = r(p)
	test c.att_red_mid#c.cbc_rate = 0
	estadd scalar pint_mid = r(p)
	test c.att_red_bottom#c.cbc_rate = 0
	estadd scalar pint_bot = r(p)

// Table Output
# delimit ;
esttab t2_m1 t2_m2 t2_m3 t2_m4 using "../output/interaction_cbc_table.tex", replace 
    noobs b(3) aux(se 3) style(tex) booktabs label 
    mgroups("Dep Var: Relative Redistribution", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span)
    mtitle("Linear" "Int: Top" "Int: Bottom" "Full Int.")
    stats(ptopmid ptopbot pmidbot pint_top pint_mid pint_bot p r2 N, fmt(3 3 3 3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "p-val Int. Top" "p-val Int. Middle" "p-val Int. Bottom" "F-stat p-val" "R-squared" "N"))
    interaction(" $\times$ ")  nonotes stardetach nostar ;
# delimit cr

// Marginal Effects Visualization (using the Full Model T2_M4)
quietly reg rel_red_imp `base_controls' c.(`ses_prefs')##c.cbc_rate

margins, dydx(att_red_top att_red_bottom) at(cbc_rate=(0(10)100))

marginsplot, recast(line) recastci(rarea) ciopts(color(%30)) ///
    title("Marginal Effect of SES Preferences by Bargaining Coverage") ///
    xtitle("Collective Bargaining Coverage (%)") ///
    ytitle("Marginal Effect on Redistribution") ///
    legend(order(3 "Top SES" 4 "Bottom SES")) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(cbc_margins, replace)

graph export "../output/margins_cbc_plot.pdf", as(pdf) replace
