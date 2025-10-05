rm(list = ls())


# -------------------- Packages & Options --------------------
options(scipen = 999)
suppressPackageStartupMessages({
  library(tidyverse) 
  library(haven)      
})

# -------------------- Paths --------------------
input_path <- "Data_New/Opening_Night_Operas_it_raw.csv"
gm_path <- "Data_GM2020/operas_1781_1820.dta"

output_path <- "Figures"
dir.create(output_path, showWarnings = FALSE, recursive = TRUE)

# -------------------- Helpers --------------------
resolve_col <- function(df, candidates, required = TRUE) {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0 && required) stop("Missing required column(s): ", paste(candidates, collapse = ", "))
  if (length(hit) == 0) return(NA_character_)
  hit[1]
}

build_plot_data <- function(df, state_name, main_city) {
  df_state <- df %>% filter(State == state_name)
  if (nrow(df_state) == 0) return(tibble(year = numeric(), Production = numeric(), Group = character()))
  
  counts <- df_state %>%
    count(year, City, name = "Productions") %>%
    tidyr::complete(
      year = seq(min(year), max(year)),
      City = unique(.$City),
      fill = list(Productions = 0)
    )
  
  main_df <- counts %>%
    filter(City == main_city) %>%
    transmute(year, Production = Productions, Group = main_city)
  
  others_df <- counts %>%
    filter(City != main_city) %>%
    group_by(year) %>%
    summarise(Production = sum(Productions), .groups = "drop") %>%
    mutate(Group = "Other Cities")
  
  bind_rows(main_df, others_df) %>%
    mutate(Group = factor(Group, levels = c(main_city, "Other Cities")))
}

build_plot <- function(df, title, ybreaks) {
  ggplot(df, aes(x = year, y = Production, color = Group, linetype = Group)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    geom_vline(xintercept = 1801, linetype = "dotted", color = "black", linewidth = 1) +
    # main (first factor level) = solid, others = long dash "31"
    scale_linetype_manual(values = c("solid", "31")) +
    scale_y_continuous(
      limits = range(ybreaks),
      breaks = ybreaks,
      minor_breaks = NULL,
      expand = expansion(mult = c(0, 0.02))
    ) +
    labs(title = title, x = "Year", y = "Opera Productions", color = "", linetype = "") +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      plot.title = element_text(hjust = 0.5),
      panel.grid.major.y = element_line(),
      panel.grid.minor.y = element_blank()
    )
}

build_gm_plot_data <- function(df_summary, state_name, main_city_label) {
  df_summary %>%
    filter(state == state_name) %>%
    select(year, operas_main, operas_no_main) %>%
    pivot_longer(c(operas_main, operas_no_main), names_to = "kind", values_to = "Production") %>%
    mutate(Group = if_else(kind == "operas_main", main_city_label, "Other Cities")) %>%
    select(year, Production, Group) %>%
    mutate(Group = factor(Group, levels = c(main_city_label, "Other Cities")))
}

# -------------------- Load ON --------------------
operas_raw <- readr::read_csv(input_path, show_col_types = FALSE)

year_col  <- resolve_col(operas_raw, c("Premiere_Date", "Year", "Premiere_Year", "premiere_year"))
city_col  <- resolve_col(operas_raw, c("City", "city"))
state_col <- resolve_col(operas_raw, c("State_Region", "state_region", "State", "state"))

operas_std <- operas_raw %>%
  mutate(
    year  = as.integer(.data[[year_col]]),
    City  = as.character(.data[[city_col]]),
    State = as.character(.data[[state_col]])
  ) %>%
  filter(!is.na(year))

# Build ON
non_gm_lombardy <- build_plot_data(operas_std, state_name = "Lombardia", main_city = "Milan")
non_gm_venetia  <- build_plot_data(operas_std, state_name = "Venetia",   main_city = "Venice")

# -------------------- Load GM (MG2020) --------------------
operas_gm <- haven::read_dta(gm_path)

state_gm <- resolve_col(operas_gm, c("state", "State", "region", "state_name"))
year_gm  <- resolve_col(operas_gm, c("year", "Year"))
tot_gm   <- resolve_col(operas_gm, c("operas", "n_operas", "total_operas"))
no_mi_gm <- resolve_col(operas_gm, c("operas_no_milan", "operas_nomilan", "no_milan", "operas_no_mi"), required = FALSE)
no_ve_gm <- resolve_col(operas_gm, c("operas_novenice", "operas_no_venice", "no_venice", "operas_no_ve"), required = FALSE)

df_summary <- operas_gm %>%
  transmute(
    state_raw = .data[[state_gm]],
    state = tolower(as.character(.data[[state_gm]])),
    year  = as.integer(.data[[year_gm]]),
    operas_total   = as.numeric(.data[[tot_gm]]),
    operas_no_milan  = if (!is.na(no_mi_gm)) as.numeric(.data[[no_mi_gm]]) else NA_real_,
    operas_novenice  = if (!is.na(no_ve_gm)) as.numeric(.data[[no_ve_gm]]) else NA_real_
  ) %>%
  filter(state %in% c("lombardy", "venetia")) %>%
  mutate(
    operas_no_main = case_when(
      state == "lombardy" ~ operas_no_milan,
      state == "venetia"  ~ operas_novenice,
      TRUE ~ NA_real_
    ),
    operas_main = operas_total - operas_no_main
  ) %>%
  arrange(state, year)

gm_lombardy <- build_gm_plot_data(df_summary, state_name = "lombardy", main_city_label = "Milan")
gm_venetia  <- build_gm_plot_data(df_summary, state_name = "venetia",  main_city_label = "Venice")

# -------------------- Plot & Save  --------------------
title_lombardy <- "Opera Production: Milan vs. Other Lombard Cities"
title_venetia  <- "Opera Production: Venice vs. Other Venetian Cities"

# 4a: Lombardy ON
p_4a <- build_plot(non_gm_lombardy, title_lombardy, ybreaks = c(0, 5, 10))
ggsave(file.path(output_path, "Figure_4a.png"), plot = p_4a, width = 8, height = 6, dpi = 300)

# 4b: Lombardy GM
p_4b <- build_plot(gm_lombardy, title_lombardy, ybreaks = c(0, 5, 10))
ggsave(file.path(output_path, "Figure_4b.png"), plot = p_4b, width = 8, height = 6, dpi = 300)

# 5a: Venetia ON
p_5a <- build_plot(non_gm_venetia, title_venetia, ybreaks = c(0, 5, 10, 15, 20))
ggsave(file.path(output_path, "Figure_5a.png"), plot = p_5a, width = 8, height = 6, dpi = 300)

# 5b: Venetia GM
p_5b <- build_plot(gm_venetia, title_venetia, ybreaks = c(0, 5, 10, 15, 20))
ggsave(file.path(output_path, "Figure_5b.png"), plot = p_5b, width = 8, height = 6, dpi = 300)

# Browse
show_subset <- function(df, title, cols = c("City"), n_show = 30) {
  cat("\n=== ", title, " ===\n", sep = "")
  cat("Rows: ", nrow(df), "\n\n", sep = "")
  df %>%
    select(any_of(cols)) %>%
    tibble::as_tibble() %>%
    print(n = n_show)
}

# 1) Lombardy (not Milan) in 1804
op_1804_lombardy_not_milan <- operas_std %>%
  filter(State == "Lombardia", City != "Milan", year == 1804) %>%
  arrange(City)
show_subset(op_1804_lombardy_not_milan, "Lombardy (not Milan) — 1804", "City", 5)

# 2) Venetia (not Venice) in 1812
op_1812_venetia_not_venice <- operas_std %>%
  filter(State == "Venetia", City != "Venice", year == 1812) %>%
  arrange(City)
show_subset(op_1812_venetia_not_venice, "Venetia (not Venice) — 1812", "City", 5)

cat("\nCity counts (Lombardy 1804):\n")
print(table(op_1804_lombardy_not_milan$City))

cat("\nCity counts (Venetia 1812):\n")
print(table(op_1812_venetia_not_venice$City))
