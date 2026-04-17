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
estadd local year_fe "Yes"
estadd local state_fe "Yes"
eststo a1

* Column 2: with treated indicator and year fixed effects
reg operas copyright_post1801 copyright i.year, nocon cluster(cluster)
estadd local year_fe "Yes"
estadd local state_fe "No"
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
reg operas treat_post post1801 i.state1, vce(cluster state1) nocon

estadd local year_fe "Yes"
estadd local state_fe "Yes"
eststo b1

* Column 2: with treated dummy instead of state fixed effects
reg operas treat_post post1801 treated, vce(cluster state1) nocon
estadd local year_fe "Yes"
estadd local state_fe "No"
eststo b2

esttab a1 a2 using "${tables}/Table_6a.txt", ///
    keep(copyright_post1801 copyright) ///
    order(copyright_post1801 copyright) ///
    coeflabels(copyright_post1801 "Lombardy \& Venetia × post" ///
               copyright "Lombardy \& Venetia") ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("OLS" "OLS") ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    replace tex title("Panel A: GM2020 Original Specification")

esttab b1 b2 using "${tables}/Table_6b.txt", ///
    keep(treat_post treated) ///
    order(treat_post treated) ///
    coeflabels(treat_post "Lombardy \& Venetia × post" ///
               treated "Lombardy \& Venetia") ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("OLS" "OLS") ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    replace tex title("Panel B: GM2020 Corrected Specification")
