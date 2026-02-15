capture which here
if _rc ssc install here, replace
here

*******************************************************
* Share of GM2020 operas found in Loewenberg
* 1781–1820, Italy
*******************************************************

clear all
set more off

*--- paths ------------------------------------------------
* Loewenberg still lives in Data_New, GM2020 panel in Data_GM2020
local loewdir "${data_new}"
local gmdir   "${data_gm}"

*--- (1) Loewenberg: collapse to state–year counts --------
import delimited "`loewdir'/Loewenberg_1781_1820_it_raw.csv", ///
    varnames(1) clear

* Make sure we have a variable called state_region
capture confirm variable state_region
if _rc {
    capture rename State_Region state_region
}

* Map Loewenberg's state names to GM2020's `state' codes
gen str20 state = ""
replace state = "d_parma"      if state_region == "Duchy_Parma"
replace state = "two_sicilies" if state_region == "Due_Sicilie"
replace state = "lombardy"     if state_region == "Lombardia"
replace state = "papal_state"  if state_region == "Papal"
replace state = "sardinia"     if state_region == "Sardinia"
replace state = "gd_tuscany"   if state_region == "Toscana"
replace state = "venetia"      if state_region == "Venetia"

assert state != ""   // ensure every Loewenberg obs is mapped

* Count number of Loewenberg operas per state–year (in GM coding)
contract state year, freq(n_operas)
tempfile loew_counts
save `loew_counts', replace

*--- (2) GM2020: state–year panel -------------------------
use "`gmdir'/operas_1781_1820.dta", clear
* This file is already an Italy state–year panel for 1781–1820,
* with total operas in variable `operas'.

*--- (3) Merge Loew counts onto GM2020 panel --------------
merge 1:1 state year using `loew_counts', nogen keep(master match)

* Loew not present in some state–years (e.g. d_modena) -> set to 0
replace n_operas = 0 if missing(n_operas)

* Optional sanity checks
* assert !missing(state, year, operas)
* assert n_operas >= 0
* NOTE: with GM2020 totals, n_operas can exceed `operas' in a few cells,
*       so we *do not* enforce n_operas <= operas here.

*--- (4) Build Loew / GM2020 ratio ------------------------
* Define ratio with 0 when GM2020 total is 0 or missing
gen double n_operas_share = 0
replace n_operas_share = n_operas/operas if operas > 0 & !missing(operas, n_operas)

label var n_operas_share "Loewenberg / GM2020 'operas' (0 if undefined)"

* With GM2020 as denominator this ratio can be > 1, so just check non-negativity
assert n_operas_share >= 0

*--- (5) Fixed effects & treatment indicator --------------
* GM2020 already has state1 and copyright_post1801,
* but keep this robust in case you run it on a variant.

capture confirm variable state1
if _rc encode state, gen(state1)

capture confirm variable copyright_post1801
if _rc {
    gen byte copyright_post1801 = inlist(state, "venetia", "lombardy") & year > 1800
    label var copyright_post1801 "Post-1800 in Venetia/Lombardy"
}

*--- (6) Regression on full sample (no if-filter) ---------
reg n_operas_share copyright_post1801 i.state1 i.year, nocon robust
