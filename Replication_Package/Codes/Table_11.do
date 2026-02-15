capture which here
if _rc ssc install here, replace
capture which esttab
if _rc ssc install estout, replace
here
eststo clear

* Build Loewenberg counts once and reuse for corrected count/share columns.
import delimited "${data_new}/Loewenberg_1781_1820_it_raw.csv", clear
contract state_region year if inrange(year,1781,1820), freq(n_operas)
tempfile loew_counts_sr loew_counts_state states years
save `loew_counts_sr', replace

* Also prepare Loewenberg counts in GM2020 state coding for share-on-GM denominator.
use `loew_counts_sr', clear
gen str20 state = ""
replace state = "d_parma"      if state_region == "Duchy_Parma"
replace state = "two_sicilies" if state_region == "Due_Sicilie"
replace state = "lombardy"     if state_region == "Lombardia"
replace state = "papal_state"  if state_region == "Papal"
replace state = "sardinia"     if state_region == "Sardinia"
replace state = "gd_tuscany"   if state_region == "Toscana"
replace state = "venetia"      if state_region == "Venetia"
drop if state == ""
collapse (sum) n_operas, by(state year)
save `loew_counts_state', replace

* Column (1): GM2020 count.
use "${data_gm}/operas_1781_1820.dta", clear
reg operas_annals copyright_post1801 i.state1 i.year, nocon robust
estadd scalar state_fe = 1
estadd scalar year_fe = 1
eststo m1

* Column (2): GM2020 share (operas_annals / operas).
capture drop share_annals
gen double share_annals = 0
replace share_annals = operas_annals/operas if operas > 0 & !missing(operas, operas_annals)
reg share_annals copyright_post1801 i.state1 i.year, nocon robust
estadd scalar state_fe = 1
estadd scalar year_fe = 1
eststo m2

* Column (3): Corrected Loewenberg count.
use `loew_counts_sr', clear
keep state_region
duplicates drop
local newN = _N + 1
set obs `newN'
replace state_region = "d_modena" in `newN'
duplicates drop state_region, force
save `states', replace

clear
set obs 40
gen year = 1780 + _n
save `years', replace

use `states', clear
cross using `years'
merge 1:1 state_region year using `loew_counts_sr', nogen
replace n_operas = 0 if missing(n_operas)
capture drop state1
capture drop copyright_post1801
encode state_region, gen(state1)
gen byte copyright_post1801 = inlist(state_region, "Venetia", "Lombardia") & year > 1800
reg n_operas copyright_post1801 i.state1 i.year, nocon robust
estadd scalar state_fe = 1
estadd scalar year_fe = 1
eststo m3

* Column (4): Corrected Loewenberg share with GM2020 denominator.
use "${data_gm}/operas_1781_1820.dta", clear
merge 1:1 state year using `loew_counts_state', nogen keep(master match)
replace n_operas = 0 if missing(n_operas)
capture drop n_operas_share
gen double n_operas_share = 0
replace n_operas_share = n_operas/operas if operas > 0 & !missing(operas, n_operas)
reg n_operas_share copyright_post1801 i.state1 i.year, nocon robust
estadd scalar state_fe = 1
estadd scalar year_fe = 1
eststo m4

* Column (5): Corrected Loewenberg share with ON denominator.
import delimited "${data_new}/Opening_Night_Operas_it_cleaned.csv", varnames(1) clear
rename state state_region
keep if inrange(year,1781,1820)
merge 1:1 state_region year using `loew_counts_sr', nogen keep(master match)
replace n_operas = 0 if missing(n_operas)
capture drop n_operas_share
gen double n_operas_share = 0
replace n_operas_share = n_operas/operas if operas > 0 & !missing(operas, n_operas)
capture drop state1
capture drop copyright_post1801
encode state_region, gen(state1)
gen byte copyright_post1801 = inlist(state_region, "Venetia", "Lombardia") & year > 1800
reg n_operas_share copyright_post1801 i.state1 i.year, nocon robust
estadd scalar state_fe = 1
estadd scalar year_fe = 1
eststo m5

esttab m1 m2 m3 m4 m5 using "${tables}/Table_11.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe, labels("State FE" "Year FE")) ///
    mtitles("Count" "Share" "Count" "Share GM2020" "Share ON") ///
    replace tex

clear all
