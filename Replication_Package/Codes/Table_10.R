# Clean Environment
rm(list = ls())
options(stringsAsFactors = FALSE)
options(scipen = 999)
# Packages
library(tidyverse)  
library(haven)    
library(kableExtra)

figure_path <- here::here("Figures")
tables_path <- here::here("Tables")

# Loewenberg data ----
annals_path <-here::here("Data_New", "Loewenberg_1781_1820_it_raw.csv")
annals <- read.csv(annals_path, header = TRUE)

# GM2020 data
gm_path <-here::here("Data_GM2020", "operas_1781_1820.dta")
gm <- read_dta(gm_path) %>%
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

ggsave(filename = "Loewenberg_vs_GM2020_Annual.png", path = figure_path, width = 8, height = 6, dpi = 400)


# Now Table: 
# ---- Build LaTeX table rows (1781–1800 vs 1801–1820) ----
periodised <- annals_merged %>%
  mutate(period = case_when(
    year >= 1781 & year <= 1800 ~ "1781--1800",
    year >= 1801 & year <= 1820 ~ "1801--1820",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(period))

lv_states <- c("lombardy", "venetia")
all_states <- sort(unique(annals_count$state))
os_states <- setdiff(all_states, lv_states)

mk_row <- function(label, states) {
  tmp <- periodised %>%
    filter(state %in% states) %>%
    group_by(period) %>%
    summarise(
      GM2020     = sum(operas_annals, na.rm = TRUE),
      Loewenberg = sum(Count,         na.rm = TRUE),
      .groups = "drop"
    ) %>%
    tidyr::pivot_wider(
      names_from = period,
      values_from = c(GM2020, Loewenberg),
      values_fill = 0
    )
  
  # Extract (default to 0 if missing)
  gm_1781_1800  <- tmp$`GM2020_1781--1800`     %||% 0
  loe_1781_1800 <- tmp$`Loewenberg_1781--1800` %||% 0
  gm_1801_1820  <- tmp$`GM2020_1801--1820`     %||% 0
  loe_1801_1820 <- tmp$`Loewenberg_1801--1820` %||% 0
  
  d1 <- loe_1781_1800 - gm_1781_1800
  d2 <- loe_1801_1820 - gm_1801_1820
  
  sprintf(
    "%s & %d & %d & %d & %d & %d & %d\\\\",
    label,
    gm_1781_1800, loe_1781_1800, d1,
    gm_1801_1820, loe_1801_1820, d2
  )
}

# Two requested rows
row_lv <- mk_row("Lombardy--Venetia", lv_states)
row_os <- mk_row("Other states",      os_states)

# ---- Assemble LaTeX lines and write to file ----
lines <- c(
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "\\multicolumn{1}{c}{ } & \\multicolumn{3}{c}{1781--1800} & \\multicolumn{3}{c}{1801--1820} \\\\",
  "\\cmidrule(l{3pt}r{3pt}){2-4} \\cmidrule(l{3pt}r{3pt}){5-7}",
  "State & GM2020 & Loewenberg & $\\Delta$ & GM2020 & Loewenberg & $\\Delta$\\\\",
  "\\midrule",
  row_lv,
  row_os,
  "\\bottomrule",
  "\\end{tabular}"
)

writeLines(lines, file.path(tables_path, "Table_10.txt"))

# How many Years do they crazy lie?

# ---- Years where GM2020 == 0 but Loewenberg >= 1, by Venetia / Lombardy / Other ----
# relies on annals_merged from your script: columns year, state, Count, operas_annals

library(dplyr)
library(kableExtra)

# ---- Years where GM2020 == 0 but Loewenberg >= 1, by Venetia / Lombardy / Other ----
df_grouped <- annals_merged %>%
  mutate(group = dplyr::recode(
    state,
    "venetia"  = "Venetia",
    "lombardy" = "Lombardy",
    .default   = "Other states"
  )) %>%
  group_by(group, year) %>%
  summarise(
    GM2020     = sum(operas_annals, na.rm = TRUE),
    Loewenberg = sum(Count,         na.rm = TRUE),
    .groups = "drop"
  )

years_with_gap <- df_grouped %>%
  filter(GM2020 == 0, Loewenberg >= 1) %>%
  arrange(group, year)

# Counts per group
counts_by_group <- years_with_gap %>%
  count(group, name = "n_years")

# Total count (year × group)
total_years <- nrow(years_with_gap)

# Years per group
years_by_group <- years_with_gap %>%
  group_by(group) %>%
  summarise(years = paste(year, collapse = ", "), .groups = "drop")

# ---- Print results ----
cat("Years where GM2020 reports 0 operas but Loewenberg reports ≥1:\n\n")

for (i in seq_len(nrow(counts_by_group))) {
  g <- counts_by_group$group[i]
  n <- counts_by_group$n_years[i]
  yrs <- years_by_group$years[years_by_group$group == g]
  cat(sprintf("%-13s: %2d years -> %s\n", g, n, yrs))
}

cat("\nTotal year × group combinations:", total_years, "\n")


## Time to print examples: 

# ---- Build (State, Year) keys from your computed years_with_gap ----
# ---- Build (State, Year) keys from your computed years_with_gap ----
keys <- years_with_gap %>%
  distinct(group, year) %>%
  mutate(group = as.character(group),
         year  = as.integer(year)) %>%
  rename(State = group, Year = year)

# ---- Helper: capitalize only the first character ----
cap_first <- function(x) {
  x <- if (is.factor(x)) as.character(x) else x
  ifelse(is.na(x) | x == "", x,
         paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x))))
}

# ---- Normalize Loewenberg rows to 3 groups & keep the needed columns ----
# Uses *actual* CSV column names: Opera_Name, Composer, city, year, State_Region
keys <- years_with_gap %>%
  distinct(group, year) %>%
  mutate(group = as.character(group),
         year  = as.integer(year)) %>%
  rename(State = group, Year = year)

# ---- Helper: Capitalize first letter of EACH word (Composer only) ----
cap_words <- function(x) {
  ifelse(is.na(x) | x == "", x,
         stringr::str_to_title(trimws(x)))
}

# ---- Normalize Loewenberg rows to 3 groups ----
annals_enriched <- annals %>%
  mutate(
    year         = as.integer(year),
    State_Region = as.character(State_Region),
    group = dplyr::case_when(
      State_Region %in% c("Lombardia", "Lombardy") ~ "Lombardy",
      State_Region %in% c("Venetia", "Veneto")     ~ "Venetia",
      TRUE                                         ~ "Other states"
    )
  ) %>%
  select(group, year, Opera = Opera_Name, Composer, City = city)

# ---- Join and select one opera per (State, Year) ----
picked <- keys %>%
  rename(group = State, year = Year) %>%
  left_join(annals_enriched, by = c("group", "year")) %>%
  group_by(group, year) %>%
  arrange(is.na(Opera), Opera) %>%
  slice_head(n = 1) %>%
  ungroup() %>%
  transmute(
    State    = group,
    Year     = year,
    Opera    = Opera,
    Composer = cap_words(Composer),
    City     = City
  ) %>%
  arrange(State, Year)

# ---- Diagnostics ----
missing <- picked %>% filter(is.na(Opera) | Opera == "")
if (nrow(missing) > 0) {
  cat("\n[Note] Missing Loewenberg match for:\n")
  apply(missing[, c("State","Year")], 1, function(r) {
    cat(sprintf("  - %s, %s\n", r[["State"]], r[["Year"]]))
  })
}

# ---- Print top 5 rows ----
cat("Table: One Loewenberg opera per (State, Year) where GM2020=0 & Loewenberg≥1 (Top 5 shown)\n\n")
cat(sprintf("%-13s | %-4s | %-45s | %-28s | %s\n",
            "State","Year","Opera","Composer","City"))
cat(strrep("-", 13 + 3 + 4 + 3 + 45 + 3 + 28 + 3 + 20), "\n", sep = "")

apply(head(picked, 5), 1, function(r) {
  cat(sprintf("%-13s | %4s | %-45s | %-28s | %s\n",
              r[["State"]], r[["Year"]], r[["Opera"]], r[["Composer"]], r[["City"]]))
})

# ---- Save ----
out_path <- file.path(tables_path, "Loewenberg_gap_examples.csv")
readr::write_csv(picked, out_path)
cat("\nSaved table to: ", out_path, "\n", sep = "")


## 2 groups

library(dplyr)
library(stringr)
library(readr)

# ---- Aggregate by 2 groups: Venetia+Lombardy vs Other states ----
df_grouped <- annals_merged %>%
  mutate(group = dplyr::case_when(
    state %in% c("venetia", "lombardy") ~ "Lombardy–Venetia",
    TRUE                                 ~ "Other states"
  )) %>%
  group_by(group, year) %>%
  summarise(
    GM2020     = sum(operas_annals, na.rm = TRUE),
    Loewenberg = sum(Count,         na.rm = TRUE),
    .groups = "drop"
  )

years_with_gap <- df_grouped %>%
  filter(GM2020 == 0, Loewenberg >= 1) %>%
  arrange(group, year)

# ---- Summary printout ----
counts_by_group <- years_with_gap %>% count(group, name = "n_years")
total_years <- nrow(years_with_gap)
years_by_group <- years_with_gap %>%
  group_by(group) %>%
  summarise(years = paste(year, collapse = ", "), .groups = "drop")

cat("Years where GM2020 reports 0 operas but Loewenberg reports ≥1 (2-group version):\n\n")
for (i in seq_len(nrow(counts_by_group))) {
  g <- counts_by_group$group[i]
  n <- counts_by_group$n_years[i]
  yrs <- years_by_group$years[years_by_group$group == g]
  cat(sprintf("%-17s: %2d years -> %s\n", g, n, yrs))
}
cat("\nTotal year × group combinations:", total_years, "\n")

# ---- Build (Group, Year) keys ----
keys <- years_with_gap %>%
  distinct(group, year) %>%
  mutate(group = as.character(group),
         year  = as.integer(year)) %>%
  rename(Group = group, Year = year)

# ---- Helper: title-case EACH word for Composer only ----
cap_words <- function(x) {
  ifelse(is.na(x) | x == "", x, stringr::str_to_title(trimws(x)))
}

# ---- Prepare Loewenberg rows with matching 2-group label ----
# CSV columns: Opera_Name, Composer, city, year, State_Region
annals_enriched <- annals %>%
  mutate(
    year         = as.integer(year),
    State_Region = as.character(State_Region),
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
    ),
    group = dplyr::case_when(
      state %in% c("venetia", "lombardy") ~ "Lombardy–Venetia",
      TRUE                                 ~ "Other states"
    )
  ) %>%
  select(group, year, Opera = Opera_Name, Composer, City = city)

# ---- Join and pick one opera per (Group, Year) ----
picked <- keys %>%
  rename(group = Group, year = Year) %>%
  left_join(annals_enriched, by = c("group", "year")) %>%
  group_by(group, year) %>%
  arrange(is.na(Opera), Opera) %>%
  slice_head(n = 1) %>%
  ungroup() %>%
  transmute(
    State    = group,
    Year     = year,
    Opera    = Opera,
    Composer = cap_words(Composer),  # only composer title-cased
    City     = City
  ) %>%
  arrange(State, Year)

# ---- Diagnostics for any missed matches ----
missing <- picked %>% filter(is.na(Opera) | Opera == "")
if (nrow(missing) > 0) {
  cat("\n[Note] Missing Loewenberg match for:\n")
  apply(missing[, c("State","Year")], 1, function(r) {
    cat(sprintf("  - %s, %s\n", r[["State"]], r[["Year"]]))
  })
}

# ---- Print top 5 rows ----
cat("\nTable: One Loewenberg opera per (Group, Year) where GM2020=0 & Loewenberg≥1 (Top 5 shown)\n\n")
cat(sprintf("%-17s | %-4s | %-45s | %-28s | %s\n",
            "Group","Year","Opera","Composer","City"))
cat(strrep("-", 17 + 3 + 4 + 3 + 45 + 3 + 28 + 3 + 20), "\n", sep = "")

apply(head(picked, 5), 1, function(r) {
  cat(sprintf("%-17s | %4s | %-45s | %-28s | %s\n",
              r[["State"]], r[["Year"]], r[["Opera"]], r[["Composer"]], r[["City"]]))
})

# ---- Save full table ----
out_path <- file.path(tables_path, "Loewenberg_gap_examples_LV_vs_other.csv")
readr::write_csv(picked, out_path)
cat("\nSaved table to: ", out_path, "\n", sep = "")


# each state is a group: 
# ---- Build (state, year) keys from computed years_with_gap ----
# Build (state, year) keys robustly from the state-level summary


library(dplyr)
library(readr)
library(stringr)

cap_words <- function(x) ifelse(is.na(x) | x == "", x, stringr::str_to_title(trimws(x)))

# Ensure Loewenberg rows have slug `state` exactly per your mapping
annals_enriched_state <- annals %>%
  mutate(
    year         = as.integer(year),
    State_Region = as.character(State_Region),
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
  select(state, year, Opera = Opera_Name, Composer, City = city)

# Collapse GM/Loewenberg to (state, year), then pick the "gap" combos
by_state_year <- annals_merged %>%
  group_by(state, year) %>%
  summarise(
    GM2020     = sum(operas_annals, na.rm = TRUE),
    Loewenberg = sum(Count,         na.rm = TRUE),
    .groups = "drop"
  )

gaps_state_year <- by_state_year %>%
  filter(GM2020 == 0, Loewenberg >= 1) %>%
  select(state, year)  # <- no GM/Loewenberg in the output

# pretty labels for slug -> display
STATE_PRETTY <- c(
  papal_state = "Papal",
  venetia     = "Venetia",
  two_sicilies= "Two Sicilies",
  lombardy    = "Lombardy",
  sardinia    = "Sardinia",
  d_parma     = "Parma",
  gd_tuscany  = "Toscany",
  d_modena    = "Modena"
)

Loewenberg_gap_examples_by_state <- gaps_state_year %>%
  left_join(annals_enriched_state, by = c("state", "year")) %>%
  group_by(state, year) %>%
  arrange(is.na(Opera), Opera, City, Composer) %>%  # deterministic example
  slice_head(n = 1) %>%
  ungroup() %>%
  mutate(
    Composer = cap_words(Composer),
    # Use pretty names; fall back to a title-cased slug if ever unmatched
    State = cap_words(gsub("_", " ", dplyr::coalesce(STATE_PRETTY[state], state)))
  ) %>%
  transmute(
    State,              # Papal, Venetia, Due Sicilie, etc.
    Year = year,
    Opera,
    Composer,
    City
  ) %>%
  arrange(State, Year)


# ---- Print top 5 (no GM2020/Loewenberg columns) ----
cat("Loewenberg > 0 & GM2020 == 0 — one opera example per (State, Year) (top 5):\n\n")
cat(sprintf("%-14s | %-4s | %-45s | %-28s | %s\n",
            "State","Year","Opera","Composer","City"))
cat(strrep("-", 14 + 3 + 4 + 3 + 45 + 3 + 28 + 3 + 20), "\n", sep = "")

apply(head(Loewenberg_gap_examples_by_state, 5), 1, function(r) {
  cat(sprintf("%-14s | %4s | %-45s | %-28s | %s\n",
              r[["State"]], r[["Year"]], r[["Opera"]], r[["Composer"]], r[["City"]]))
})

# ---- Save CSV (slug "pretty" names) ----
out_path <- file.path(tables_path, "Loewenberg_gap_examples_by_state.csv")
readr::write_csv(Loewenberg_gap_examples_by_state, out_path)
cat("\nSaved table to: ", out_path, "\n", sep = "")


# ---- Print TOTAL Loewenberg operas where GM2020 == 0 ----
total_loewenberg_gaps <- by_state_year %>%
  filter(GM2020 == 0, Loewenberg >= 1) %>%
  summarise(total = sum(Loewenberg, na.rm = TRUE)) %>%
  pull(total)

cat("\nTotal Loewenberg operas for all (State, Year) where GM2020 == 0: ",
    total_loewenberg_gaps, "\n", sep = "")


Loewenberg_gaps_full <- annals_enriched_state %>%
  semi_join(
    by_state_year %>% filter(GM2020 == 0, Loewenberg >= 1),
    by = c("state", "year")
  ) %>%
  mutate(
    Composer = cap_words(Composer),
    State = cap_words(gsub("_", " ", dplyr::coalesce(STATE_PRETTY[state], state)))
  ) %>%
  transmute(
    State,
    Year = year,
    Opera,
    Composer,
    City
  ) %>%
  arrange(State, Year, Opera)

out_path <- file.path(tables_path, "Loewenberg_all_gaps_by_state.csv")
readr::write_csv(Loewenberg_gaps_full, out_path)

cat("\nSaved full Loewenberg gaps table to: ", out_path, "\n", sep = "")
