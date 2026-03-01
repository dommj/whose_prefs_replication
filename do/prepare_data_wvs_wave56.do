*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Data Cleaning for waves 5 and 6
*Last update: 27.02.23

*===============================================================================

//Settings

set more off
clear all
set maxvar 15000, permanently
set matsize 5000
set linesize 80  

//Additional packages

*ssc install egenmore

//Import WVS data
cd ..
cd "data"
use WVS_TimeSeries_4_0.dta, clear

//Rename weighting variable
rename S017 weight

//Rename country variable
rename S003 country
decode country, gen(country_str)


//Standardize country labels (i.e. naming is based on SWIID)
replace country_str="Bosnia and Herzegovina" if country_str=="Bosnia Herzegovina"
replace country_str = "Czech Republic" 	if country_str == "Czechia"
replace country_str = "Dominican Republic" 	if country_str == "Dominican Rep."
replace country_str = "Palestinian Territories" if country_str == "Palestine"
replace country_str = "Korea" 	if country_str == "South Korea"
replace country_str = "Hong Kong" 	if country_str == "Hong Kong SAR"
replace country_str = "Macau" 	if country_str == "Macau SAR"
replace country_str = "Macedonia" 	if country_str == "North Macedonia"
replace country_str = "Taiwan" 	if country_str == "Taiwan ROC"


*===============================================================================
*CONSTRUCTION OF VARIABLES
*===============================================================================


*TIME VARIABLES

gen year = S020	 

gen country_year = S025	

gen wave = S002VS	

egen wave_recent = max(wave), by(country)

//Restrict Sample to wave 5 and 6

keep if wave >4

drop if wave >6


*Note: For Haiti observations are also from 2016
**************************
*SOCIO-DEMOGRAPHICS


*SES

//Social class (subjective)
gen class = X045 
replace class = . if X045<1
label variable class "Social class (5=Lower class)"

//Income group (subjective)
gen income = X047_WVS 
replace income = . if X047_WVS<1
label variable class "Income group (10=Highest)"

//Education
gen educ = X025
replace educ = . if X025<1
label variable educ "Education (8=University)"


*ATTITUTDE TOWARDS REDISTRIBTUION

gen att_red = E035 			
replace att_red = abs(att_red-10)	// 0 = We need larger income differences as incentives, 9 = Incomes should be made more equal
replace att_red =. if E035<1
label variable att_red "Red. pref. (9=Equality)"


*SES INDEX

//PCA for social class, income and education
	
pca class income educ, comp(1) blanks(0.3)
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

egen tert_index = xtile(index), by(country) nq(3)
gen top_indextert = 1 if tert_index==3
gen mid_indextert = 1 if tert_index==2
gen bottom_indextert = 1 if tert_index==1


*REDISTRIBUTION PREFERENCES OF SES GROUPS


// Attidudes of 5% SES groups
gen att_red_top = att_red if top_index == 1
gen att_red_mid = att_red if mid_index == 1
gen att_red_bottom = att_red if bottom_index == 1

// Attidudes of 10% SES groups
gen att_red_top10 = att_red if top_index10 == 1
gen att_red_mid10 = att_red if mid_index10 == 1
gen att_red_bottom10 = att_red if bottom_index10 == 1

	
// Attidudes of tercile SES groups
gen att_red_toptert = att_red if top_indextert == 1
gen att_red_midtert = att_red if mid_indextert == 1
gen att_red_bottomtert = att_red if bottom_indextert == 1


*===============================================================================
*CONSTRUCTION OF WVS DATA SET FOR WAVE 3 & 4
*===============================================================================

//Keep relevant variables

keep country country_str year country_year wave wave_recent att_red index top_index bottom_index mid_index top_index10 bottom_index10 mid_index10 tert_index top_indextert mid_indextert bottom_indextert att_red_top att_red_mid att_red_bottom att_red_top10 att_red_mid10 att_red_bottom10 att_red_toptert att_red_midtert att_red_bottomtert

//Aggregate data over waves by country

gen sample=1 if index!=.


collapse (mean) wave wave_recent att_red index top_index bottom_index mid_index  top_index10 bottom_index10 mid_index10 tert_index top_indextert mid_indextert bottom_indextert att_red_top att_red_mid att_red_bottom att_red_top10 att_red_mid10 att_red_bottom10 att_red_toptert att_red_midtert att_red_bottomtert ///
	(lastnm) year country_year country_str ///
	(sum) n_sample=sample n_top=top_index  n_mid=mid_index n_bottom=bottom_index n_top10=top_index10  n_mid10=mid_index10 n_bottom10=bottom_index10 n_toptert=top_indextert n_midtert=mid_indextert n_bottomtert=bottom_indextert, by(country)



// Set preferences for redistribution to missing if based on less than 30 observarions
replace att_red_top = . if n_top<30  // Dom. rep, Morocco, Uganda
replace att_red_mid = . if n_mid<30  // Bosnia and Herzegovina, Dom. rep., Indonesia, Morocco & Uganda
replace att_red_bottom = . if n_bottom<30  // Dom. rep. & Morocco

tab country_str if index==.


//Save data
save wvs_avg_wave56.dta, replace


*===============================================================================
*MERGE WVS WITH SWIID
*===============================================================================


//Import SWIID data
import delimited "swiid8_3_summary.csv", clear


//Compute relative redistribution 

gen rel_red_imp = 100*(gini_mkt - gini_disp)/gini_mkt


//Compute absolute difference in gini 
gen abs_red_imp = gini_mkt - gini_disp


//Keep years closest to 2015 since wave 6 ends in 2014

gsort country -year
by country: gen count = _n
gen distance2015=abs(year-2015)
bysort country: egen mindistance2015=min(distance2015)
keep if distance2015==mindistance2015


//Indicator of year
rename year year_swiid
rename country country_str

// Save data
save swiid_prep_wave56.dta, replace


//Merge WVS with SWIID
use wvs_avg_wave56.dta, clear
merge m:1 country_str using swiid_prep_wave56.dta
drop if _merge!=3
drop _merge


//Save data
save redistribution_merged_wave56.dta, replace


*===============================================================================
*MERGE WITH IMF DATA (CONTROL for GDP and POPULATION)
*===============================================================================

*Note: As wave 5 of the WVS/EVS data is from 2005, we try to find data only
*control variables before 2005. (If missing, we use data after 2005.)

*GDP DATA BEFORE 2005

//Import data
import excel using gdp_percapita_ppp.xls, firstrow clear

//Destring variables (convert missings)

destring gdp_pc_ppp1980-gdp_pc_ppp2024,replace force

//Reshape long (one observation per year)
reshape long gdp_pc_ppp, i(country) j(year)

//Keep if before 2005
drop if year>=2005
drop if gdp_pc_ppp==.
gsort country -year

//Generate index for how close year is to 2005 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 2005
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
save imf_gdp_pre05,replace

//Merge with main dataset
use redistribution_merged_wave56,clear
merge 1:1 country_str using imf_gdp_pre05.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge


//Save data
save redistribution_merged_wave56,replace


*Note: No additional data available after 2005



*POPULATION DATA BEFORE 2005

//Import data
import excel using imf_population.xls, firstrow clear

//Destring variables (convert missings)

destring population1980-population2024,replace force

//Reshape long (one observation per year)
reshape long population, i(country_str) j(year)

//Keep if before 2005
drop if year>=2005
drop if population==.
gsort country_str -year

//Generate index for how close year is to 2005 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 2005
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
save imf_pop_pre05,replace

//Merge with main dataset
use redistribution_merged_wave56,clear

merge 1:1 country_str using imf_pop_pre05.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge


//Save data
save redistribution_merged_wave56,replace

*Note: No additional data available after 2005


*===============================================================================
*MERGE WITH DEMOCRACY MEASURE
*===============================================================================

*Note: We follow Acemoglu et al. (2019) to compute a democracy measure

//Import data
use DDCGdata_final,clear

//Only keep relevant variables
keep country_name wbcode year dem
drop if dem==.

//Keep if observations for 2004
keep if year==2004


//Manually adjust country names
replace country_name="Bosnia and Herzegovina" if country_name=="Bosnia & Herzegovina"
replace country_name="Slovakia" if country_name=="Slovak Republic"
replace country_name="Iran" if country_name=="Iran, I.R. of"
replace country_name="Kyrgyzstan" if country_name=="Kyrgyz Republic"
replace country_name="Macedonia" if country_name=="Macedonia, FYR"
replace country_name="Yemen" if country_name=="Yemen, Republic of"
replace country_name="Venezuela" if country_name=="Venezuela, Rep. Bol."


*Note: For Serbia & Montenegro create two observations
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

//Merge with main dataset
use redistribution_merged_wave56,clear

merge 1:1 country_str using dem_ANRR.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge

*Note: No data for Andorra, Hong Kong, Palestinian Territories, Puerto Rico
*We use the approach described in Acemoglu et al. 2019 to measure democracy in remaining countries.
*Use Freedom house as primary measure and check with Boix, Miller, Rosato (2012) and Cheibub, Gandhi, Vreeland (2010) where possible.
*Again we use data closest to 2005 and manually impute the deomcracy measure of ANRR


*Andorra: Data available in Freedomhouse, BMR and CGV
replace dem_ANRR = 1 if country_str == "Andorra"

*Hong Kong: Data only available in Freedomhouse (partially free, 2005)
replace dem_ANRR= 1 if country_str == "Hong Kong"

*Palestinian Territories: Data only available in Freedomhouse (not free, 2005)
replace dem_ANRR= 0 if country_str == "Palestinian Territories"

*Puerto Rico : Data only available in Freedomhouse (free, 2005)
replace dem_ANRR= 1 if country_str == "Puerto Rico"

//Save data
save redistribution_merged_wave56,replace



*==============================================================================
*GENERATE AND LABEL NEW VARIABLES
*==============================================================================

//Generate log gdp and pop
gen lngdp=ln(gdp_pc_ppp)
gen lnpop=ln(population)

//Label variables 

label var att_red_top "Top 5\%"
label var att_red_mid "Middle 5\%"
label var att_red_bottom "Bottom 5\%"
label var att_red_top10 "Top 10\%"
label var att_red_mid10 "Middle 10\%"
label var att_red_bottom10 "Bottom 10\%"
label var att_red_toptert "Top 33\%"
label var att_red_midtert "Middle 33\%"
label var att_red_bottomtert "Bottom 33\%"
label var att_red "Attitude Redistribution"
label var index "Social Class Index"
label var rel_red_imp "Relative Redistribution"
label var abs_red_imp "Absolute Redistribution"
label var gini_disp "Gini post-tax"
label var gini_mkt "Gini pre-tax"
label var lngdp "ln(GDP per capita)"
label var lnpop "ln(Population)"

 
//Save final data
save redistribution_merged_wave56.dta,replace

