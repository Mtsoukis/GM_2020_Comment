
clear all
set more off


here

/*******************************************************************************
* STEP 1: AGGREGATE CITY-LEVEL DATA TO THE STATE-LEVEL
*******************************************************************************/

// Use the city-level dataset
use "${here}/Replication_Package/Data_GM2020/city_level_operas_1781_1820.dta", clear

// Generate a 'state' variable based on city names
gen state = ""
replace state = "lombardy" if inlist(city, "milan", "bergamo", "brescia", "mantua")
replace state = "venetia" if inlist(city, "venice", "verona", "vicenza", "padova", "rovigo")

// Keep only the observations for Lombardy and Venetia
keep if inlist(state, "lombardy", "venetia")

// Generate new variables for opera counts, excluding the main cities
gen new_operas_no_milan = operas_city if state == "lombardy" & city != "milan"
gen new_operas_novenice = operas_city if state == "venetia" & city != "venice"
gen new_opera_nomi_nove = operas_city if (state == "lombardy" & city != "milan") | (state == "venetia" & city != "venice")

// Collapse the data by state and year to get total opera counts
collapse (sum) new_operas_no_milan new_operas_novenice new_opera_nomi_nove, by(state year)

// Save the aggregated data to a temporary file
tempfile city_agg
save `city_agg'

/*******************************************************************************
* STEP 2: MERGE AGGREGATED DATA AND UPDATE THE MAIN DATASET
*******************************************************************************/

// Load the main state-level dataset
use "${here}/Replication_Package/Data_GM2020/operas_1781_1820.dta", clear

// Merge the new city-aggregated data with the main dataset
merge 1:1 state year using `city_agg', nogenerate

// Replace the original variables with the newly calculated ones for the relevant states
replace operas_no_milan = new_operas_no_milan if state == "lombardy"
replace operas_novenice = new_operas_novenice if state == "venetia"

// 'opera_nomi_nove' is the count excluding Milan for Lombardy and excluding Venice for Venetia
replace opera_nomi_nove = new_opera_nomi_nove if inlist(state, "lombardy", "venetia")

// Drop the temporary variables used for the merge
drop new_operas_no_milan new_operas_novenice new_opera_nomi_nove

/*******************************************************************************
* STEP 3: RUN THE REGRESSIONS FROM THE ORIGINAL DO-FILE
* This section replicates the analysis from JPE_MS_20180234_AppendixTableA6.do
*******************************************************************************/

// Set the panel data structure
xtset state1 year

//***** EXCLUDING VENICE *****
reg operas_novenice copyright_post1801 i.state1 i.year, nocon robust

poisson operas_novenice copyright_post1801 i.state1 i.year, vce(robust)

//***** EXCLUDING MILAN *****
reg operas_no_milan copyright_post1801 i.state1 i.year, nocon robust

poisson operas_no_milan copyright_post1801 i.state1 i.year, vce(robust)

//***** EXCLUDING MILAN AND VENICE *****
reg opera_nomi_nove copyright_post1801 i.state1 i.year, nocon robust

poisson opera_nomi_nove copyright_post1801 i.state1 i.year, vce(robust)

//***** EXCLUDING VENETIA STATE *****
preserve
drop if state == "venetia"

reg operas copyright_post1801 i.state1 i.year, nocon robust

poisson operas copyright_post1801 i.state1 i.year, vce(robust)
restore
