clear all
set more off

use "${here}/Replication_Package/Data_GM2020/composer_level_data.dta", clear

duplicates drop composer_id, force
isid composer_id

tab tot_operas

clear all


use "${here}/Replication_Package/Data_GM2020/composer_level_data.dta", clear
local variables annals met amazon

foreach variable of local variables {
gen `variable'_share=`variable'/comp_operas
}



*Copying from GM2020, but changing the thresholds from 30 (Panel B) and 20 (Panel C) to 7 and 3, respectively.


***********PANEL B: EXCLUDING TOP 10% COMPOSERS****************************************
***Column 1: All Operas
reg comp_operas copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust

****HISTORICALLY POPULAR OPERAS IN LOEWENBERG (1978)

***Column 2: Count
reg annals copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust

***Column 3: Share
reg annals_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust

****OPERAS PERFORMED AT THE METROPOLITAN, 1900-2014

***Column 4: Count
reg met copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust

***Column 5: Share
reg met_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust

****DURABLE OPERAS ON AMAZON TODAY

***Column 6: Count
reg amazon copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust

***Column 7: Share
reg amazon_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<7, nocon robust



***********PANEL C: EXCLUDING TOP 20% COMPOSERS******************************************
***Column 1: All Operas
reg comp_operas copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust

****HISTORICALLY POPULAR OPERAS IN LOEWENBERG (1978)

***Column 2: Count
reg annals copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust

***Column 3: Share
reg annals_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust

****OPERAS PERFORMED AT THE METROPOLITAN, 1900-2014

***Column 4: Count
reg met copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust

***Column 5: Share
reg met_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust

****DURABLE OPERAS ON AMAZON TODAY

***Column 6: Count
reg amazon copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust

***Column 7: Share
reg amazon_share copyright_post1801 i.composer_id i.state1 i.year if tot_operas<3, nocon robust


