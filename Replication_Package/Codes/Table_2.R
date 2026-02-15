# Packages
library(here)
library(haven)
library(knitr)
library(kableExtra)
library(stringr)

# -------------------------------------------------------------------
# Files and explicit column mapping (from inspecting the .dta files)
# -------------------------------------------------------------------
files <- c(
  "city_level_operas_1781_1820.dta",
  "composer_level_data.dta",
  "operas_1781_1820.dta"
)
base_names <- tools::file_path_sans_ext(files)
paths <- setNames(here::here("Data_GM2020", files), base_names)

# Exact columns per file for Annals, Amazon, Met
col_map <- list(
  city_level_operas_1781_1820 = c(
    Annals = "operas_city_annals",
    Amazon = "operas_city_amazon",
    Met    = "operas_city_met"
  ),
  composer_level_data = c(
    Annals = "annals",
    Amazon = "amazon",
    Met    = "met"
  ),
  operas_1781_1820 = c(
    Annals = "operas_annals",
    Amazon = "operas_amazon",
    Met    = "operas_met"
  )
)

# -------------------------------------------------------------------
# Sum helper
# -------------------------------------------------------------------
sum_for_file <- function(path, cols_named) {
  df <- haven::read_dta(path)
  sapply(cols_named, function(col) {
    if (!col %in% names(df)) {
      stop(sprintf("Column '%s' not found in %s", col, basename(path)), call. = FALSE)
    }
    sum(as.numeric(df[[col]]), na.rm = TRUE)
  })
}

# Compute totals: rows = sources; columns = file basenames
totals_list <- mapply(sum_for_file, p = paths, cols_named = col_map, SIMPLIFY = FALSE)
totals_mat  <- do.call(cbind, totals_list)
rownames(totals_mat) <- c("Annals","Amazon","Met")
colnames(totals_mat) <- names(paths)

# -------------------------------------------------------------------
# Build the table:
#   rownames = Source (Annals/Amazon/Met)
#   columns  = Paper (blank) + each dataset
# -------------------------------------------------------------------
tbl <- data.frame(
  Paper = "",
  totals_mat[, base_names, drop = FALSE],
  check.names = FALSE
)
rownames(tbl) <- rownames(totals_mat)

# Optional: integer formatting of numeric columns
num_cols <- setdiff(names(tbl), "Paper")
for (cc in num_cols) tbl[[cc]] <- as.integer(tbl[[cc]])

# -------------------------------------------------------------------
# LaTeX table
#   columns: [rownames] | Paper | city | composer | operas
# -------------------------------------------------------------------
caption_text <- "Total operas counted by source across datasets"
align_vec    <- c("l", "l", rep("r", length(base_names)))  # rownames, Paper, datasets

kbl_obj <- kable(
  tbl,
  format    = "latex",
  booktabs  = TRUE,
  align     = align_vec,
  caption   = caption_text,
  col.names = c("Paper", base_names),  # header for col2–5; col1 (rownames) is blank
  row.names = TRUE
) |>
  # first 2 columns (rownames + Paper) blank; 'Datasets' over the 3 dataset cols
  add_header_above(c(" " = 2, "Datasets" = length(base_names))) |>
  kable_styling(latex_options = "hold_position")

# -------------------------------------------------------------------
# Extract only the tabular environment and write to a file
# -------------------------------------------------------------------
latex_full    <- as.character(kbl_obj)
latex_tabular <- stringr::str_extract(
  latex_full,
  "\\\\begin\\{tabular\\}[\\s\\S]*?\\\\end\\{tabular\\}"
)

out_file <- here::here("Tables", "Table_2.txt")
dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
writeLines(latex_tabular, out_file)

# Reorder columns so that after Paper we have operas_1781_1820 first
ordered_names <- c("Paper",
                   "operas_1781_1820",
                   "composer_level_data",
                   "city_level_operas_1781_1820")

tbl <- tbl[, ordered_names, drop = FALSE]

# Alignment: rownames = l, then 4 centered columns = cccc
align_vec <- c("l", rep("c", length(ordered_names)))

kbl_obj <- kable(
  tbl,
  format    = "latex",
  booktabs  = TRUE,
  align     = align_vec,
  caption   = caption_text,
  col.names = ordered_names,
  row.names = TRUE
) |>
  # rownames + Paper = 2 columns blank; header spans last 3 dataset columns
  add_header_above(c(" " = 2, "Datasets" = 3)) |>
  kable_styling(latex_options = "hold_position")

# Extract only tabular
latex_full    <- as.character(kbl_obj)
latex_tabular <- stringr::str_extract(
  latex_full,
  "\\\\begin\\{tabular\\}[\\s\\S]*?\\\\end\\{tabular\\}"
)

# Save
out_file <- here::here("Tables", "Table_2.txt")
dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
writeLines(latex_tabular, out_file)

