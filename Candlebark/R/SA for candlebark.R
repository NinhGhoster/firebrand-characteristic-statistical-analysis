library(tidyverse) ## lots of useful utility functions and plotting routines
library(readxl) ## to read Excel files
library(mgcv) ## to fit GAMs
library(glmmTMB) ## to fit GLMMs
library(emmeans) ## to show some key estimates
library(performance) ## to compare performance of different models
library(MASS, exclude = "select") ## has negative binomial regression model
library(broom)

## ------------------------------------------------------------------
## Load Data — Read all 24 sheets, parse factors from sheet names
## ------------------------------------------------------------------

excel_path <- "/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Candlebark/candlebark.xlsx"

sheets <- excel_sheets(excel_path)

## Parse sheet name to extract experimental factors
## Example: "Curve 1 100 kW 60 cm_AUTO" -> shape=Curve, replicate=1, fire_intensity=100kW, sample_length=60cm
parse_sheet_name <- function(name) {
  ## Remove _AUTO suffix if present
  clean <- gsub("_AUTO$", "", name)

  ## Pattern: "{Shape} {Replicate} {Intensity} kW {Length} cm"
  parts <- str_match(clean, "^(Curve|Flat)\\s+(\\d+)\\s+(\\d+)\\s+kW\\s+(\\d+)\\s+cm$")

  list(
    shape          = parts[, 2],
    replicate      = as.integer(parts[, 3]),
    fire_intensity = paste0(parts[, 4], " kW"),
    sample_length  = paste0(parts[, 5], " cm")
  )
}

## Read all sheets and combine into one data frame
all_data <- map_dfr(sheets, function(s) {
  df <- read_excel(excel_path, sheet = s)
  info <- parse_sheet_name(s)

  df %>% mutate(
    sheet_name     = s,
    shape          = info$shape,
    replicate      = info$replicate,
    fire_intensity = info$fire_intensity,
    sample_length  = info$sample_length
  )
})

## Rename columns to clean names
all_data <- all_data %>%
  rename(
    volume       = `Volume (mm3)`,
    surface_area = `Surface Area (mm2)`,
    length       = `Length (mm)`,
    width        = `Width (mm)`,
    height       = `Height (mm)`
  ) %>%
  mutate(
    shape = factor(shape, levels = c("Flat", "Curve"), labels = c("Flat", "Cylindrical")),
    fire_intensity = factor(fire_intensity, levels = c("50 kW", "100 kW", "150 kW")),
    sample_length = factor(sample_length, levels = c("20 cm", "40 cm", "60 cm")),
    replicate = factor(replicate),

    ## Derived ratios
    vol_sa_ratio = volume / surface_area,
    sa_vol_ratio = surface_area / volume
  )

glimpse(all_data)
summary(all_data)

## ------------------------------------------------------------------
## Create Dataset Groups for Comparisons
## ------------------------------------------------------------------

## 1. Fire Intensity Comparison — all data
df_fire <- all_data

## 2. Shape Comparison — Flat vs Curve, restricted to 60 cm only
##    (Curve only has 60 cm samples)
df_shape <- all_data %>% filter(sample_length == "60 cm")

## 3. Sample Length Comparison — Flat only
##    (Curve only has 60 cm, so length comparison is Flat-only)
df_length <- all_data %>% filter(shape == "Flat")

cat("\nDataset sizes:\n")
cat("  Fire Intensity (all data):", nrow(df_fire), "rows\n")
cat("  Shape (60 cm only):", nrow(df_shape), "rows\n")
cat("  Sample Length (Flat only):", nrow(df_length), "rows\n")

## ------------------------------------------------------------------
## V/SA Histogram
## ------------------------------------------------------------------

figures_dir <- "Candlebark/R/figures"
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

for (ds_info in list(
  list(df = df_fire, name = "Fire_Intensity", group = "fire_intensity"),
  list(df = df_shape, name = "Shape", group = "shape"),
  list(df = df_length, name = "Sample_Length", group = "sample_length")
)) {
  hist_plot <- ggplot(ds_info$df, aes(x = vol_sa_ratio)) +
    geom_histogram(bins = 30, fill = "grey40", color = "white") +
    facet_wrap(as.formula(paste("~", ds_info$group)), ncol = 1) +
    labs(x = "Volume/surface area ratio", y = "Count") +
    theme_bw(base_size = 10) +
    theme(plot.margin = margin(5, 10, 5, 5))

  hist_file <- paste0(figures_dir, "/", ds_info$name, "_vol_sa_ratio_histogram.png")
  ggsave(hist_file, plot = hist_plot, width = 5, height = 4)
  cat("-> Histogram saved to:", hist_file, "\n")
}

## ------------------------------------------------------------------
## Parameters and Datasets
## ------------------------------------------------------------------

params <- c("volume", "surface_area", "length", "width", "height")
ratio_params <- c("vol_sa_ratio", "sa_vol_ratio")
all_model_params <- c(params, ratio_params)

dataset_list <- list(
  "Fire Intensity" = list(data = df_fire, condition_var = "fire_intensity"),
  "Shape"          = list(data = df_shape, condition_var = "shape"),
  "Sample Length"  = list(data = df_length, condition_var = "sample_length")
)

## Define output paths
report_file <- "Candlebark/R/model_selection_report.txt"
figures_dir <- "Candlebark/R/figures"

## Initialize report file (overwrite if exists)
cat("Candlebark Model Selection Report\n", file = report_file)
cat("Generated on:", as.character(Sys.time()), "\n\n", file = report_file, append = TRUE)

## Create figures directory if it doesn't exist
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

## ------------------------------------------------------------------
## Summary Table Initialization
## ------------------------------------------------------------------

all_params <- c(all_model_params, "n_points")
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
## Automated Model Selection (Supervisor's 2 Models)
## mod4a: glmmTMB Gamma(log) — linear covariate effects
## mod4d: GAM Gamma(log)     — smooth effects where applicable
## ------------------------------------------------------------------

select_best_model <- function(df, param_name, dataset_name, condition_var) {
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
    return(list(sig = NA, model = NULL))
  }

  ## Build formulas based on the comparison type
  ## Each dataset uses a different primary condition variable
  if (condition_var == "fire_intensity") {
    ## Fire Intensity comparison — control for shape and sample_length
    f_4a <- as.formula(paste(param_name, "~ fire_intensity + shape + sample_length"))
    f_4d <- as.formula(paste(param_name, "~ fire_intensity + shape + sample_length"))
  } else if (condition_var == "shape") {
    ## Shape comparison (60 cm only) — control for fire_intensity
    f_4a <- as.formula(paste(param_name, "~ shape + fire_intensity"))
    f_4d <- as.formula(paste(param_name, "~ shape + fire_intensity"))
  } else {
    ## Sample Length comparison (Flat only) — control for fire_intensity
    f_4a <- as.formula(paste(param_name, "~ sample_length + fire_intensity"))
    f_4d <- as.formula(paste(param_name, "~ sample_length + fire_intensity"))
  }

  ## List to store fitted models
  fitted_models <- list()

  ## mod4a: glmmTMB — Gamma(log)
  tryCatch(
    {
      fitted_models$mod4a <- glmmTMB(f_4a, data = df, family = Gamma(link = "log"))
    },
    error = function(e) cat("  Error fitting mod4a (glmmTMB Gamma log): ", e$message, "\n")
  )

  ## mod4d: GAM — Gamma(log)
  tryCatch(
    {
      fitted_models$mod4d <- gam(f_4d, data = df, family = Gamma(link = "log"))
    },
    error = function(e) cat("  Error fitting mod4d (GAM Gamma log): ", e$message, "\n")
  )

  ## If no models fitted, return NA
  if (length(fitted_models) == 0) {
    msg <- "  No models converged for this parameter.\n"
    cat(msg)
    cat(msg, file = report_file, append = TRUE)
    return(list(sig = NA, model = NULL))
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

  ## Print summary of the winner to report
  sink(report_file, append = TRUE)
  print(summary(best_model))
  sink()

  ## Generate estimated marginal means for the condition variable
  emm_formula <- as.formula(paste0("~", condition_var))
  emm <- emmeans(best_model, emm_formula, type = "response")

  ## Print Emmeans to console and report
  print(emm)
  sink(report_file, append = TRUE)
  cat(paste0("\nEstimated Marginal Means (by ", condition_var, "):\n"))
  print(emm)
  cat(paste0("\nPairwise Comparisons (", condition_var, "):\n"))
  pw <- pairs(emm)
  print(pw)
  cat("\nConfidence Intervals:\n")
  print(confint(pw))
  sink()

  ## Extract p-value — use overall Anova-style test for multi-level factor
  pw_sum <- summary(pw)

  if (nrow(pw_sum) == 1) {
    p_val <- pw_sum$p.value[1]
  } else {
    jt <- joint_tests(best_model)
    p_val <- jt$p.value[jt$`model term` == condition_var]
  }

  ## Generate and save per-parameter emmeans plot (by condition variable)
  emm_df <- as.data.frame(emm)

  ## Detect column names dynamically
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

  emm_plot <- ggplot(emm_df, aes(x = .data[[mean_col]], y = .data[[condition_var]])) +
    geom_point(size = 2) +
    geom_errorbarh(aes(xmin = .data[[lcl_col]], xmax = .data[[ucl_col]]), height = 0.2) +
    labs(x = x_label, y = "Type") +
    theme_bw(base_size = 10) +
    theme(
      plot.margin = margin(5, 10, 5, 5)
    )

  safe_dataset_name <- gsub(" ", "_", dataset_name)
  safe_dataset_name <- gsub("[()]", "", safe_dataset_name)
  filename <- paste0(figures_dir, "/", safe_dataset_name, "_", param_name, ".png")
  ggsave(filename, plot = emm_plot, width = 5, height = 2.5)
  cat(paste0("  -> Plot saved to: ", filename, "\n"))

  ## Generate and save per-parameter emmeans plot (by fire_intensity)
  ## fire_intensity is in every model (as condition or covariate)
  tryCatch(
    {
      emm_fi <- emmeans(best_model, ~fire_intensity, type = "response")
      pw_fi <- pairs(emm_fi)
      pw_fi_sum <- summary(pw_fi)

      if (nrow(pw_fi_sum) == 1) {
        p_val_fi <- pw_fi_sum$p.value[1]
      } else {
        jt_fi <- joint_tests(best_model)
        p_val_fi <- jt_fi$p.value[jt_fi$`model term` == "fire_intensity"]
      }

      emm_fi_df <- as.data.frame(emm_fi)
      fi_mean_col <- if ("response" %in% names(emm_fi_df)) "response" else "emmean"
      fi_lcl_col <- if ("asymp.LCL" %in% names(emm_fi_df)) "asymp.LCL" else "lower.CL"
      fi_ucl_col <- if ("asymp.UCL" %in% names(emm_fi_df)) "asymp.UCL" else "upper.CL"

      emm_fi_plot <- ggplot(emm_fi_df, aes(x = .data[[fi_mean_col]], y = fire_intensity)) +
        geom_point(size = 2) +
        geom_errorbarh(aes(xmin = .data[[fi_lcl_col]], xmax = .data[[fi_ucl_col]]), height = 0.2) +
        labs(x = x_label, y = "Type") +
        theme_bw(base_size = 10) +
        theme(
          axis.title.y = element_text(angle = 0, vjust = 0.5),
          plot.margin = margin(5, 10, 5, 5)
        )

      filename_fi <- paste0(figures_dir, "/", safe_dataset_name, "_", param_name, "_fire_intensity.png")
      ggsave(filename_fi, plot = emm_fi_plot, width = 5, height = 2.5)
      cat(paste0("  -> Plot saved to: ", filename_fi, "\n"))
    },
    error = function(e) cat("  Fire intensity emmeans error:", e$message, "\n")
  )

  return(list(sig = paste0(best_model_name, " ", get_sig_string(p_val)), model = best_model))
}

## ------------------------------------------------------------------
## Run the Loop — Store Best Models
## ------------------------------------------------------------------

best_models <- list()

for (d_name in names(dataset_list)) {
  current_df <- dataset_list[[d_name]]$data
  cond_var <- dataset_list[[d_name]]$condition_var
  best_models[[d_name]] <- list()

  for (p in all_model_params) {
    result <- select_best_model(current_df, p, d_name, cond_var)
    results_matrix[p, d_name] <- result$sig
    best_models[[d_name]][[p]] <- result$model
  }
}

## ------------------------------------------------------------------
## Automated Count Analysis (Points per Sheet / Experimental Unit)
## ------------------------------------------------------------------

analyze_counts <- function(df, dataset_name, condition_var) {
  cat(paste0("\n======================================================\n"))
  cat(paste0("Testing Counts (n_points) | Dataset: ", dataset_name, "\n"))
  cat(paste0("======================================================\n"))

  ## Append header to report
  cat(paste0("\n======================================================\n"), file = report_file, append = TRUE)
  cat(paste0("Testing Counts (n_points) | Dataset: ", dataset_name, "\n"), file = report_file, append = TRUE)
  cat(paste0("======================================================\n"), file = report_file, append = TRUE)

  ## Count observations per sheet (each sheet = one experimental unit)
  df_npoints <- df %>%
    group_by(sheet_name) %>%
    summarise(
      n_points = n(),
      shape = first(shape),
      fire_intensity = first(fire_intensity),
      sample_length = first(sample_length),
      replicate = first(replicate),
      .groups = "drop"
    )

  ## Build count model formula with the condition var + covariates
  if (condition_var == "fire_intensity") {
    count_formula <- n_points ~ fire_intensity + shape + sample_length
  } else if (condition_var == "shape") {
    count_formula <- n_points ~ shape + fire_intensity
  } else {
    count_formula <- n_points ~ sample_length + fire_intensity
  }

  ## Fit Models
  models_list <- list()

  ## mod3a: Poisson
  tryCatch(
    {
      models_list$mod3a <- glm(count_formula, data = df_npoints, family = poisson)
    },
    error = function(e) cat("  Error fitting mod3a (Poisson): ", e$message, "\n")
  )

  ## mod3b: Negative Binomial
  tryCatch(
    {
      models_list$mod3b <- glm.nb(count_formula, data = df_npoints)
    },
    error = function(e) cat("  Error fitting mod3b (Negative Binomial): ", e$message, "\n")
  )

  ## Check for overdispersion
  is_pois_od <- FALSE
  is_nb_od <- FALSE

  if (!is.null(models_list$mod3a)) {
    od_check <- check_overdispersion(models_list$mod3a)
    is_pois_od <- od_check$p_value < 0.05
    cat(paste0(
      "  Poisson Overdispersion p-value: ", round(od_check$p_value, 3),
      ifelse(is_pois_od, " (Significant)", " (NS)"), "\n"
    ))
  }

  if (!is.null(models_list$mod3b)) {
    od_check_nb <- check_overdispersion(models_list$mod3b)
    is_nb_od <- od_check_nb$p_value < 0.05
    cat(paste0(
      "  NB Overdispersion p-value: ", round(od_check_nb$p_value, 3),
      ifelse(is_nb_od, " (Significant)", " (NS)"), "\n"
    ))
  }

  ## Selection Logic
  best_model <- NULL
  best_model_name <- ""

  if (is.null(models_list$mod3a) && is.null(models_list$mod3b)) {
    cat("  No count models converged.\n")
    return(NA)
  } else if (is.null(models_list$mod3b)) {
    best_model <- models_list$mod3a
    best_model_name <- "mod3a"
  } else if (is.null(models_list$mod3a)) {
    best_model <- models_list$mod3b
    best_model_name <- "mod3b"
  } else {
    ## Both models exist
    if (is_pois_od && !is_nb_od) {
      best_model <- models_list$mod3b
      best_model_name <- "mod3b (Poisson Overdispersed)"
    } else if (!is_pois_od && is_nb_od) {
      best_model <- models_list$mod3a
      best_model_name <- "mod3a (NB Overdispersed)"
    } else {
      perf <- compare_performance(models_list$mod3a, models_list$mod3b, metrics = c("AIC", "RMSE"))
      print(perf)
      perf_sorted <- perf[order(perf$AIC), ]
      best_model_name <- perf_sorted$Name[1]
      best_model <- models_list[[best_model_name]]
      best_model_name <- paste0(best_model_name, " (Based on AIC/RMSE)")
    }
  }

  cat(paste0("  -> WINNER: ", best_model_name, "\n"))
  cat(paste0("  -> WINNER: ", best_model_name, "\n"), file = report_file, append = TRUE)

  ## Summary
  sink(report_file, append = TRUE)
  print(summary(best_model))

  ## Emmeans
  emm_formula <- as.formula(paste0("~", condition_var))
  emm <- emmeans(best_model, emm_formula, type = "response")
  cat("\nEstimated Marginal Means:\n")
  print(emm)

  ## Pairwise
  cat("\nPairwise Comparisons:\n")
  pw <- pairs(emm)
  print(pw)

  ## Confint
  cat("\nConfidence Intervals:\n")
  print(confint(pw))
  sink()

  ## Extract p-value
  pw_sum <- summary(pw)
  if (nrow(pw_sum) == 1) {
    pw_p <- pw_sum$p.value[1]
  } else {
    jt <- joint_tests(best_model)
    pw_p <- jt$p.value[jt$`model term` == condition_var]
  }

  ## Build count EMM plot
  emm_ct_df <- as.data.frame(emm)
  ct_mean_col <- if ("rate" %in% names(emm_ct_df)) "rate" else if ("response" %in% names(emm_ct_df)) "response" else "emmean"
  ct_lcl_col <- if ("asymp.LCL" %in% names(emm_ct_df)) "asymp.LCL" else "lower.CL"
  ct_ucl_col <- if ("asymp.UCL" %in% names(emm_ct_df)) "asymp.UCL" else "upper.CL"

  p <- ggplot(emm_ct_df, aes(x = .data[[ct_mean_col]], y = .data[[condition_var]])) +
    geom_point(size = 2) +
    geom_errorbarh(aes(xmin = .data[[ct_lcl_col]], xmax = .data[[ct_ucl_col]]), height = 0.2) +
    labs(x = "EMM count", y = "Type") +
    theme_bw(base_size = 10) +
    theme(
      axis.title.y = element_text(angle = 0, vjust = 0.5),
      plot.margin = margin(5, 10, 5, 5)
    )

  ## Save
  safe_dataset_name <- gsub(" ", "_", dataset_name)
  safe_dataset_name <- gsub("[()]", "", safe_dataset_name)
  filename <- paste0(figures_dir, "/", safe_dataset_name, "_count.png")
  ggsave(filename, plot = p, width = 5, height = 2.5)
  cat(paste0("  -> Plot saved to: ", filename, "\n"))

  return(paste0(best_model_name, " ", get_sig_string(pw_p)))
}

## Run Count Analysis Loop
for (d_name in names(dataset_list)) {
  p_res <- analyze_counts(
    dataset_list[[d_name]]$data,
    d_name,
    dataset_list[[d_name]]$condition_var
  )
  results_matrix["n_points", d_name] <- p_res
}


## ------------------------------------------------------------------
## Export Summary Table to Report
## ------------------------------------------------------------------

cat("\n\n======================================================\n", file = report_file, append = TRUE)
cat("Summary of Pairwise Comparisons (P-Values)\n", file = report_file, append = TRUE)
cat("Signif. codes:  ns (p >= 0.05); * (p < 0.05); ** (p < 0.01); *** (p < 0.001)\n", file = report_file, append = TRUE)
cat("======================================================\n", file = report_file, append = TRUE)

sink(report_file, append = TRUE)
print(results_matrix, quote = FALSE)
sink()

cat("\nEnd of Report\n", file = report_file, append = TRUE)
