*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Tables for main manuscript
*Last update: 05.03.23


*Note: To run the analyses, data cleaning should be applied first by running the do-file prepare_data

*===============================================================================


//Settings

set more off
clear all
set maxvar 15000, permanently
set matsize 5000
set linesize 80  


*===============================================================================
*TABLE 1
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


//Run regressions

quietly{

eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_mid
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_bottom
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR 
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
}


//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "table1.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(ptopmid ptopbot pmidbot p r2 N, fmt(3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "F-stat p-val" "R-squared"))
	;
# delimit cr


// Test for difference between coefficients middle and bottom

eststo mid: reg rel_red_imp att_red_mid
eststo bot:reg rel_red_imp att_red_bottom
eststo top: reg rel_red_imp att_red_top

suest mid bot, vce(robust)
test [mid_mean]att_red_mid=[bot_mean]att_red_bottom

suest mid top, vce(robust)
test [mid_mean]att_red_mid=[top_mean]att_red_top

suest bot top, vce(robust)
test [bot_mean]att_red_bottom=[top_mean]att_red_top



*===============================================================================
*TABLE 2
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear

//Create redistribution index
	
pca rel_red_imp tax socsec gini_disp, comp(1) blanks(0.3)
predict red_index, score

//Run regressions



quietly{
eststo m1: bootstrap, reps(1000) seed(1): reg tax att_red_top att_red_mid att_red_bottom
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m2: bootstrap, reps(1000) seed(1): reg socsec att_red_top att_red_mid att_red_bottom
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m3: bootstrap, reps(1000) seed(1): reg gini_disp att_red_top att_red_mid att_red_bottom
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m4: bootstrap, reps(1000) seed(1): reg red_index att_red_top att_red_mid att_red_bottom
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m5: bootstrap, reps(1000) seed(1): reg tax att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m6: bootstrap, reps(1000) seed(1): reg socsec att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m7: bootstrap, reps(1000) seed(1): reg gini_disp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
eststo m8: bootstrap, reps(1000) seed(1): reg red_index att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m3 m7  m1 m5 m2 m6  m4 m8   using "table2.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs nomtitles mgroups("\shortstack{Gini\\post-tax}" "Taxes" "\shortstack{Social\\security}" "\shortstack{Redistribution\\index}" , pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )label 
	nonotes  stardetach nostar stats(ptopmid ptopbot pmidbot p r2 N, fmt(3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "F-stat p-val" "R-squared"))
	;
# delimit cr

