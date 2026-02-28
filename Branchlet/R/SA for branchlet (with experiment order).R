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

df_leave <- read_excel(excel_path, sheet = "leave") %>% mutate(condition = "leave") # nolint
df_noleave_branchlet <- read_excel(excel_path, sheet = "no leave - branchlet") %>% mutate(condition = "noleave_branchlet") # nolint
df_twig2 <- read_excel(excel_path, sheet = "twigs (2)") %>% mutate(condition = "twig_2") # nolint
df_pine <- read_excel(excel_path, sheet = "Pine") %>% mutate(condition = "Pine")
df_acacia <- read_excel(excel_path, sheet = "Acacia") %>% mutate(condition = "Acacia") # nolint

## combine them, they are all data groups for comparison

leave_vs_noleave_branchlet <- bind_rows(df_leave, df_noleave_branchlet)
leave_vs_twig <- bind_rows(df_twig2, df_leave)
noleave_branchlet_vs_twig <- bind_rows(df_twig2, df_noleave_branchlet)
eucalyptus_vs_pine <- bind_rows(df_twig2, df_pine)
eucalyptus_vs_acacia <- bind_rows(df_twig2, df_acacia)
acacia_vs_pine <- bind_rows(df_pine, df_acacia)

## use subset here if want to remove based on density (not recommended)

## check that the data looks as expected
glimpse(leave_vs_noleave_branchlet)
glimpse(leave_vs_twig)
glimpse(noleave_branchlet_vs_twig)
glimpse(eucalyptus_vs_pine)
glimpse(eucalyptus_vs_acacia)
glimpse(acacia_vs_pine)

## print summaries per variable
summary(leave_vs_noleave_branchlet)
summary(leave_vs_twig)
summary(noleave_branchlet_vs_twig)
summary(eucalyptus_vs_pine)
summary(eucalyptus_vs_acacia)
summary(acacia_vs_pine)

## ------------------------------------------------------------------
## Data Processing Function
## ------------------------------------------------------------------

process_branchlet_data <- function(df) {
  df <- mutate_if(df, is.character, factor)

  df <- df %>%
    rename(
      volume_mm3       = `Volume (mm3)`,
      surface_area_mm2 = `Surface Area (mm2)`,
      length_mm        = `Length (mm)`,
      width_mm         = `Width (mm)`,
      height_mm        = `Height (mm)`,
      mass_g           = `Mass (g)`,
      density_kg_m3    = `Density (kg/m3)`,
      experiment_order = `Experiment order`
    )

  df <- df %>%
    mutate(
      volume = volume_mm3,
      surface_area = surface_area_mm2,
      length = length_mm,
      width = width_mm,
      height = height_mm,
      mass = mass_g,
      density = density_kg_m3,
      condition = factor(condition),
      experiment = experiment_order,

      ## Derived ratios
      vol_sa_ratio = volume_mm3 / surface_area_mm2,
      sa_vol_ratio = surface_area_mm2 / volume_mm3
    )

  return(df)
}

## Process Datasets
df1 <- process_branchlet_data(leave_vs_noleave_branchlet)
df2 <- process_branchlet_data(leave_vs_twig)
df3 <- process_branchlet_data(noleave_branchlet_vs_twig)
df4 <- process_branchlet_data(eucalyptus_vs_pine)
df5 <- process_branchlet_data(eucalyptus_vs_acacia)
df6 <- process_branchlet_data(acacia_vs_pine)

glimpse(df1)
glimpse(df2)
glimpse(df3)
glimpse(df4)
glimpse(df5)
glimpse(df6)

## ------------------------------------------------------------------
## V/SA Histogram
## ------------------------------------------------------------------

figures_dir <- "Branchlet/R/figures"
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

hist_datasets <- list(
  list(df = df1, name = "Leave_vs_No_Leave", group = "condition"),
  list(df = df2, name = "Leave_vs_Twig", group = "condition"),
  list(df = df3, name = "No_Leave_vs_Twig", group = "condition"),
  list(df = df4, name = "Eucalyptus_vs_Pine", group = "condition"),
  list(df = df5, name = "Eucalyptus_vs_Acacia", group = "condition"),
  list(df = df6, name = "Acacia_vs_Pine", group = "condition")
)

for (ds_info in hist_datasets) {
  ## Relabel condition levels to match EMM plots
  is_species <- grepl("Eucalyptus|Acacia|Pine", ds_info$name)
  is_leave_vs_noleave <- grepl("Leave_vs_No_Leave", ds_info$name, ignore.case = TRUE)
  label_map <- c(
    "leave"              = "Leaves",
    "noleave_branchlet"  = ifelse(is_leave_vs_noleave, "No leaves", "Branchlet"),
    "twig_2"             = ifelse(is_species, "Eucalyptus", "Twigs")
  )
  plot_df <- ds_info$df
  for (old_lab in names(label_map)) {
    levels(plot_df$condition)[levels(plot_df$condition) == old_lab] <- label_map[[old_lab]]
  }

  fd_bw <- 2 * IQR(plot_df$vol_sa_ratio, na.rm = TRUE) / sum(!is.na(plot_df$vol_sa_ratio))^(1 / 3)

  ## Use quantile-based x limit to avoid outliers stretching the axis
  x_upper <- quantile(plot_df$vol_sa_ratio, 0.99, na.rm = TRUE) * 1.1

  hist_plot <- ggplot(plot_df, aes(x = vol_sa_ratio)) +
    geom_histogram(binwidth = fd_bw, fill = "grey40", color = "white") +
    facet_wrap(~condition, ncol = 1) +
    coord_cartesian(xlim = c(0, x_upper)) +
    labs(x = "Volume/surface area ratio", y = "Count") +
    theme_bw(base_size = 10) +
    theme(plot.margin = margin(5, 10, 5, 5))

  hist_file <- paste0(figures_dir, "/", ds_info$name, "_vol_sa_ratio_histogram.png")
  ggsave(hist_file, plot = hist_plot, width = 5, height = 4)
  cat("-> Histogram saved to:", hist_file, "\n")
}

## Define parameters to test
params <- c("volume", "surface_area", "vol_sa_ratio", "sa_vol_ratio", "length", "width", "height", "mass")

## Define datasets to iterate over (named list for clear output)
dataset_list <- list(
  "Leave vs No Leave" = df1,
  "Leave vs Twig" = df2,
  "No Leave vs Twig" = df3,
  "Eucalyptus vs Pine" = df4,
  "Eucalyptus vs Acacia" = df5,
  "Acacia vs Pine" = df6
)

## Define output paths
## Define output paths
report_file <- "Branchlet/R/model_selection_report.txt"
figures_dir <- "Branchlet/R/figures"

## Initialize report file (overwrite if exists)
cat("Model Selection Report\n", file = report_file)
cat("Generated on:", as.character(Sys.time()), "\n\n", file = report_file, append = TRUE)

## Create figures directory if it doesn't exist
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

## ------------------------------------------------------------------
## Summary Table Initialization
## ------------------------------------------------------------------

## Parameters to track: params + "n_points"
all_params <- c(params, "n_points")
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
## Automated Model Selection (Supervisor's 4 Models)
## mod1a: Gamma(inverse) with (1|experiment)
## mod1b: Gamma(log)     with (1|experiment)
## mod1c: Gamma(identity) — fixed effects only
## mod2:  Lognormal       with (1|experiment)
## ------------------------------------------------------------------

## Function to fit candidate models and select the best one
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

  ## Formulas
  f_re <- as.formula(paste(param_name, "~ condition + (1 | experiment)"))
  f_fe <- as.formula(paste(param_name, "~ condition"))

  ## List to store fitted models
  fitted_models <- list()

  ## mod1a: Gamma (inverse link) with random effect
  tryCatch(
    {
      fitted_models$mod1a <- glmmTMB(f_re, data = df, family = Gamma)
    },
    error = function(e) cat("  Error fitting mod1a (Gamma inverse): ", e$message, "\n")
  )

  ## mod1b: Gamma (log link) with random effect
  tryCatch(
    {
      fitted_models$mod1b <- glmmTMB(f_re, data = df, family = Gamma(link = "log"))
    },
    error = function(e) cat("  Error fitting mod1b (Gamma log): ", e$message, "\n")
  )

  ## mod1c: Gamma (identity link) — fixed effects only (no random effect)
  tryCatch(
    {
      fitted_models$mod1c <- glmmTMB(f_fe, data = df, family = Gamma(link = "identity"))
    },
    error = function(e) cat("  Error fitting mod1c (Gamma identity): ", e$message, "\n")
  )

  ## mod2: Lognormal with random effect
  tryCatch(
    {
      fitted_models$mod2 <- glmmTMB(f_re, data = df, family = lognormal)
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
  ## For species comparisons, twig_2 -> Eucalyptus; otherwise twig_2 -> Twigs
  is_species <- grepl("Eucalyptus", dataset_name, ignore.case = TRUE)
  is_leave_vs_noleave <- grepl("Leave vs No Leave", dataset_name, ignore.case = TRUE)
  label_map <- c(
    "leave"              = "Leaves",
    "noleave_branchlet"  = ifelse(is_leave_vs_noleave, "No leaves", "Branchlet"),
    "twig_2"             = ifelse(is_species, "Eucalyptus", "Twigs")
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
    "mass"         = "EMM mass (g)",
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
  safe_dataset_name <- gsub("/", "_", safe_dataset_name) # Just in case
  filename <- paste0(figures_dir, "/", safe_dataset_name, "_", param_name, ".png")

  ggsave(filename, plot = p, width = 5, height = 2.5)
  cat(paste0("  -> Plot saved to: ", filename, "\n"))

  return(paste0(best_model_name, " ", get_sig_string(p_val)))
}

## Run the loop
for (d_name in names(dataset_list)) {
  current_df <- dataset_list[[d_name]]

  for (p in params) {
    # Run selection and store p-value string
    p_res <- select_best_model(current_df, p, d_name)
    results_matrix[p, d_name] <- p_res
  }
}

## ------------------------------------------------------------------
## Automated Count Analysis (Points per Experiment)
## ------------------------------------------------------------------

analyze_counts <- function(df, dataset_name) {
  cat(paste0("\n======================================================\n"))
  cat(paste0("Testing Counts (n_points) | Dataset: ", dataset_name, "\n"))
  cat(paste0("======================================================\n"))

  ## Append header to report
  cat(paste0("\n======================================================\n"), file = report_file, append = TRUE)
  cat(paste0("Testing Counts (n_points) | Dataset: ", dataset_name, "\n"), file = report_file, append = TRUE)
  cat(paste0("======================================================\n"), file = report_file, append = TRUE)

  ## Summarize points per experiment
  df_npoints <- df %>%
    group_by(experiment) %>%
    summarise(
      condition = first(condition),
      n_points = n(),
      .groups = "drop"
    )

  ## Fit Models
  models_list <- list()

  ## mod3a: Poisson
  tryCatch(
    {
      models_list$mod3a <- glm(n_points ~ condition, data = df_npoints, family = poisson)
    },
    error = function(e) cat("  Error fitting mod3a (Poisson): ", e$message, "\n")
  )

  ## mod3b: Negative Binomial
  tryCatch(
    {
      models_list$mod3b <- glm.nb(n_points ~ condition, data = df_npoints)
    },
    error = function(e) cat("  Error fitting mod3b (Negative Binomial): ", e$message, "\n")
  )

  ## Check for overdispersion
  ## check_overdispersion returns a list with p_value. p < 0.05 indicates overdispersion.
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
    # check_overdispersion on NB is less common/standard but performance package does it
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
      ## Poisson has OD, NB does not -> Pick NB
      best_model <- models_list$mod3b
      best_model_name <- "mod3b (Poisson Overdispersed)"
    } else if (!is_pois_od && is_nb_od) {
      ## NB has weird OD, Poisson does not -> Pick Poisson (rare)
      best_model <- models_list$mod3a
      best_model_name <- "mod3a (NB Overdispersed)"
    } else {
      ## Both fit fine (No OD) OR Both failed OD check -> Compare AIC/RMSE
      perf <- compare_performance(models_list$mod3a, models_list$mod3b, metrics = c("AIC", "RMSE"))
      print(perf)

      ## Sort by AIC
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
  emm <- emmeans(best_model, ~condition, type = "response")
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

  ## Generate Plot
  pw_p <- summary(pw)$p.value[1]

  ## Relabel condition levels for publication
  is_species <- grepl("Eucalyptus", dataset_name, ignore.case = TRUE)
  is_leave_vs_noleave <- grepl("Leave vs No Leave", dataset_name, ignore.case = TRUE)
  label_map <- c(
    "leave"              = "Leaves",
    "noleave_branchlet"  = ifelse(is_leave_vs_noleave, "No leaves", "Branchlet"),
    "twig_2"             = ifelse(is_species, "Eucalyptus", "Twigs")
  )
  emm_df <- as.data.frame(emm)
  emm_df$condition <- as.character(emm_df$condition)
  for (old_lab in names(label_map)) {
    emm_df$condition[emm_df$condition == old_lab] <- label_map[[old_lab]]
  }
  emm_df$condition <- factor(emm_df$condition)

  ## Detect column names dynamically (varies by model family/link)
  mean_col <- if ("rate" %in% names(emm_df)) "rate" else if ("response" %in% names(emm_df)) "response" else "emmean"
  lcl_col <- if ("asymp.LCL" %in% names(emm_df)) "asymp.LCL" else "lower.CL"
  ucl_col <- if ("asymp.UCL" %in% names(emm_df)) "asymp.UCL" else "upper.CL"

  p <- ggplot(emm_df, aes(x = .data[[mean_col]], y = condition)) +
    geom_point(size = 2) +
    geom_errorbarh(aes(xmin = .data[[lcl_col]], xmax = .data[[ucl_col]]), height = 0.2) +
    labs(x = "EMM count", y = "Type") +
    theme_bw(base_size = 10) +
    theme(
      axis.title.y = element_text(angle = 0, vjust = 0.5),
      plot.margin = margin(5, 10, 5, 5)
    )

  ## Save
  safe_dataset_name <- gsub(" ", "_", dataset_name)
  filename <- paste0(figures_dir, "/", safe_dataset_name, "_count.png")
  ggsave(filename, plot = p, width = 5, height = 2.5)
  cat(paste0("  -> Plot saved to: ", filename, "\n"))

  return(paste0(best_model_name, " ", get_sig_string(pw_p)))
}

## Run Count Analysis Loop
for (d_name in names(dataset_list)) {
  p_res <- analyze_counts(dataset_list[[d_name]], d_name)
  results_matrix["n_points", d_name] <- p_res
}

## ------------------------------------------------------------------
## Export Summary Table to Report
## ------------------------------------------------------------------

cat("\n\n======================================================\n", file = report_file, append = TRUE)
cat("Summary of Pairwise Comparisons (P-Values)\n", file = report_file, append = TRUE)
cat("Signif. codes:  ns (p >= 0.05); * (p < 0.05); ** (p < 0.01); *** (p < 0.001)\n", file = report_file, append = TRUE)
cat("======================================================\n", file = report_file, append = TRUE)

# Print using capture.output to preserve formatting
sink(report_file, append = TRUE)
print(results_matrix, quote = FALSE)
sink()

cat("\nEnd of Report\n", file = report_file, append = TRUE)
