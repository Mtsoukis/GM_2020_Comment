
import delimited "/Users/mariostsoukis/Documents/GitHub/GM_2020_Comment/Replication_Package/Data_New/Opening_Night_Operas_it_cleaned.csv", clear

encode state, gen(state1)

* generate treatment×year interactions (excluding 1781–1790)
foreach y of numlist 1791/1820 {
    gen cp_year_`y' = (year==`y') & copyright
    label var cp_year_`y' "beta_`y'"
}

* regression with state FE + year FE
areg operas cp_year_1791-cp_year_1820 i.year, absorb(state1) vce(robust)

	* joint F-test: are all pre-treatment effects zero?
testparm cp_year_1791-cp_year_1800
display "Joint pre-treatment p-value = " %6.4f r(p)

* 95% CI using t critical from residual df
scalar alpha = 0.05
scalar tcrit = invttail(e(df_r), alpha/2)   // two-sided

tempfile betas
postfile pf int yr double b se ll ul t p using "`betas'", replace
foreach y of numlist 1791/1820 {
    quietly {
        scalar bb = _b[cp_year_`y']
        scalar ss = _se[cp_year_`y']
        scalar tt = bb/ss
        scalar pp = 2*ttail(e(df_r), abs(tt))
        post pf (`y') (bb) (ss) (bb - tcrit*ss) (bb + tcrit*ss) (tt) (pp)
    }
}
postclose pf
use "`betas'", clear

* event-study plot
twoway (rcap ll ul yr) (scatter b yr), ///
    yline(0) xline(1801, lpattern(dash)) ///
    xlabel(1790(5)1820) xtitle("") ///
    ytitle("{&beta}_t Coefficients") legend(off) ///
    title("Time-Varying Estimates for Effects of Copyrights")
	
clear all 



use "/Users/mariostsoukis/Documents/GitHub/GM_2020_Comment/Replication_Package/Data_GM2020/operas_1781_1820.dta", clear


* generate treatment×year interactions (excluding 1781–1790)
foreach y of numlist 1791/1820 {
    gen cp_year_`y' = (year==`y') & copyright
    label var cp_year_`y' "beta_`y'"
}

* regression with state FE + year FE
areg operas cp_year_1791-cp_year_1820 i.year, absorb(state1) vce(robust)

	* joint F-test: are all pre-treatment effects zero?
testparm cp_year_1791-cp_year_1800
display "Joint pre-treatment p-value = " %6.4f r(p)

* 95% CI using t critical from residual df
scalar alpha = 0.05
scalar tcrit = invttail(e(df_r), alpha/2)   // two-sided

tempfile betas
postfile pf int yr double b se ll ul t p using "`betas'", replace
foreach y of numlist 1791/1820 {
    quietly {
        scalar bb = _b[cp_year_`y']
        scalar ss = _se[cp_year_`y']
        scalar tt = bb/ss
        scalar pp = 2*ttail(e(df_r), abs(tt))
        post pf (`y') (bb) (ss) (bb - tcrit*ss) (bb + tcrit*ss) (tt) (pp)
    }
}
postclose pf
use "`betas'", clear

* event-study plot
twoway (rcap ll ul yr) (scatter b yr), ///
    yline(0) xline(1801, lpattern(dash)) ///
    xlabel(1790(5)1820) xtitle("") ///
    ytitle("{&beta}_t Coefficients") legend(off) ///
    title("Time-Varying Estimates for Effects of Copyrights")
