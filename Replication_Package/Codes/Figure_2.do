capture which here
if _rc ssc install here, replace
here

import delimited "${data_new}/Opening_Night_Operas_it_cleaned.csv", clear

/*******************************************************************************
* Panel A: ON data
*******************************************************************************/
collapse (mean) operas, by(year copyright)

rename operas total_operas

twoway line total_operas year if copyright==1, lcolor(black) || line total_operas year if copyright==0, ///
lpattern(dash) lcolor(black) ytitle("Mean New Operas per Year") xtitle("")  ///
xline(1801, lcolor(black) lpattern(shortdash)) text(15 1801.5 "1801 Copyright Law", placement(e)) ///
legend(label(1 "Lombardy & Venetia") label(2 "Other States")) ///
graphregion(color(white)) 


graph export "${figures}/Figure_2_Panel_A.png", replace

/*******************************************************************************
* Panel B: GM2020 data
*******************************************************************************/
use "${data_gm}/operas_copyright_total.dta", clear

twoway line total_operas year if copyright==1, lcolor(black) || ///
    line total_operas year if copyright==0, lpattern(dash) lcolor(black) ///
    ytitle("Mean New Operas per Year") xtitle("") ///
    ylabel(0(5)15, grid) ///
    yscale(range(0 15)) ///
    xline(1801, lcolor(black) lpattern(shortdash)) ///
    text(15 1801.5 "1801 Copyright Law", placement(e)) ///
    legend(label(1 "Lombardy & Venetia") label(2 "Other States")) ///
    graphregion(color(white))


graph export "${figures}/Figure_2_Panel_B.png", replace
