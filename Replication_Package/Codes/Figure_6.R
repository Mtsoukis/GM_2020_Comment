# Clean Environment
rm(list = ls())
options(stringsAsFactors = FALSE)
options(scipen = 999)
# Packages
library(tidyverse)  
library(haven)    

# ---- Load data ----
annals <- read.csv("Data_New/Loewenberg_1781_1820_it_raw.csv", header = TRUE)

# GM2020 data
gm <- read_dta("Data_GM2020/operas_1781_1820.dta") %>%
  select(year, state, operas_annals)

annals <- annals %>%
  mutate(
    year = as.integer(year),
    State_Region = as.character(State_Region)
  )

annals_count <- annals %>%
  group_by(State_Region, year) %>%
  summarise(Count = n(), .groups = "drop") %>%
  tidyr::complete(
    State_Region = c(unique(annals$State_Region), "Duchy_Modena"),
    year = min(annals$year, na.rm = TRUE):max(annals$year, na.rm = TRUE),
    fill = list(Count = 0)
  ) %>%
  mutate(
    state = dplyr::recode(
      State_Region,
      "Papal"        = "papal_state",
      "Venetia"      = "venetia",
      "Due_Sicilie"  = "two_sicilies",
      "Lombardia"    = "lombardy",
      "Sardinia"     = "sardinia",
      "Duchy_Parma"  = "d_parma",
      "Toscana"      = "gd_tuscany",
      "Duchy_Modena" = "d_modena",
      .default = NA_character_
    )
  ) %>%
  select(year, state, Count)

# ---- Merge with GM2020 and aggregate----
annals_merged <- inner_join(annals_count, gm, by = c("year", "state"))

df_all <- annals_merged %>%
  group_by(year) %>%
  summarise(
    sum_GM2020 = sum(operas_annals, na.rm = TRUE),
    sum_Me     = sum(Count,         na.rm = TRUE),
    .groups    = "drop"
  )

# ---- Plot and save ----
p <- ggplot(df_all, aes(x = year)) +
  geom_line(aes(y = sum_GM2020, color = "GM2020"), linewidth = 1) +
  geom_point(aes(y = sum_GM2020, color = "GM2020")) +
  geom_line(aes(y = sum_Me,     color = "OCR"), linetype = "31", linewidth = 1) +
  geom_point(aes(y = sum_Me,    color = "OCR")) +
  geom_vline(xintercept = 1801, linetype = "dotted", color = "black", linewidth = 1) +
  labs(
    title = "Loewenberg Operas: GM2020 vs OCR",
    x = "Year", y = "Opera Productions", color = ""
  ) +
  scale_color_hue(direction = 1) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

dir.create("Figures", recursive = TRUE, showWarnings = FALSE)
ggsave(filename = "Figure_6.png", path = "Figures", width = 8, height = 6, dpi = 400)
