capture which here
if _rc ssc install here, replace
capture which esttab
if _rc ssc install estout, replace
here

clear all
set more off

** There is a small discrepancy between code output and column 8 of the table. This is because Table 4 Panel A is taken verbatim from GM2020- where their replication code and table have small differences. 

capture program drop run_table4_models
program define run_table4_models
    syntax, Prefix(string)

    xtset state1 year

    * Column 1: OLS excluding Venice
    reg operas_novenice copyright_post1801 i.state1 i.year, nocon robust
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'1

    * Column 2: Poisson excluding Venice
    poisson operas_novenice copyright_post1801 i.state1 i.year, vce(robust)
    margins, dydx(*) post
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'2

    * Column 3: OLS excluding Milan
    reg operas_no_milan copyright_post1801 i.state1 i.year, nocon robust
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'3

    * Column 4: Poisson excluding Milan 
    poisson operas_no_milan copyright_post1801 i.state1 i.year, vce(robust)
    margins, dydx(*) post
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'4

    * Column 5: OLS excluding Milan and Venice
    reg opera_nomi_nove copyright_post1801 i.state1 i.year, nocon robust
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'5

    * Column 6: Poisson excluding Milan and Venice
    poisson opera_nomi_nove copyright_post1801 i.state1 i.year, vce(robust)
    margins, dydx(*) post
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'6

    * Column 7: OLS excluding Venetia
    preserve
    drop if state == "venetia"
    reg operas copyright_post1801 i.state1 i.year, nocon robust
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'7

    * Column 8: Poisson excluding Venetia
    poisson operas copyright_post1801 i.state1 i.year, vce(robust)
    margins, dydx(*) post
    estadd scalar state_fe = 1
    estadd scalar year_fe = 1
    eststo `prefix'8
    restore
end

/*******************************************************************************
* Panel A: GM2020 operas_1781_1820.dta
*******************************************************************************/
use "${data_gm}/operas_1781_1820.dta", clear
eststo clear
run_table4_models, prefix(a)

esttab a1 a2 a3 a4 a5 a6 a7 a8 using "${tables}/Table_4.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    mtitles("OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson") ///
    replace tex title("Panel A: GM2020 operas_1781_1820.dta")

/*******************************************************************************
* Panel B: Rebuilt exclusions from city_level_operas_1781_1820.dta
*******************************************************************************/
tempfile city_agg

use "${data_gm}/city_level_operas_1781_1820.dta", clear

gen state = ""
replace state = "lombardy" if inlist(city, "milan", "bergamo", "brescia", "mantua")
replace state = "venetia" if inlist(city, "venice", "verona", "vicenza", "padova", "rovigo")

keep if inlist(state, "lombardy", "venetia")

gen new_operas_no_milan = operas_city if state == "lombardy" & city != "milan"
gen new_operas_novenice = operas_city if state == "venetia" & city != "venice"
gen new_opera_nomi_nove = operas_city if (state == "lombardy" & city != "milan") | (state == "venetia" & city != "venice")

collapse (sum) new_operas_no_milan new_operas_novenice new_opera_nomi_nove, by(state year)
save `city_agg', replace

use "${data_gm}/operas_1781_1820.dta", clear
merge 1:1 state year using `city_agg', nogenerate

replace operas_no_milan = new_operas_no_milan if state == "lombardy"
replace operas_novenice = new_operas_novenice if state == "venetia"
replace opera_nomi_nove = new_opera_nomi_nove if inlist(state, "lombardy", "venetia")
drop new_operas_no_milan new_operas_novenice new_opera_nomi_nove

eststo clear
run_table4_models, prefix(b)

esttab b1 b2 b3 b4 b5 b6 b7 b8 using "${tables}/Table_4.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    mtitles("OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson") ///
    append tex title("Panel B: Rebuilt exclusions from city_level_operas_1781_1820.dta")
