capture which here
if _rc ssc install here, replace
capture which here
if _rc {
    di as error "Required command 'here' is not installed. Run: ssc install here"
    exit 199
}
here

clear all
set more off

* Resolve Replication_Package root robustly from the current {here} anchor.
local root ""
if fileexists("${here}/Codes/Master.do") {
    local root "${here}"
}
else if fileexists("${here}/Master.do") {
    local root "${here}/.."
}
else if fileexists("${here}/Replication_Package/Codes/Master.do") {
    local root "${here}/Replication_Package"
}
else {
    di as error "Could not resolve Replication_Package root from: ${here}"
    exit 601
}

global here "`root'"
global codes "${here}/Codes"
global data_new "${here}/Data_New"
global data_gm "${here}/Data_GM2020"
global figures "${here}/Figures"
global tables "${here}/Tables"

capture mkdir "${figures}"
capture mkdir "${tables}"

di as text "Project root  : ${here}"
di as text "Codes         : ${codes}"
di as text "Data_New      : ${data_new}"
di as text "Data_GM2020   : ${data_gm}"
di as text "Figures out   : ${figures}"
di as text "Tables out    : ${tables}"

* Run all .do files in Codes (except this master file).
local files : dir "${codes}" files "*.do"
local files : list sort files

foreach f of local files {
    if "`f'" == "Master.do" continue

    cd "${codes}"
    di as text "----------------------------------------------"
    di as text "Running file: ${codes}/`f'"
    di as text "----------------------------------------------"
    do "${codes}/`f'"
}

* Run Stata scripts that live outside Codes.
local panel3 "${data_gm}/Loewenberg_Share_GM2020.do"
if fileexists("`panel3'") {
    cd "${codes}"
    di as text "----------------------------------------------"
    di as text "Running file: `panel3'"
    di as text "----------------------------------------------"
    do "`panel3'"
}

clear
di as result "All Stata scripts completed."
