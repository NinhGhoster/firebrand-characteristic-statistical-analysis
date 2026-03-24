## Combined histogram: Leave, No leave/branchlet, Twigs
## This script produces a single figure with 3 vertically stacked histograms

library(tidyverse)
library(readxl)
library(ggplot2)

## Load data
excel_path <- "/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Branchlet/branchlet raw data.xlsx"

df_leave <- read_excel(excel_path, sheet = "leave") %>% mutate(condition = "Leaves")
df_noleave <- read_excel(excel_path, sheet = "no leave - branchlet") %>% mutate(condition = "No leaves/Branchlet")
df_twig <- read_excel(excel_path, sheet = "twigs (2)") %>% mutate(condition = "Twigs")

## Combine all three
df_all <- bind_rows(df_leave, df_noleave, df_twig)

## Compute vol/sa ratio
df_all <- df_all %>%
    mutate(
        vol_sa_ratio = `Volume (mm3)` / `Surface Area (mm2)`,
        condition = factor(condition, levels = c("Leaves", "No leaves/Branchlet", "Twigs"))
    )

## Freedman-Diaconis bin width
fd_bw <- 2 * IQR(df_all$vol_sa_ratio, na.rm = TRUE) / sum(!is.na(df_all$vol_sa_ratio))^(1 / 3)

## Cap x-axis at 99th percentile to avoid outlier stretching
x_upper <- quantile(df_all$vol_sa_ratio, 0.99, na.rm = TRUE) * 1.1

## Build the combined 3-panel histogram
combined_hist <- ggplot(df_all, aes(x = vol_sa_ratio)) +
    geom_histogram(binwidth = fd_bw, fill = "grey40", color = "white") +
    facet_wrap(~condition, ncol = 1, scales = "free_y") +
    coord_cartesian(xlim = c(0, x_upper)) +
    labs(x = "Volume/surface area ratio", y = "Count") +
    theme_bw(base_size = 10) +
    theme(plot.margin = margin(5, 10, 5, 5))

## Save
figures_dir <- "Branchlet/R/figures"
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

out_file <- paste0(figures_dir, "/Combined_vol_sa_ratio_histogram.png")
ggsave(out_file, plot = combined_hist, width = 5, height = 6)
cat("-> Combined histogram saved to:", out_file, "\n")
