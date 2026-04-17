# Clean Environment
rm(list = ls())
options(stringsAsFactors = FALSE)
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

library(tidyverse)
library(haven)
library(extrafont)

#font_import(pattern = "Computer Modern", prompt = FALSE)
#loadfonts(quiet = TRUE)

data_path   <- rp_require_dir("Data_GM2020")
output_path <- rp_path("Figures")

operas <- read_dta(file.path(data_path, "operas_1781_1820.dta")) %>%
  select(year, state, operas)

repeated_operas <- read_dta(file.path(data_path, "operas_1781_1820_repeat_premiere.dta")) %>%
  select(state, year, season_count)

merged_data <- inner_join(operas, repeated_operas, by = c("state", "year"))

# 3. Run regression to get fitted line
model <- lm(operas ~ season_count, data = merged_data)
model_sum <- summary(model)

# Print R^2
r2_value <- model_sum$r.squared
message(sprintf("R^2 = %.3f", r2_value))

# Scatter plot with regression line
p <- ggplot(merged_data, aes(x = season_count, y = operas)) +
  geom_point(alpha = 0.75, size = 3, color = "black") +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1, color = "dodgerblue4") +
  labs(
    title = "",
    x = "Season Count (operas_1781_1820_repeat_premiere.dta)",
    y = "Operas (Main Data)"
  ) +
  theme_minimal(base_size = 16) +
  theme(plot.title = element_text(hjust = 0.5), panel.grid.minor = element_blank(),  # removes minor grid lines
        axis.line = element_line(color = "black"),  # adds clean axes lines
        panel.border = element_blank()              # keeps it minimal
  )

ggsave(
  filename = file.path(output_path, "Figure_1.png"),
  plot = p, width = 8, height = 6, dpi = 300
)
