clear all
set more off


net install here, from("https://raw.githubusercontent.com/korenmiklos/here/master/")

*Change to where you download the replication package.
cd /Users/mariostsoukis/Documents/GitHub/GM_2020_Comment


here, set
display "${here}"
cd "${here}"



local path "${here}/Replication_Package/Codes"

* List all .do files inside that folder
local files : dir "`path'" files "*.do"

* Loop through and run each .do file (from the main directory)
foreach f of local files {
    di as text "----------------------------------------------"
    di as text "Running file: `f'"
    di as text "----------------------------------------------"
    do "`path'/`f'"
}

clear
