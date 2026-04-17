capture which here
if _rc ssc install here, replace
capture which esttab
if _rc ssc install estout, replace
here

clear all
set more off
eststo clear

use "${data_gm}/composer_level_data.dta", clear

duplicates drop composer_id, force
isid composer_id

quietly _pctile tot_operas, p(80 90)
scalar top20_threshold = r(r1)
scalar top10_threshold = r(r2)

di as text "Composer tot_operas thresholds from unique composers:"
di as result "  Top 20% threshold (80th percentile): " %9.0g scalar(top20_threshold)
di as result "  Top 10% threshold (90th percentile): " %9.0g scalar(top10_threshold)

clear all


use "${data_gm}/composer_level_data.dta", clear
local variables annals met amazon

foreach variable of local variables {
gen `variable'_share=`variable'/comp_operas
}



*Copying from GM2020, but changing the thresholds from 30 (Panel B) and 20 (Panel C) to 7 and 3, respectively. It's justified above. 


***********PANEL B: EXCLUDING TOP 10% COMPOSERS****************************************
***Column 1: All Operas
reg comp_operas copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust
eststo b1

****HISTORICALLY POPULAR OPERAS IN LOEWENBERG (1978)

***Column 2: Count
reg annals copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust
eststo b2

***Column 3: Share
reg annals_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust
eststo b3

****OPERAS PERFORMED AT THE METROPOLITAN, 1900-2014

***Column 4: Count
reg met copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust
eststo b4

***Column 5: Share
reg met_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust
eststo b5

****DURABLE OPERAS ON AMAZON TODAY

***Column 6: Count
reg amazon copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust
eststo b6

***Column 7: Share
reg amazon_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust
eststo b7



***********PANEL C: EXCLUDING TOP 20% COMPOSERS******************************************
***Column 1: All Operas
reg comp_operas copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust
eststo c1

****HISTORICALLY POPULAR OPERAS IN LOEWENBERG (1978)

***Column 2: Count
reg annals copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust
eststo c2

***Column 3: Share
reg annals_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust
eststo c3

****OPERAS PERFORMED AT THE METROPOLITAN, 1900-2014

***Column 4: Count
reg met copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust
eststo c4

***Column 5: Share
reg met_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust
eststo c5

****DURABLE OPERAS ON AMAZON TODAY

***Column 6: Count
reg amazon copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust
eststo c6

***Column 7: Share
reg amazon_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust
eststo c7

esttab b1 b2 b3 b4 b5 b6 b7 using "${tables}/Table_7.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("All" "Annals Cnt" "Annals Shr" "Met Cnt" "Met Shr" "Amazon Cnt" "Amazon Shr") ///
    replace tex title("Panel B: Excluding Top 10% Composers")

esttab c1 c2 c3 c4 c5 c6 c7 using "${tables}/Table_7.txt", ///
    keep(copyright_post1801) ///
    se starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("All" "Annals Cnt" "Annals Shr" "Met Cnt" "Met Shr" "Amazon Cnt" "Amazon Shr") ///
    append tex title("Panel C: Excluding Top 20% Composers")
