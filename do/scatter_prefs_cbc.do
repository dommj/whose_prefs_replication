*===============================================================================
* EXTENSION ANALYSIS: Scatter Plot of Preferences vs. Bargaining Coverage
*===============================================================================

// Settings
set more off
clear all

// 1. Load Augmented Data (created by extension_analysis.do)
// If not already created, this script expects the data/redistribution_augmented.dta
cd "../data"
capture use "redistribution_augmented.dta", clear
if _rc {
    display as error "Data file not found. Please run do/extension_analysis.do first."
    exit
}

// 2. Prepare Labels and Regression Stats
// We label specific illustrative countries across the distribution
gen plot_label = ""
// Original + New countries for better coverage
local label_isos "USA SWE DEU BRA FRA GBR ZAF CHL JPN FIN AUT BEL TUR MEX RUS CHE KOR CAN"
foreach iso in `label_isos' {
    replace plot_label = country_str if iso3 == "`iso'"
}

// Calculate regression statistics for the note
quietly reg att_red_bottom cbc_rate
local b : display %4.3f _b[cbc_rate]
local se : display %4.3f _se[cbc_rate]
local n = e(N)
local r2 : display %4.2f e(r2)

// 3. Create Scatter Plot
// Y-axis: Preferences for redistribution (Bottom 5%)
// X-axis: Collective Bargaining Coverage (%)
twoway (scatter att_red_bottom cbc_rate, mlabel(plot_label) mlabpos(3) msize(small) mcolor(gray)) ///
       (lfit att_red_bottom cbc_rate, lcolor(black) lwidth(medthick)), ///
    title("Redistribution Preferences vs. Collective Bargaining", size(medium)) ///
    subtitle("Bottom 5% Income Group", size(small)) ///
    xtitle("Collective Bargaining Coverage (%)") ///
    ytitle("Mean Pref. for Redistribution (Bottom 5%)") ///
    legend(off) ///
    note("Slope: `b' (SE: `se'), R-sq: `r2', N: `n'" "Source: ISSP/WVS and ILOSTAT. Line represents linear fit.") ///
    graphregion(fcolor(white) lcolor(white)) ///
    plotregion(lcolor(white))

// 4. Export
graph export "../output/scatter_prefs_cbc.pdf", as(pdf) replace
graph export "../output/scatter_prefs_cbc.png", as(png) replace
