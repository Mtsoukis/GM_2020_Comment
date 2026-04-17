rm(list = ls())

# -------------------- Packages & Options --------------------
options(scipen = 999)

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

suppressPackageStartupMessages({
  library(tidyverse) 
  library(haven)      
})

library(fixest)

# -------------------- Paths --------------------

input_path  <- rp_require_file("Data_New", "Opening_Night_Operas_it_raw.csv")

output_clean_path         <- rp_path("Data_New", "Opening_Night_Operas_it_cleaned.csv")
output_nomilan_path       <- rp_path("Data_New", "Opening_Night_Operas_it_nomilan.csv")
output_novenice_path      <- rp_path("Data_New", "Opening_Night_Operas_it_novenice.csv")
output_nomilanvenice_path <- rp_path("Data_New", "Opening_Night_Operas_it_nomilanvenice.csv")

# -------------------- Read raw data --------------------
raw <- readr::read_csv(input_path)

# -------------------- Helper to build panel --------------------
build_panel <- function(data) {
  
  # States that have copyright protection
  copyright_states <- c("Lombardia", "Venetia")
  
  # Count number of operas by year x state
  panel_counts <- data %>% 
    transmute(
      year  = Premiere_Date,
      state = State_Region
    ) %>% 
    count(year, state, name = "operas")
  
  # All years and all states present in the (filtered) raw data
  all_years  <- seq(min(panel_counts$year, na.rm = TRUE),
                    max(panel_counts$year, na.rm = TRUE))
  
  all_states <- sort(unique(panel_counts$state))
  
  # Balanced panel + extra variables
  panel_clean <- tidyr::expand_grid(
    year  = all_years,
    state = all_states
  ) %>% 
    left_join(panel_counts, by = c("year", "state")) %>% 
    mutate(
      operas   = dplyr::coalesce(operas, 0L),
      post1801 = if_else(year >= 1801L, 1L, 0L),
      copyright = if_else(state %in% copyright_states, 1L, 0L),
      copyright_post1801 = copyright * post1801
    ) %>% 
    arrange(year, state)
  
  panel_clean
}

# -------------------- 1) Original --------------------
panel_clean <- build_panel(raw)
readr::write_csv(panel_clean, output_clean_path)

# -------------------- 2) No Milan --------------------
raw_nomilan <- raw %>% 
  filter(City != "Milan")

panel_nomilan <- build_panel(raw_nomilan)
readr::write_csv(panel_nomilan, output_nomilan_path)

# -------------------- 3) No Venice --------------------
raw_novenice <- raw %>% 
  filter(City != "Venice")

panel_novenice <- build_panel(raw_novenice)
readr::write_csv(panel_novenice, output_novenice_path)

# -------------------- 4) No Milan & no Venice --------------------
raw_nomilanvenice <- raw %>% 
  filter(!City %in% c("Milan", "Venice"))

panel_nomilanvenice <- build_panel(raw_nomilanvenice)
readr::write_csv(panel_nomilanvenice, output_nomilanvenice_path)
