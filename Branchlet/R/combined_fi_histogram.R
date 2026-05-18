## Combined histogram: Fire Intensity (50kW, 100kW, 150kW)
## This script produces a single figure with 3 vertically stacked histograms

library(tidyverse)
library(readxl)
library(ggplot2)

## Load data
excel_path <- "/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Branchlet/branchlet raw data.xlsx"

df_150k <- read_excel(excel_path, sheet = "twigs (2)") %>% mutate(condition = "150 kW")
df_100k <- read_excel(excel_path, sheet = "100 kW") %>% mutate(condition = "100 kW")
df_50k <- read_excel(excel_path, sheet = "50 kW") %>% mutate(condition = "50 kW")

## Combine all three
df_all <- bind_rows(df_50k, df_100k, df_150k)

## Compute vol/sa ratio
df_all <- df_all %>%
    mutate(
        vol_sa_ratio = `Volume (mm3)` / `Surface Area (mm2)`,
        condition = factor(condition, levels = c("50 kW", "100 kW", "150 kW"))
    )

## Freedman-Diaconis bin width
fd_bw <- 2 * IQR(df_all$vol_sa_ratio, na.rm = TRUE) / sum(!is.na(df_all$vol_sa_ratio))^(1 / 3)

## Cap x-axis at 99th percentile to avoid outlier stretching
x_upper <- quantile(df_all$vol_sa_ratio, 0.99, na.rm = TRUE) * 1.1

## Build the combined 3-panel histogram
combined_hist <- ggplot(df_all, aes(x = vol_sa_ratio)) +
    geom_histogram(binwidth = fd_bw, fill = "grey40", color = "white") +
    facet_wrap(~condition, ncol = 1, scales = "fixed") +
    coord_cartesian(xlim = c(0, x_upper), ylim = c(0, 100)) +
    labs(x = "V/Sa (mm)", y = "Count") +
    theme_bw(base_size = 10) +
    theme(plot.margin = margin(5, 10, 5, 5))

## Save
figures_dir <- "Branchlet/R/figures_no_experiment"
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

out_file <- paste0(figures_dir, "/Combined_FI_vol_sa_ratio_histogram.png")
ggsave(out_file, plot = combined_hist, width = 5, height = 6)
cat("-> Combined histogram saved to:", out_file, "\n")
