*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Tables for Online Appendix
*Last update: 05.03.23

*Note: To run the analyses, data cleaning should be applied first by running the do-file prepare_data


*===============================================================================


//Settings

set more off
clear all
set maxvar 15000, permanently
set matsize 5000
set linesize 80  


//Addiditional packages

*ssc install gtools
*ssc install reghdfe
*ssc install erepost

*===============================================================================
*TABLE B.1
*===============================================================================

//Import data - only from 94 countries included in main analysis 
cd ..
cd "data"
use redistribution_merged,clear
reg rel_red_imp att_red_top, robust
keep country
keep if e(sample)==1
merge 1:m country using wvs.dta
drop if _merge==2
drop _merge


*INCOME

// Generate indicator for top income bracket by country and wave
qui{
gen top_income =.
levelsof country, local(levels)			//Generates list with unique values of country
forvalues i = 4(1)5 {
foreach l of local levels {
	su income_cs if country == `l' & wave == `i', d       //Summarize income for a given country and wave
	replace top_income = (income_cs == r(max)) if country == `l' & wave == `i' & income_cs!=.
}
}
}


// Generate indicator for bottom income bracket by country and wave
qui{
gen bottom_income =.
levelsof country, local(levels)			//Generates list with unique values of country
forvalues i = 4(1)5 {
foreach l of local levels {
	su income_cs if country == `l' & wave == `i', d       //Summarize income for a given country and wave
	replace bottom_income = (income_cs == r(min)) if country == `l' & wave == `i' & income_cs!=.
}
}
}


//Regress top income bracket on  top index indicator

label variable top_index "Top 5\%"
label variable bottom_index "Bottom 5\%"

eststo clear
qui eststo m1: xi: reg top_income top_index  i.country i.wave, cluster(country)
					sum top_income if top_index!=1 & e(sample)==1
					estadd scalar mean = r(mean)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)

//Regress top bottom income bracket on bottom indicator

qui eststo m2: xi: reg bottom_income  bottom_index i.country i.wave, cluster(country)
					sum bottom_income if bottom_index!=1 & e(sample)==1
					estadd scalar mean = r(mean)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)


*SUPERVISOR

//Regress supervisor role on  top index indicator

qui eststo m3: xi: reg work_supervis top_index  i.country i.wave, cluster(country)
					sum work_supervis if top_index!=1 & e(sample)==1
					estadd scalar mean = r(mean)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)


*POLITICAL PARTY

//Regress political party membership on  top index indicator

qui eststo m4: xi: reg polpart_memb top_index i.country i.wave, cluster(country)
					sum polpart_memb if top_index!=1 & e(sample)==1
					estadd scalar mean = r(mean)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)


//Compute and save table
cd ..
cd "output"

# delimit ;
	qui esttab m1 m2 m3 m4 using "tableB1.tex", replace keep(top_index bottom_index) constant ///
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mtitle("Top income" "Bottom income" "Supervisor" "\shortstack{Pol. party\\membership}") indicate("Country FE = _Icountry*" "Wave FE = _Iwave*") ///
	nonotes stardetach nostar stats(mean r2 N country, fmt(3 3 0 0) labels("\shortstack[l]{Reference\\category mean}" "R-squared" "N" "Countries"))
	;
# delimit cr


*===============================================================================
*TABLE B.2
*===============================================================================


//Create matrix

matrix M = J(20,5,.)
matrix colnames M = "Bottom" "Middle" "Top" "N" "Countries"
matrix rownames M = "Male" "" "Age" "" "Married" "" "Children" "" "Employed" "" "Unemployed" ""  "Manual work" "" "Routine work" ""  "Immigrant parent"  "" "Political left" "" 

mata
rownames = ("Male"\ ""\ "Age" \"" \ "Married"\ ""\ "Children"\ ""\ "Employed"\ ""\ "Unemployed"\ ""\ "Manual work"\ "" \"Routine work"\ ""\ "Immigrant parent" \ "" \"Political left" \"")
end


//Import data - only from 94 countries included in main analysis 
cd ..
cd "data"
use redistribution_merged,clear
reg rel_red_imp att_red_top, robust
keep country
keep if e(sample)==1
merge 1:m country using wvs.dta
drop if _merge==2
drop _merge

//Compute descriptives and fill into matrix

local c=1
local r=1


foreach var in male age married children employed unemployed  work_manual work_routine  immig_parent political {	
	local var_label: variable label `var'
	foreach group in bottom_index mid_index top_index {
					sum `var' if `group'==1
					local mean_`group'=round(r(mean), 0.01)
					dis `mean_`group''
					sum `var' if `group'==1	
					local sd_`group'=round(r(sd), 0.01)
					dis `sd_`group''
				}
					count if `var'!=. & (bottom_index ==1 | mid_index ==1 | top_index ==1)
					return list
					local N_nm=r(N)
					dis `N_nm'
					
					gdistinct country if `var'!=. & (bottom_index ==1 | mid_index ==1 | top_index ==1)
					local country = r(ndistinct)
					
	matrix M[`r', `c'+0] = `mean_bottom_index'
	matrix M[`r', `c'+1] = `mean_mid_index'
	matrix M[`r', `c'+2] = `mean_top_index'
	matrix M[`r', `c'+3] = `N_nm'
	matrix M[`r', `c'+4] = `country'
	matrix M[`r'+1, `c'+0] = `sd_bottom_index'
	matrix M[`r'+1, `c'+1] = `sd_mid_index'
	matrix M[`r'+1, `c'+2] = `sd_top_index'


	local r = `r'+2

}


//Export table as tex file
matrix list M
clear
getmata rownames
svmat  M, names(col)
tostring Bottom Middle Top N Countries, replace format(%15.2fc) force

foreach var in N Countries {
replace `var' = "" if `var' =="."
replace `var' = substr(`var', 1, strpos(`var', ".")-1)
}

gen n = _n
gen r = mod(n, 2)
foreach var in Bottom Middle Top{
	replace `var' = "("+ `var' +")" if r==0
	
}

drop r n

//Save table
cd ..
cd "output"
dataout, save("tableB2.tex") noauto tex replace

*NOTE: Need to adjust table manually for paper version


*===============================================================================
*TABLE B.3
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


quietly{
eststo clear
eststo m1: bootstrap, reps(1000) seed(1): reg abs_red_imp att_red_top
eststo m2: bootstrap, reps(1000) seed(1): reg abs_red_imp att_red_mid
eststo m3: bootstrap, reps(1000) seed(1): reg abs_red_imp att_red_bottom
eststo m4: bootstrap, reps(1000) seed(1): reg abs_red_imp att_red_top att_red_mid att_red_bottom
eststo m5: bootstrap, reps(1000) seed(1): reg abs_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR 
eststo m6: bootstrap, reps(1000) seed(1): reg abs_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "tableB3.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Absolute redistribution" , pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr



*===============================================================================
*TABLE B.4
*===============================================================================

//Import data
cd ..
cd "data"
use wvs.dta, clear

//Collapse to get one observation per country and year

collapse (mean) att_red_top  att_red_mid att_red_bottom att_red_top10  att_red_mid10 att_red_bottom10 att_red_toptert  att_red_midtert att_red_bottomtert , by(country year)


//Combute preferences SES groups for first and last year and time gap

foreach group in top mid bottom top10 mid10 bottom10 toptert midtert bottomtert{
	sort country year

	by country: egen first_year = min(year) if att_red_`group'!=.
	gen first_year_`group' = att_red_`group' if year == first_year

	by country: egen last_year = max(year) if att_red_`group'!=.
	gen last_year_`group' = att_red_`group' if year == last_year

	gen year_diff_`group' = last_year - first_year
	drop first_year last_year
}


//Collaps to get one observation per country_

collapse (firstnm) first_year_top last_year_top year_diff_top first_year_mid last_year_mid year_diff_mid first_year_bottom last_year_bottom year_diff_bottom first_year_top10 last_year_top10 year_diff_top10 first_year_mid10 last_year_mid10 year_diff_mid10 first_year_bottom10 last_year_bottom10 year_diff_bottom10 first_year_toptert last_year_toptert year_diff_toptert first_year_midtert last_year_midtert year_diff_midtert first_year_bottomtert last_year_bottomtert year_diff_bottomtert, by(country)


//Regress first on last year controling for time gap

qui{
gen last_year=.
gen first_year =.
gen year_gap =. 

label var first_year "First year"
label var year_gap "Time gap"

*Top 5%

replace last_year = last_year_top
replace first_year = first_year_top
replace year_gap = year_diff_top

eststo m1: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Middle 5%

replace last_year = last_year_mid
replace first_year = first_year_mid
replace year_gap = year_diff_mid

eststo m2: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Bottom 5%

replace last_year = last_year_bottom
replace first_year = first_year_bottom
replace year_gap = year_diff_bottom

eststo m3: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Top 10%

replace last_year = last_year_top10
replace first_year = first_year_top10
replace year_gap = year_diff_top10

eststo m4: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Middle 10%

replace last_year = last_year_mid10
replace first_year = first_year_mid10
replace year_gap = year_diff_mid10

eststo m5: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Bottom 10%

replace last_year = last_year_bottom10
replace first_year = first_year_bottom10
replace year_gap = year_diff_bottom10

eststo m6: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Top tertile

replace last_year = last_year_toptert
replace first_year = first_year_toptert
replace year_gap = year_diff_toptert

eststo m7: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Middle tertile

replace last_year = last_year_midtert
replace first_year = first_year_midtert
replace year_gap = year_diff_midtert

eststo m8: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap

*Bottom tertile

replace last_year = last_year_bottomtert
replace first_year = first_year_bottomtert
replace year_gap = year_diff_bottomtert

eststo m9: bootstrap, reps(1000) seed(1): reg last_year first_year year_gap
}


//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 using "tableB4.tex", replace constant  mgroups("Preferences for redistribution", pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mtitle("Top5\%" "Mid5\%" "Bot5\%" "Top10\%" "Mid10\%" "Bot10\%" "Top33\%" "Mid33\%" "Bot33\%")
	nonotes stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared")) 
	;
# delimit cr


*===============================================================================
*TABLE B.5
*===============================================================================


*WAVE 3 & 4

//Import data
cd ..
cd "data"
use redistribution_merged_wave34,clear

eststo clear
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt


*WAVE 5 & 6

//Import data
cd ..
cd "data"
use redistribution_merged_wave56,clear


eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt

//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 m4 using "tableB5.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Wave 3 \& 4"  "Wave 5 \& 6", pattern(1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr

*===============================================================================
*TABLE B.6
*===============================================================================


//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear

quietly{
eststo clear
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top10
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_mid10
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_bottom10
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top10 att_red_mid10 att_red_bottom10
eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top10 att_red_mid10 att_red_bottom10 lngdp lnpop dem_ANRR 
eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top10 att_red_mid10 att_red_bottom10 lngdp lnpop dem_ANRR gini_mkt
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "tableB6.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


*===============================================================================
*TABLE B.7
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


quietly{

eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_toptert
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_midtert
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_bottomtert
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_toptert att_red_midtert att_red_bottomtert
eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_toptert att_red_midtert att_red_bottomtert lngdp lnpop dem_ANRR
eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_toptert att_red_midtert att_red_bottomtert lngdp lnpop dem_ANRR gini_mkt
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "tableB7.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


*===============================================================================
*TABLE B.8
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


quietly{

eststo m1: bootstrap, reps(1000) seed(1): reg rel_red att_red_top
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red att_red_mid
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red att_red_bottom
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red att_red_top att_red_mid att_red_bottom
eststo m5: bootstrap, reps(1000) seed(1): reg rel_red att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR 
eststo m6: bootstrap, reps(1000) seed(1): reg rel_red att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
}


//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "tableB8.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution (non-imputed)" , pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


*===============================================================================
*TABLE B.9
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear

//Drop if negative relative redistribution
drop if rel_red_imp<0

quietly{

eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_mid
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_bottom
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom
eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR
eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
}


//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "tableB9.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


*===============================================================================
*TABLE B.10
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


//Income value: Include all countries


qui{
eststo clear
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_topincval
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_midincval
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_botincval
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_topincval att_red_midincval att_red_botincval
eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_topincval att_red_midincval att_red_botincval lngdp lnpop dem_ANRR 
eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_topincval att_red_midincval att_red_botincval lngdp lnpop dem_ANRR gini_mkt
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "tableB10.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr



*===============================================================================
*TABLE B.11
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


qui{
eststo clear

eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom if dem_ANRR==1
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop  gini_mkt if dem_ANRR==1
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom if dem_ANRR==0
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop  gini_mkt if dem_ANRR==0
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 m4  using "tableB11.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Democratic" "Nondemocratic", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


// Test for difference between coefficients


eststo dem: reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop  gini_mkt if dem_ANRR==1

eststo nondem: reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop  gini_mkt if dem_ANRR==0

suest dem nondem, vce(robust)
test [dem_mean]att_red_bottom=[nondem_mean]att_red_bottom


*===============================================================================
*TABLE B.12
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear

quietly{
eststo clear
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop gini_mkt democratic
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop  gini_mkt if democratic==1
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop  gini_mkt if democratic==0
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 using "tableB12.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes mtitles ("Full sample" "Democ." "NonDemoc." ) stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr



*===============================================================================
*TABLE B.13
*===============================================================================


//Import data
cd ..
cd "data"
use issp_merged.dta, clear

gen red_top =.
label var red_top "Top 5\%"
gen red_middle =.
label var red_middle "Middle 5\%"
gen red_bottom =. 
label var red_bottom "Bottom 5\%"

quietly{

replace red_top = att_red_top
replace red_middle = att_red_mid
replace red_bottom = att_red_bottom

eststo clear

eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

replace red_top = att_toptax_top
replace red_middle = att_toptax_mid
replace red_bottom = att_toptax_bottom

eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

replace red_top = att_ineq_top
replace red_middle = att_ineq_mid
replace red_bottom = att_ineq_bottom

eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

replace red_top = current_toptax_top
replace red_middle = current_toptax_mid
replace red_bottom = current_toptax_bottom

eststo m7: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m8: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)
	
}


//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m5 m6 m7 m8 m1 m2 m3 m4 using "tableB13.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups( "\shortstack{Attitude\\inequality\\(change)}" "\shortstack{Perception\\top taxes\\(change)}" "\shortstack{Attitude\\redistribution\\(level)}" "\shortstack{Attitude\\top taxes\\(level)}", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(ptopmid ptopbot pmidbot p r2 N, fmt(3 3 3 3 3 0) labels("Top=Middle" "Top=Bottom" "Middle=Bottom" "F-stat p-val" "R-squared"))
	;
# delimit cr



*===============================================================================
*TABLE B.14
*===============================================================================


//Import data
cd ..
cd "data"
use issp_merged.dta, clear

//Correlation of attitudes bottom

label var att_ineq_bottom "Att. inequality"
label var att_red_bottom "Att. redistribution"
label var att_toptax_bottom "Att. top taxes"
label var current_toptax_bottom "Perc. top taxes"


eststo corr: estpost correlate  att_ineq_bottom current_toptax_bottom  att_red_bottom  att_toptax_bottom ,  matrix


cd ..
cd "output"
# delimit ;
	qui esttab corr using "issp_corr_bott.tex", replace 
	not unstack compress noobs nonumbers nonotes label nostar
	;
# delimit cr



//Correlation of attitudes middle

label var att_ineq_mid "Att. inequality"
label var att_red_mid "Att. redistribution"
label var att_toptax_mid "Att. top taxes"
label var current_toptax_mid "Perc. top taxes"


eststo corr: estpost correlate  att_ineq_mid current_toptax_mid  att_red_mid  att_toptax_mid ,  matrix

cd ..
cd "output"
# delimit ;
	qui esttab corr using "issp_corr_mid.tex", replace 
	not unstack compress noobs nonumbers nonotes label nostar
	;
# delimit cr

//Correlation of attitudes top

label var att_ineq_top "Att. inequality"
label var att_red_top "Att. redistribution"
label var att_toptax_top "Att. top taxes"
label var current_toptax_top "Perc. top taxes"


eststo corr: estpost correlate  att_ineq_top current_toptax_top att_red_top att_toptax_top,  matrix

cd ..
cd "output"
# delimit ;
	qui esttab corr using "issp_corr_top.tex", replace 
	not unstack compress noobs nonumbers nonotes label nostar
	;
# delimit cr

//Combine panels of correlations and save

cd ..
cd "output"
include "https://raw.githubusercontent.com/steveofconnell/PanelCombine/master/PanelCombine.do"
panelcombine, use(issp_corr_top.tex issp_corr_mid.tex issp_corr_bott.tex)  columncount(5) paneltitles("Top 5\%" "Middle 5\%" "Bottom 5\%") save(tableB14.tex) cleanup



*===============================================================================
*TABLE B.15
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear

//Compute redistribution index

	
pca rel_red_imp tax_nonres socsec gini_disp, comp(1) blanks(0.3)
predict red_index2, score


quietly{
eststo clear

eststo m1: bootstrap, reps(1000) seed(1): reg tax_nonres att_red_top att_red_mid att_red_bottom
eststo m2: bootstrap, reps(1000) seed(1): reg tax_nonres att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
eststo m3: bootstrap, reps(1000) seed(1): reg red_index2 att_red_top att_red_mid att_red_bottom, robust
eststo m4: bootstrap, reps(1000) seed(1): reg red_index2 att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt

}

//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 m4 using "tableB15.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs nomtitle label mgroups("Tax non-mineral" "\shortstack{Redistribution\\Index 2}", pattern(1 0  1 0  1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes  stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr



*===============================================================================
*TABLE B.16
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


quiet{
eststo clear
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt 
estadd local legor "No" , replace

//Confidence in government
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt conf_gov
estadd local legor "No" , replace


//Moral universalism
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt trust_universal
estadd local legor "No" , replace


//Ethnic fractionalization
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt efindex
estadd local legor "No" , replace


//Include all

eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt conf_gov trust_universal  efindex 
estadd local legor "No" , replace

//Legal origin 
eststo m6: bootstrap, reps(1000) seed(1): reghdfe rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt , absorb (legor)
estadd local legor "Yes" , replace

}

//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 using "tableB16.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(legor p r2 N, fmt(0 3 3 0) labels("Legal origin FE" "F-stat p-val" "R-squared"))
	;
# delimit cr


*===============================================================================
*TABLE B.17
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


//Split sample into high vs. low loc of bottom class

sum belief_control_bottom, d
gen control_low = (belief_control_bottom <= r(p50)) if belief_control_bottom!=.
tab control_low, m


quietly{
	
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom if control_low==1
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR if control_low==1
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt if control_low==1
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom if control_low==0
eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR if control_low==0
eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt if control_low==0
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 m4 m5 m6 using "tableB17.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label 		mgroups("Low LOC (Bottom 5\%)" "High LOC (Bottom 5\%)", pattern(1 0 0 1 0 0 ) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


// Test for difference between coefficients

eststo lo: reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt if control_low==1
eststo hi: reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt if control_low==0

suest hi lo, vce(robust)
test [hi_mean]att_red_bottom=[lo_mean]att_red_bottom




*===============================================================================
*TABLE B.18
*===============================================================================

//Import data - only from 94 countries included in main analysis 
cd ..
cd "data"
use redistribution_merged,clear
reg rel_red_imp att_red_top, robust
keep country
keep if e(sample)==1
merge 1:m country using wvs.dta
drop if _merge==2
drop _merge

//Compute shares of political orientation

gen pol_left = (political >=8)
replace pol_left = . if political==.


gen pol_right = (political <=1)
replace pol_right = . if political ==.

gen pol_swing = (political<6 & political>3)
replace pol_swing = . if political ==.



qui{
gen share_left_bot =.
gen share_left_mid =.
gen share_left_top =.


gen share_right_bot =.
gen share_right_mid =.
gen share_right_top =.

gen share_swing_bot =.
gen share_swing_mid =.
gen share_swing_top =. 

gen pol_ratio_bot =.
gen pol_ratio_mid =.
gen pol_ratio_top =.

gen share_extreme_bot=.
gen share_extreme_mid=.
gen share_extreme_top=.

rename (top_index mid_index bottom_index) (top mid bot)

levelsof country, local(levels)			//Generates list with unique values of country
foreach l of local levels {
	foreach v in left right swing{
		foreach x in top mid bot{
			

	su pol_`v' if country == `l' & `x'==1, d       
	replace share_`v'_`x' = r(mean) if country == `l' 
		}

	}
	
	replace share_extreme_bot = (share_left_bot + share_right_bot)  if country == `l' 
	replace share_extreme_mid = (share_left_mid + share_right_mid)  if country == `l' 
	replace share_extreme_top = (share_left_top + share_right_top)  if country == `l' 
}
}

//Collapse data on country level

collapse (mean) pol_left pol_right share_left_bot share_left_mid share_left_top    share_right_bot share_right_mid share_right_top share_extreme_bot share_extreme_mid share_extreme_top share_swing_bot share_swing_mid share_swing_top, by(country)

//Test difference
ttest share_extreme_bot=share_extreme_mid
ttest share_extreme_bot=share_extreme_top
ttest share_extreme_mid=share_extreme_top

ttest share_swing_bot=share_swing_mid
ttest share_swing_bot=share_swing_top
ttest share_swing_mid=share_swing_top

//Create table
preserve
matrix M = J(6,4,.)
matrix colnames M = "Left" "Right" "Extreme" "Swing"
matrix rownames M = "Top 5%" "" "Middle 5%" "" "Bottom 5%" ""

mata
rownames = ("Top 5%" \ "" \ "Middle 5%" \ "" \ "Bottom 5%" \ "")
end


//Compute shares and fill into matrix

local c=1
local r=1

foreach x in top mid bot{
	sum share_left_`x'
	local share_left_`x' = round(r(mean), 0.01)
	local sd_share_left_`x' =round(r(sd), 0.01)

	sum share_right_`x'
	local share_right_`x' = round(r(mean), 0.01)
	local sd_share_right_`x' =round(r(sd), 0.01)
	
	sum share_extreme_`x'
	local share_extreme_`x' = round(r(mean), 0.01)
	local sd_share_extreme_`x' =round(r(sd), 0.01)
	
	sum share_swing_`x'
	local share_swing_`x' = round(r(mean), 0.01)
	local sd_share_swing_`x' =round(r(sd), 0.01)
	
	matrix M[`r', 1] = `share_left_`x''
	matrix M[`r'+1, 1] = `sd_share_left_`x''
	matrix M[`r', 2] = `share_right_`x''
	matrix M[`r'+1, 2] = `sd_share_right_`x''
	matrix M[`r', 3] = `share_extreme_`x''
	matrix M[`r'+1, 3] = `sd_share_extreme_`x''
	matrix M[`r', 4] = `share_swing_`x''
	matrix M[`r'+1, 4] = `sd_share_swing_`x''
	
	local r = `r'+2
}

//Export table as tex file
matrix list M
clear
getmata rownames
svmat  M, names(col)
tostring Left Right Extreme Swing, replace format(%15.2fc) force



gen n = _n
gen r = mod(n, 2)
foreach var in Left Right Extreme Swing{
	replace `var' = "("+ `var' +")" if r==0
	
}

drop r n

//Save table
cd ..
cd "output"
dataout, save("tableB18.tex") noauto tex replace

*NOTE: Need to adjust table manually for paper version
restore

*===============================================================================
*TABLE B.19
*===============================================================================

*Note: Need to run code for B.18 first to creat political view shares

//Split sample based on share of bottom with extreme views

sum share_extreme_bot, d
gen bot_extreme = (share_extreme_bot>`r(p50)')
replace bot_extreme=. if share_extreme_bot==.

keep country bot_extreme 

cd ..
cd "data"
save bot_extreme, replace
use redistribution_merged,clear
merge 1:1 country using bot_extreme.dta


qui{
eststo clear



eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom if bot_extreme==1
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR  gini_mkt if bot_extreme==1
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom if bot_extreme==0
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR  gini_mkt if bot_extreme==0

}


//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 m4  using "tableB19.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("High Share Extreme" "Low Share Extreme", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


//Test difference of coefficients

eststo hiextr: reg rel_red_imp att_red_top att_red_mid att_red_bottom  lngdp lnpop dem_ANRR  gini_mkt  if bot_extreme==1
eststo loextr: reg rel_red_imp att_red_top att_red_mid att_red_bottom  lngdp lnpop dem_ANRR  gini_mkt  if bot_extreme==0

suest hiextr loextr, vce(robust)
test [hiextr_mean]att_red_bottom=[loextr_mean]att_red_bottom


*===============================================================================
*TABLE B.20
*===============================================================================

//Import data - only from 94 countries included in main analysis 
cd ..
cd "data"
use redistribution_merged,clear
reg rel_red_imp att_red_top, robust
keep country
keep if e(sample)==1
merge 1:m country using wvs.dta
drop if _merge==2
drop _merge

//Label variables

label variable top_index "Top 5\%"
label variable mid_index "Middle 5\%"
label variable bottom_index "Bottom 5\%"

//Regress political party membership on top and bottom index  

qui{
eststo clear
eststo m1: reghdfe polac_boycott top_index mid_index bottom_index, absorb(wave country) vce(cluster country)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)
					estfe m1,labels(wave "Wave FE" country "Country FE")
					
										
eststo m2: reghdfe polac_strike top_index mid_index bottom_index, absorb(wave country) vce(cluster country)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)
					estfe m2,labels(wave "Wave FE" country "Country FE")
					
					
eststo m3: reghdfe polac_demo top_index mid_index bottom_index, absorb(wave country) vce(cluster country)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)
					estfe m3,labels(wave "Wave FE" country "Country FE")
					
eststo m4: reghdfe polac_petition top_index mid_index bottom_index, absorb(wave country) vce(cluster country)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)
					estfe m4,labels(wave "Wave FE" country "Country FE")
					
eststo m5: reghdfe polpar_index top_index mid_index bottom_index, absorb(wave country) vce(cluster country)
					gdistinct country if e(sample)==1
					estadd scalar country = r(ndistinct)
					estfe m5,labels(wave "Wave FE" country "Country FE")
}					

//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 using "tableB20.tex", replace keep(top_index mid_index bottom_index) constant ///
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs mtitle( "Boycotts" "Strike" "Demonstration" "Petition" "Index") label  indicate(`r(indicate_fe)') ///
	nonotes stardetach nostar stats(r2 N country, fmt(3 0 0) labels("R-squared" "N" "Countries"))
	;
# delimit cr




*===============================================================================
*TABLE B.21
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear

quietly{
eststo clear
eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom
eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom polpar_top polpar_mid polpar_bottom
eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom polpar_top polpar_mid polpar_bottom lngdp lnpop dem_ANRR
eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp att_red_top att_red_mid att_red_bottom polpar_top polpar_mid polpar_bottom lngdp lnpop dem_ANRR gini_mkt
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	qui esttab m1 m2 m3 m4 using "tableB21.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


*===============================================================================
*TABLE B.22
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


eststo clear
quietly{


eststo m1: bootstrap, reps(1000) seed(1): reg AR_4y att_red_top att_red_mid att_red_bottom
eststo m2: bootstrap, reps(1000) seed(1): reg AR_4y att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
eststo m3: bootstrap, reps(1000) seed(1): reg AR_3y att_red_top att_red_mid att_red_bottom
eststo m4: bootstrap, reps(1000) seed(1): reg AR_3y att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
eststo m5: bootstrap, reps(1000) seed(1): reg AR_2y att_red_top att_red_mid att_red_bottom
eststo m6: bootstrap, reps(1000) seed(1): reg AR_2y att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
eststo m7: bootstrap, reps(1000) seed(1): reg AR_y att_red_top att_red_mid att_red_bottom
eststo m8: bootstrap, reps(1000) seed(1): reg AR_y att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
}

//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m1 m2 m3 m4 m5 m6 m7 m8 using "tableB22.tex", replace
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs nomtitle label 
	mgroups("\shortstack{Avg. tax rate\\for incomes =\\4x GDP p.c.}" "\shortstack{Avg. tax rate\\for incomes =\\3x GDP p.c.}" "\shortstack{Avg. tax rate\\for incomes =\\2x GDP p.c.}" "\shortstack{Avg. tax rate\\for incomes =\\GDP p.c.}", pattern(1 0 1 0 1 0 1 0) 		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes stardetach nostar stats(p r2 N, fmt(3 3 0) labels("F-stat p-val" "R-squared"))
	;
# delimit cr


// Test for difference between coefficients


eststo top: reg AR_4y att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt
eststo avrg: reg AR_y att_red_top att_red_mid att_red_bottom lngdp lnpop dem_ANRR gini_mkt

suest top avrg, vce(robust)
test [top_mean]att_red_bottom=[avrg_mean]att_red_bottom



*===============================================================================
*TABLE B.23
*===============================================================================

//Import data - only from 94 countries included in main analysis 
cd ..
cd "data"
use redistribution_merged,clear
reg rel_red_imp att_red_top, robust
keep country
keep if e(sample)==1
merge 1:m country using wvs.dta
drop if _merge==2
drop _merge



label var top_index "Top 5\%"
label var mid_index "Middle 5\%"
label var bottom_index "Bottom 5\%"


//Compute and save table
cd ..
cd "output"
eststo clear
eststo m1: reghdfe prob_count_poverty top_index mid_index bottom_index , absorb(country) vce(robust)
	gdistinct country if e(sample)==1
	estadd scalar country = r(ndistinct)
eststo m2: reghdfe prob_count_discr top_index mid_index bottom_index , absorb(country) vce(robust)
	gdistinct country if e(sample)==1
	estadd scalar country = r(ndistinct)
eststo m3: reghdfe prob_count_sanit top_index mid_index bottom_index , absorb(country) vce(robust)
	gdistinct country if e(sample)==1
	estadd scalar country = r(ndistinct)
eststo m4: reghdfe prob_count_educ top_index mid_index bottom_index , absorb(country) vce(robust)
	gdistinct country if e(sample)==1
	estadd scalar country = r(ndistinct)
eststo m5: reghdfe prob_count_environ top_index mid_index bottom_index , absorb(country) vce(robust)
	gdistinct country if e(sample)==1
	estadd scalar country = r(ndistinct)

estfe m*, labels(country "Country FE")


# delimit ;
	qui esttab m1 m2 m3 m4 m5 using "tableB23.tex", replace keep(top_index mid_index bottom_index) constant ///
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mtitles("Poverty" "Discrimination" "Sanitation" "Education" "Environment") indicate(`r(indicate_fe)') ///
	nonotes stardetach nostar stats( r2 N country, fmt( 3 0 0) labels( "R-squared" "N" "Countries"))
	;
# delimit cr





*===============================================================================
*TABLE B.24
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged_weight.dta, clear


//Run regressions

quietly{
eststo clear
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
	esttab m1 m2 m3 m4 m5 m6 using "tableB24.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups("Relative redistribution" , pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(ptopmid ptopbot pmidbot p r2 N, fmt(3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "F-stat p-val" "R-squared"))
	;
# delimit cr


*===============================================================================
*TABLE B.25
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged_weight.dta, clear

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
	qui esttab m3 m7  m1 m5 m2 m6  m4 m8   using "tableB25.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs nomtitles mgroups("\shortstack{Gini\\post-tax}" "Taxes" "\shortstack{Social\\security}" "\shortstack{Redistribution\\index}" , pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )label 
	nonotes  stardetach nostar stats(ptopmid ptopbot pmidbot p r2 N, fmt(3 3 3 3 3 0) labels("p-val Top=Middle" "p-val Top=Bottom" "p-val Middle=Bottom" "F-stat p-val" "R-squared"))
	;
# delimit cr



*===============================================================================
*TABLE B.26
*===============================================================================


//Import data
cd ..
cd "data"
use issp_merged_weight.dta, clear

gen red_top =.
label var red_top "Top 5\%"
gen red_middle =.
label var red_middle "Middle 5\%"
gen red_bottom =. 
label var red_bottom "Bottom 5\%"

quietly{

replace red_top = att_red_top
replace red_middle = att_red_mid
replace red_bottom = att_red_bottom

eststo clear

eststo m1: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m2: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

replace red_top = att_toptax_top
replace red_middle = att_toptax_mid
replace red_bottom = att_toptax_bottom

eststo m3: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m4: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

replace red_top = att_ineq_top
replace red_middle = att_ineq_mid
replace red_bottom = att_ineq_bottom

eststo m5: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m6: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

replace red_top = current_toptax_top
replace red_middle = current_toptax_mid
replace red_bottom = current_toptax_bottom

eststo m7: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)

eststo m8: bootstrap, reps(1000) seed(1): reg rel_red_imp red_top red_middle red_bottom lngdp lnpop dem_ANRR gini_mkt

	test red_top = red_middle
	estadd scalar ptopmid = r(p)
	test red_top = red_bottom
	estadd scalar ptopbot = r(p)
	test red_middle = red_bottom
	estadd scalar pmidbot = r(p)
	
}


//Compute and save table
cd ..
cd "output"
# delimit ;
	esttab m5 m6 m7 m8 m1 m2 m3 m4 using "tableB26.tex", replace 
	noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label mgroups( "\shortstack{Attitude\\inequality\\(change)}" "\shortstack{Perception\\top taxes\\(change)}" "\shortstack{Attitude\\redistribution\\(level)}" "\shortstack{Attitude\\top taxes\\(level)}", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )
	nonotes nomtitles stardetach nostar stats(ptopmid ptopbot pmidbot p r2 N, fmt(3 3 3 3 3 0) labels("Top=Middle" "Top=Bottom" "Middle=Bottom" "F-stat p-val" "R-squared"))
	;
# delimit cr


