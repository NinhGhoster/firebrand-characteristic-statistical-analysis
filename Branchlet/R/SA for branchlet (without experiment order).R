library(tidyverse) ## lots of useful utility functions and plotting routines
library(readxl) ## to read Excel files
library(mgcv) ## to fit GAMs
library(glmmTMB) ## to fit GLMMs
library(broom) ##
library(emmeans) ## to show some key estimates
library(performance) ## to compare performance of different models
library(MASS, exclude = "select") ## has negative binomial regression model
library(ggplot2) ## for plotting

## load data from Excel and assign condition for each sheet

excel_path <- "/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Branchlet/branchlet raw data.xlsx" # nolint

df_twig2 <- read_excel(excel_path, sheet = "twigs (2)") %>% mutate(condition = "twig_2") # nolint
df_100k <- read_excel(excel_path, sheet = "100 kW") %>% mutate(condition = "100kW") # nolint
df_50k <- read_excel(excel_path, sheet = "50 kW") %>% mutate(condition = "50kW") # nolint

## combine them, they are all data groups for comparison

fi_150kW_vs_50kW <- bind_rows(df_twig2, df_50k)
fi_150kW_vs_100kW <- bind_rows(df_twig2, df_100k)
fi_100kW_vs_50kW <- bind_rows(df_100k, df_50k)

## check that the data looks as expected
glimpse(fi_150kW_vs_50kW)
glimpse(fi_150kW_vs_100kW)
glimpse(fi_100kW_vs_50kW)

## print summaries per variable
summary(fi_150kW_vs_50kW)
summary(fi_150kW_vs_100kW)
summary(fi_100kW_vs_50kW)

## ------------------------------------------------------------------
## Data Processing Function
## ------------------------------------------------------------------
## NOTE: These datasets do NOT have Experiment order, Mass, or Density
## columns (except twigs (2)). We only rename/create columns that exist
## in all sheets: Volume, Surface Area, Length, Width, Height.

process_branchlet_data <- function(df) {
  df <- mutate_if(df, is.character, factor)

  df <- df %>%
    rename(
      volume_mm3       = `Volume (mm3)`,
      surface_area_mm2 = `Surface Area (mm2)`,
      length_mm        = `Length (mm)`,
      width_mm         = `Width (mm)`,
      height_mm        = `Height (mm)`
    )

  df <- df %>%
    mutate(
      volume = volume_mm3,
      surface_area = surface_area_mm2,
      length = length_mm,
      width = width_mm,
      height = height_mm,
      condition = factor(condition),

      ## Derived ratios
      vol_sa_ratio = volume_mm3 / surface_area_mm2,
      sa_vol_ratio = surface_area_mm2 / volume_mm3
    )

  return(df)
}

## Process Datasets
df1 <- process_branchlet_data(fi_150kW_vs_50kW)
df2 <- process_branchlet_data(fi_150kW_vs_100kW)
df3 <- process_branchlet_data(fi_100kW_vs_50kW)

glimpse(df1)
glimpse(df2)
glimpse(df3)

## ------------------------------------------------------------------
## Automated Model Selection for Multiple Parameters
## ------------------------------------------------------------------

## Parameters to test (no mass — not available in 100kW / 50kW sheets)
params <- c("volume", "surface_area", "vol_sa_ratio", "sa_vol_ratio", "length", "width", "height")

## Define datasets to iterate over (named list for clear output)
dataset_list <- list(
  "150kW vs 50kW"  = df1,
  "150kW vs 100kW" = df2,
  "100kW vs 50kW"  = df3
)

## Define output paths (separate from the with-experiment report)
## Define output paths (separate from the with-experiment report)
report_file <- "Branchlet/R/model_selection_report_no_experiment.txt"
figures_dir <- "Branchlet/R/figures_no_experiment"

## Initialize report file (overwrite if exists)
cat("Model Selection Report (Without Experiment Order)\n", file = report_file)
cat("Generated on:", as.character(Sys.time()), "\n\n", file = report_file, append = TRUE)

## Create figures directory if it doesn't exist
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

## ------------------------------------------------------------------
## Summary Table Initialization
## ------------------------------------------------------------------

## Parameters to track (no n_points — no experiment grouping available)
all_params <- params
results_matrix <- matrix(NA, nrow = length(all_params), ncol = length(dataset_list))
rownames(results_matrix) <- all_params
colnames(results_matrix) <- names(dataset_list)

## Helper function for significance string
get_sig_string <- function(p) {
  if (is.na(p)) {
    return("NA")
  }

  sig_code <- ""
  if (p < 0.001) {
    sig_code <- "***"
  } else if (p < 0.01) {
    sig_code <- "**"
  } else if (p < 0.05) {
    sig_code <- "*"
  } else {
    sig_code <- "ns"
  }

  p_str <- ifelse(p < 0.001, "< 0.001", paste0("= ", round(p, 3)))
  return(paste0(sig_code, " (p ", p_str, ")"))
}

## ------------------------------------------------------------------
## Automated Model Selection (Supervisor's 4 Models — Fixed Effects Only)
## mod1a: Gamma(inverse) — default link
## mod1b: Gamma(log)
## mod1c: Gamma(identity)
## mod2:  Lognormal
## No random effects (no experiment grouping in this dataset)
## ------------------------------------------------------------------

## Function to fit candidate models and select the best one
## Uses: param ~ condition (NO random effects, since no experiment grouping)
select_best_model <- function(df, param_name, dataset_name) {
  cat(paste0("\n======================================================\n"))
  cat(paste0("Testing Parameter: ", param_name, " | Dataset: ", dataset_name, "\n"))
  cat(paste0("======================================================\n"))

  ## Append header to report
  cat(paste0("\n======================================================\n"), file = report_file, append = TRUE)
  cat(paste0("Testing Parameter: ", param_name, " | Dataset: ", dataset_name, "\n"), file = report_file, append = TRUE)
  cat(paste0("======================================================\n"), file = report_file, append = TRUE)

  ## Check if parameter exists and has data
  if (!param_name %in% names(df)) {
    msg <- paste0("Skipping: Parameter '", param_name, "' not found in dataset.\n")
    cat(msg)
    cat(msg, file = report_file, append = TRUE)
    return(NA)
  }

  ## Define the formula dynamically — FIXED EFFECTS ONLY
  f <- as.formula(paste(param_name, "~ condition"))

  ## List to store fitted models
  fitted_models <- list()

  ## mod1a: Gamma (inverse link) — default
  tryCatch(
    {
      fitted_models$mod1a <- glmmTMB(f, data = df, family = Gamma)
    },
    error = function(e) cat("  Error fitting mod1a (Gamma inverse): ", e$message, "\n")
  )

  ## mod1b: Gamma (log link)
  tryCatch(
    {
      fitted_models$mod1b <- glmmTMB(f, data = df, family = Gamma(link = "log"))
    },
    error = function(e) cat("  Error fitting mod1b (Gamma log): ", e$message, "\n")
  )

  ## mod1c: Gamma (identity link)
  tryCatch(
    {
      fitted_models$mod1c <- glmmTMB(f, data = df, family = Gamma(link = "identity"))
    },
    error = function(e) cat("  Error fitting mod1c (Gamma identity): ", e$message, "\n")
  )

  ## mod2: Lognormal
  tryCatch(
    {
      fitted_models$mod2 <- glmmTMB(f, data = df, family = lognormal)
    },
    error = function(e) cat("  Error fitting mod2 (Lognormal): ", e$message, "\n")
  )

  ## If no models fitted, return NA
  if (length(fitted_models) == 0) {
    msg <- "  No models converged for this parameter.\n"
    cat(msg)
    cat(msg, file = report_file, append = TRUE)
    return(NA)
  }

  ## Compare performance
  perf <- compare_performance(fitted_models, metrics = c("AIC", "RMSE"))
  print(perf)

  ## Select best model based on AIC (lowest), then RMSE (lowest)
  perf_sorted <- perf[order(perf$AIC, perf$RMSE), ]

  best_model_name <- perf_sorted$Name[1]
  best_model <- fitted_models[[best_model_name]]

  cat(paste0("  -> WINNER: ", best_model_name, "\n"))
  cat(paste0("  -> WINNER: ", best_model_name, "\n"), file = report_file, append = TRUE)
  cat(paste0("  -> AIC: ", round(perf_sorted$AIC[1], 2), "\n"), file = report_file, append = TRUE)

  ## Print summary of the winner to report using sink
  sink(report_file, append = TRUE)
  print(summary(best_model))
  sink()

  ## Generate estimated marginal means (Emmeans)
  emm <- emmeans(best_model, ~condition, type = "response")

  ## Print Emmeans to console and report
  print(emm)
  sink(report_file, append = TRUE)
  cat("\nEstimated Marginal Means:\n")
  print(emm)
  cat("\nPairwise Comparisons:\n")
  pw <- pairs(emm)
  print(pw)
  cat("\nConfidence Intervals:\n")
  print(confint(pw))
  sink()

  ## Extract p-value for plot and summary table
  pw_sum <- summary(pw)
  p_val <- pw_sum$p.value[1]

  ## Relabel condition levels for publication
  label_map <- c(
    "leave"              = "Leaves",
    "noleave_branchlet"  = "No leaves",
    "twig_2"             = "150 kW",
    "50kW"               = "50 kW",
    "100kW"              = "100 kW"
  )
  emm_df <- as.data.frame(emm)
  emm_df$condition <- as.character(emm_df$condition)
  for (old_lab in names(label_map)) {
    emm_df$condition[emm_df$condition == old_lab] <- label_map[[old_lab]]
  }
  emm_df$condition <- factor(emm_df$condition)

  ## Generate and Save Plot (no title, no caption)
  ## Detect column names dynamically (varies by model family/link)
  mean_col <- if ("response" %in% names(emm_df)) "response" else "emmean"
  lcl_col <- if ("asymp.LCL" %in% names(emm_df)) "asymp.LCL" else "lower.CL"
  ucl_col <- if ("asymp.UCL" %in% names(emm_df)) "asymp.UCL" else "upper.CL"

  ## Parameter-specific x-axis labels
  param_labels <- c(
    "volume"       = expression("EMM volume (mm"^3 * ")"),
    "surface_area" = expression("EMM surface area (mm"^2 * ")"),
    "length"       = "EMM length (mm)",
    "width"        = "EMM width (mm)",
    "height"       = "EMM height (mm)",
    "vol_sa_ratio" = "EMM volume/surface area ratio",
    "sa_vol_ratio" = "EMM surface area/volume ratio"
  )
  x_label <- if (param_name %in% names(param_labels)) param_labels[[param_name]] else paste("EMM", param_name)

  p <- ggplot(emm_df, aes(x = .data[[mean_col]], y = condition)) +
    geom_point(size = 2) +
    geom_errorbarh(aes(xmin = .data[[lcl_col]], xmax = .data[[ucl_col]]), height = 0.2) +
    labs(x = x_label, y = "Type") +
    theme_bw(base_size = 10) +
    theme(
      plot.margin = margin(5, 10, 5, 5)
    )

  ## Construct safe filename
  safe_dataset_name <- gsub(" ", "_", dataset_name)
  safe_dataset_name <- gsub("/", "_", safe_dataset_name)
  filename <- paste0(figures_dir, "/", safe_dataset_name, "_", param_name, ".png")

  ggsave(filename, plot = p, width = 5, height = 2.5)
  cat(paste0("  -> Plot saved to: ", filename, "\n"))

  return(paste0(best_model_name, " ", get_sig_string(p_val)))
}

## Run the loop
for (d_name in names(dataset_list)) {
  current_df <- dataset_list[[d_name]]

  for (p in params) {
    ## Run selection and store p-value string
    p_res <- select_best_model(current_df, p, d_name)
    results_matrix[p, d_name] <- p_res
  }
}

## ------------------------------------------------------------------
## Export Summary Table to Report
## ------------------------------------------------------------------

cat("\n\n======================================================\n", file = report_file, append = TRUE)
cat("Summary of Pairwise Comparisons (P-Values)\n", file = report_file, append = TRUE)
cat("Signif. codes:  ns (p >= 0.05); * (p < 0.05); ** (p < 0.01); *** (p < 0.001)\n", file = report_file, append = TRUE)
cat("======================================================\n", file = report_file, append = TRUE)

## Print using capture.output to preserve formatting
sink(report_file, append = TRUE)
print(results_matrix, quote = FALSE)
sink()

cat("\nEnd of Report\n", file = report_file, append = TRUE)
