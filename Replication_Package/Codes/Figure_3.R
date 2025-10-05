# ---- clean environment ----
rm(list = ls())
options(stringsAsFactors = FALSE)
options(scipen = 999)

library(tidyverse)

# ---- output path ----
output_path <- "Figures/"

# ---- load cleaned data ----
df <- read.csv("Data_New/Opening_Night_Operas_it_cleaned.csv",
               header = TRUE, stringsAsFactors = FALSE) %>%
  mutate(year = as.numeric(year),
         Treatment = if_else(copyright == 1, "Lombardia + Venetia", "Other States"))

# ---- average across states within treatment each year ----
avg_state_year <- df %>%
  group_by(year, Treatment) %>%
  summarise(Avg_operas = mean(operas, na.rm = TRUE), .groups = "drop")

# ---- plot ----
p <- ggplot(avg_state_year,
            aes(x = year, y = Avg_operas,
                color = Treatment, linetype = Treatment)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 1801, linetype = "dotted", color = "black") +
  scale_linetype_manual(values = c("Lombardia + Venetia" = "solid",
                                   "Other States" = "31")) +
  labs(title = "New Operas Across States",
       x = "Year", y = "Mean New Opera Production per Year",
       color = "", linetype = "") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5))

# ---- save ----
ggsave(filename = "Figure_3.png",
       plot = p,
       path = output_path,
       width = 8, height = 6, dpi = 300)

