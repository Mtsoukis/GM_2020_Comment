capture which here
if _rc ssc install here, replace
here

clear 

use "${data_gm}/operas_1781_1820.dta"
xtset state1 year

drop pretrend_lombardy pretrend_modena pretrend_papal_state pretrend_parma pretrend_tuscany pretrend_venetia pretrend_sicily pretrend_sardinia linear_pretrend


* Base pre-period trend: years since 1780 up to 1800
gen prebase = cond(year <= 1800, year - 1801, 0)

gen linear_pretrend = prebase * (copyright == 1)

* State-specific pretrends
gen pretrend_modena      = prebase * (state == "Duchy_Modena")
gen pretrend_parma       = prebase * (state == "Duchy_Parma")
gen pretrend_tuscany     = prebase * (state == "Toscana")
gen pretrend_lombardy    = prebase * (state == "Lombardia")
gen pretrend_papal_state = prebase * (state == "Papal")
gen pretrend_sardinia    = prebase * (state == "Sardinia")
gen pretrend_sicily      = prebase * (state == "Due_Sicilie")
gen pretrend_venetia     = prebase * (state == "Venetia")



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
