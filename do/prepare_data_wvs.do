*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Data Cleaning and Mergin of WVS Data
*Last update: 28.02.23

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

//Restrict Sample and exclude wave 1 & 2 and wave 7
keep if wave >2 
drop if wave >6


*SOCIO-DEMOGRAPHICS

//Age
gen age = X003
replace age =. if X003<0
label variable age "Age"


//Gender

gen male =.
replace male = 1 if  X001 == 1
replace male = 0 if  X001 == 2
label variable male "Male"

//Married

gen married = .
replace married = 1 if X007 == 1 | X007 == 2
replace married = 0 if X007 >2 
replace married = . if X007 < 1
label variable married "Married"


//Children
gen children = X011
replace children = . if X011<0
label variable children "Children"

//Employment
gen employed = .
replace employed = 1 if X028 <= 3
replace employed = 0 if X028 > 3 & X028 <=8
replace employed =. if X028<1
label variable employed "Employed"


gen unemployed = .
replace unemployed = 0 if X028 <= 8
replace unemployed = 1 if X028 == 7
replace unemployed =. if X028<1
label variable unemployed "Unemployed"


//Type of work
gen work_public = .
replace work_public = 1 if X052 ==1
replace work_public = 0 if X052 >1
replace work_public = . if X052 <1
label variable work_public "Public institution"

gen work_manual = X053
replace work_manual = abs(work_manual-10)	// 0 = Mostly non-manual, 9 = Mostly manual tasks
replace work_manual = . if X053 <1		
label variable work_manual "Manual work"

gen work_routine = X054
replace work_routine = abs(work_routine-10)				// 0 = Mostly non-routine, 9 = Mostly routine tasks
replace work_routine = . if X054<1
label variable work_routine "Routine work"

//Immigrant
gen immig_parent = .
replace immig_parent = 1 if G026==1 | G027==1
replace immig_parent = 0 if G026==0 & G027==0
label variable immig_parent "Immigrant parent"


//Supervising position at work
gen work_supervis = X031
replace work_supervis =. if X031<0
label variable work_supervis "Supervisor"


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


//Country specific income brackets
gen income_cs = X047CS 
replace income_cs =. if X047CS<=10


*POLITICAL ATTITUDES


//Political views

gen political = E033
replace political = abs(political-10)
replace political =.  if E033<1
label variable political "Political left"

//Member of political party

*Note: There are two variables which indicate membership in political party A102 and A068 

gen polpart_memb = 0
replace polpart_memb =  1 if A102==1 | A102 ==2| A068 ==1
replace polpart_memb=. if A102 <0 & A068 <0
label variable polpart_memb "Party member"

gen polpart_memb_activ = (A102==2)
replace polpart_memb_activ =. if A102 <0


//Politcal action

gen polac_petition = 0
replace polac_petition = 1 if E025==1
replace polac_petition = . if E025<1

gen polac_boycott = 0
replace polac_boycott = 1 if E026==1
replace polac_boycott = . if E026<1

gen polac_demo = 0
replace polac_demo = 1 if E027==1
replace polac_demo = . if E027<1

gen polac_strike = 0
replace polac_strike = 1 if E028==1
replace polac_strike = . if E028<1


//Index of political particiaption

pca polac_petition polac_boycott polac_demo polac_strike, comp(1) blanks(0.3)
predict polpar_index, score


//Confidence in government
gen conf_gov = E069_11
replace conf_gov = abs(conf_gov-4)
replace conf_gov=. if E069_11<1
label variable conf_gov "V115: Confidence in government (3=great deal)"


//Policy priorities
gen prob_count_poverty =0
replace prob_count_poverty = 1 if E240==1
replace prob_count_poverty=. if E240<1

gen prob_count_discr =0
replace prob_count_discr = 1 if E240==2
replace prob_count_discr=. if E240<1

gen prob_count_sanit =0
replace prob_count_sanit = 1 if E240==3
replace prob_count_sanit=. if E240<1

gen prob_count_educ =0
replace prob_count_educ = 1 if E240==4
replace prob_count_educ=. if E240<1

gen prob_count_environ =0
replace prob_count_environ = 1 if E240==5
replace prob_count_environ=. if E240<1



*MORAL VALUES

*Note: We compute moral universalism as the difference in difference between average in group trust and average out group trust. 

//Generate in group trust

gen trust_family = abs(D001_B-4) // 0 = trust not at all, 3 = trust completely
replace trust_family = . if D001_B<1

gen trust_neighbor = abs(G007_18_B-4)
replace trust_neighbor = . if G007_18_B<1

gen trust_personal = abs(G007_33_B-4)
replace trust_personal = . if G007_33_B<1

egen trust_ingroup = rowmean(trust_family trust_neighbor trust_personal)


//Generate out group trust

gen trust_first = abs(G007_34_B-4)
replace trust_first = . if G007_34_B<1

gen trust_relig = abs(G007_35_B-4)
replace trust_relig = . if G007_35_B<1

gen trust_nat = abs(G007_36_B-4)
replace trust_nat = . if G007_36_B<1

egen trust_outgroup = rowmean(trust_first trust_relig trust_nat)

//Generate universalist trust

gen trust_universal =.
replace trust_universal = trust_outgroup - trust_ingroup if trust_outgroup!=. & trust_ingroup!=.



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


*INCOME CLASSES

*Note: We use lowest, middle, and highest value of scale for income classes

gen top_incval = 1 if income==10
gen mid_incval = 1 if income ==5
gen bottom_incval = 1 if income ==1


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



//Generate median and mode attitudes for each country

qui{
gen median_att_red=.
levelsof country, local(levels)			//Generates list with unique values of country
foreach l of local levels {
	su att_red if country == `l' & index!=., d       //Summarize attitudes for a given country
	replace median_att_red = r(p50) if country == `l' 
}
}

bysort country: egen mode_att_red = mode(att_red) if index!=.

//Distance to median

gen dist_med_top = att_red_top - median_att_red if att_red_top!=.
gen dist_med_mid = att_red_mid - median_att_red if att_red_mid!=.
gen dist_med_bottom = att_red_bottom - median_att_red if att_red_bottom!=.

//Distance to mode

gen dist_mode_top = att_red_top - mode_att_red if att_red_top!=.
gen dist_mode_mid = att_red_mid - mode_att_red if att_red_mid!=.
gen dist_mode_bottom = att_red_bottom - mode_att_red if att_red_bottom!=.


*REDISTRIBUTION PREFERENCES OF INCOME GROUPS

gen att_red_topincval = att_red if top_incval == 1
gen att_red_midincval = att_red if mid_incval == 1
gen att_red_botincval = att_red if bottom_incval == 1


*CONFIDENCE IN GOVERNMENT OF SES GROUPS

gen conf_gov_top = conf_gov if top_index == 1
gen conf_gov_mid = conf_gov if mid_index == 1
gen conf_gov_bottom = conf_gov if bottom_index == 1


*POLITICAL PARTICIPATION OF SES GROUPS

gen polpar_top = polpar_index if top_index == 1
gen polpar_mid = polpar_index if mid_index == 1
gen polpar_bottom = polpar_index if bottom_index == 1


*LOCUS OF CONTROL

gen belief_control = A173
replace belief_control =  belief_control-1 // 9: great deal of choice and control, 0: Not at all control and choice
replace belief_control = . if A173<1
label variable belief_control "Completely free choice and control over live. (9=Great deal of control and choice)"


// Locus of control of SES groups
gen belief_control_top = belief_control if top_index == 1
gen belief_control_mid = belief_control if mid_index == 1
gen belief_control_bottom = belief_control if bottom_index == 1


*===============================================================================
*CONSTRUCTION OF WVS MAIN DATA SET
*===============================================================================

//Keep relevant variables

keep wave year country country_year country_str year country_year wave wave_recent weight age male married children employed unemployed work_public work_manual work_routine immig_parent work_supervis class income educ income_cs political polpart_memb polpart_memb_activ polac_petition polac_boycott polac_demo polac_strike polpar_index conf_gov prob_count_poverty prob_count_discr prob_count_sanit prob_count_educ prob_count_environ trust_family trust_neighbor trust_personal trust_ingroup trust_first trust_relig trust_nat trust_outgroup trust_universal att_red index top_index bottom_index mid_index top_index10 bottom_index10 mid_index10  tert_index top_indextert mid_indextert bottom_indextert top_incval mid_incval bottom_incval att_red_top att_red_mid att_red_bottom att_red_top10 att_red_mid10 att_red_bottom10 att_red_toptert att_red_midtert att_red_bottomtert median_att_red mode_att_red dist_med_top dist_med_mid dist_med_bottom dist_mode_top dist_mode_mid dist_mode_bottom att_red_topincval att_red_midincval att_red_botincval conf_gov_top conf_gov_mid conf_gov_bottom polpar_top polpar_mid polpar_bottom belief_control belief_control_top belief_control_mid belief_control_bottom
sort country year

//Save data
save wvs.dta, replace

preserve
//Aggregate data over waves by country

gen sample=1 if index!=.

collapse (mean)  age male married children employed unemployed work_public work_manual work_routine immig_parent work_supervis class income educ income_cs political polpart_memb polpart_memb_activ polac_petition polac_boycott polac_demo polac_strike polpar_index conf_gov prob_count_poverty prob_count_discr prob_count_sanit prob_count_educ prob_count_environ trust_family trust_neighbor trust_personal trust_ingroup trust_first trust_relig trust_nat trust_outgroup trust_universal att_red index top_index bottom_index mid_index top_index10 bottom_index10 mid_index10  tert_index top_indextert mid_indextert bottom_indextert top_incval mid_incval bottom_incval att_red_top att_red_mid att_red_bottom att_red_top10 att_red_mid10 att_red_bottom10 att_red_toptert att_red_midtert att_red_bottomtert median_att_red mode_att_red dist_med_top dist_med_mid dist_med_bottom dist_mode_top dist_mode_mid dist_mode_bottom att_red_topincval att_red_midincval att_red_botincval conf_gov_top conf_gov_mid conf_gov_bottom polpar_top polpar_mid polpar_bottom belief_control belief_control_top belief_control_mid belief_control_bottom ///
	(lastnm) year country_year country_str ///
	(rawsum) n_sample=sample n_top=top_index  n_mid=mid_index n_bottom=bottom_index  n_top10=top_index10  n_mid10=mid_index10 n_bottom10=bottom_index10  n_toptert=top_indextert n_midtert=mid_indextert n_bottomtert=bottom_indextert n_topincval=top_incval n_midincval=mid_incval n_botincval=bottom_incval, by(country)



//Set preferences for redistribution to missing if based on less than 30 observarions

tab country_str if n_top<30 & index!=.		 // Dom. rep
tab country_str if n_mid<30 & index!=.		// Dom. rep. & Uganda
tab country_str if n_bottom<30 & index!=.		// Dom. rep.


tab country_str if n_top10<30	& index!=.	 // no countries
tab country_str if n_mid10<30 & index!=.		// no countries
tab country_str if n_bottom10<30 & index!=.		// no countries

tab country_str if n_toptert<30 & index!=.		 // no countries
tab country_str if n_midtert<30 & index!=.		// no countries
tab country_str if n_bottomtert<30 & index!=.		// no countries


tab country_str if n_topincval <30 & income!=. // 39 countries
tab country_str if n_midincval <30 & income!=. // 1 country
tab country_str if n_botincval <30 & income!=.  // 5 countries

replace att_red_top = . if n_top<30 
replace att_red_mid = . if n_mid<30 
replace att_red_bottom = . if n_bottom<30 

replace att_red_topincval = . if n_topincval<30 
replace att_red_midincval = . if n_midincval<30 
replace att_red_botincval = . if n_botincval<30 


//Save data
save wvs_avg.dta, replace
restore


preserve
//Aggregate data over waves by country using survey weights


gen sample=1 if index!=.

collapse (mean)  age male married children employed unemployed work_public work_manual work_routine immig_parent work_supervis class income educ income_cs political polpart_memb polpart_memb_activ polac_petition polac_boycott polac_demo polac_strike polpar_index conf_gov prob_count_poverty prob_count_discr prob_count_sanit prob_count_educ prob_count_environ trust_family trust_neighbor trust_personal trust_ingroup trust_first trust_relig trust_nat trust_outgroup trust_universal att_red index top_index bottom_index mid_index top_index10 bottom_index10 mid_index10  tert_index top_indextert mid_indextert bottom_indextert top_incval mid_incval bottom_incval att_red_top att_red_mid att_red_bottom att_red_top10 att_red_mid10 att_red_bottom10 att_red_toptert att_red_midtert att_red_bottomtert median_att_red mode_att_red dist_med_top dist_med_mid dist_med_bottom dist_mode_top dist_mode_mid dist_mode_bottom att_red_topincval att_red_midincval att_red_botincval conf_gov_top conf_gov_mid conf_gov_bottom polpar_top polpar_mid polpar_bottom belief_control belief_control_top belief_control_mid belief_control_bottom ///
	(lastnm) year country_year country_str ///
	(rawsum) n_sample=sample n_top=top_index  n_mid=mid_index n_bottom=bottom_index  n_top10=top_index10  n_mid10=mid_index10 n_bottom10=bottom_index10  n_toptert=top_indextert n_midtert=mid_indextert n_bottomtert=bottom_indextert n_topincval=top_incval n_midincval=mid_incval n_botincval=bottom_incval [pw=weight], by(country)



//Set preferences for redistribution to missing if based on less than 30 observarions

replace att_red_top = . if n_top<30 
replace att_red_mid = . if n_mid<30 
replace att_red_bottom = . if n_bottom<30 

replace att_red_topincval = . if n_topincval<30 
replace att_red_midincval = . if n_midincval<30 
replace att_red_botincval = . if n_botincval<30 


//Save data
save wvs_avg_weight.dta, replace
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


//Keep years closest to 2015

gsort country -year
gen distance2015=abs(year-2015)
bysort country: egen mindistance2015=min(distance2015)
sum mindistance, d
keep if distance2015==mindistance2015
drop distance2015 mindistance2015 

//Indicator of year
rename year year_swiid
rename country country_str

// Save data
save swiid_prep.dta, replace

//Merge WVS with SWIID
use wvs_avg.dta, clear
merge m:1 country_str using swiid_prep.dta
tab country_str if _merge==1
drop if _merge!=3
drop _merge


//Save data
save redistribution_merged.dta, replace


//Merge weighted WVS with SWIID
use wvs_avg_weight.dta, clear
merge m:1 country_str using swiid_prep.dta
tab country_str if _merge==1
drop if _merge!=3
drop _merge


//Save data
save redistribution_merged_weight.dta, replace


*===============================================================================
*MERGE WITH IMF GDP AND POPULATION DATA 
*===============================================================================


*Note: As the first wave of the WVS/EVS data is from 1995, we use data for
*control variables before 1995. (If missing, we use data after 1995.)


*GDP DATA BEFORE 1995


//Import data
import excel using gdp_percapita_ppp.xls, firstrow clear

//Destring variables (convert missings)

destring gdp_pc_ppp1980-gdp_pc_ppp2024,replace force

//Reshape long (one observation per year)
reshape long gdp_pc_ppp, i(country) j(year)

//Keep if before 1995
drop if year>=1995
drop if gdp_pc_ppp==.
gsort country -year

//Generate index for how close year is to 1995 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1995
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
save imf_gdp_pre95,replace

//Merge with main dataset
use redistribution_merged,clear
merge 1:1 country_str using imf_gdp_pre95.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge


//Save data
save redistribution_merged,replace

//Merge with weighted main dataset
use redistribution_merged_weight,clear
merge 1:1 country_str using imf_gdp_pre95.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge


//Save data
save redistribution_merged_weight,replace


*GDP DATA AFTER 1995


//Import data
import excel using gdp_percapita_ppp.xls, firstrow clear

//Destring variables (convert missings)

destring gdp_pc_ppp1980-gdp_pc_ppp2024,replace force

//Reshape long (one observation per year)
reshape long gdp_pc_ppp, i(country) j(year)

//Keep if after 1995
keep if year>=1995
drop if gdp_pc_ppp==.
sort country -year

//Generate index for how close year is to 1995 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1995
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
save imf_gdp_post95,replace

//Merge with datasetsets

foreach file in redistribution_merged redistribution_merged_weight{
use `file',clear
merge 1:1 country_str using imf_gdp_post95.dta, update
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Save data
save `file', replace
}


*POPULATION DATA BEFORE 1995

//Import data
import excel using imf_population.xls, firstrow clear

//Destring variables (convert missings)

destring population1980-population2024,replace force

//Reshape long (one observation per year)
reshape long population, i(country_str) j(year)

//Keep if before 1995
drop if year>=1995
drop if population==.
gsort country_str -year

//Generate index for how close year is to 1995 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1995
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
save imf_pop_pre95,replace

//Merge with main datasetsets

foreach file in redistribution_merged redistribution_merged_weight{
use `file',clear
merge 1:1 country_str using imf_pop_pre95.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Save data
save `file',replace
}


*POPULATION DATA AFTER 1995

//Import data
import excel using imf_population.xls, firstrow clear

//Destring variables (convert missings)

destring population1980-population2024,replace force

//Reshape long (one observation per year)
reshape long population, i(country_str) j(year)

//Keep if before 1995
keep if year>=1995
drop if population==.
sort country_str -year

//Generate index for how close year is to 1995 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1995
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
save imf_pop_post95,replace

//Merge with datasetsets

foreach file in redistribution_merged redistribution_merged_weight{
use `file',clear
merge 1:1 country_str using imf_pop_post95.dta,update
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Save data
save `file',replace
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

//Keep if observations for 1994
keep if year==1994


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

//Merge with datasets

foreach file in redistribution_merged redistribution_merged_weight{
use `file',clear

merge 1:1 country_str using dem_ANRR.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge

*Note: No data for Andorra, Hong Kong, Palestinian Territories, Puerto Rico
*We use the approach described in Acemoglu et al. 2019 to measure democracy in remaining countries.
*Use Freedom house as primary measure and check with Boix, Miller, Rosato (2012) and Cheibub, Gandhi, Vreeland (2010) where possible.
*Again we use data closest to 1995 and manually impute the deomcracy measure of ANRR


*Andorra: Data available in Freedomhouse, BMR and CGV
replace dem_ANRR = 1 if country_str == "Andorra"

*Hong Kong: Data only available in Freedomhouse (partially free, 1994-1995)
replace dem_ANRR= 1 if country_str == "Hong Kong"

*Palestinian Territories: Data only available in Freedomhouse (not free, 1996-1997)
replace dem_ANRR= 0 if country_str == "Palestinian Territories"

*Puerto Rico : Data only available in Freedomhouse (free, 1994-1995)
replace dem_ANRR= 1 if country_str == "Puerto Rico"

//Save data
save `file',replace
}


*==========================================================================
*MERGE WITH POLITY IV SCORE 
*==========================================================================


*POLITY SCORE DATA BEFORE 1995

//Import data
use polityiv_2017,clear


//Keep if before 1995
drop if year>=1995
gsort country -year

//Only keep relevant variables
keep country year polity2
drop if polity2==.

//Generate index for how close year is to 1995 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1995
keep if id<=1
drop id

//Drop if observations too old, before 1975
drop if year<1975

//Manually adjust country names
replace country="Bosnia and Herzegovina" if country=="Bosnia"
replace country="Korea" if country=="Korea South"
replace country="Slovakia" if country=="Slovak Republic"

rename country country_str
rename year year_polity2

//Save data
save polity2_pre95,replace

//Merge with main dataset
use redistribution_merged,clear
merge 1:1 country_str using polity2_pre95.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge


//Save data
save redistribution_merged,replace


*POLITY SCORE DATA AFTER 1995


//Import data
use polityiv_2017,clear

//Keep if before 1995
keep if year>=1995
sort country year

//Only keep relevant variables
keep country year polity2
drop if polity2==.

//Generate index for how close year is to 1995 (1=closest year)
by country: gen id=_n

//Only keep observation from year closest to 1995
keep if id<=1
drop id


//Manually adjust country names
replace country="Korea" if country=="Korea South"
replace country="Slovakia" if country=="Slovak Republic"

rename country country_str
rename year year_polity2

//Save data
save polity2_post95,replace

//Merge with main dataset
use redistribution_merged,clear
merge 1:1 country_str using polity2_post95.dta,update
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Generate indicator for democratic country

gen democratic=(polity2>=6) if polity2!=. 

label variable democratic "Democracy"
label variable polity2 "Polity score"

//Save data
save redistribution_merged,replace



*===============================================================================
*MERGE WITH HISTORICAL INDEX OF ETHNIC FRACTIONALIZATION DATASET
*===============================================================================


//Import data
import delimited "hief.csv", varnames(1)  clear 

//Keep hief from 1994
keep if year==1994

rename year year_hief

label var efindex "Ethnic fractionalization"

//Manually adjust country names
rename country country_str
replace country_str="Bosnia and Herzegovina" if country_str=="Bosnia-Herzegovina"
replace country_str="Germany" if country_str=="German Federal Republic"
replace country_str="Korea" if country_str=="Republic of Korea"
replace country_str="Kyrgyzstan" if country_str=="Kyrgyz Republic"
replace country_str="United States" if country_str=="United States of America"
replace country_str="Vietnam" if country_str=="Democratic Republic of Vietnam"
replace country_str="Yemen" if country_str=="Yemen Arab Republic"


//Save data
save hief,replace

//Merge with main dataset
use redistribution_merged,clear
merge 1:1 country_str using hief.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Save data
save redistribution_merged,replace



*===============================================================================
*MERGE WITH LEGAL ORIGIN DUMMIES DUMMIES
*===============================================================================

//Import data
import excel using economiccon_data.xls, firstrow sheet("Table 1") clear

keep country code legor_uk legor_fr legor_ge legor_sc legor_so

//Drop notes in file
drop if _n>190

foreach v in legor_uk legor_fr legor_ge legor_sc legor_so{
	destring `v', replace
}

//Create indicator variables

gen legor=0
replace legor = 1 if legor_uk==1
replace legor = 2 if legor_fr==1
replace legor = 3 if legor_ge==1
replace legor = 4 if legor_sc==1
replace legor = 5 if legor_so==1
replace legor=. if legor_uk==.


//Manually adjust country names
rename country country_str
replace country_str="Egypt" if country_str=="Egypt, Arab Rep."
replace country_str="Hong Kong" if country_str=="Hong Kong, China"
replace country_str="Iran" if country_str=="Iran, Islamic Rep."
replace country_str="Korea" if country_str=="Korea, Rep."
replace country_str="Kyrgyzstan" if country_str=="Kyrgyz Republic"
replace country_str="Macedonia" if country_str=="Macedonia, FYR"
replace country_str="Palestinian Territories" if country_str=="West Bank and Gaza"
replace country_str="Russia" if country_str=="Russian Federation"
replace country_str="Slovakia" if country_str=="Slovak Republic"
replace country_str="Venezuela" if country_str=="Venezuela, RB"
replace country_str="Yemen" if country_str=="Yemen, Rep."


//Save data
save legalorigin.dta,replace

//Merge with main dataset
use redistribution_merged,clear
merge 1:1 country_str using legalorigin.dta
tab country_str if _merge==1
drop if _merge==2
drop _merge

//Create seperate observations for Serbia and Montenegro
replace legor_fr = 1 if country_str=="Serbia"
replace legor_uk = 0 if country_str=="Serbia"
replace legor_ge = 0 if country_str=="Serbia"
replace legor_sc = 0 if country_str=="Serbia"
replace legor_so = 0 if country_str=="Serbia"
replace legor = 2 if country_str=="Serbia"


replace legor_fr = 1 if country_str=="Montenegro"
replace legor_uk = 0 if country_str=="Montenegro"
replace legor_ge = 0 if country_str=="Montenegro"
replace legor_sc = 0 if country_str=="Montenegro"
replace legor_so = 0 if country_str=="Montenegro"
replace legor = 2 if country_str=="Montenegro"


//Save data
save redistribution_merged,replace


*==========================================================================
*MERGE WITH RPE DATA FOR ADDITIONAL REDISTRIBUTION MEASURES
*==========================================================================

//Import data
import excel using rpc_2020_comp, firstrow clear


//Drop irrelevant variables
keep country year rpe_agri rpe_gdp rpe_gdp_nonres tax_nonres tax socsec edu_share se_share  gdppc pop

//Drop observations before 2010
drop if year < 2010

//Transform expenditure shares into expenditure/GDP
foreach v in edu_share se_share{
replace `v' = `v' / gdppc
}

//Only keep observations clostes to 2015 (As WVS wave 6 ended 2015)
foreach v in rpe_gdp rpe_gdp_nonres tax_nonres tax socsec edu_share se_share {
gsort country -year
gen distance2015=abs(year-2015) if `v'!=.
bysort country: egen mindistance2015=min(distance2015) if `v'!=.
gen used_`v' = 1 if distance2015==mindistance2015 & `v'!=.
drop distance2015 mindistance2015
}


keep if used_rpe_gdp==1 | used_rpe_gdp_nonres ==1 |used_tax_nonres ==1 | used_tax ==1 | used_socsec ==1 | used_edu_share ==1 |used_se_share ==1 
bysort country: egen maxyear = max(year)
keep if year ==2015 | year == maxyear //Drop older observation if there are two observations closest to 2015
drop maxyear
gsort country year
collapse (firstnm) year rpe_agri rpe_gdp rpe_gdp_nonres tax_nonres tax gdppc socsec pop edu_share se_share, by(country)



//Manually adjust country names
rename country country_str
replace country_str="Bosnia and Herzegovina" if country=="Bosnia & Herzegovina"
replace country_str="China" if country=="China, P.R.: Mainland"
replace country_str="Macedonia" if country=="Macedonia, Fyr"
replace country_str="Serbia" if country=="Serbia, Republic of"
replace country_str="Slovakia" if country=="Slovak Republic"
replace country_str="Korea" if country=="Korea, Republic Of"
replace country_str="Yemen" if country=="Yemen, Republic Of"
replace country_str="Kyrgyzstan" if country=="Kyrgyz Republic"
replace country_str="Czech Republic" if country=="Czechia"
replace country_str="Macedonia" if country=="North Macedonia"
replace country_str="Russia" if country=="Russian Federation"

rename year year_rpe

//Label Variables

label variable rpe_gdp "RPE"
label variable rpe_gdp_nonres "RPE (non-res)"
label variable tax "Taxes"
label variable tax_nonres "Taxes (non-res)"
label variable socsec "Soc. sec. taxes"
label variable se_share "Soc. prot. exp."
label variable edu_share "Educ. exp."

// Compute alt. redistribution measures as percent of GDP

foreach var in  tax tax_nonres socsec se_share{
    replace `var' = `var' *100
}

//Save data
save rpe.dta,replace

//Merge with datasetsets

foreach file in redistribution_merged redistribution_merged_weight{
use `file',clear
merge 1:1 country_str using rpe.dta
drop if _merge==2
drop _merge

//Save data
save `file',replace
}


*==============================================================================
*MERGE WITH TOP INCOME TAX RATE (WORLD TAX INDICATORS)
*==============================================================================


//Import data
use "AYS World_Tax_Indicators_V1_Data.dta",clear


//Manually adjust country names
rename name_un country_str
replace country_str="Hong Kong" if strpos(country_str, "Hong Kong")
replace country_str="Iran" if strpos(country_str, "Iran")
replace country_str="Korea" if strpos(country_str, "Korea")
replace country_str="Libya" if strpos(country_str, "Libya")
replace country_str="Macedonia" if strpos(country_str, "Macedonia")
replace country_str="Moldova" if strpos(country_str, "Moldova")
replace country_str="Russia" if strpos(country_str, "Russia")
replace country_str="Taiwan" if strpos(country_str, "Taiwan")
replace country_str="Tanzania" if strpos(country_str, "Tanzania")
replace country_str="United Kingdom" if strpos(country_str, "United Kingdom")
replace country_str="United States" if strpos(country_str, "United States")
replace country_str="Venezuela" if strpos(country_str, "Venezuela")
replace country_str="Vietnam" if strpos(country_str, "Viet")


//Only keep latest observation
gsort country_str -year 
by country_str: gen id=_n
keep if id<=1
drop id

rename year year_wti

//Save data
save wti.dta,replace

//Merge with main dataset
use redistribution_merged,clear
merge 1:1 country_str using wti.dta
drop if _merge==2
drop _merge

//Save data
save redistribution_merged,replace


*==============================================================================
*GENERATE AND LABEL NEW VARIABLES
*==============================================================================

foreach file in redistribution_merged redistribution_merged_weight{

use `file',clear

//Generate log gdp and pop
gen lngdp=ln(gdp_pc_ppp)
gen lnpop=ln(population)

//Label variables 

label var top_index "Top 5\%"
label var mid_index "Middle 5\%"
label var bottom_index "Bottom 5\%"
label var att_red_top "Top 5\%"
label var att_red_mid "Middle 5\%"
label var att_red_bottom "Bottom 5\%"
label var att_red_top10 "Top 10\%"
label var att_red_mid10 "Middle 10\%"
label var att_red_bottom10 "Bottom 10\%"
label var att_red_toptert "Top 33\%"
label var att_red_midtert "Middle 33\%"
label var att_red_bottomtert "Bottom 33\%"
label var att_red_topincval "Top income"
label var att_red_midincval "Middle income"
label var att_red_botincval "Bottom income"
label var att_red "Attitude Redistribution"
label var class "Social class"
label var income "Income"
label var educ "Education"
label var conf_gov "Confidence in government"
label var trust_universal "Moral Universalism"
label variable polpar_bottom "Polit. activ. Bottom 5\%"
label variable polpar_mid "Polit. activ. Middle 5\%"
label variable polpar_top "Polit. activ. Top 5\%"
label var index "Social Class Index"
label var rel_red_imp "Relative Redistribution"
label var abs_red_imp "Absolute Redistribution"
label var gini_disp "Gini post-tax"
label var gini_mkt "Gini pre-tax"
label var lngdp "ln(GDP per capita)"
label var lnpop "ln(Population)"

 
//Save final data
save `file',replace
}
