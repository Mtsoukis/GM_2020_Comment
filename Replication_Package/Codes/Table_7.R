######## Average_Operas_it (recreated) ########
# Input  : Data_New/Opening_Night_Operas_it_cleaned.csv
# Output : Tables/Table_7.txt  (LaTeX table text)

# Packages
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(knitr)
})

options(stringsAsFactors = FALSE, scipen = 999)

# Paths
ON_dta <- "Data_New/Opening_Night_Operas_it_cleaned.csv"
out_file <- file.path("Tables", "Table_7.txt")

# Ensure output dir exists
dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

# Load cleaned state-year data:
# expected columns: year, state, operas, copyright, post1801, copyright_post1801
df <- readr::read_csv(ON_dta, show_col_types = FALSE)

# Map treatment & period labels
df_labeled <- df %>%
  mutate(
    Treatment = if_else(copyright == 1, "Lombardia + Venetia", "Other States"),
    Period    = if_else(post1801 == 1, "Post-1801", "Pre-1801")
  )

# --- Average production matrix (mean operas per state-year) ---
avg_production <- df_labeled %>%
  group_by(Treatment, Period) %>%
  summarise(Avg_Production = mean(operas, na.rm = TRUE), .groups = "drop")

avg_production_matrix_it <- avg_production %>%
  tidyr::pivot_wider(names_from = Period, values_from = Avg_Production) %>%
  mutate(
    `Pre-1801`  = round(`Pre-1801`, 2),
    `Post-1801` = round(`Post-1801`, 2),
    `%Δ`        = round(((`Post-1801` - `Pre-1801`) / `Pre-1801`) * 100, 2)
  ) %>%
  select(Treatment, `Pre-1801`, `Post-1801`, `%Δ`) %>%
  rename(State = Treatment)

# --- t-tests (within-treatment: Pre vs Post) ---
treat_test <- df_labeled %>%
  filter(Treatment == "Lombardia + Venetia") %>%
  { t.test(operas ~ factor(Period), data = .) }

ctrl_test <- df_labeled %>%
  filter(Treatment == "Other States") %>%
  { t.test(operas ~ factor(Period), data = .) }

ttest_summary <- data.frame(
  State   = c("Lombardia + Venetia", "Other States"),
  `t-value` = c(round(as.numeric(treat_test$statistic), 2),
                round(as.numeric(ctrl_test$statistic),  2)),
  `p-value` = c(round(treat_test$p.value, 2),
                round(ctrl_test$p.value,  2)),
  check.names = FALSE
)

# Combine averages with t-stats
combined_table <- avg_production_matrix_it %>%
  left_join(ttest_summary, by = "State")

# Build LaTeX table and write to txt
latex_tbl <- knitr::kable(
  combined_table,
  format    = "latex",
  booktabs  = TRUE,
  row.names = FALSE,
  escape    = FALSE,
  col.names = c("State", "Pre-1801", "Post-1801", "$\\Delta\\%$", "t-value", "p-value")
)

writeLines(latex_tbl, con = out_file)

# (Optional) console print
print(combined_table)
message("Saved LaTeX table to: ", out_file)
