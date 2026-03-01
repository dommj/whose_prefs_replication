**********************************************************************
***          Whose Preferences Matter for Redistribution: 		   ***
***            			Cross-country Evidence 	 			       ***
***										 					   	   ***
***  Michel Marechal, Alain Cohn, Jeffrey Yusof, Raymond Fisman   ***
**********************************************************************

*** This do file replicates Figures D.1 and D.2 of the Online Appendix.	***


*net install cleanplots, from("https://tdmize.github.io/data/cleanplots") 				// To install graph scheme, simply execute this code line
set scheme cleanplots 

* load data
cd ..
cd "data"
use experiment_data.dta, clear



*************************
** Income Distribution **
*************************

tab incomeUS, mi
drop if incomeUS==.
snapshot save



**************************
**	Figures D.1 and D.2 **
**************************

* change directory
cd ..
cd "output"

snapshot restore 1
collapse (mean) taxwealth taxincome (semean) taxwealthse= taxwealth taxincomese = taxincome, by(incomeUS)

gen x = 5 			if incomeUS ==1
replace x = 15 		if incomeUS ==2
replace x = 25 		if incomeUS ==3
replace x = 35 		if incomeUS ==4
replace x = 45 		if incomeUS ==5
replace x = 55 		if incomeUS ==6
replace x = 65 		if incomeUS ==7
replace x = 75 		if incomeUS ==8
replace x = 90 		if incomeUS ==9
replace x = 110 	if incomeUS ==10
replace x = 135 	if incomeUS ==11
replace x = 175 	if incomeUS ==12
replace x = 225 	if incomeUS ==13
replace x = 300 	if incomeUS ==14
replace x = 425 	if incomeUS ==15
replace x = 625 	if incomeUS ==16
replace x = 875 	if incomeUS ==17
replace x = 1500 	if incomeUS ==18

label define income_lab 5 "0-10k" 15 "10-20k" 25 "20-30k" 35 "30-40k" 45 "40-50k" 55 "50-60k" 65 "60-70k" 75 "70-80k" 90 "80-100k" 110 "100-120k" 135 "120-150k" 175 "150-200k" 225 "200-250k" 300 "250-350k" 425 "350-500k" 625 "500-750k" 875 "750k-1m" 1500 "1m+", replace
label values x income_lab

foreach var in taxwealth taxincome {
gen hi`var' = `var' + 2*`var'se 
gen lo`var' = `var' - 2*`var'se 
}

*mean attitudes + 95% confidence interval 
#delimit ;
twoway  (scatter taxincome x if x!=175 & x!=875, mcolor(gs12) msymbol(smcircle) sort) (scatter taxincome x if x==175 | x==875, mcolor(black) sort) (rcap hitaxincome lotaxincome x if x!=175 & x!=875, color(gs12)) (rcap hitaxincome lotaxincome x if x==175 | x==875, color(black)), ytitle("Attitudes towards the top income" "(-2 = much lower, 2 = much higher)") ylabel(-2(1)2) xtitle(Household income) xlabel(5 55 110 175 225 300 425 625 875 1500, valuelabel angle(45)) legend(order(2 "Mean" 4 "95% CI") holes(1 3) cols(1) size(small) ring(0) position(1) bmargin(r+10 t+4)) name(taxincome, replace)
;	
#delimit cr	
graph export "figureD1.pdf", replace

#delimit ;
twoway  (scatter taxwealth x if x!=175 & x!=875, mcolor(gs12) msymbol(smcircle) sort) (scatter taxwealth x if x==175 | x==875, mcolor(black) sort) (rcap hitaxwealth lotaxwealth x if x!=175 & x!=875, color(gs12)) (rcap hitaxwealth lotaxwealth x if x==175 | x==875, color(black)), ytitle("Attitudes towards the estate tax" "(-2 = much lower, 2 = much higher)") ylabel(-2(1)2) xtitle(Household income) xlabel(5 55 110 175 225 300 425 625 875 1500, valuelabel angle(45)) legend(order(2 "Mean" 4 "95% CI") holes(1 3) cols(1) size(small) ring(0) position(1) bmargin(r+10 t+4)) name(taxwealth, replace)
;	
#delimit cr	
graph export "figureD2.pdf", replace



