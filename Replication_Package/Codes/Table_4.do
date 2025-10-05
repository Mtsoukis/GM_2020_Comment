clear 

use "${here}/Replication_Package/Data_GM2020/operas_1781_1820.dta"
xtset state1 year

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
esttab model1 model2 model3 model4 model5 using ${here}/Replication_Package/Tables/Table_4.txt, ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(state_fe year_fe linear_pretrend_LV state_spec_pretrend, ///
          labels("State FE" "Year FE" "Linear pretrend for L&V" "State-specific linear pretrend")) ///
    replace tex
