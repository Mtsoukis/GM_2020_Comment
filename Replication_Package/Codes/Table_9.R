# =========================
# Clean env & options
# =========================
rm(list = ls())
options(stringsAsFactors = FALSE, scipen = 999)

bootstrap_paths <- local({
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  candidate_dirs <- character(0)

  if (length(file_arg)) {
    candidate_dirs <- c(
      candidate_dirs,
      dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = FALSE))
    )
  }

  frames <- sys.frames()
  ofiles <- vapply(
    frames,
    function(frame) {
      ofile <- frame$ofile
      if (is.null(ofile)) {
        return(NA_character_)
      }
      normalizePath(ofile, winslash = "/", mustWork = FALSE)
    },
    character(1)
  )
  if (any(!is.na(ofiles))) {
    candidate_dirs <- c(candidate_dirs, dirname(tail(ofiles[!is.na(ofiles)], 1)))
  }

  candidate_dirs <- unique(c(candidate_dirs, getwd()))
  helper_candidates <- unique(c(
    file.path(candidate_dirs, "_paths.R"),
    file.path(candidate_dirs, "Codes", "_paths.R")
  ))
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]

  if (!length(helper_path) || is.na(helper_path)) {
    stop("Could not locate Replication_Package/Codes/_paths.R.", call. = FALSE)
  }

  helper_path
})
source(bootstrap_paths, local = TRUE)
rm(bootstrap_paths)

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
ON_dta <- rp_require_file("Data_New", "Opening_Night_Operas_it_raw.csv")
mg_dta <- rp_require_file("Data_GM2020", "operas_1781_1820.dta")
out_file <- rp_path("Tables", "Table_9.txt")

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
              Group = "ON")
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
# Build the final table from the inferred ON / GM2020 totals
# =========================
build_period_summary <- function(on_df, mg_df, region_label) {
  bind_rows(on_df, mg_df) %>%
    mutate(Period = if_else(Year < 1801, "Pre-1801", "Post-1801")) %>%
    group_by(Group, Period) %>%
    summarise(Total_Production = sum(Production, na.rm = TRUE), .groups = "drop") %>%
    tidyr::complete(
      Group = c("MG2020", "ON"),
      Period = c("Pre-1801", "Post-1801"),
      fill = list(Total_Production = 0)
    ) %>%
    pivot_wider(names_from = Period, values_from = Total_Production) %>%
    transmute(
      Group,
      !!paste0(region_label, "_Pre-1801") := `Pre-1801`,
      !!paste0(region_label, "_Post-1801") := `Post-1801`
    )
}

tbl <- build_period_summary(on_lombardy, mg_lombardy, "Lombardy") %>%
  left_join(
    build_period_summary(on_venetia, mg_venetia, "Venetia"),
    by = "Group"
  ) %>%
  mutate(Group = factor(Group, levels = c("MG2020", "ON"))) %>%
  arrange(Group) %>%
  mutate(Group = as.character(Group))

kable(
  tbl,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l", "c", "c", "c", "c"),
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
writeLines(latex_tabular, out_file)
