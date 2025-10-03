# Clean environment
rm(list = ls())
options(stringsAsFactors = FALSE)
options(scipen = 999)

# Load packages
library(tidyverse)
library(haven)

data_path   <- "Data_GM2020/"
output_path <- "Figures/"

# -------------------------------
# City-level aggregation
# -------------------------------

df_city_raw <- read_dta(file.path(data_path, "city_level_operas_1781_1820.dta")) %>%
  select(city, operas_city, year)

lombardy_cities <- c("milan", "bergamo", "brescia", "mantua")
venetia_cities  <- c("venice", "verona", "vicenza", "padova", "rovigo")
main_cities     <- c("milan", "venice")

df_state <- df_city_raw %>%
  filter(city %in% c(lombardy_cities, venetia_cities)) %>%
  mutate(
    state = case_when(
      city %in% lombardy_cities ~ "lombardy",
      city %in% venetia_cities  ~ "venetia"
    )
  )

state_year_opera <- df_state %>%
  group_by(state, year) %>%
  summarise(
    operas_main    = sum(operas_city[city %in% main_cities],  na.rm = TRUE),
    operas_no_main = sum(operas_city[!city %in% main_cities], na.rm = TRUE),
    operas_total   = sum(operas_city,                         na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(dataset = "city_level")

# --------------------------------------------
# Main dataset
# --------------------------------------------
df_operas <- read_dta(file.path(data_path, "operas_1781_1820.dta")) %>%
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
  select(state, year, operas_no_main, operas_main, operas_total) %>%
  arrange(state, year) %>%
  mutate(dataset = "operas_1781_1820")

# -------------------------------
# Combine & plot
# -------------------------------
df_combined <- bind_rows(state_year_opera, df_operas)

make_plot <- function(state_name) {
  ggplot(
    df_combined %>% filter(state == state_name),
    aes(x = year, y = operas_no_main, color = dataset, linetype = dataset)
  ) +
    geom_line(linewidth = 1) +
    geom_point() +
    geom_vline(xintercept = 1801, linetype = "dotted", color = "black", linewidth = 1) +
    scale_linetype_manual(values = c("city_level" = "solid", "operas_1781_1820" = "31")) +
    labs(
      x = "Year",
      y = "Operas Excluding Main City",
      color = "",
      linetype = ""
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
}

# Venetia
p_venetia <- make_plot("venetia")
ggsave(
  filename = file.path(output_path, "Figure_2a.png"),
  plot = p_venetia, width = 8, height = 6, dpi = 300
)

# Lombardy
p_lombardy <- make_plot("lombardy")
ggsave(
  filename = file.path(output_path, "Figure_2b.png"),
  plot = p_lombardy, width = 8, height = 6, dpi = 300
)
