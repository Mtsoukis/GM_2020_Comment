#The opera counts do not match

rm(list = ls())

getwd()
library(haven)

operas_1781_1820 <- read_dta(here::here("Data_GM2020", "operas_1781_1820.dta"))
operas_copyright_total <- read_dta(here::here("Data_GM2020", "operas_copyright_total.dta"))
operas_composer <- read_dta(here::here("Data_GM2020", "composer_level_data.dta"))
operas_cities <- read_dta(here::here("Data_GM2020", "city_level_operas_1781_1820.dta"))

# Counts
n_operas_1781_1820  <- sum(operas_1781_1820$operas,     na.rm = TRUE)
n_operas_composer   <- sum(operas_composer$comp_operas, na.rm = TRUE)
n_operas_city_level <- sum(operas_cities$operas_city,   na.rm = TRUE)
w <- ifelse(operas_copyright_total$copyright == 1, 2L, 6L)
n_operas_copyright_tot <- sum(operas_copyright_total$total_operas * w, na.rm = TRUE)

# Assemble table
tab_df <- data.frame(
  `operas_1781_1820`            = n_operas_1781_1820,
  `operas_copyright_total`      = n_operas_copyright_tot,
  `composer_level`              = n_operas_composer,
  `city_level_operas_1781_1820` = n_operas_city_level,
  check.names = FALSE
)
rownames(tab_df) <- "Operas"

# Replace underscores with LaTeX \_
names(tab_df) <- gsub("_", "\\_", names(tab_df))

# Output 
library(knitr)
latex_tab <- knitr::kable(
  tab_df,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l","r","r","r","r"),
  row.names = TRUE,
  digits   = c(0, 1, 0, 0)
)

writeLines(latex_tab, here::here("Tables", "Table_1.txt"))