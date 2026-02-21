library(tidyverse) ## lots of useful utility functions and plotting routines
library(readxl) ## to read Excel files
library(mgcv) ## to fit GAMs
library(glmmTMB) ## to fit GLMMs
library(emmeans) ## to show some key estimates
library(performance) ## to compare performance of different models
library(MASS, exclude = "select") ## has negative binomial regression model
library(broom)

## Load data from Excel and assign condition for each sheet
excel_path <- "/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Stringybark/stringybark.xlsx"

df_T17 <- read_excel(excel_path, sheet = "E  obliqua 90% char T17") %>% mutate(condition = "90%")
df_T16 <- read_excel(excel_path, sheet = "E  obliqua 50-90% char T16") %>% mutate(condition = "50-90%")
df_T9 <- read_excel(excel_path, sheet = "E  obliqua 10-50% char T9") %>% mutate(condition = "10-50%")
df_T5 <- read_excel(excel_path, sheet = "E  obliqua 0% char T5") %>% mutate(condition = "O_0%")
df_T8 <- read_excel(excel_path, sheet = "E  radiata 0% char T8") %>% mutate(condition = "R_0%")

## Combine them
obliqua <- bind_rows(df_T17, df_T16, df_T9, df_T5) # use this for hazard level comparision
species <- bind_rows(df_T5, df_T8) # use this for species comparison

## Remove unwanted data, only apply for ones which have density column, run each test from here
df1 <- obliqua
df2 <- species

## Check that the data looks as expected
glimpse(df1)
glimpse(df2)

## Print summaries per variable
summary(df1)
summary(df2)

## Convert character variables to 'factor' representation
df1 <- mutate_if(df1, is.character, factor)
df2 <- mutate_if(df2, is.character, factor)

## Map column names to what the pseudocode expects
## ============================
## Columns:
## Source.Name, File (ID), Volume (mm3), Surface Area (mm2), Length (mm), Width (mm), Height (mm), Mass (g), Density (kg/m3)

## Make clean, consistent names for modeling
## restore variable names expected by the original script
## Make clean, consistent names for modeling
## Map column names to what the pseudocode expects

df1 <- df1 %>%
  rename(
    volume       = `Volume (mm3)`,
    surface_area = `Surface Area (mm2)`,
    length       = `Length (mm)`,
    width        = `Width (mm)`,
    height       = `Height (mm)`, # Renamed to avoid confusion with trunk height
    mass         = `Mass (g)`,
    density      = `Density (kg/m3)`
  ) %>%
  mutate(
    ## Extract Height from Source.Name (e.g. "S13.csv" -> 13)
    height_section = as.numeric(str_extract(`Source.Name`, "(?<=S)\\d+")),
    condition = factor(condition, levels = c("O_0%", "10-50%", "50-90%", "90%")),

    ## Derive Fire Intensity based on section number (repeating pattern 1, 2, 0 mod 3)
    fire_intensity = factor(case_when(
      height_section %% 3 == 1 ~ "150kW",
      height_section %% 3 == 2 ~ "100kW",
      height_section %% 3 == 0 ~ "50kW",
      TRUE ~ NA_character_
    ), levels = c("50kW", "100kW", "150kW"))
  )

glimpse(df1)

df2 <- df2 %>%
  rename(
    volume       = `Volume (mm3)`,
    surface_area = `Surface Area (mm2)`,
    length       = `Length (mm)`,
    width        = `Width (mm)`,
    height       = `Height (mm)`, # Renamed to avoid confusion with trunk height
    mass         = `Mass (g)`,
    density      = `Density (kg/m3)`
  ) %>%
  mutate(
    ## Extract Height from Source.Name (e.g. "S13.csv" -> 13)
    height_section = as.numeric(str_extract(`Source.Name`, "(?<=S)\\d+")),
    condition = factor(condition, levels = c("O_0%", "R_0%")),

    ## Derive Fire Intensity based on section number (repeating pattern 1, 2, 0 mod 3)
    fire_intensity = factor(case_when(
      height_section %% 3 == 1 ~ "150kW",
      height_section %% 3 == 2 ~ "100kW",
      height_section %% 3 == 0 ~ "50kW",
      TRUE ~ NA_character_
    ), levels = c("50kW", "100kW", "150kW"))
  )

glimpse(df2)

## ------------------------------------------------------------------
## Automated Model Selection for Multiple Parameters
## ------------------------------------------------------------------

## Parameters to test
params <- c("volume", "surface_area", "length", "width", "height", "mass")

## Define datasets to iterate over (named list for clear output)
dataset_list <- list(
  "Obliqua (Char Levels)" = df1,
  "Species (O vs R)"      = df2
)

## Define output paths
report_file <- "Stringybark/R/model_selection_report.txt"
figures_dir <- "Stringybark/R/figures"

## Initialize report file (overwrite if exists)
cat("Stringybark Model Selection Report\n", file = report_file)
cat("Generated on:", as.character(Sys.time()), "\n\n", file = report_file, append = TRUE)

## Create figures directory if it doesn't exist
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

## ------------------------------------------------------------------
## Summary Table Initialization
## ------------------------------------------------------------------

## Parameters to track: params + count
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
## Automated Model Selection (Supervisor's 2 Models)
## mod4a: glmmTMB Gamma(log) — linear height effect
## mod4d: GAM Gamma(log)     — smooth height effect s(height_section)
## ------------------------------------------------------------------

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
    return(list(sig = NA, model = NULL))
  }

  ## Formulas
  f_4a <- as.formula(paste(param_name, "~ height_section + condition + fire_intensity"))
  f_4d <- as.formula(paste(param_name, "~ fire_intensity + s(height_section) + condition"))

  ## List to store fitted models
  fitted_models <- list()

  ## mod4a: glmmTMB — linear effect of height
  tryCatch(
    {
      fitted_models$mod4a <- glmmTMB(f_4a, data = df, family = Gamma(link = "log"))
    },
    error = function(e) cat("  Error fitting mod4a (glmmTMB Gamma log): ", e$message, "\n")
  )

  ## mod4d: GAM — smooth effect of height
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

  ## Generate estimated marginal means for condition
  emm <- emmeans(best_model, ~condition, type = "response")

  ## Print Emmeans to console and report
  print(emm)
  sink(report_file, append = TRUE)
  cat("\nEstimated Marginal Means (by condition):\n")
  print(emm)
  cat("\nPairwise Comparisons (condition):\n")
  pw <- pairs(emm)
  print(pw)
  cat("\nConfidence Intervals:\n")
  print(confint(pw))
  sink()

  ## Extract p-value — use overall Anova-style test for condition (multi-level factor)
  pw_sum <- summary(pw)

  if (nrow(pw_sum) == 1) {
    p_val <- pw_sum$p.value[1]
  } else {
    jt <- joint_tests(best_model)
    p_val <- jt$p.value[jt$`model term` == "condition"]
  }

  ## Generate and save per-parameter emmeans plot (by condition)
  p_label <- ifelse(p_val < 0.001, "p < 0.001", paste0("p = ", round(p_val, 3)))
  emm_plot <- plot(emm) +
    labs(title = param_name, subtitle = dataset_name, caption = p_label)

  safe_dataset_name <- gsub(" ", "_", dataset_name)
  safe_dataset_name <- gsub("[()]", "", safe_dataset_name)
  filename <- paste0(figures_dir, "/", safe_dataset_name, "_", param_name, ".png")
  ggsave(filename, plot = emm_plot, width = 8, height = 6)
  cat(paste0("  -> Plot saved to: ", filename, "\n"))

  ## Generate and save per-parameter emmeans plot (by fire_intensity)
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

      p_label_fi <- ifelse(p_val_fi < 0.001, "p < 0.001", paste0("p = ", round(p_val_fi, 3)))
      emm_fi_plot <- plot(emm_fi) +
        labs(
          title = paste0(param_name, " (by Fire Intensity)"),
          subtitle = dataset_name, caption = p_label_fi
        )

      filename_fi <- paste0(figures_dir, "/", safe_dataset_name, "_", param_name, "_fire_intensity.png")
      ggsave(filename_fi, plot = emm_fi_plot, width = 8, height = 6)
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
  current_df <- dataset_list[[d_name]]
  best_models[[d_name]] <- list()

  for (p in params) {
    result <- select_best_model(current_df, p, d_name)
    results_matrix[p, d_name] <- result$sig
    best_models[[d_name]][[p]] <- result$model
  }
}

## ------------------------------------------------------------------
## Automated Count Analysis (Points per Height Section)
## ------------------------------------------------------------------

analyze_counts <- function(df, dataset_name) {
  cat(paste0("\n======================================================\n"))
  cat(paste0("Testing Counts (n_points) | Dataset: ", dataset_name, "\n"))
  cat(paste0("======================================================\n"))

  ## Append header to report
  cat(paste0("\n======================================================\n"), file = report_file, append = TRUE)
  cat(paste0("Testing Counts (n_points) | Dataset: ", dataset_name, "\n"), file = report_file, append = TRUE)
  cat(paste0("======================================================\n"), file = report_file, append = TRUE)

  ## Summarize points per height section PER condition
  ## (Different trees share the same height_section numbering, so we must

  ##  group by condition too to avoid merging data across trees.)
  df_npoints <- df %>%
    group_by(condition, height_section) %>%
    summarise(
      fire_intensity = first(fire_intensity),
      n_points = n(),
      .groups = "drop"
    )

  ## Fit Models
  models_list <- list()

  ## mod3a: Poisson
  tryCatch(
    {
      models_list$mod3a <- glm(n_points ~ condition + fire_intensity + height_section, data = df_npoints, family = poisson)
    },
    error = function(e) cat("  Error fitting mod3a (Poisson): ", e$message, "\n")
  )

  ## mod3b: Negative Binomial
  tryCatch(
    {
      models_list$mod3b <- glm.nb(n_points ~ condition + fire_intensity + height_section, data = df_npoints)
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

  ## Extract p-value
  pw_sum <- summary(pw)
  if (nrow(pw_sum) == 1) {
    pw_p <- pw_sum$p.value[1]
  } else {
    jt <- joint_tests(best_model)
    pw_p <- jt$p.value[jt$`model term` == "condition"]
  }

  p_label <- ifelse(pw_p < 0.001, "p < 0.001", paste0("p = ", round(pw_p, 3)))

  p <- plot(emm) +
    labs(title = "Points per Height Section", subtitle = dataset_name, caption = p_label)

  ## Save
  safe_dataset_name <- gsub(" ", "_", dataset_name)
  safe_dataset_name <- gsub("[()]", "", safe_dataset_name)
  filename <- paste0(figures_dir, "/", safe_dataset_name, "_count.png")
  ggsave(filename, plot = p, width = 8, height = 6)
  cat(paste0("  -> Plot saved to: ", filename, "\n"))

  return(paste0(best_model_name, " ", get_sig_string(pw_p)))
}

## Run Count Analysis Loop
for (d_name in names(dataset_list)) {
  p_res <- analyze_counts(dataset_list[[d_name]], d_name)
  results_matrix["n_points", d_name] <- p_res
}

## ------------------------------------------------------------------
## Combined Figures — 3 per dataset (Height, Fire Intensity, Condition)
## ------------------------------------------------------------------

for (d_name in names(dataset_list)) {
  safe_name <- gsub(" ", "_", d_name)
  safe_name <- gsub("[()]", "", safe_name)

  ## Collect emmeans data for all parameters that have models
  emm_height_all <- data.frame()
  emm_intensity_all <- data.frame()
  emm_condition_all <- data.frame()

  ## Helper: standardize tidy() output column names across different link functions
  standardize_emm_df <- function(df) {
    ## tidy() may produce 'estimate' or 'response' depending on the link function
    if ("response" %in% names(df) && !"estimate" %in% names(df)) {
      df <- rename(df, estimate = response)
    }
    ## Confidence interval columns may also vary
    if ("asymp.LCL" %in% names(df) && !"conf.low" %in% names(df)) {
      df <- rename(df, conf.low = asymp.LCL, conf.high = asymp.UCL)
    }
    return(df)
  }

  for (p in params) {
    mod <- best_models[[d_name]][[p]]
    if (is.null(mod)) next

    ## 1. Height Section (continuous) — line + ribbon
    tryCatch(
      {
        emm_h <- emmeans(mod, ~height_section,
          at = list(height_section = seq(1, 44, 0.5)),
          type = "response"
        )
        emm_h_df <- tidy(emm_h, conf.int = TRUE)
        emm_h_df <- standardize_emm_df(emm_h_df)
        emm_h_df$parameter <- p
        emm_height_all <- bind_rows(emm_height_all, emm_h_df)
      },
      error = function(e) cat("  Height EMM error for", p, ":", e$message, "\n")
    )

    ## 2. Fire Intensity (categorical) — point + errorbar
    tryCatch(
      {
        emm_fi <- emmeans(mod, ~fire_intensity, type = "response")
        emm_fi_df <- tidy(emm_fi, conf.int = TRUE)
        emm_fi_df <- standardize_emm_df(emm_fi_df)
        emm_fi_df$parameter <- p
        emm_intensity_all <- bind_rows(emm_intensity_all, emm_fi_df)
      },
      error = function(e) cat("  Fire Intensity EMM error for", p, ":", e$message, "\n")
    )

    ## 3. Condition (categorical) — point + errorbar
    tryCatch(
      {
        emm_c <- emmeans(mod, ~condition, type = "response")
        emm_c_df <- tidy(emm_c, conf.int = TRUE)
        emm_c_df <- standardize_emm_df(emm_c_df)
        emm_c_df$parameter <- p
        emm_condition_all <- bind_rows(emm_condition_all, emm_c_df)
      },
      error = function(e) cat("  Condition EMM error for", p, ":", e$message, "\n")
    )
  }

  ## Enforce consistent factor level ordering for condition and fire_intensity
  cond_levels <- if (d_name == "Obliqua (Char Levels)") {
    c("O_0%", "10-50%", "50-90%", "90%")
  } else {
    c("O_0%", "R_0%")
  }
  fi_levels <- c("50kW", "100kW", "150kW")

  if (nrow(emm_condition_all) > 0) {
    emm_condition_all$condition <- factor(emm_condition_all$condition, levels = cond_levels)
  }
  if (nrow(emm_intensity_all) > 0) {
    emm_intensity_all$fire_intensity <- factor(emm_intensity_all$fire_intensity, levels = fi_levels)
  }

  ## --- Plot 1: Height Section (all params, single graph) ---
  if (nrow(emm_height_all) > 0) {
    p1 <- ggplot(emm_height_all, aes(x = height_section, color = parameter, fill = parameter)) +
      geom_line(aes(y = estimate)) +
      geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.1, color = NA) +
      scale_x_continuous(limits = c(0, 45), expand = c(0, 0)) +
      scale_y_log10() +
      labs(
        x = "Height Section",
        y = "Estimated Mean (log scale)",
        color = "Parameter", fill = "Parameter",
        title = paste0(d_name, " — Effect of Height Section")
      ) +
      theme_bw()

    ggsave(paste0(figures_dir, "/", safe_name, "_by_height.png"),
      plot = p1, width = 10, height = 6
    )
    cat("  -> Saved:", paste0(safe_name, "_by_height.png"), "\n")
  }

  ## --- Plot 2: Fire Intensity (all params, single graph) ---
  if (nrow(emm_intensity_all) > 0) {
    p2 <- ggplot(emm_intensity_all, aes(x = fire_intensity, color = parameter)) +
      geom_point(aes(y = estimate), size = 3, position = position_dodge(width = 0.4)) +
      geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
        width = 0.2, alpha = 0.5,
        position = position_dodge(width = 0.4)
      ) +
      scale_y_log10() +
      labs(
        x = "Fire Intensity",
        y = "Estimated Mean (log scale)",
        color = "Parameter",
        title = paste0(d_name, " — Effect of Fire Intensity")
      ) +
      theme_bw()

    ggsave(paste0(figures_dir, "/", safe_name, "_by_fire_intensity.png"),
      plot = p2, width = 10, height = 6
    )
    cat("  -> Saved:", paste0(safe_name, "_by_fire_intensity.png"), "\n")
  }

  ## --- Plot 3: Condition (all params, single graph) ---
  if (nrow(emm_condition_all) > 0) {
    p3 <- ggplot(emm_condition_all, aes(x = condition, color = parameter)) +
      geom_point(aes(y = estimate), size = 3, position = position_dodge(width = 0.4)) +
      geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
        width = 0.2, alpha = 0.5,
        position = position_dodge(width = 0.4)
      ) +
      scale_y_log10() +
      labs(
        x = "Condition",
        y = "Estimated Mean (log scale)",
        color = "Parameter",
        title = paste0(d_name, " — Effect of Condition")
      ) +
      theme_bw()

    ggsave(paste0(figures_dir, "/", safe_name, "_by_condition.png"),
      plot = p3, width = 10, height = 6
    )
    cat("  -> Saved:", paste0(safe_name, "_by_condition.png"), "\n")
  }
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
