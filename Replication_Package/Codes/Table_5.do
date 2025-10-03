clear 



 use "${here}/Replication_Package/Data_GM2020/operas_1781_1820.dta"
  
 collapse (mean) operas, by(state post1801)
   
 gen treated = (state == "venetia" | state == "lombardy")
 
  gen treat_post = treated * post1801
  
  encode state, gen(state1)
  
xtset state1 post

* Model 1 with state fixed effects
reg operas treat_post post i.state1, vce(robust) nocon
estadd scalar year_fe = 1
estadd scalar state_fe = 1
eststo model1

* Model 2 with only a dummy for treated instead of state FE
reg operas treat_post post treated, vce(robust) nocon
estadd scalar year_fe = 1
estadd scalar state_fe = 0
eststo model2

