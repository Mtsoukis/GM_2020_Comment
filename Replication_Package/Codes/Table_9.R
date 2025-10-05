# =========================
# Clean env & options
# =========================
rm(list = ls())
options(stringsAsFactors = FALSE, scipen = 999)

# =========================
# Libraries
# =========================
library(tidyverse)
library(haven)  
library(knitr)  
library(kableExtra)

# =========================
# Paths
# =========================
ON_dta <- "Data_New/Opening_Night_Operas_it_raw.csv"
mg_dta <- "Data_GM2020/operas_1781_1820.dta"


df <- read.csv(ON_dta, header = TRUE, stringsAsFactors = FALSE)


names(df) <- tolower(names(df))
year_col  <- "premiere_date"
state_col <- "state_region"
city_col  <- "city"

# =========================
# Helper: ON dataset excluding the capital by region
# =========================
make_on_no_capital <- function(data, region_name, capital_city, year_col, state_col, city_col) {
  data %>%
    filter(.data[[state_col]] == region_name) %>%
    group_by(.data[[year_col]], .data[[city_col]]) %>%
    summarise(prod_city_year = dplyr::n(), .groups = "drop") %>%        # city-year tallies
    filter(.data[[city_col]] != capital_city) %>%
    group_by(.data[[year_col]]) %>%
    summarise(Production = sum(prod_city_year, na.rm = TRUE), .groups = "drop") %>%
    arrange(.data[[year_col]]) %>%
    transmute(Year = as.numeric(.data[[year_col]]),
              Production = as.numeric(Production),
              Group = "ON Dataset")
}

# Build ON datasets, excluding capitals
on_lombardy <- make_on_no_capital(df, "Lombardia", "Milan",  year_col, state_col, city_col)
on_venetia  <- make_on_no_capital(df, "Venetia",  "Venice", year_col, state_col, city_col)

# =========================
# MG2020 series
# =========================
mg <- read_dta(mg_dta)

mg_lombardy <- mg %>%
  filter(state == "lombardy") %>%
  transmute(Year = as.numeric(year),
            Production = as.numeric(operas_no_milan),
            Group = "MG2020")

mg_venetia <- mg %>%
  filter(state == "venetia") %>%
  transmute(Year = as.numeric(year),
            Production = as.numeric(operas_novenice),
            Group = "MG2020")

# =========================
# Build & PRINT period-sum tables (Pre-1801 vs Post-1801)
# =========================
make_period_table <- function(on_df, mg_df, caption_text) {
  bind_rows(on_df, mg_df) %>%
    mutate(Period = if_else(Year < 1801, "Pre-1801", "Post-1801")) %>%
    group_by(Group, Period) %>%
    summarise(Total_Production = sum(Production, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = Period, values_from = Total_Production) %>%
    select(Group, `Pre-1801`, `Post-1801`) %>%
    kable(align = c("l", "r", "r"), caption = caption_text)
}

make_period_table(on_lombardy, mg_lombardy, "Operas_Differences_Lombardy")
make_period_table(on_venetia,  mg_venetia,  "Operas_Differences_Venetia")

#Format it nicely:

tbl <- data.frame(
  Group = c("MG2020", "ON"),
  `Lombardy_Pre-1801`  = c(14, 29),
  `Lombardy_Post-1801` = c(50, 19),
  `Venetia_Pre-1801`   = c(8,  43),
  `Venetia_Post-1801`  = c(40, 33),
  check.names = FALSE
)

kable(
  tbl,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l", "r", "r", "r", "r"),
  col.names = c("Group", "Pre-1801", "Post-1801", "Pre-1801", "Post-1801")
) |>
  add_header_above(c(" " = 1, "Lombardy" = 2, "Venetia" = 2)) |>
  kable_styling(latex_options = "hold_position")

# build the LaTeX
latex_full <- kable(
  tbl,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l", "r", "r", "r", "r"),
  col.names = c("Group", "Pre-1801", "Post-1801", "Pre-1801", "Post-1801")
) |>
  add_header_above(c(" " = 1, "Lombardy" = 2, "Venetia" = 2)) |>
  kable_styling(latex_options = "hold_position") |>
  as.character()

# extract only the tabular environment
latex_tabular <- str_extract(latex_full, "\\\\begin\\{tabular\\}[\\s\\S]*?\\\\end\\{tabular\\}")
writeLines(latex_tabular, "Tables/Table_9.txt")
