*===============================================================================
* EXTENSION ANALYSIS: Quality of Government (ICRG) Interaction Effects
* Using Local CSV: qog_bas_ts_jan26.csv
*===============================================================================

set more off
clear all
eststo clear

// [1. Data Preparation: Quality of Government (QoG) Data]
// Load the specific CSV file requested
import delimited "../data/qog_bas_ts_jan26.csv", clear

// We only need a few variables: country name, year, and icrg_qog
keep cname year icrg_qog
drop if icrg_qog == .

// Filter for 2014 or nearest available data for each country
gen dist2014 = abs(year - 2014)
bysort cname: egen mindist2014 = min(dist2014)
keep if dist2014 == mindist2014

// In case of ties (e.g., 2013 and 2015), take the more recent year
bysort cname: keep if year == year[_N]

// Standardize country names for merging with the main dataset
// The main dataset uses "country_str"
rename cname country_str

// Manual recoding to match 'redistribution_merged.dta' conventions if necessary
replace country_str = "United States" if country_str == "United States of America"
replace country_str = "United Kingdom" if country_str == "United Kingdom of Great Britain and Northern Ireland"
replace country_str = "Russia" if country_str == "Russian Federation"
replace country_str = "Korea" if country_str == "Korea, South"
replace country_str = "Slovakia" if country_str == "Slovak Republic"
replace country_str = "Czech Republic" if country_str == "Czechia"
replace country_str = "Macedonia" if country_str == "North Macedonia"
replace country_str = "Vietnam" if country_str == "Viet Nam"
replace country_str = "Iran" if country_str == "Iran (Islamic Republic of)"
replace country_str = "Taiwan" if country_str == "Taiwan, Province of China"

tempfile qog_data
save `qog_data'

// [2. Load Main Dataset and Merge]
use "../data/redistribution_merged.dta", clear

merge 1:1 country_str using `qog_data'
// Keep only successful matches
drop if _merge != 3
drop _merge

*===============================================================================
* ANALYSIS SETTINGS
*===============================================================================
local base_controls lngdp lnpop dem_ANRR gini_mkt
local ses_prefs att_red_top att_red_mid att_red_bottom

*===============================================================================
* 1. QUALITY OF GOVERNMENT (ICRG_QOG) INTERACTIONS
*===============================================================================

// Model 1: Linear Control (No Interaction)
eststo qog_m1: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' icrg_qog
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)

// Model 2: Interaction with Top SES
eststo qog_m2: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.att_red_top##c.icrg_qog att_red_mid att_red_bottom
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)
    test c.att_red_top#c.icrg_qog = 0
    estadd scalar pint_top = r(p)

// Model 3: Interaction with Bottom SES
eststo qog_m3: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' att_red_top att_red_mid c.att_red_bottom##c.icrg_qog
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)
    test c.att_red_bottom#c.icrg_qog = 0
    estadd scalar pint_bot = r(p)

// Model 4: Full Interactions (All SES groups)
bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.(`ses_prefs')##c.icrg_qog
eststo qog_m4
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)
    test c.att_red_top#c.icrg_qog = 0
    estadd scalar pint_top = r(p)
    test c.att_red_mid#c.icrg_qog = 0
    estadd scalar pint_mid = r(p)
    test c.att_red_bottom#c.icrg_qog = 0
    estadd scalar pint_bot = r(p)

*===============================================================================
* 2. MARGINAL EFFECTS VISUALIZATION
*===============================================================================

// Get observed range for icrg_qog
quietly sum icrg_qog
local min_obs = r(min)
local max_obs = r(max)

// 1. Calculate the global y-axis range across all three SES groups for consistency
tempfile m1 m2 m3
quietly margins, dydx(att_red_top) at(icrg_qog=(`min_obs'(0.05)`max_obs')) saving(`m1', replace)
quietly margins, dydx(att_red_mid) at(icrg_qog=(`min_obs'(0.05)`max_obs')) saving(`m2', replace)
quietly margins, dydx(att_red_bottom) at(icrg_qog=(`min_obs'(0.05)`max_obs')) saving(`m3', replace)

preserve
    use `m1', clear
    append using `m2'
    append using `m3'
    // Calculate 95% CI bounds for axis fitting
    gen lb = _margin - invnormal(0.975)*_se
    gen ub = _margin + invnormal(0.975)*_se
    summarize lb, meanonly
    local global_ymin = r(min)
    summarize ub, meanonly
    local global_ymax = r(max)
    
    // Create readable "nice" ticks (increments of 2)
    local ymin_plot = floor(`global_ymin' / 2) * 2
    local ymax_plot = ceil(`global_ymax' / 2) * 2
    
    // Store in globals for use in plotting calls
    global y_lab_range "`ymin_plot'(2)`ymax_plot'"
    global y_scale_range "`ymin_plot' `ymax_plot'"
restore

// 2. Generate Plots

// Panel A: Top SES
quietly margins, dydx(att_red_top) at(icrg_qog=(`min_obs'(0.05)`max_obs'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Top SES") ///
    xtitle("ICRG Index") ytitle("Marginal Effect") ///
    xlabel(0.1(0.2)0.9) ylabel($y_lab_range) yscale(range($y_scale_range)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(p_top, replace) nodraw

// Panel B: Middle SES
quietly margins, dydx(att_red_mid) at(icrg_qog=(`min_obs'(0.05)`max_obs'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Middle SES") ///
    xtitle("ICRG Index") ytitle("") ///
    xlabel(0.1(0.2)0.9) ylabel($y_lab_range) yscale(range($y_scale_range)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(p_mid, replace) nodraw

// Panel C: Bottom SES
quietly margins, dydx(att_red_bottom) at(icrg_qog=(`min_obs'(0.05)`max_obs'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Bottom SES") ///
    xtitle("ICRG Index") ytitle("") ///
    xlabel(0.1(0.2)0.9) ylabel($y_lab_range) yscale(range($y_scale_range)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(p_bot, replace) nodraw

// Combine into a horizontal row
graph combine p_top p_mid p_bot, rows(1) ycommon xcommon ///
    title("Marginal Effect of Preferences by Quality of Government", size(medium))

graph export "../output/margins_qog_plot.pdf", replace

*===============================================================================
* 3. EXPORT TABLES
*===============================================================================

# delimit ;
esttab qog_m1 qog_m2 qog_m3 qog_m4 using "../output/interaction_qog_table.tex", replace 
    noobs b(3) aux(se 3) style(tex) booktabs label 
    mgroups("Dep Var: Relative Redistribution", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span)
    mtitle("Linear" "Int: Top" "Int: Bottom" "Full Int.")
    stats(ptopmid ptopbot pmidbot pint_top pint_mid pint_bot p r2 N, fmt(3 3 3 3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "p-val Int. Top" "p-val Int. Middle" "p-val Int. Bottom" "F-stat p-val" "R-squared" "N"))
    interaction(" $\times$ ")  nonotes stardetach nostar ;
# delimit cr
