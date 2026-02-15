capture which here
if _rc ssc install here, replace
here

import delimited "${data_new}/Opening_Night_Operas_it_raw.csv", clear

* 1. Rename variables 
rename premiere_date year
rename state_region state

* 2. Generate numeric variables to count
gen count_operas = 1
gen count_no_milan = (city != "Milan")
gen count_novenice = (city != "Venice")
gen count_nomi_nove = (city != "Milan" & city != "Venice")

* 3. Collapse summing the variables created above
collapse (sum) operas = count_operas ///
         (sum) operas_no_milan = count_no_milan ///
         (sum) operas_novenice = count_novenice ///
         (sum) opera_nomi_nove = count_nomi_nove, ///
         by(state year)

* 4. Balance the panel (create observations for missing state-year pairs)
fillin state year

* 5. Replace missing values with 0
foreach var of varlist operas operas_no_milan operas_novenice opera_nomi_nove {
    replace `var' = 0 if `var' == .
}

* Optional: Clean up the indicator variable created by fillin
drop _fillin

encode state, gen(state1)

capture drop treated_region
gen treated_region = (state == "Venetia" | state == "Lombardia")

* 2. Run the regression (Base Year = 1800)
* We use ib1800.year to explicitly tell Stata that 1800 is the reference category
* We cluster by state (standard for DiD to account for serial correlation)
* 1. Run the regression again to be sure
* ---------------------------------------------------------
* 1. REGRESSION
* ---------------------------------------------------------
* Base year = 1800 (ib1800). 
* This forces 1800 to be the "Zero" standard.
reg opera_nomi_nove 1.treated_region#ib1800.year i.state1 i.year, robust 

* ---------------------------------------------------------
* 2. ROBUST "DIFFERENCE" PLOT DATA
* ---------------------------------------------------------
preserve
    clear
    set obs 40
    gen year = 1780 + _n  // 1781 to 1820
    
    gen beta = .
    gen se = .
    gen ci_upper = .
    gen ci_lower = .

    count
    local N = r(N)
    
    forvalues i = 1/`N' {
        local y = year[`i']
        
        * METHOD: Calculate (Year Y) - (Year 1800)
        * This works even if Stata didn't drop 1800 in the table.
        * It forces 1800 to be exactly 0 with SE=0.
        
        capture lincom 1.treated_region#`y'.year - 1.treated_region#1800.year
        
        if _rc == 0 {
            replace beta = r(estimate) in `i'
            replace se = r(se) in `i'
        }
    }

    replace ci_upper = beta + (1.96 * se)
    replace ci_lower = beta - (1.96 * se)

* ---------------------------------------------------------
* 3. PLOT
* ---------------------------------------------------------
    twoway ///
        (rcap ci_upper ci_lower year, lcolor(gs10) lwidth(thin)) /// 
        (connected beta year, mcolor(black) msymbol(circle) lcolor(black) lpattern(solid)), /// 
        yline(0, lcolor(black) lwidth(thin)) ///
        xline(1801, lpattern(dash) lcolor(maroon)) /// 
        xlabel(1781 1791 1801 1811 1820, labsize(small)) ///
        xtitle("Year") ///
        ytitle("Coefficients", size(small)) ///
        title("", span color(black)) ///
        subtitle("", span size(small)) /// ##OLS Estimates (not Excluding Milan and Venice)
        scheme(s1mono) /// 
        legend(off) ///
        note("")
		*Base Year: 1800
restore

graph export "${figures}/Figure_AppendixB1.png", replace



*******

gen copyrights = (state == "Venetia" | state == "Lombardia")
gen copyright = (state == "Venetia" | state == "Lombardia")
gen copyright_post1801 = 0
replace copyright_post1801 = 1 if copyrights == 1 & year > 1800

* Base pre-period trend: years since 1780 up to 1800
gen prebase = cond(year <= 1800, year - 1801, 0)

gen linear_pretrend = prebase * (copyrights== 1)

* State-specific pretrends
gen pretrend_modena      = prebase * (state == "Duchy_Modena")
gen pretrend_parma       = prebase * (state == "Duchy_Parma")
gen pretrend_tuscany     = prebase * (state == "Toscana")
gen pretrend_lombardy    = prebase * (state == "Lombardia")
gen pretrend_papal_state = prebase * (state == "Papal")
gen pretrend_sardinia    = prebase * (state == "Sardinia")
gen pretrend_sicily      = prebase * (state == "Due_Sicilie")
gen pretrend_venetia     = prebase * (state == "Venetia")



reg operas_novenice copyright_post1801 i.state1 i.year ///
    pretrend_modena pretrend_parma pretrend_tuscany pretrend_lombardy ///
    pretrend_papal_state pretrend_sardinia pretrend_sicily pretrend_venetia, ///
    nocon robust	
	
collapse (mean) opera_nomi_nove, by(year copyright)

rename opera_nomi_nove total_operas

twoway line total_operas year if copyright==1, lcolor(black) || line total_operas year if copyright==0, ///
lpattern(dash) lcolor(black) ytitle("Mean New Operas per Year") xtitle("")  ///
xline(1801, lcolor(black) lpattern(shortdash)) text(15 1801.5 "1801 Copyright Law", placement(e)) ///
legend(label(1 "Lombardy & Venetia") label(2 "Other States")) ///
graphregion(color(white)) 

graph export "${figures}/Figure_AppendixB2.png", replace
