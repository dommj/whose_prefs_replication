*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Figures for Online Appendix
*Last update: 05.03.23


*Note: To run the analyses, data cleaning should be applied first by running the do-file prepare_data

*===============================================================================


//Settings

set more off
clear all
set maxvar 15000, permanently
set matsize 5000
set linesize 80  

//Additional packages

*ssc install kountry
*search labmask, sj
*net install binscatter2, from("https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/")

*===============================================================================
* FIGURE A.1
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

//Create ventiles

xtile index_ventile = index, nq(20)
egen mean_ventile_att_red = mean(att_red), by(index_ventile)

//Compute SEs by decile
gen ub = .
gen lb = .

forvalues v = 1(1)20 {
  ci means att_red if   index_ventile == `v'
	replace ub = mean_ventile_att_red + r(se) if index_ventile == `v'
	replace lb = mean_ventile_att_red - r(se) if index_ventile == `v'
}

//Compute figure
twoway 	(scatter mean_ventile_att_red index_ventile, sort fcolor(edkblue) lcolor(edkblue) lwidth(vthin) msize(small) ) ///
		(rcap ub lb index_ventile, col(black) lwidth(vthin)), ///
		ytitle("Average attitude""0: We need larger Income diff., 9: Income should be equal", size(small)) b1title("Ventiles of the Socioeconomic Status Index""1  = Bottom 5%; 20 = Top 5%", size(small)) graphregion(color(gs16)) ///
		xlabel(1  2  3  4  5  6  7 8 9  10  11  12 13 14 15  16  17  18 19 20, valuelabel noticks labgap(*1.3) labsize(small)) ///
		yscale(lstyle(none)) xscale(lstyle(none)) ///
		ylabel(3 3.5 4 4.5 5, angle(horizontal) glcolor(gs14) labsize(small) noticks gmin) xtitle("") legend(off) yline(4.5, lwidth(thin) lcolor(red))  graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) 
		

//Save figure
cd ..
cd "output"		
graph export figureA1.pdf, replace


*===============================================================================
* FIGURE A.2
*===============================================================================


//Import data - only from 93 countries included in main analysis 
cd ..
cd "data"
use redistribution_merged,clear
reg rel_red_imp att_red_mid, robust
keep country
keep if e(sample)==1
merge 1:m country using wvs.dta
drop if _merge==2
drop _merge

//Compute means for each country and class

qui{
levelsof country, local(levels) 
local i = 1
foreach l of local levels {
    sum att_red_top if country==`l'
	scalar mean_att_top_`i' = r(mean)
    sum att_red_bottom if country==`l'
	scalar mean_att_bottom_`i' = r(mean)
    sum att_red_mid if country==`l'
	scalar mean_att_mid_`i' = r(mean)
	scalar country_`i' =  `l'
	local i = `i'+1
	}
}

clear 
set obs 93
egen t = seq()


gen mean_att_top_ =.
gen mean_att_bottom =.
gen mean_att_mid_=.
gen country =.


forvalues x = 1(1)93{
    replace country = country_`x' if t ==`x'
    foreach var in att_bottom att_top att_mid{
	    replace mean_`var' = mean_`var'_`x' if t ==`x'
	}
}

//Generate country names

kountry country, from(iso3n) m
tabulate country if MARKER==0
rename NAMES_STD country_str

replace country_str= "Taiwan" if country==158
replace country_str= "Serbia" if country==688
drop MARKER
tab country_str, m


sort mean_att_mid
egen x = seq()

//Assign country labels

replace country_str = "Bosnia Herzeg." if country_str=="Bosnia and Herzegovina"
replace country_str = "Kyrgyzstan" if country_str=="Kyrgyz Republic"
replace country_="Slovakia" if country_str=="Slovak Republic"
replace country_str="Trinidad Tobago" if country_str=="Trinidad and Tobago"

labmask x, values(country_str)
	
//Create ghost country to have equal number of countries for both figures

expand 2 if country_str=="Slovenia"

replace x = 94 if _n==94

replace mean_att_top=. if x ==94
replace mean_att_bottom=. if x ==94
replace mean_att_mid=. if x ==94

//Compute figure

cd ..
cd "output"	

twoway 	(scatter x mean_att_top if x < 48, mcolor("185 42 23") mlcolor("185 42 23") msymbol(d) msize(small)) ///
		(scatter x mean_att_mid if x < 48, mcolor("93 165 98") mlcolor("93 165 98") msymbol(o) msize(small)) ///
		(scatter x mean_att_bottom if x < 48, mcolor("26 64 101") mlcolor("26 64 101") msymbol(s) msize(small)), ///
		ylabel(1(1)47, valuelabel noticks labsize(vsmall) angle(0) nogrid) ytitle("", size(tiny)) ///
		xlabel(, labsize(vsmall) noticks) xtitle("0: We need larger Income differences, 9: Incomes should be equal", size(vsmall))  ///
		aspect(1.5) graphregion(color(white)) plotregion(fcolor(white) lcolor(white)) note("") ysize(7) xsize(5) saving(countryclass1, replace) ///
		legend(order(3 2 1)lab(1 "Top 5%") lab(2 "Middle 5%") lab(3 "Bottom 5%") size(vsmall) bmargin(zero) region(lwidth(none)) row(1)) 

twoway 	(scatter x mean_att_top if x >= 48, mcolor("185 42 23") mlcolor("185 42 23") msymbol(d) msize(small)) ///
		(scatter x mean_att_mid if x >= 48, mcolor("93 165 98") mlcolor("93 165 98") msymbol(o) msize(small)) ///
		(scatter x mean_att_bottom if x >= 48, mcolor("26 64 101") mlcolor("26 64 101") msymbol(s) msize(small)), ///
		ylabel(48(1)93, valuelabel noticks labsize(vsmall) angle(0) nogrid) ytitle("", size(tiny)) ///
		xlabel(, labsize(vsmall) noticks) xtitle("0: We need larger Income differences, 9: Incomes should be equal", size(vsmall))  ///
		aspect(1.5) graphregion(color(white)) plotregion(fcolor(white) lcolor(white)) note("") ysize(5) xsize(3) saving(countryclass2, replace) ///
		legend(order(3 2 1)lab(1 "Top 5%") lab(2 "Middle 5%") lab(3 "Bottom 5%") size(vsmall) bmargin(zero) region(lwidth(none)) row(1))

grc1leg "countryclass1" "countryclass2", xcommon  rows(1) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))  legendfrom(countryclass1) 


//Save figure
	
graph export figureA2.pdf, replace


*===============================================================================
* FIGURE A.3
*===============================================================================

//Import data
cd ..
cd "data"
use redistribution_merged.dta, clear


//Compute correlation coefficients
spearman att_red_top  att_red_mid
local topmed = round(r(rho),0.001)
di `topmed'

spearman att_red_top  att_red_bottom
local topbott = round(r(rho),0.001)
di `topbott'

spearman att_red_mid  att_red_bottom
local medbott = round(r(rho),0.001)
di `medbott'

cd ..
cd "output"

//Correlation between attitudes for top and middle
*Note: Manual insert corr coeff since cannot be displayed correctly
twoway (scatter att_red_top att_red_mid, sort) (lfit att_red_top att_red_mid),  xtitle("Attitudes of the Middle 5%", size(medlarge)) ytitle("Attitudes of the Top 5%", size(medlarge)) legend(off) yscale(lstyle(none)) xscale(lstyle(none))  ylabel(1 (1) 7, angle(horizontal) noticks)  xlabel(1 (1) 7, noticks)  xsize(8) ysize(8) text(6.8 4 "Spearman’s rho = 0.697") graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))    saving(topmid, replace) 

//Correlation between attitudes for top and bottom
twoway (scatter att_red_top att_red_bottom, sort) (lfit att_red_top att_red_bottom),  xtitle("Attitudes of the Bottom 5%", size(medlarge)) ytitle("Attitudes of the Top 5%", size(medlarge)) legend(off) yscale(lstyle(none)) xscale(lstyle(none))  ylabel(1 (1) 7, angle(horizontal) noticks)  xlabel(1 (1) 7, noticks)  xsize(8) ysize(8) text(6.8 4 "Spearman’s rho = 0`topbott'") graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))   saving(topbott, replace)

//Correlation between attitudes for middle and bottom
twoway (scatter att_red_mid att_red_bottom ,sort) (lfit att_red_mid att_red_bottom),  xtitle("Attitudes of the Bottom 5%", size(medlarge)) ytitle("Attitudes of the Middle 5%", size(medlarge)) legend(off) yscale(lstyle(none)) xscale(lstyle(none))  ylabel(1 (1) 7, angle(horizontal) noticks)  xlabel(1 (1) 7, noticks)  xsize(8) ysize(8) text(6.8 4 "Spearman’s rho = 0`medbott'") graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))   saving(midbott, replace)
graph export scatter_medianbottom.eps, replace

//Combine graphs
gr combine "topbott" "topmid"  "midbott", ycommon xcommon rows(1) iscale(1.2) xsize(10) ysize(3) note("0: We need larger Income diff, 9: Income should be equal", pos(6) ring(4) size(medlarge)) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))  

//Save figure
graph export figureA3.pdf,  replace	



*===============================================================================
* FIGURE A.4
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

//Compute index ventiles

xtile index_ventile = index, nq(20)

//Compute figure
set scheme s2color
binscatter2  belief_control index_ventile, absorb(country wave) ///
	xtitle("Ventiles of Socioeconomic Status Index", size(small)) ///
	xlabel(1  2  3  4  5  6  7 8 9  10  11  12 13 14 15  16  17  18 19 20, valuelabel noticks labgap(*1.3) labsize(small)) xscale(lstyle(none)) ///
	yscale(lstyle(none)) ylabel(, angle(horizontal) glcolor(gs14) labsize(small) noticks gmin) ///
	ytitle("Locus of Control""0: No choice at all, 9: Great deal of choice", size(small))   graphregion(color(white))  replace

//Save figure
cd ..
cd "output"
graph export figureA4.pdf, replace	



*===============================================================================
* FIGURE A.5
*===============================================================================

//Import data and keep countries from main analysis
cd ..
cd "data"
use redistribution_merged.dta, clear
reg rel_red_imp att_red_top, robust
keep if e(sample)==1

//Compute bootstrapped SEs
qui{
foreach x in dist_mode dist_med{
	foreach v in top mid bottom{
	bootstrap mean=r(mean), reps(1000): summarize `x'_`v'
	gen se_`x'_`v' = e(se)[1,1]    
	}
}
}

//Compute graphs of average distance by SES group

collapse dist_mode_top dist_mode_mid dist_mode_bottom dist_med_top dist_med_mid dist_med_bottom se_dist_mode_top se_dist_mode_mid se_dist_mode_bottom se_dist_med_top se_dist_med_mid se_dist_med_bottom

foreach v in top mid bottom{
    gen hi_mode_`v' = dist_mode_`v' + se_dist_mode_`v'
	gen lo_mode_`v' = dist_mode_`v' - se_dist_mode_`v'
	gen hi_med_`v' = dist_med_`v' + se_dist_med_`v'
	gen lo_med_`v' = dist_med_`v' - se_dist_med_`v'
}

expand 3
gen x = _n

cd ..
cd "output"


twoway 	(scatter dist_mode_bottom x if x == 1,  mcolor(navy) msymbol(O) msize(large)) ///
		(scatter dist_mode_mid x if x == 2, mcolor(navy) msymbol(O)  msize(large)) ///
		(scatter dist_mode_top x if x == 3, mcolor(navy) msymbol(O) msize(large)) ///
		(rcap hi_mode_bottom lo_mode_bottom x if x == 1, col(black) lwidth(medium)) ///
		(rcap hi_mode_mid lo_mode_mid x if x == 2, col(black) lwidth(medium)) ///
		(rcap hi_mode_top lo_mode_top x if x==3, col(black) lwidth(medium)), ///
		fxsize(85) ytitle("Difference", margin(esubhead) ) yscale(range(-0.5 1.5) lcolor(gs14)) ylabel(-0.5 0 0.5 1 1.5, angle(horizontal) glcolor(gs14) noticks gmin) ///
		xtitle("") legend(off) xlabel(1 "Bottom 5%" 2 "Middle 5%" 3"Top 5%", valuelabel noticks labgap(*1.3) labsize(small)) xscale(lstyle(none) range(0.5 3.5)) yline(0, lcolor(red)) ///
		graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) title("Difference from Modal Attitude") saving(mode, replace)



twoway 	(scatter dist_med_bottom x if x == 1,  mcolor(navy) msymbol(O) msize(large)) ///
		(scatter dist_med_mid x if x == 2, mcolor(navy) msymbol(O)  msize(large)) ///
		(scatter dist_med_top x if x == 3, mcolor(navy) msymbol(O) msize(large)) ///
		(rcap hi_med_bottom lo_med_bottom x if x == 1, col(black) lwidth(medium)) ///
		(rcap hi_med_mid lo_med_mid x if x == 2, col(black) lwidth(medium)) ///
		(rcap hi_med_top lo_med_top x if x==3, col(black) lwidth(medium)), ///
		fxsize(85) ytitle("", margin(esubhead)) yscale(range(-0.5 1.5) lcolor(gs14)) ylabel(-0.5 0 0.5 1 1.5, angle(horizontal) glcolor(gs14) noticks gmin) ///
		xtitle("") legend(off) xlabel(1 "Bottom 5%" 2 "Middle 5%" 3"Top 5%", valuelabel noticks labgap(*1.3) labsize(small)) xscale(lstyle(none) range(0.5 3.5)) yline(0, lcolor(red)) ///
		graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) title("Difference from Median Attitude") saving(median, replace)

		
//Combine graphs		
gr combine "mode" "median"  , ycommon xcommon rows(1)  graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))  

//Save figure
graph export figureA5.pdf,  replace



*===============================================================================
* FIGURE A.6
*===============================================================================

//Import data
cd ..
cd "data"
use laypeople_clean, clear

//Compute shares and SEs

keep if top_class==1 | middle_class==1 | bottom_class==1

gen class=.
replace class = 1 if top_class==1
replace class = 2 if middle_class==1
replace class = 3 if bottom_class==1

gen red_bottom_1 = 0
replace  red_bottom_1=1 if red_bottom ==1

gen red_middle_1 = 0
replace  red_middle_1=1 if red_middle ==1

gen red_top_1 = 0
replace  red_top_1=1 if red_top ==1



collapse (mean) red_bottom_1 red_middle_1 red_top_1  (semean) se_red_bottom_1 =red_bottom_1  se_red_middle_1=red_middle_1 se_red_top_1=red_top_1, by(class)

gen hiredbott = red_bottom_1 + se_red_bottom_1 				
gen loredbott = red_bottom_1 - se_red_bottom_1

gen hiredmid = red_middle_1 + se_red_middle_1 				
gen loredmid = red_middle_1 - se_red_middle_1

gen hiredtop = red_top_1 + se_red_top_1 				
gen loredtop = red_top_1 - se_red_top_1

expand 2, gen(red)
expand 2 if red==1, gen(dup)
replace red =2 if dup==1
drop dup


//Compute graphs
cd ..
cd "output"

//Predictions of top 10%
twoway 	(bar red_bottom_1 red if red == 0 & class==1, sort fcolor(white) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_middle_1 red if red == 1 & class==1, sort fcolor(gs12) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_top_1 red if red == 2 & class==1, sort fcolor(gs8) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(rcap hiredbott loredbott red if red == 0 & class==1, col(black) lwidth(medium)) ///
		(rcap hiredmid loredmid red if red == 1 & class==1, col(black) lwidth(medium)) ///
		(rcap hiredtop loredtop red if red == 2 & class==1, col(black) lwidth(medium)), ///
		fxsize(85)  ///
		ytitle("", margin(esubhead)) yscale(range(0 0.6) lcolor(gs14))  ylabel(0 0.2 "20" 0.4 "40" 0.6 "60" , angle(horizontal) glcolor(gs14) gmin noticks) ///
		xtitle("") legend(off) xlabel(0 "Bottom 5%" 1 "Middle 5%" 2 "Top 5%", valuelabel noticks labgap(*1.3) labsize(vsmall)) xscale(lstyle(none) range(-0.5 1.5)) scale(0.9) ///
		name(red_top, replace) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) title("Top 10%", color(black))
		

//Predictions of middle 10%
twoway 	(bar red_bottom_1 red if red == 0 & class==2, sort fcolor(white) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_middle_1 red if red == 1 & class==2, sort fcolor(gs12) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_top_1 red if red == 2 & class==2, sort fcolor(gs8) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(rcap hiredbott loredbott red if red == 0 & class==2, col(black) lwidth(medium)) ///
		(rcap hiredmid loredmid red if red == 1 & class==2, col(black) lwidth(medium)) ///
		(rcap hiredtop loredtop red if red == 2 & class==2, col(black) lwidth(medium)), ///
		fxsize(85)  ///
		ytitle("", margin(esubhead)) yscale(range(0 0.6) lcolor(gs14))  ylabel(0 0.2 "20" 0.4 "40" 0.6 "60" , angle(horizontal) glcolor(gs14) gmin noticks) ///
		xtitle("") legend(off) xlabel(0 "Bottom 5%" 1 "Middle 5%" 2 "Top 5%", valuelabel noticks labgap(*1.3) labsize(vsmall)) xscale(lstyle(none) range(-0.5 1.5)) scale(0.9) ///
		name(red_middle, replace) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) title("Middle 10%", color(black))
		
//Predictions of bottom 10%
twoway 	(bar red_bottom_1 red if red == 0 & class==3, sort fcolor(white) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_middle_1 red if red == 1 & class==3, sort fcolor(gs12) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_top_1 red if red == 2 & class==3, sort fcolor(gs8) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(rcap hiredbott loredbott red if red == 0 & class==3, col(black) lwidth(medium)) ///
		(rcap hiredmid loredmid red if red == 1 & class==3, col(black) lwidth(medium)) ///
		(rcap hiredtop loredtop red if red == 2 & class==3, col(black) lwidth(medium)), ///
		fxsize(85)  ///
		ytitle("", margin(esubhead)) yscale(range(0 0.6) lcolor(gs14))  ylabel(0 0.2 "20" 0.4 "40" 0.6 "60", angle(horizontal) glcolor(gs14) gmin noticks) ///
		xtitle("") legend(off) xlabel(0 "Bottom 5%" 1 "Middle 5%" 2 "Top 5%", valuelabel noticks labgap(*1.3) labsize(vsmall)) xscale(lstyle(none) range(-0.5 1.5)) scale(0.9) ///
		name(red_bottom, replace) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) title("Bottom 10%", color(black))
		


gr combine red_bottom red_middle red_top, row(1) ycommon xcommon l1(% of participants, size(medlarge)) iscale(1.5) xsize(10) ysize(3) graphregion(fcolor(white) lcolor(white)) 

//Save graph
graph export figureA6.pdf, replace



