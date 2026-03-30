*===============================================================================
* SAMPLE COMPARISON: Original vs. Extension Subsamples
*===============================================================================

set more off
clear all

// [1. Prepare Subsample Indicators]

// A. Load Union Data to identify that subsample
import delimited "../data/collective_barg_union.csv", varnames(1) clear
capture rename collectivebargainingcoveragerat cbc_rate
capture rename tradeuniondensityrate tud_rate
rename ref_area iso3
rename ref_area_label country_str
// Standardize names (matching extension_unions_w_interaction_2.do)
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
keep country_str tud_rate cbc_rate
gen in_union_sample = 1
tempfile union_mark
save `union_mark'

// B. Load QoG Data to identify that subsample and get institutional quality
import delimited "../data/qog_bas_ts_jan26.csv", clear
keep cname year icrg_qog
drop if icrg_qog == .
gen dist2014 = abs(year - 2014)
bysort cname: egen mindist2014 = min(dist2014)
keep if dist2014 == mindist2014
bysort cname: keep if year == year[_N]
rename cname country_str
// Standardize names (matching extension_qog_interaction.do)
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
gen in_qog_sample = 1
tempfile qog_mark
save `qog_mark'

// C. Merge into Original Dataset
use "../data/redistribution_merged.dta", clear
gen in_original_sample = 1

merge 1:1 country_str using `union_mark', keep(master match)
replace in_union_sample = 0 if _merge == 1
drop _merge

merge 1:1 country_str using `qog_mark', keep(master match)
replace in_qog_sample = 0 if _merge == 1
drop _merge

*===============================================================================
* 1. SUMMARY TABLE: Comparison of Sample Characteristics
*===============================================================================

local vars lngdp rel_red_imp dem_ANRR att_red_top att_red_mid att_red_bottom

// Create a descriptive label for the samples
gen sample_cat = "Original" if in_original_sample == 1
label var in_original_sample "Full Sample"
label var in_union_sample "Union Subsample"
label var in_qog_sample "QoG Subsample"

eststo clear
estpost tabstat `vars', by(in_original_sample) statistics(mean sd n) columns(statistics)
eststo original_stats

estpost tabstat `vars' if in_union_sample == 1, statistics(mean sd n) columns(statistics)
eststo union_stats

estpost tabstat `vars' if in_qog_sample == 1, statistics(mean sd n) columns(statistics)
eststo qog_stats

// Export Summary Table
esttab original_stats union_stats qog_stats using "../output/sample_summary_comparison.tex", ///
    replace main(mean) aux(sd) mtitle("Original" "Unions" "QoG") ///
    booktabs label title("Mean Characteristics across Samples") ///
    stats(N, labels("Number of Countries"))

*===============================================================================
* 2. INSTITUTIONAL QUALITY FREQUENCY TABLE
*===============================================================================

// Define Institutional Quality Categories based on Absolute Splits of the 0-1 range
// Low: 0-0.33, Medium: 0.33-0.66, High: 0.66-1
gen qog_cat = .
replace qog_cat = 1 if icrg_qog >= 0 & icrg_qog <= 0.333
replace qog_cat = 2 if icrg_qog > 0.333 & icrg_qog <= 0.666
replace qog_cat = 3 if icrg_qog > 0.666 & icrg_qog <= 1.0
label define qog_lab 1 "Low (0-0.33)" 2 "Medium (0.33-0.66)" 3 "High (0.66-1)"
label values qog_cat qog_lab
label var qog_cat "Institutional Quality (ICRG)"

// Frequency table for each sample
// We want the relative number (percentages)
tab qog_cat if in_original_sample == 1
tab qog_cat if in_union_sample == 1
tab qog_cat if in_qog_sample == 1

// Combined frequency table (relative proportions)
eststo clear
estpost tab qog_cat if in_original_sample == 1
eststo freq_orig
estpost tab qog_cat if in_union_sample == 1
eststo freq_union
estpost tab qog_cat if in_qog_sample == 1
eststo freq_qog

// Display percentages in a clear table
esttab freq_orig freq_union freq_qog using "../output/institutional_quality_freq.tex", ///
    replace cells("pct(fmt(1))") mtitle("Original" "Unions" "QoG") ///
    booktabs label title("Distribution of Institutional Quality (%)") ///
    nonumbers nodepvars
