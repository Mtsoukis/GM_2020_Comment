capture which here
if _rc ssc install here, replace
here

*******************************************************
* Build share of Opening Night operas found in Loewenberg
* 1781–1820, Italy
*******************************************************

clear all
set more off

*--- paths ------------------------------------------------
local datadir "${data_new}"

*--- (1) Loewenberg: collapse to state–year counts --------
import delimited "`datadir'/Loewenberg_1781_1820_it_raw.csv", varnames(1) clear

* Count number of Loewenberg operas per state–year
contract state_region year, freq(n_operas)
tempfile loew_counts
save `loew_counts', replace

*--- (2) Opening Night totals: state–year panel -----------
import delimited "`datadir'/Opening_Night_Operas_it_cleaned.csv", varnames(1) clear
rename state state_region
keep if inrange(year,1781,1820)

* This file is already state–year totals named "operas"
* Duchy_Modena is present here but not in Loewenberg; merge will yield missing n_operas -> set to 0

*--- (3) Merge Loew counts onto Opening Night panel -------
merge 1:1 state_region year using `loew_counts', nogen keep(master match)
replace n_operas = 0 if missing(n_operas)

* Optional sanity checks
* assert !missing(state_region, year, operas)
* assert n_operas >= 0
* If you want to be strict about the share range (ignoring 0 denominators), enable:
* assert n_operas <= operas if operas>0

*--- (4) Build share: Loew / Opening_Night ----------------
* Ensure Loew count is 0 when absent after the merge
replace n_operas = 0 if missing(n_operas)

* Define share with 0 when Opening_Night total is 0 or missing
gen double n_operas_share = 0
replace n_operas_share = n_operas/operas if operas>0 & !missing(operas, n_operas)

label var n_operas_share "Share of Opening-Night operas found in Loewenberg (0 if undefined)"

* Sanity check: share within [0,1]
assert inrange(n_operas_share, 0, 1)

*--- (5) Fixed effects & treatment indicator --------------
capture confirm variable state1
if _rc encode state_region, gen(state1)

capture confirm variable copyright_post1801
if _rc gen byte copyright_post1801 = inlist(state_region, "Venetia", "Lombardia") & year > 1800
label var copyright_post1801 "Post-1800 in Venetia/Lombardia"

*--- (6) Regression on full sample (no if-filter) --------
reg n_operas_share copyright_post1801 i.state1 i.year, nocon robust
