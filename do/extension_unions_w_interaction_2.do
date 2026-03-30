*===============================================================================
* EXTENSION ANALYSIS: Interaction Effects & Marginal Effects Visualization
*===============================================================================

set more off
clear all
eststo clear  // Clear once at the start

// [Data Preparation Block]
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

// Models
eststo t1_m1: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' tud_rate
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)

eststo t1_m2: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.att_red_top##c.tud_rate att_red_mid att_red_bottom
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)
    test c.att_red_top#c.tud_rate = 0
    estadd scalar pint_top = r(p)

eststo t1_m3: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' att_red_top att_red_mid c.att_red_bottom##c.tud_rate
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)
    test c.att_red_bottom#c.tud_rate = 0
    estadd scalar pint_bot = r(p)

bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.(`ses_prefs')##c.tud_rate
eststo t1_m4
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

// Marginal Effects Visualization (Horizontal Panels)
quietly sum tud_rate
local min_tud = r(min)
local max_tud = r(max)

// Calculate global y-range for TUD
tempfile t1 t2 t3
quietly margins, dydx(att_red_top) at(tud_rate=(`min_tud'(5)`max_tud')) saving(`t1', replace)
quietly margins, dydx(att_red_mid) at(tud_rate=(`min_tud'(5)`max_tud')) saving(`t2', replace)
quietly margins, dydx(att_red_bottom) at(tud_rate=(`min_tud'(5)`max_tud')) saving(`t3', replace)

preserve
    use `t1', clear
    append using `t2'
    append using `t3'
    gen lb = _margin - invnormal(0.975)*_se
    gen ub = _margin + invnormal(0.975)*_se
    summarize lb, meanonly
    local ymin = r(min)
    summarize ub, meanonly
    local ymax = r(max)
    local ymin_plot = floor(`ymin' / 5) * 5
    local ymax_plot = ceil(`ymax' / 5) * 5
    global tud_y_lab "`ymin_plot'(5)`ymax_plot'"
    global tud_y_scale "`ymin_plot' `ymax_plot'"
restore

// Panel A: Top SES
quietly margins, dydx(att_red_top) at(tud_rate=(`min_tud'(5)`max_tud'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Top SES") ///
    xtitle("TUD (%)") ytitle("Marginal Effect") ///
    xlabel(0(20)80) ylabel($tud_y_lab) yscale(range($tud_y_scale)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(tud_top, replace) nodraw

// Panel B: Middle SES
quietly margins, dydx(att_red_mid) at(tud_rate=(`min_tud'(5)`max_tud'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Middle SES") ///
    xtitle("TUD (%)") ytitle("") ///
    xlabel(0(20)80) ylabel($tud_y_lab) yscale(range($tud_y_scale)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(tud_mid, replace) nodraw

// Panel C: Bottom SES
quietly margins, dydx(att_red_bottom) at(tud_rate=(`min_tud'(5)`max_tud'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Bottom SES") ///
    xtitle("TUD (%)") ytitle("") ///
    xlabel(0(20)80) ylabel($tud_y_lab) yscale(range($tud_y_scale)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(tud_bot, replace) nodraw

// Combine for TUD
graph combine tud_top tud_mid tud_bot, rows(1) ycommon xcommon ///
    title("Marginal Effect by Trade Union Density", size(medium))
graph export "../output/margins_tud_plot.pdf", replace

*===============================================================================
* 2. COLLECTIVE BARGAINING COVERAGE (CBC) INTERACTIONS
*===============================================================================

eststo t2_m1: bootstrap, reps(1000) seed(1): reg rel_red_imp `ses_prefs' `base_controls' cbc_rate
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)

eststo t2_m2: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.att_red_top##c.cbc_rate att_red_mid att_red_bottom
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)
    test c.att_red_top#c.cbc_rate = 0
    estadd scalar pint_top = r(p)

eststo t2_m3: bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' att_red_top att_red_mid c.att_red_bottom##c.cbc_rate
    test att_red_top = att_red_mid
    estadd scalar ptopmid = r(p)
    test att_red_top = att_red_bottom
    estadd scalar ptopbot = r(p)
    test att_red_mid = att_red_bottom
    estadd scalar pmidbot = r(p)
    test c.att_red_bottom#c.cbc_rate = 0
    estadd scalar pint_bot = r(p)

bootstrap, reps(1000) seed(1): reg rel_red_imp `base_controls' c.(`ses_prefs')##c.cbc_rate
eststo t2_m4
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

// Marginal Effects Visualization (Horizontal Panels)
quietly sum cbc_rate
local min_cbc = r(min)
local max_cbc = r(max)

// Calculate global y-range for CBC
tempfile c1 c2 c3
quietly margins, dydx(att_red_top) at(cbc_rate=(`min_cbc'(10)`max_cbc')) saving(`c1', replace)
quietly margins, dydx(att_red_mid) at(cbc_rate=(`min_cbc'(10)`max_cbc')) saving(`c2', replace)
quietly margins, dydx(att_red_bottom) at(cbc_rate=(`min_cbc'(10)`max_cbc')) saving(`c3', replace)

preserve
    use `c1', clear
    append using `c2'
    append using `c3'
    gen lb = _margin - invnormal(0.975)*_se
    gen ub = _margin + invnormal(0.975)*_se
    summarize lb, meanonly
    local ymin = r(min)
    summarize ub, meanonly
    local ymax = r(max)
    local ymin_plot = floor(`ymin' / 5) * 5
    local ymax_plot = ceil(`ymax' / 5) * 5
    global cbc_y_lab "`ymin_plot'(5)`ymax_plot'"
    global cbc_y_scale "`ymin_plot' `ymax_plot'"
restore

// Panel A: Top SES
quietly margins, dydx(att_red_top) at(cbc_rate=(`min_cbc'(10)`max_cbc'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Top SES") ///
    xtitle("CBC (%)") ytitle("Marginal Effect") ///
    xlabel(0(20)100) ylabel($cbc_y_lab) yscale(range($cbc_y_scale)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(cbc_top, replace) nodraw

// Panel B: Middle SES
quietly margins, dydx(att_red_mid) at(cbc_rate=(`min_cbc'(10)`max_cbc'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Middle SES") ///
    xtitle("CBC (%)") ytitle("") ///
    xlabel(0(20)100) ylabel($cbc_y_lab) yscale(range($cbc_y_scale)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(cbc_mid, replace) nodraw

// Panel C: Bottom SES
quietly margins, dydx(att_red_bottom) at(cbc_rate=(`min_cbc'(10)`max_cbc'))
marginsplot, recast(line) recastci(rarea) ciopts(color(%25)) ///
    title("Bottom SES") ///
    xtitle("CBC (%)") ytitle("") ///
    xlabel(0(20)100) ylabel($cbc_y_lab) yscale(range($cbc_y_scale)) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    name(cbc_bot, replace) nodraw

// Combine for CBC
graph combine cbc_top cbc_mid cbc_bot, rows(1) ycommon xcommon ///
    title("Marginal Effect by Collective Bargaining Coverage", size(medium))
graph export "../output/margins_cbc_plot.pdf", replace

*===============================================================================
* 3. EXPORT TABLES
*===============================================================================

// Export TUD Table
# delimit ;
esttab t1_m1 t1_m2 t1_m3 t1_m4 using "../output/interaction_tud_table.tex", replace 
    noobs b(3) aux(se 3) style(tex) booktabs label 
    mgroups("Dep Var: Relative Redistribution", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span)
    mtitle("Linear" "Int: Top" "Int: Bottom" "Full Int.")
    stats(ptopmid ptopbot pmidbot pint_top pint_mid pint_bot p r2 N, fmt(3 3 3 3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "p-val Int. Top" "p-val Int. Middle" "p-val Int. Bottom" "F-stat p-val" "R-squared" "N"))
    interaction(" $\times$ ")  nonotes stardetach nostar ;
# delimit cr

// Export CBC Table
# delimit ;
esttab t2_m1 t2_m2 t2_m3 t2_m4 using "../output/interaction_cbc_table.tex", replace 
    noobs b(3) aux(se 3) style(tex) booktabs label 
    mgroups("Dep Var: Relative Redistribution", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span)
    mtitle("Linear" "Int: Top" "Int: Bottom" "Full Int.")
    stats(ptopmid ptopbot pmidbot pint_top pint_mid pint_bot p r2 N, fmt(3 3 3 3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "p-val Int. Top" "p-val Int. Middle" "p-val Int. Bottom" "F-stat p-val" "R-squared" "N"))
    interaction(" $\times$ ")  nonotes stardetach nostar ;
# delimit cr
