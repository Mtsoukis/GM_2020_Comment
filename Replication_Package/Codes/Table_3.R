rm(list = ls())

library(haven)

operas_main <- read_dta(here::here("Data_GM2020", "operas_1781_1820.dta"))
operas_composer <- read_dta(here::here("Data_GM2020", "composer_level_data.dta"))
tables_path <- here::here("Tables")

# Grouping and period bins used in Table 3.
grp_main <- ifelse(operas_main$state %in% c("lombardy", "venetia"),
                   "Lombardy and Venetia", "Other States")
grp_comp <- ifelse(operas_composer$copyright == 1,
                   "Lombardy and Venetia", "Other States")

per_main <- ifelse(operas_main$year <= 1800, "1781-1800", "1801-1820")
per_comp <- ifelse(operas_composer$year <= 1800, "1781-1800", "1801-1820")

main_sum <- tapply(operas_main$operas, list(grp_main, per_main), sum, na.rm = TRUE)
comp_sum <- tapply(operas_composer$comp_operas, list(grp_comp, per_comp), sum, na.rm = TRUE)

all_groups <- c("Lombardy and Venetia", "Other States")
all_periods <- c("1781-1800", "1801-1820")

main_sum <- main_sum[all_groups, all_periods, drop = FALSE]
comp_sum <- comp_sum[all_groups, all_periods, drop = FALSE]

main_sum[is.na(main_sum)] <- 0
comp_sum[is.na(comp_sum)] <- 0

main_sum <- round(main_sum)
comp_sum <- round(comp_sum)

df <- data.frame(
  state = all_groups,
  `1781-1800 main` = main_sum[, "1781-1800"],
  `1781-1800 composer` = comp_sum[, "1781-1800"],
  `1781-1800 delta` = comp_sum[, "1781-1800"] - main_sum[, "1781-1800"],
  `1801-1820 main` = main_sum[, "1801-1820"],
  `1801-1820 composer` = comp_sum[, "1801-1820"],
  `1801-1820 delta` = comp_sum[, "1801-1820"] - main_sum[, "1801-1820"],
  check.names = FALSE,
  row.names = NULL
)

fmt <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")

lines <- c(
  "\\begin{tabular}[t]{lcccccc}",
  "\\toprule",
  "State & \\multicolumn{3}{c}{1781--1800} & \\multicolumn{3}{c}{1801--1820}\\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & main & composer & $\\Delta$ & main & composer & $\\Delta$\\\\",
  "\\midrule",
  sprintf(
    "%s & %s & %s & %s & %s & %s & %s\\\\",
    df$state,
    fmt(df$`1781-1800 main`),
    fmt(df$`1781-1800 composer`),
    fmt(df$`1781-1800 delta`),
    fmt(df$`1801-1820 main`),
    fmt(df$`1801-1820 composer`),
    fmt(df$`1801-1820 delta`)
  ),
  "\\bottomrule",
  "\\end{tabular}"
)

writeLines(lines, file.path(tables_path, "Table_3.txt"))
