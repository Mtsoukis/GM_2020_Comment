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

esttab a1 a2 a3 a4 a5 a6 a7 a8 using "${tables}/Table_4_2.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    mtitles("OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson") ///
    replace tex title("Panel A: GM2020 operas_1781_1820.dta")

/*******************************************************************************
* Panel B: City-level data collapsed to the eight GM2020 states
*******************************************************************************/
tempfile city_counts states years

use "${data_gm}/city_level_operas_1781_1820.dta", clear

gen str20 state = ""
replace state = "papal_state"  if inlist(city, "ancona", "bologna", "ferrara", "rome")
replace state = "lombardy"     if inlist(city, "bergamo", "brescia", "mantua", "milan")
replace state = "gd_tuscany"   if inlist(city, "florence", "livorno")
replace state = "sardinia"     if inlist(city, "genoa", "turin")
replace state = "two_sicilies" if inlist(city, "messina", "naples", "palermo")
replace state = "d_modena"     if inlist(city, "modena", "reggio_emilia")
replace state = "venetia"      if inlist(city, "padova", "rovigo", "venice", "verona", "vicenza")
replace state = "d_parma"      if inlist(city, "parma", "piacenza")

assert state != ""

gen operas = operas_city
gen operas_no_milan = operas_city if city != "milan"
replace operas_no_milan = 0 if missing(operas_no_milan)

gen operas_novenice = operas_city if city != "venice"
replace operas_novenice = 0 if missing(operas_novenice)

gen opera_nomi_nove = operas_city if !inlist(city, "milan", "venice")
replace opera_nomi_nove = 0 if missing(opera_nomi_nove)

collapse (sum) operas operas_no_milan operas_novenice opera_nomi_nove, by(state year)
save `city_counts', replace

use `city_counts', clear
keep state
duplicates drop
assert _N == 8
save `states', replace

clear
set obs 40
gen year = 1780 + _n
save `years', replace

use `states', clear
cross using `years'
merge 1:1 state year using `city_counts', nogen

foreach var of varlist operas operas_no_milan operas_novenice opera_nomi_nove {
    replace `var' = 0 if missing(`var')
}

assert _N == 320
bysort state year: assert _N == 1
assert inlist(state, "d_modena", "d_parma", "gd_tuscany", "lombardy", "papal_state", "sardinia", "two_sicilies", "venetia")

encode state, gen(state1)
gen byte copyright = inlist(state, "lombardy", "venetia")
gen byte post1801 = year > 1800
gen byte copyright_post1801 = copyright & post1801

eststo clear
run_table4_models, prefix(b)

esttab b1 b2 b3 b4 b5 b6 b7 b8 using "${tables}/Table_4_2.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    mtitles("OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson" "OLS" "Poisson") ///
    append tex title("Panel B: City-level data collapsed to the eight GM2020 states")
