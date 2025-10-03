# Clean Environment
rm(list = ls())
options(stringsAsFactors = FALSE)
options(scipen = 999)

library(tidyverse)
library(haven)

data_path   <- "Data_GM2020/"
output_path <- "Figures/"

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
  geom_point(alpha = 0.75, size = 2, color = "black") +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8, color = "turquoise3") +
  labs(
    title = "",
    x = "Season Count (operas_1781_1820_repeat_premiere.dta)",
    y = "Operas (Main Data)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave(
  filename = file.path(output_path, "Figure_1.png"),
  plot = p, width = 8, height = 6, dpi = 300
)
