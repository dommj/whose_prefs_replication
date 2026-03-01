*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Data Cleaning and Merging for ISSP data
*Last update: 28.02.23

*===============================================================================

//Settings

set more off
clear all
set maxvar 15000, permanently
set matsize 5000
set linesize 80  


//Import WVS data
cd ..
cd "data"
use issp_cumul.dta, clear

//Additional packages

*ssc install kountry

*===============================================================================
*CLEAN WAVE 1992 and 1999
*===============================================================================


//Rename Country 

gen country = V5
kountry V5, from(iso3n) m
rename NAMES_STD country_str
replace country_str = "Slovakia" if country_st == "Slovak Republic"

//Year of survey
gen year = V4	 
tab year, m	

//Weighting variable
rename WEIGHT weight

//Drop data from wave 1987 and 2009

drop if year==1987
drop if year==2009

*SES

//Education 

gen educ = DEGREE
replace educ = . if DEGREE ==.n

//Social class (subjective)
gen class = V66 
replace class = . if class ==.a
label variable class "Social class (1=Lower class, 6=upper class)"

//Social group (subjective)
gen group = TOPBOT 
replace group =. if TOPBOT ==.d | TOPBOT ==.n | TOPBOT ==.r
label variable class "Social group (1=lowest, 10=Highest)"



*ATTITUTDE TOWARDS REDISTRIBTUION


//Attitudes toward income inequality

gen att_ineq = V32 // Income differences in country are too large
replace att_ineq = . if V32 ==.a
replace att_ineq = abs(att_ineq-5) //4 = strongly agree
label variable att_ineq "Income differences in country are too large (4=strongly agree)"

//Attitudes toward redistribution
gen att_red = V33 					// Government should reduce income differences
replace att_red = . if V33 ==.a
replace att_red = abs(att_red-5) //4 = strongly agree
label variable att_red "Goverment should reduce income differences (4=strongly agree)"


//Attitudes towards high income taxes

gen att_toptax = V39 // Should people with high incomes pay more taxes
replace att_toptax = . if V39 ==.a
replace att_toptax = abs(att_toptax-5) //4 = Much larger share

//Current taxes for high incomes

gen current_toptax = V40 //How are taxes in country for those with high incomes 
replace current_toptax = . if V40==.a
replace current_toptax = current_toptax-1 // 4 = much too low


//Save data

keep country_str weight educ country year class group att_ineq att_red att_toptax current_toptax  


save issp92.dta, replace


*===============================================================================
*CLEAN AND APPEND WAVE 2009
*==============================================================================

//Import WVS data
cd ..
cd "data"
use issp_2009.dta, clear

//Rename Country 

gen country = V5
kountry V5, from(iso3n) m
rename NAMES_STD country_str

replace country_str = "Slovakia" if country_st == "Slovak Republic"
replace country_str = "Taiwan" if country_st == "158"
replace country_str = "Korea" if country_str == "South Korea"

//Year of survey
gen year = 2009

//Weighting variable
rename WEIGHT weight

*SES

//Education 

gen educ = DEGREE 
replace educ = . if DEGREE ==8 | DEGREE ==9


//Social class (subjective)
gen class = V66 
replace class = . if class ==0 | class ==8 | class ==9
label variable class "Social class (1=Lower class, 6=upper class)"

//Social group (subjective)
gen group = V44 
replace group =. if group ==97 | group ==98 | group ==99
label variable class "Social group (1=lowest, 10=Highest)"


*ATTITUTDE TOWARDS REDISTRIBTUION

//Attitudes toward income inequality

gen att_ineq = V32 // Income differences in country are too large
replace att_ineq = . if V32 >=8
replace att_ineq = abs(att_ineq-5) //4 = strongly agree
label variable att_ineq "Income differences in country are too large (4=strongly agree)"

//Attitudes toward redistribution
gen att_red = V33 					// Government should reduce income differences
replace att_red = . if V33 >=8
replace att_red = abs(att_red-5) //4 = strongly agree
label variable att_red "Goverment should reduce income differences (4=strongly agree)"


//Attitudes towards high income taxes

gen att_toptax = V36 // Should people with high incomes pay more taxes
replace att_toptax = . if V39 >=8
replace att_toptax = abs(att_toptax-5) //4 = Much larger share

//Current taxes for high incomes

gen current_toptax = V37 //How are taxes in country for those with high incomes 
replace current_toptax = . if V37>=8
replace current_toptax = current_toptax-1 // 4 = much too low


//Save data

keep country_str weight educ country year  class group att_ineq att_red att_toptax current_toptax  
gen cumul = 1

save issp09.dta, replace

//Append wave 2009

use issp92, clear
append using issp09


*SES INDEX

//PCA for social class, income and education
	
pca class group educ, comp(1) blanks(0.3)
predict index, score
label variable index "Social Class Index"

// Top 5% by country based on index
qui{
gen top_index =.
levelsof country, local(levels)			//Generates list with unique values of country
foreach l of local levels {
	su index if country == `l', d       //Summarize index for a given country
	replace top_index = (index >= r(p95)) if country == `l' & index!=.
}

// Bottom 5% by country based on index
gen bottom_index =.
levelsof country, local(levels)
foreach l of local levels {
	su index if country == `l', d
	replace bottom_index = (index <= r(p5)) if country == `l' & index!=.
}


// Middle 5% citizen by country based on index
gen mid_index =.
bysort country: egen p47 = pctile(index), p(47)
bysort country: egen p53 = pctile(index), p(53)
levelsof country, local(levels)
foreach l of local levels {
	su index if country == `l', d
	replace mid_index = (index >= p47 & index < p53) if country == `l' & index!=.
}



// Top 10% by country based on index
gen top_index10 =.
levelsof country, local(levels)
foreach l of local levels {
	su index if country == `l', d
	replace top_index10 = (index >= r(p90)) if country == `l' & index!=.
}

// Bottom 10% by country based on index
gen bottom_index10 =.
levelsof country, local(levels)
foreach l of local levels {
	su index if country == `l', d
	replace bottom_index10 = (index <= r(p10)) if country == `l' & index!=.
}

// Middle 10% citizen by country based on index
gen mid_index10 =.
bysort country: egen p45 = pctile(index), p(45)
bysort country: egen p55 = pctile(index), p(55)
levelsof country, local(levels)
foreach l of local levels {
	su index if country == `l', d
	replace mid_index10 = (index >= p45 & index < p55) if country == `l' & index!=.
	}

}


// Top, middle and bottom 33% by country based on index

*Need to install egenmore

egen tert_index = xtile(index), by(country) nq(3)

gen top_indextert = 1 if tert_index==3
gen mid_indextert = 1 if tert_index==2
gen bottom_indextert = 1 if tert_index==1


*REDISTRIBUTION PREFERENCES OF SES GROUPS



// Attidudes of 5% SES groups
foreach var in  att_ineq att_red att_toptax current_toptax{
    gen `var'_top = `var' if top_index == 1
	gen `var'_mid = `var' if mid_index == 1
	gen `var'_bottom = `var' if bottom_index == 1
}

// Attidudes of 10% SES groups
foreach var in  att_ineq att_red att_toptax current_toptax{
    gen `var'_top10 = `var' if top_index10 == 1
	gen `var'_mid10 = `var' if mid_index10 == 1
	gen `var'_bottom10 = `var' if bottom_index10 == 1
}


// Attidudes of tercile SES groups
foreach var in  att_ineq att_red att_toptax current_toptax{
    gen `var'_toptert = `var' if top_indextert == 1
	gen `var'_midtert = `var' if mid_indextert == 1
	gen `var'_bottomtert = `var' if bottom_indextert == 1
}


*===============================================================================
*CONSTRUCTION OF WVS MAIN DATA SET
*===============================================================================

* Keep newly created variables 

keep country country_str year weight educ class group att_ineq att_red att_toptax current_toptax cumul index top_index bottom_index mid_index top_index10 bottom_index10 mid_index10 tert_index top_indextert mid_indextert bottom_indextert att_ineq_top att_ineq_mid att_ineq_bottom att_red_top att_red_mid att_red_bottom att_toptax_top att_toptax_mid att_toptax_bottom current_toptax_top current_toptax_mid current_toptax_bottom att_ineq_top10 att_ineq_mid10 att_ineq_bottom10 att_red_top10 att_red_mid10 att_red_bottom10 att_toptax_top10 att_toptax_mid10 att_toptax_bottom10 current_toptax_top10 current_toptax_mid10 current_toptax_bottom10 att_ineq_toptert att_ineq_midtert att_ineq_bottomtert att_red_toptert att_red_midtert att_red_bottomtert att_toptax_toptert att_toptax_midtert att_toptax_bottomtert current_toptax_toptert current_toptax_midtert current_toptax_bottomtert

//Save data
save issp.dta, replace


preserve
//Aggregate data over waves by country
gen sample=1 if index!=.


collapse (mean) educ class group att_ineq att_red att_toptax current_toptax cumul index top_index bottom_index mid_index top_index10 bottom_index10 mid_index10 tert_index top_indextert mid_indextert bottom_indextert att_ineq_top att_ineq_mid att_ineq_bottom att_red_top att_red_mid att_red_bottom att_toptax_top att_toptax_mid att_toptax_bottom current_toptax_top current_toptax_mid current_toptax_bottom att_ineq_top10 att_ineq_mid10 att_ineq_bottom10 att_red_top10 att_red_mid10 att_red_bottom10 att_toptax_top10 att_toptax_mid10 att_toptax_bottom10 current_toptax_top10 current_toptax_mid10 current_toptax_bottom10 att_ineq_toptert att_ineq_midtert att_ineq_bottomtert att_red_toptert att_red_midtert att_red_bottomtert att_toptax_toptert att_toptax_midtert att_toptax_bottomtert current_toptax_toptert current_toptax_midtert current_toptax_bottomtert ///
	(lastnm) year  country_str ///
	(sum) n_sample=sample n_top=top_index  n_mid=mid_index n_bottom=bottom_index  n_top10=top_index10  n_mid10=mid_index10 n_bottom10=bottom_index10  n_toptert=top_indextert n_midtert=mid_indextert n_bottomtert=bottom_indextert, by(country)


rename year year_recent


// Set preferences for redistribution to missing if based on less than 30 observarions*


tab country_str if n_top<30 & index!=.		 // no countries
tab country_str if n_mid<30 & index!=.		// Canada
tab country_str if n_bottom<30 & index!=.		// no countries

tab country_str if n_top10<30	& index!=.	 // no countries
tab country_str if n_mid10<30 & index!=.		// no countries
tab country_str if n_bottom10<30 & index!=.		// no countries

tab country_str if n_toptert<30 & index!=.		 // no countries
tab country_str if n_midtert<30 & index!=.		// no countries
tab country_str if n_bottomtert<30 & index!=.		// no countries

*Note: Only for mid 5% class there are countries with less than 30 observations

foreach var in att_ineq_mid att_red_mid att_toptax_mid current_toptax_mid{
    replace `var' =. if n_mid<30
}

//Save data
save issp_avg.dta, replace
restore



preserve
//Aggregate data over waves by country using survey weights
gen sample=1 if index!=.


collapse (mean) educ class group att_ineq att_red att_toptax current_toptax cumul index top_index bottom_index mid_index top_index10 bottom_index10 mid_index10 tert_index top_indextert mid_indextert bottom_indextert att_ineq_top att_ineq_mid att_ineq_bottom att_red_top att_red_mid att_red_bottom att_toptax_top att_toptax_mid att_toptax_bottom current_toptax_top current_toptax_mid current_toptax_bottom att_ineq_top10 att_ineq_mid10 att_ineq_bottom10 att_red_top10 att_red_mid10 att_red_bottom10 att_toptax_top10 att_toptax_mid10 att_toptax_bottom10 current_toptax_top10 current_toptax_mid10 current_toptax_bottom10 att_ineq_toptert att_ineq_midtert att_ineq_bottomtert att_red_toptert att_red_midtert att_red_bottomtert att_toptax_toptert att_toptax_midtert att_toptax_bottomtert current_toptax_toptert current_toptax_midtert current_toptax_bottomtert ///
	(lastnm) year  country_str ///
	(sum) n_sample=sample n_top=top_index  n_mid=mid_index n_bottom=bottom_index  n_top10=top_index10  n_mid10=mid_index10 n_bottom10=bottom_index10  n_toptert=top_indextert n_midtert=mid_indextert n_bottomtert=bottom_indextert [pw=weight], by(country)


rename year year_recent


// Set preferences for redistribution to missing if based on less than 30 observarions*


foreach var in att_ineq_mid att_red_mid att_toptax_mid current_toptax_mid{
    replace `var' =. if n_mid<30
}

//Save data
save issp_avg_weight.dta, replace
restore



*===============================================================================
*MERGE WVS WITH SWIID
*===============================================================================


//Import SWIID data
import delimited "swiid8_3_summary.csv", clear


//Compute relative redistribution 

gen rel_red_imp = 100*(gini_mkt - gini_disp)/gini_mkt


//Compute absolute difference in gini 
gen abs_red_imp = gini_mkt - gini_disp


//Keep years closest to 2010

gsort country -year
gen distance2010=abs(year-2010)
bysort country: egen mindistance2010=min(distance2010)
sum mindistance, d
keep if distance2010==mindistance2010
drop distance2010 mindistance2010

//Indicator of year
rename year year_swiid
rename country country_str

// Save data
save swiid_prep.dta, replace


//Merge IVS with SWIID

use issp_avg.dta, clear
merge m:1 country_str using swiid_prep.dta
drop if _merge!=3
drop _merge


//Save data
save issp_merged.dta, replace

//Merge weighted IVS with SWIID

use issp_avg_weight.dta, clear
merge m:1 country_str using swiid_prep.dta
drop if _merge!=3
drop _merge


//Save data
save issp_merged_weight.dta, replace


*===============================================================================
*MERGE WITH IMF GDP AND POPULATION DATA 
*===============================================================================


*Note: As the first wave of the ISSP data is from 1992, we use data for
*control variables before 1992. (If missing, we use data after 1992.)

*GDP DATA BEFORE 1992


//Import data
import excel using gdp_percapita_ppp.xls, firstrow clear

//Destring variables (convert missings)

destring gdp_pc_ppp1980-gdp_pc_ppp2024,replace force

//Reshape long (one observation per year)
reshape long gdp_pc_ppp, i(country) j(year)

//Keep if before 1992
drop if year>=1992
drop if gdp_pc_ppp==.
gsort country -year

//Generate index for how close year is to 1992 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1992
keep if id<=1
drop id


//Manually adjust country names

sort country
replace country="China" if country=="China, People's Republic of"
replace country="Hong Kong" if country=="Hong Kong SAR"
replace country="Korea" if country=="Korea, Republic of"
replace country="Kyrgyzstan" if country=="Kyrgyz Republic"
replace country="Russia" if country=="Russian Federation"
replace country="Slovakia" if country=="Slovak Republic"
replace country="Taiwan" if country=="Taiwan Province of China"
replace country="Macedonia" if country=="North Macedonia "

rename country country_str
rename year year_imf_gdp

//Save data
save imf_gdp_pre92,replace

//Merge with datasets

foreach file in issp_merged issp_merged_weight{
use `file',clear
merge 1:1 country_str using imf_gdp_pre92.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge


//Save data
save `file',replace
}


*GDP DATA AFTER 1992


//Import data
import excel using gdp_percapita_ppp.xls, firstrow clear

//Destring variables (convert missings)

destring gdp_pc_ppp1980-gdp_pc_ppp2024,replace force

//Reshape long (one observation per year)
reshape long gdp_pc_ppp, i(country) j(year)

//Keep if after 1992
keep if year>=1992
drop if gdp_pc_ppp==.
sort country -year

//Generate index for how close year is to 1992 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1992
keep if id<=1
drop id


//Manually adjust country names

sort country
replace country="China" if country=="China, People's Republic of"
replace country="Hong Kong" if country=="Hong Kong SAR"
replace country="Korea" if country=="Korea, Republic of"
replace country="Kyrgyzstan" if country=="Kyrgyz Republic"
replace country="Russia" if country=="Russian Federation"
replace country="Slovakia" if country=="Slovak Republic"
replace country="Taiwan" if country=="Taiwan Province of China"
replace country="Macedonia" if country=="North Macedonia "

rename country country_str
rename year year_imf_gdp

//Save data
save imf_gdp_post92,replace

//Merge with datasets

foreach file in issp_merged issp_merged_weight{
use `file',clear
merge 1:1 country_str using imf_gdp_post92.dta, update
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Save data
save `file', replace
}



*POPULATION DATA BEFORE 1992

//Import data
import excel using imf_population.xls, firstrow clear

//Destring variables (convert missings)

destring population1980-population2024,replace force

//Reshape long (one observation per year)
reshape long population, i(country_str) j(year)

//Keep if before 1992
drop if year>=1992
drop if population==.
gsort country_str -year

//Generate index for how close year is to 1992 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1992
keep if id<=1
drop id


//Manually adjust country names

sort country_str
replace country_str="China" if country=="China, People's Republic of"
replace country_str="Hong Kong" if country=="Hong Kong SAR"
replace country_str="Korea" if country=="Korea, Republic of"
replace country_str="Kyrgyzstan" if country=="Kyrgyz Republic"
replace country_str="Russia" if country=="Russian Federation"
replace country_str="Slovakia" if country=="Slovak Republic"
replace country_str="Taiwan" if country=="Taiwan Province of China"
replace country_str="Macedonia" if country=="North Macedonia "

rename year year_imf_pop

//Save data
save imf_pop_pre92,replace

//Merge with datasets

foreach file in issp_merged issp_merged_weight{
use `file',clear
merge 1:1 country_str using imf_pop_pre92.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge


//Save data
save `file',replace
}


*POPULATION DATA AFTER 1992

//Import data
import excel using imf_population.xls, firstrow clear

//Destring variables (convert missings)

destring population1980-population2024,replace force

//Reshape long (one observation per year)
reshape long population, i(country_str) j(year)

//Keep if before 1992
keep if year>=1992
drop if population==.
sort country_str -year

//Generate index for how close year is to 1992 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1992
keep if id<=1
drop id

//Manually adjust country names

sort country_str
replace country_str="China" if country=="China, People's Republic of"
replace country_str="Hong Kong" if country=="Hong Kong SAR"
replace country_str="Korea" if country=="Korea, Republic of"
replace country_str="Kyrgyzstan" if country=="Kyrgyz Republic"
replace country_str="Russia" if country=="Russian Federation"
replace country_str="Slovakia" if country=="Slovak Republic"
replace country_str="Taiwan" if country=="Taiwan Province of China"
replace country_str="Macedonia" if country=="North Macedonia "

rename year year_imf_pop

//Save data
save imf_pop_post92,replace

//Merge with datasets

foreach file in issp_merged issp_merged_weight{
use `file',clear
merge 1:1 country_str using imf_pop_post92.dta,update
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Save data
save `file', replace
}
 

*===============================================================================
*MERGE WITH DEMOCRACY MEASURE
*===============================================================================

*Note: We follow Acemoglu et al. (2019) to compute a democracy measure

//Import data
use DDCGdata_final,clear

//Only keep relevant variables
keep country_name wbcode year dem
drop if dem==.

//Keep if observations for 1991
keep if year==1991

//Rename country string and year

replace country_name="Bosnia and Herzegovina" if country_name=="Bosnia & Herzegovina"
replace country_name="Slovakia" if country_name=="Slovak Republic"
replace country_name="Iran" if country_name=="Iran, I.R. of"
replace country_name="Kyrgyzstan" if country_name=="Kyrgyz Republic"
replace country_name="Macedonia" if country_name=="Macedonia, FYR"
replace country_name="Yemen" if country_name=="Yemen, Republic of"
replace country_name="Venezuela" if country_name=="Venezuela, Rep. Bol."


*Note: For Serbia & Montenegro create two observations, as country has split into Serbia and Montenegro after 2006
expand 2 if country_name == "Serbia & Montenegro", gen(dup)
replace country_name="Serbia" if country_name=="Serbia & Montenegro" & dup==0
replace country_name="Montenegro" if country_name=="Serbia & Montenegro" & dup==1
drop dup

rename country_name country_str
rename year year_dem_ANRR
rename dem dem_ANRR
label variable dem_ANRR "Democracy"

//Save data
save dem_ANRR,replace

//Merge with datasets

foreach file in issp_merged issp_merged_weight{
use `file',clear
merge 1:1 country_str using dem_ANRR.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Save data
save `file',replace
}


*==============================================================================
*GENERATE AND LABEL NEW VARIABLES
*==============================================================================

foreach file in issp_merged issp_merged_weight{
use `file', clear	
//Generate log gdp and pop

gen lngdp=ln(gdp_pc_ppp)
gen lnpop=ln(population)

//Label variables 

 
foreach var in  att_ineq att_red att_toptax current_toptax{
	label var `var'_top "Top 5\%"
	label var `var'_mid "Middle 5\%"
	label var `var'_bottom "Bottom 5\%"
	label var `var'_top10 "Top 10\%"
	label var `var'_mid10 "Middle 10\%"
	label var `var'_bottom10 "Bottom 10\%"
	label var `var'_toptert "Top tertile"
	label var `var'_midtert "Middle tertile"
	label var `var'_bottomtert "Bottom tertile"
}
 
label var rel_red_im "Relative Redistribution"
label var abs_red_imp "Absolute Redistribution"
label var lngdp "ln(GDP per capita)"
label var lnpop "ln(Population)"
label var gini_mkt "Gini pre-tax"


 
//Save final data
save `file',replace
}
