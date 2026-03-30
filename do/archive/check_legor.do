use "../data/redistribution_augmented.dta", clear
tab legor_uk, m
tab legor, m
list country_str iso3 legor_uk if missing(legor_uk)
