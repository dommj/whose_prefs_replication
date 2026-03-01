*===============================================================================
*DISCLAIMER
*===============================================================================

*Projec: Whose Preferences Matter For Redistribution - JPE Micro 
*Do-File: Runs all data cleaning do files
*Last update: 05.03.23

*===============================================================================

//Additional packages

*ssc install egenmore
*ssc install kountry

//Prepare WVS data
global root "/Users/domj/Library/CloudStorage/OneDrive-Personal/Documents/BSE/Political Economy/final_project/whose_prefs_replication"

cd "$root/do"

do prepare_data_wvs

//Prepare WVS data for wave 3 and 4

cd "$root/do"

do prepare_data_wvs_wave34

//Prepare WVS data for wave 5 and 6

cd "$root/do"

do prepare_data_wvs_wave56

//Prepare ISSP data

cd "$root/do"

do prepare_data_issp.do
