capture which here
if _rc ssc install here, replace
here

import delimited "${data_new}/Opening_Night_Operas_it_raw.csv", clear

* Rename identifiers
rename premiere_date year
rename state_region state


************************************************************
* 1. Build state-year counts 
************************************************************
gen count_operas = 1

collapse (sum) operas = count_operas, by(state year)

* Balance the panel (create missing state-year pairs)
fillin state year

* Replace missing counts with 0
replace operas = 0 if operas == .

drop _fillin

encode state, gen(state1)

capture drop treated_region
gen treated_region = (state == "Venetia" | state == "Lombardia")


************************************************************
* 2. Event-study style regression + Figure_3.png 
************************************************************
* Base year = 1800
reg operas 1.treated_region#ib1800.year i.state1 i.year, robust

preserve
    clear
    set obs 40
    gen year = 1780 + _n   // 1781 to 1820

    gen beta = .
    gen se = .
    gen ci_upper = .
    gen ci_lower = .

    count
    local N = r(N)

    forvalues i = 1/`N' {
        local y = year[`i']

        * Effect in year y relative to 1800
        capture lincom 1.treated_region#`y'.year - 1.treated_region#1800.year
        if _rc == 0 {
            replace beta = r(estimate) in `i'
            replace se   = r(se)       in `i'
        }
    }

    replace ci_upper = beta + (1.96 * se)
    replace ci_lower = beta - (1.96 * se)

    twoway ///
        (rcap ci_upper ci_lower year, lcolor(gs10) lwidth(thin)) ///
        (connected beta year, mcolor(black) msymbol(circle) lcolor(black) lpattern(solid)), ///
        yline(0, lcolor(black) lwidth(thin)) ///
        xline(1801, lpattern(dash) lcolor(maroon)) ///
        xlabel(1781 1791 1801 1811 1820, labsize(small)) ///
        xtitle("Year") ///
        ytitle("Coefficients", size(small)) ///
        scheme(s1mono) ///
        legend(off) ///
        note("")
restore

graph export "${figures}/Figure_3.png", replace


************************************************************
* 3. Pretrend DiD regression 
************************************************************
gen copyright = (state == "Venetia" | state == "Lombardia")
gen copyright_post1801 = (copyright == 1 & year > 1800)

* Base pre-period trend
gen prebase = cond(year <= 1800, year - 1801, 0)

* State-specific pretrends
gen pretrend_modena      = prebase * (state == "Duchy_Modena")
gen pretrend_parma       = prebase * (state == "Duchy_Parma")
gen pretrend_tuscany     = prebase * (state == "Toscana")
gen pretrend_lombardy    = prebase * (state == "Lombardia")
gen pretrend_papal_state = prebase * (state == "Papal")
gen pretrend_sardinia    = prebase * (state == "Sardinia")
gen pretrend_sicily      = prebase * (state == "Due_Sicilie")
gen pretrend_venetia     = prebase * (state == "Venetia")

reg operas copyright_post1801 i.state1 i.year ///
    pretrend_modena pretrend_parma pretrend_tuscany pretrend_lombardy ///
    pretrend_papal_state pretrend_sardinia pretrend_sicily pretrend_venetia, ///
    nocon robust
