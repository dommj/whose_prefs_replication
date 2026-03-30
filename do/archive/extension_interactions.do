*===============================================================================
* EXTENSION ANALYSIS: Institutional and Cultural Moderators (Interactions)
*===============================================================================

* This do-file investigates whether the influence of the Bottom 5% preferences
* on redistribution depends on a country's democratic status, inequality level,
* or moral universalism.

// Settings
set more off
clear all

// 1. Load Data
use "../data/redistribution_merged.dta", clear

// Label variables for the table
label var att_red_bottom "Bottom 5% Pref."
label var dem_ANRR "Democracy"
label var gini_mkt "Pre-tax Gini"
label var trust_universal "Moral Universalism"

// 2. Interaction Models
local base_controls lngdp lnpop
local main_pref att_red_bottom

eststo clear

// Model 1: Democracy Interaction
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp c.att_red_bottom##c.dem_ANRR `base_controls' gini_mkt
	estadd scalar p_fstat = r(p)

// Model 2: Inequality Interaction
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp c.att_red_bottom##c.gini_mkt `base_controls' dem_ANRR
	estadd scalar p_fstat = r(p)

// Model 3: Moral Universalism Interaction
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp c.att_red_bottom##c.trust_universal `base_controls' dem_ANRR gini_mkt
	estadd scalar p_fstat = r(p)

// Model 4: Full Interaction Model
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp c.att_red_bottom##c.dem_ANRR c.att_red_bottom##c.gini_mkt c.att_red_bottom##c.trust_universal `base_controls'
	estadd scalar p_fstat = r(p)

// 3. Output Results
cd "../output"
# delimit ;
esttab m1 m2 m3 m4 using "extension_interactions.tex", replace 
    noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label 
    mgroups("Relative redistribution", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    mtitle("Democ. Mod." "Ineq. Mod." "Moral Mod." "Full")
    stats(p_fstat r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared" "N"))
    nonotes stardetach nostar ;
# delimit cr
