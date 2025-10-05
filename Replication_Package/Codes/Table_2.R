rm(list = ls())

library(haven)

operas_1781_1820 <- read_dta(here::here("Data_GM2020", "operas_1781_1820.dta"))
operas_composer  <- read_dta(here::here("Data_GM2020", "composer_level_data.dta"))
tables_path <- here::here("Tables")

# Group: Lombardy & Venetia vs Other States
grp_op <- ifelse(operas_1781_1820$state %in% c("lombardy","venetia"),
                 "Lombardy and Venetia", "Other States")
grp_cp <- ifelse(operas_composer$copyright == 1,
                 "Lombardy and Venetia", "Other States")

# Periods
per_op <- ifelse(operas_1781_1820$year <= 1800, "1781-1800", "1801-1820")
per_cp <- ifelse(operas_composer$year  <= 1800, "1781-1800", "1801-1820")

# Operas (state-year file)
op <- tapply(operas_1781_1820$operas, list(grp_op, per_op), sum, na.rm = TRUE)

# Composer-level (sum comp_operas)
cp <- tapply(operas_composer$comp_operas, list(grp_cp, per_cp), sum, na.rm = TRUE)

# Align dims and compute discrepancies: composer − operas
all_groups  <- c("Lombardy and Venetia", "Other States")
all_periods <- c("1781-1800","1801-1820")
op <- op[all_groups, all_periods, drop = FALSE]
cp <- cp[all_groups, all_periods, drop = FALSE]
diff_tab <- cp - op

# Round to integers for display
diff_tab[is.na(diff_tab)] <- 0
diff_tab <- round(diff_tab)

dir.create("Tables", showWarnings = FALSE, recursive = TRUE)
lines <- c(
  "\\begin{tabular}[t]{lrr}",
  "\\toprule",
  "State & 1781-1800 & 1801-1820\\\\",
  "\\midrule",
  sprintf("Lombardy and Venetia & %d & %d\\\\", diff_tab["Lombardy and Venetia","1781-1800"], diff_tab["Lombardy and Venetia","1801-1820"]),
  sprintf("Other States & %d & %d\\\\", diff_tab["Other States","1781-1800"], diff_tab["Other States","1801-1820"]),
  "\\bottomrule",
  "\\end{tabular}"
)

writeLines(lines, file.path(tables_path, "Table_2.txt"))