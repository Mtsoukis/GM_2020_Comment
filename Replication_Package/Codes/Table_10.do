


*** Table of OCR of Loewenberg 1978. 

import delimited "${here}/Replication_Package/Data_New/Loewenberg_1781_1820_it_raw.csv", clear
** collapse data to create panel:

* --- build counts 1781–1820 ---
contract state_region year if inrange(year,1781,1820)
rename _freq n_operas
tempfile counts
save `counts'

use `counts', clear
keep state_region
duplicates drop

quietly count if state_region == "d_modena"
if r(N) == 0 {
    local newN = _N + 1
    set obs `newN'               // <-- evaluate _N+1
    replace state_region = "d_modena" in `newN'
    // alternatively (if available): insobs 1, after( L )  &  replace ... in L
}

tempfile states
save `states'

* --- years 1781..1820 ---
clear
set obs 40
gen year = 1780 + _n
tempfile years
save `years'

* --- full grid, merge, fill zeros ---
use `states', clear
cross using `years'
merge 1:1 state_region year using `counts', nogen
replace n_operas = 0 if missing(n_operas)

encode state_region, gen(state_region_id)
xtset state_region_id year
order state_region year n_operas
sort  state_region year

* necessary for regression
encode state_region, gen(state1)
gen copyright_post1801 = (inlist(state_region, "Venetia", "Lombardia") & year > 1800)

* copy-paste from GM2020 Table_4 replication package, but with change of variable name.
reg n_operas copyright_post1801 i.state1 i.year, nocon robust

clear all


*copy-paste from GM2020 Table_4 replication package. 


clear all 

use "${here}/Replication_Package/Data_GM2020/operas_1781_1820.dta"


*copy-paste from GM2020 Table_4 replication package. 
reg operas_annals copyright_post1801 i.state1 i.year, nocon robust

clear all
