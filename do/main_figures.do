*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Figures for main manuscript
*Last update: 04.03.23


*Note: To run the analyses, data cleaning should be applied first by running the do-file prepare_data

*===============================================================================


//Settings

set more off
clear all
set maxvar 15000, permanently
set matsize 5000
set linesize 80  

*===============================================================================
* FIGURE 1
*===============================================================================


//Import data

cd "$root/data"
use redistribution_merged.dta, clear


//Compute correlation coefficients
spearman rel_red_imp  att_red_top
local top = round(r(rho),0.001)
di `top'

spearman rel_red_imp  att_red_mid
local mid = round(r(rho),0.001)
di `mid'

spearman rel_red_imp  att_red_bottom
local bott = round(r(rho),0.001)
di `bott'


cd "$root/output"

//Correlation between top preferences and redistribution
twoway (scatter rel_red_imp att_red_top, sort mcolor(gray)) (lfit rel_red_imp att_red_top, lcolor(black) lwidth(medthick)),  xtitle("Attitudes of the Top 5%", size(medlarge)) ytitle("") legend(off) yscale(lstyle(none)) xscale(lstyle(none))  ylabel(-20 0 20 40 60, angle(horizontal) glcolor(gs14) gmin noticks)  xlabel(1 (1) 7, noticks) xsize(8) ysize(8) text(55 4 "Spearman's rho = `top'") graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))  saving(redtop, replace) 

//Correlation between middle preferences and redistribution
twoway (scatter rel_red_imp att_red_mid, sort mcolor(gray)) (lfit rel_red_imp att_red_mid, lcolor(black) lwidth(medthick)),  xtitle("Attitudes of the Middle 5%", size(medlarge)) ytitle("")  legend(off) yscale(lstyle(none)) xscale(lstyle(none))  ylabel(-20 0 20 40 60, angle(horizontal) glcolor(gs14) gmin noticks)  xlabel(1 (1) 7, noticks) xsize(8) ysize(8) text(55 4 "Spearman's rho = `mid'") graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))  saving(redmid, replace)

//Correlation between attitudes for median/bottom 
twoway (scatter rel_red_imp att_red_bottom ,sort mcolor(gray)) (lfit rel_red_imp att_red_bottom, lcolor(black) lwidth(medthick) ),  xtitle("Attitudes of the Bottom 5%", size(medlarge)) ytitle("")  legend(off) yscale(lstyle(none)) xscale(lstyle(none))  ylabel(-20 0 20 40 60, angle(horizontal) glcolor(gs14) gmin noticks)  xlabel(1 (1) 7, noticks) xsize(8) ysize(8) text(55 4 "Spearman's rho = `bott'") graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))  saving(redbott, replace)

//Combine graphs
gr combine "redtop" "redmid" "redbott", xcommon rows(1) l1(Relative redistribution, size(large)) iscale(1.2) xsize(10) ysize(3) note("0: We need larger Income diff, 9: Income should be equal",pos(6) ring(4) size(medlarge)) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))  


//Save figure
graph export figure1.eps, replace	


*===============================================================================
*FIGURE 2 - PANEL A (EXPERTS)
*===============================================================================

//Import data
cd "$root/data"
use expert_clean, clear


//Compute shares and SEs

gen red_bottom_1 = 0
replace  red_bottom_1=1 if red_bottom ==1

gen red_middle_1 = 0
replace  red_middle_1=1 if red_middle ==1

gen red_top_1 = 0
replace  red_top_1=1 if red_top ==1


collapse (mean) red_bottom_1 red_middle_1 red_top_1   (semean) se_red_bottom_1 =red_bottom_1  se_red_middle_1=red_middle_1 se_red_top_1=red_top_1 

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


//Compute figure

twoway 	(bar red_bottom_1 red if red == 0 , sort fcolor(white) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_middle_1 red if red == 1 , sort fcolor(gs12) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_top_1 red if red == 2 , sort fcolor(gs8) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(rcap hiredbott loredbott red if red == 0 , col(black) lwidth(medium)) ///
		(rcap hiredmid loredmid red if red == 1 , col(black) lwidth(medium)) ///
		(rcap hiredtop loredtop red if red == 2 , col(black) lwidth(medium)), ///
		fxsize(85)  ///
		ytitle("% of participants", margin(esubhead) size(large)) yscale(range(0 0.6) lcolor(gs14))  ylabel(0 0.2 "20" 0.4 "40" 0.6 "60" , labsize(medlarge) angle(horizontal) glcolor(gs14) gmin noticks) ///
		xtitle("") legend(off) xlabel(0 "Bottom 5%" 1 "Middle 5%" 2 "Top 5%", valuelabel noticks labgap(*1.3) labsize(medlarge)) xscale(lstyle(none) range(-0.5 1.5)) scale(0.9) ///
		name(red_neutral, replace) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) title("")

//Save figure

cd "$root/output"
graph export figure2a.eps, replace 

*===============================================================================
*FIGURE 2 - PANEL B (LAYPEOPLE)
*===============================================================================

//Import data

cd "$root/data"
use laypeople_clean, clear

//Compute shares and SEs

gen red_bottom_1 = 0
replace  red_bottom_1=1 if red_bottom ==1

gen red_middle_1 = 0
replace  red_middle_1=1 if red_middle ==1

gen red_top_1 = 0
replace  red_top_1=1 if red_top ==1


collapse (mean) red_bottom_1 red_middle_1 red_top_1  (semean) se_red_bottom_1 =red_bottom_1  se_red_middle_1=red_middle_1 se_red_top_1=red_top_1 

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

//Compute figure

twoway 	(bar red_bottom_1 red if red == 0 , sort fcolor(white) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_middle_1 red if red == 1 , sort fcolor(gs12) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(bar red_top_1 red if red == 2 , sort fcolor(gs8) lcolor(black) lwidth(vthin) barwidth(0.8)) ///
		(rcap hiredbott loredbott red if red == 0 , col(black) lwidth(medium)) ///
		(rcap hiredmid loredmid red if red == 1 , col(black) lwidth(medium)) ///
		(rcap hiredtop loredtop red if red == 2 , col(black) lwidth(medium)), ///
		fxsize(85)  ///
		ytitle("% of participants", margin(esubhead) size(large)) yscale(range(0 0.6) lcolor(gs14))  ylabel(0 0.2 "20" 0.4 "40" 0.6 "60" , labsize(medlarge) angle(horizontal) glcolor(gs14) gmin noticks) ///
		xtitle("") legend(off) xlabel(0 "Bottom 5%" 1 "Middle 5%" 2 "Top 5%", valuelabel noticks labgap(*1.3) labsize(medlarge)) xscale(lstyle(none) range(-0.5 1.5)) scale(0.9) ///
		name(red, replace) graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) title("")
		
//Save figure
cd "$root/output"
graph export figure2b.eps, replace 		

