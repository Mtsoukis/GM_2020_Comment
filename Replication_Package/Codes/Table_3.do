import delimited "/Users/mariostsoukis/Documents/GitHub/GM_2020_Comment/Replication_Package/Data_New/Opening_Night_Operas_it_cleaned.csv", clear

encode state, gen(state1)

* Base pre-period trend: years since 1780, but only up to 1800
gen prebase = cond(year <= 1800, year - 1801, 0)

gen linear_pretrend = prebase * (copyright == 1)

* State-specific pretrends
gen pretrend_modena      = prebase * (state == "Duchy_Modena")
gen pretrend_parma       = prebase * (state == "Duchy_Parma")
gen pretrend_tuscany     = prebase * (state == "Toscana")
gen pretrend_lombardy    = prebase * (state == "Lombardia")
gen pretrend_papal_state = prebase * (state == "Papal")
gen pretrend_sardinia    = prebase * (state == "Sardinia")
gen pretrend_sicily      = prebase * (state == "Due_Sicilie")
gen pretrend_venetia     = prebase * (state == "Venetia")



*Copied from GM2020: 

xtset state1 year

***Column 1: State and Year Fixed Effects
reg operas copyright_post1801 i.state1 i.year, nocon robust

***Column 2: Year Fixed Effects
reg operas copyright_post1801 copyright i.year, nocon robust

***Column 3: State and Year Fixed Effects + Linear Pre-Trend for Lombardy and Venetia
reg operas copyright_post1801 i.state1 i.year linear_pretrend, nocon robust

***Column 4: State and Year Fixed Effects + State Specific Pre-Trend
reg operas copyright_post1801 i.state1 i.year pretrend_modena pretrend_parma pretrend_tuscany pretrend_lombardy pretrend_papal_state pretrend_sardinia pretrend_sicily pretrend_venetia, nocon robust

***Column 5: Poisson
poisson operas copyright_post1801 i.state1 i.year, vce(robust)
margins, dydx(*)
