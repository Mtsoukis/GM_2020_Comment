capture which here
if _rc ssc install here, replace
capture which esttab
if _rc ssc install estout, replace
here

clear all
set more off
eststo clear

/*******************************************************************************
* Panel A: GM2020 original specification 
*******************************************************************************/
use "${data_gm}/operas_1781_1820.dta", clear
xtset state1 year

* Column 1: with state and year fixed effects
reg operas copyright_post1801 i.state1 i.year, nocon cluster(cluster)
estadd scalar year_fe = 1
estadd scalar state_fe = 1
eststo a1

* Column 2: with treated indicator and year fixed effects
reg operas copyright_post1801 copyright i.year, nocon cluster(cluster)
estadd scalar year_fe = 1
estadd scalar state_fe = 0
eststo a2

/*******************************************************************************
* Panel B: Corrected collapsed specification (Bertrand et al. 2004)
*******************************************************************************/
use "${data_gm}/operas_1781_1820.dta", clear

collapse (mean) operas, by(state post1801)

gen treated = (state == "venetia" | state == "lombardy")
gen treat_post = treated * post1801
encode state, gen(state1)

xtset state1 post1801

* Column 1: with state fixed effects
reg operas treat_post post1801 i.state1, vce(robust) nocon

* I suppose it's better to do this: reg operas treat_post post1801 i.state1, vce(cluster state1) nocon
* but the other one works too- gives more benefit of the doubt to Giorcelli & Moser. 

estadd scalar year_fe = 1
estadd scalar state_fe = 1
eststo b1

* Column 2: with treated dummy instead of state fixed effects
reg operas treat_post post1801 treated, vce(robust) nocon
estadd scalar year_fe = 1
estadd scalar state_fe = 0
eststo b2

esttab a1 a2 using "${tables}/Table_6.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    replace tex title("Panel A: GM2020 Original Specification")

esttab b1 b2 using "${tables}/Table_6.txt", ///
    keep(treat_post) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    append tex title("Panel B: GM2020 Corrected Specification")
