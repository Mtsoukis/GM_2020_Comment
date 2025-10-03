rm(list = ls())

# ---- Paths ----
output_path <- "Figures/"
dir.create(output_path, showWarnings = FALSE, recursive = TRUE)

# ---- Options & Packages ----
options(stringsAsFactors = FALSE)
options(scipen = 999)

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(ggplot2)
})

# ---- Helpers ----
build_plot <- function(df, title, ybreaks) {
  ggplot(df, aes(x = year, y = Production, color = Group, linetype = Group)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    geom_vline(xintercept = 1801, linetype = "dotted", color = "black", linewidth = 1) +
    scale_linetype_manual(values = c("Milan" = "solid", "Venice" = "solid", "Other Cities" = "31")) +
    # Only draw gridlines at the tick marks (no minor lines)
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
      panel.grid.major.y = element_line(),  # lines only at y ticks
      panel.grid.minor.y = element_blank()
      # if you also want to remove vertical gridlines, uncomment:
      # , panel.grid.major.x = element_blank()
    )
}

build_non_gm_plot_data <- function(italy_operas_it, state_region, main_city_label) {
  df_state <- italy_operas_it %>% filter(State_Region == state_region)
  if (nrow(df_state) == 0) return(tibble(year = numeric(), Production = numeric(), Group = character()))
  
  all_years  <- seq(min(df_state$Year, na.rm = TRUE), max(df_state$Year, na.rm = TRUE))
  all_cities <- sort(unique(df_state$City))
  
  complete_grid <- expand.grid(Year = all_years, City = all_cities)
  
  counts <- df_state %>%
    group_by(Year, City) %>%
    summarise(Productions = n(), .groups = "drop") %>%
    right_join(complete_grid, by = c("Year", "City")) %>%
    mutate(Productions = if_else(is.na(Productions), 0L, Productions)) %>%
    arrange(Year, City)
  
  main_df <- counts %>%
    filter(City == main_city_label) %>%
    transmute(year = Year, Production = Productions, Group = main_city_label)
  
  others_df <- counts %>%
    filter(City != main_city_label) %>%
    group_by(Year) %>%
    summarise(Production = sum(Productions), .groups = "drop") %>%
    transmute(year = Year, Production, Group = "Other Cities")
  
  bind_rows(main_df, others_df) %>%
    mutate(Group = factor(Group, levels = c(main_city_label, "Other Cities")))
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

# ======================================================
# Load & prepare NON-GM (Italy + Italian-born) data
# ======================================================
italy_operas <- read.csv(
  "/Users/mariostsoukis/Documents/NYU/Applied_Micro_1/Do_Not_Believe/Replication_ME/Data_Correct/italy_operas.csv",
  header = TRUE, sep = ","
)

# Drop 'Country' and Friuli-Venezia Giulia (not Italy then)
if ("Country" %in% names(italy_operas)) italy_operas$Country <- NULL
italy_operas <- italy_operas[italy_operas$State_Region != "Friuli-Venezia Giulia", ]

# Normalize composer label
italy_operas <- italy_operas %>%
  mutate(Composer = ifelse(Composer == "[Marcello Bernardini] Marcello di Capua",
                           "Marcello Bernardini", Composer))

# Historical state mapping
italy_operas$State_Region[italy_operas$State_Region %in% c("Friuli-Venezia", "Veneto")] <- "Venetia"
italy_operas$State_Region[italy_operas$State_Region %in% c("Marche", "Lazio", "Umbria")] <- "Papal"
italy_operas$State_Region[italy_operas$State_Region %in% c("Campania", "Puglia", "Abruzzi", "Sicilia")] <- "Due_Sicilie"
italy_operas$State_Region[italy_operas$State_Region %in% c("Piemonte", "Liguria")] <- "Sardinia"
italy_operas$State_Region[italy_operas$City %in% c("Modena", "Reggio nell'Emilia", "Corregio")] <- "Duchy_Modena"
italy_operas$State_Region[italy_operas$City %in% c("Parma", "Piacenza", "Medesano")] <- "Duchy_Parma"
italy_operas$State_Region[italy_operas$City %in% c("Bologna", "Ferrara", "Rimini", "Faenza", "Bagnacavallo", "Cento", "Forli", "Lugo")] <- "Papal"

italy_operas$Premiere_Date <- as.character(italy_operas$Premiere_Date)

# Italian-born filter merge (append 5 composers as Italian-born)
new_composers <- data.frame(
  V1 = c("Francesco Ruggi (1)", "Francesco Federici (2)", "Marcello Bernardini",
         "Hieronymus Mango", "Francesco Cannetti (1)"),
  V2 = rep("Yes", 5),
  stringsAsFactors = FALSE
)
italy_composers <- read.csv(
  "/Users/mariostsoukis/Documents/NYU/Applied_Micro_1/Do_Not_Believe/Replication_ME/Data_Correct/Composers_Italian_Born.csv",
  header = FALSE, sep = ","
)
italy_composers <- rbind(italy_composers, new_composers)

merged_data <- merge(italy_operas, italy_composers, by.x = "Composer", by.y = "V1")
italy_operas_it <- merged_data[merged_data$V2 == "Yes", ] %>%
  mutate(Year = as.numeric(Premiere_Date))

# Build NON-GM plot data
non_gm_lombardy <- build_non_gm_plot_data(italy_operas_it, state_region = "Lombardia", main_city_label = "Milan")
non_gm_venetia  <- build_non_gm_plot_data(italy_operas_it, state_region = "Venetia",   main_city_label = "Venice")

# ======================================================
# Load & prepare GM (MG2020) dataset
# ======================================================
df_operas <- read_dta("/Users/mariostsoukis/Documents/NYU/Applied_Micro_1/Do_Not_Believe/Replication_Data/datasets/operas_1781_1820.dta")

df_summary <- df_operas %>%
  select(state, year, operas, operas_no_milan, operas_novenice) %>%
  filter(state %in% c("lombardy", "venetia")) %>%
  mutate(
    operas_total   = operas,
    operas_no_main = case_when(
      state == "lombardy" ~ operas_no_milan,
      state == "venetia"  ~ operas_novenice
    ),
    operas_main    = operas_total - operas_no_main
  ) %>%
  select(state, year, operas_main, operas_no_main) %>%
  arrange(state, year)

# Build GM plot data
gm_lombardy <- build_gm_plot_data(df_summary, state_name = "lombardy", main_city_label = "Milan")
gm_venetia  <- build_gm_plot_data(df_summary, state_name = "venetia",  main_city_label = "Venice")

# ======================================================
# Plot & Save (only the four files)
# ======================================================
title_lombardy <- "Opera Production: Milan vs. Other Lombard Cities"
title_venetia  <- "Opera Production: Venice vs. Other Venetian Cities"

# Figure 4a: Lombardy non-GM (y: 0,5,10)
p_4a <- build_plot(non_gm_lombardy, title_lombardy, ybreaks = c(0, 5, 10))
ggsave(file.path(output_path, "Figure_4a.png"), plot = p_4a, width = 8, height = 6, dpi = 300)

# Figure 4b: Lombardy GM (y: 0,5,10)
p_4b <- build_plot(gm_lombardy, title_lombardy, ybreaks = c(0, 5, 10))
ggsave(file.path(output_path, "Figure_4b.png"), plot = p_4b, width = 8, height = 6, dpi = 300)

# Figure 5a: Venetia non-GM (y: 0,5,10,15,20)
p_5a <- build_plot(non_gm_venetia, title_venetia, ybreaks = c(0, 5, 10, 15, 20))
ggsave(file.path(output_path, "Figure_5a.png"), plot = p_5a, width = 8, height = 6, dpi = 300)

# Figure 5b: Venetia GM (y: 0,5,10,15,20)
p_5b <- build_plot(gm_venetia, title_venetia, ybreaks = c(0, 5, 10, 15, 20))
ggsave(file.path(output_path, "Figure_5b.png"), plot = p_5b, width = 8, height = 6, dpi = 300)





# Columns to display if they exist
cols <- c("City")

# How many rows to print (change to Inf if you want all)
max_print <- 5

# Helper to print a tidy preview
show_subset <- function(df, title, cols, n_show = 30) {
  cat("\n=== ", title, " ===\n", sep = "")
  cat("Rows: ", nrow(df), "\n\n", sep = "")
  df %>%
    select(any_of(cols)) %>%
    tibble::as_tibble() %>%
    print(n = n_show)
}

## 1) Lombardy (not Milan) in 1804
op_1804_lombardy_not_milan <- italy_operas_it %>%
  filter(State_Region == "Lombardia", City != "Milan", Year == 1804) %>%
  arrange(City, Composer)

show_subset(op_1804_lombardy_not_milan, "Lombardy (not Milan) — 1804", cols, max_print)

## 2) Venetia (not Venice) in 1812
op_1812_venetia_not_venice <- italy_operas_it %>%
  filter(State_Region == "Venetia", City != "Venice", Year == 1812) %>%
  arrange(City, Composer)

show_subset(op_1812_venetia_not_venice, "Venetia (not Venice) — 1812", cols, max_print)

# Optional quick city counts (compact)
cat("\nCity counts (Lombardy 1804):\n")
print(table(op_1804_lombardy_not_milan$City))

cat("\nCity counts (Venetia 1812):\n")
print(table(op_1812_venetia_not_venice$City))