capture which here
if _rc ssc install here, replace
here

clear 

use "${data_gm}/operas_1781_1820.dta"
xtset state1 year

* Rebuild the pretrend variables explicitly so the specification does not
* depend on any shipped intermediate columns in the dataset. I explain in 3.3 why their pre-trends are not correct. Regardless, their preferred regression is reported in column 1.  
capture drop prebase
capture drop linear_pretrend
capture drop pretrend_modena
capture drop pretrend_parma
capture drop pretrend_tuscany
capture drop pretrend_lombardy
capture drop pretrend_papal_state
capture drop pretrend_sardinia
capture drop pretrend_sicily
capture drop pretrend_venetia

gen prebase = cond(year <= 1800, year - 1801, 0)
gen linear_pretrend = prebase * (copyright == 1)

gen pretrend_modena      = prebase * (state == "d_modena")
gen pretrend_parma       = prebase * (state == "d_parma")
gen pretrend_tuscany     = prebase * (state == "gd_tuscany")
gen pretrend_lombardy    = prebase * (state == "lombardy")
gen pretrend_papal_state = prebase * (state == "papal_state")
gen pretrend_sardinia    = prebase * (state == "sardinia")
gen pretrend_sicily      = prebase * (state == "two_sicilies")
gen pretrend_venetia     = prebase * (state == "venetia")



*** Column 1: State and Year Fixed Effects
reg operas copyright_post1801 i.state1 i.year, nocon cluster(state1)
estadd scalar state_fe = 1
estadd scalar year_fe = 1
estadd scalar linear_pretrend_LV = 0
estadd scalar state_spec_pretrend = 0
eststo model1

*** Column 2: Year Fixed Effects
reg operas copyright_post1801 copyright i.year, nocon cluster(state1)
estadd scalar state_fe = 0
estadd scalar year_fe = 1
estadd scalar linear_pretrend_LV = 0
estadd scalar state_spec_pretrend = 0
eststo model2

*** Column 3: State and Year Fixed Effects + Linear Pre-Trend for Lombardy and Venetia
reg operas copyright_post1801 i.state1 i.year linear_pretrend, nocon cluster(state1)
estadd scalar state_fe = 1
estadd scalar year_fe = 1
estadd scalar linear_pretrend_LV = 1
estadd scalar state_spec_pretrend = 0
eststo model3

*** Column 4: State and Year Fixed Effects + State-Specific Pre-Trend
reg operas copyright_post1801 i.state1 i.year ///
    pretrend_modena pretrend_parma pretrend_tuscany pretrend_lombardy ///
    pretrend_papal_state pretrend_sardinia pretrend_sicily pretrend_venetia, ///
    nocon cluster(state1)
estadd scalar state_fe = 1
estadd scalar year_fe = 1
estadd scalar linear_pretrend_LV = 0
estadd scalar state_spec_pretrend = 1
eststo model4

*** Column 5: Poisson + Marginal Effects
poisson operas copyright_post1801 i.state1 i.year, vce(cluster state1)
margins, dydx(*) post
estadd scalar state_fe = 1
estadd scalar year_fe = 1
estadd scalar linear_pretrend_LV = 0
estadd scalar state_spec_pretrend = 0
eststo model5

*** Export to LaTeX
esttab model1 model2 model3 model4 model5 using "${tables}/Table_5.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe linear_pretrend_LV state_spec_pretrend, ///
          labels("State FE" "Year FE" "Linear pretrend for L&V" "State-specific linear pretrend")) ///
    replace tex
