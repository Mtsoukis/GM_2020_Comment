rm(list = ls())

codes_dir <- ("Codes")
scripts <- list.files(codes_dir, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)

for (s in scripts) {
  cat(">>> Running:", s, "\n")
  source(s, chdir = TRUE, echo = TRUE, max.deparse.length = Inf)
}

cat("All R scripts completed successfully.\n")