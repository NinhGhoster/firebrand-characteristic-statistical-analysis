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
    condition = factor(condition),

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
    condition = factor(condition),

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
## Modeling Volume vs Height (Trunk Section)
## ------------------------------------------------------------------

## Using 'condition' as a fixed effect (it represents Tree + Char level)
## Using 'height_section' as the continuous predictor
## Using 'fire_intensity' as a fixed effect (150kW, 100kW, 50kW)

## Model 4a: Linear effect of height
## Note: 'condition' is a FIXED effect here because we specifically want to compare
## these specific trees/char levels against each other (e.g. "Does 90% char differ from 0%?").
mod4a <- glmmTMB(volume ~ height_section + condition + fire_intensity,
  data = df1,
  family = Gamma(link = "log")
)

## Model 4d: Smooth effect of height (GAM) -- FIXED INTERCEPTS
## Assumes height effect is the SAME shape for all trees, but baseline volume varies fixedly by tree
mod4d <- gam(volume ~ fire_intensity + s(height_section) + condition,
  data = df1,
  family = Gamma(link = "log")
)

## Compare models
compare_performance(mod4a, mod4d, metrics = c("AIC", "RMSE"))

summary(mod4a)
summary(mod4d)

## Plot the fitted smooths
## This shows how volume changes with height for each condition
## Note for mod4a: Since it's a GLMM, we use emmeans to visualize the linear trends
EMM_by_condition <- emmeans(mod4a, ~condition)
EMM_by_intensity <- emmeans(mod4a, ~fire_intensity)
## do the same for continuous variable, at specific levles
EMM_by_height <- emmeans(mod4a, ~height_section, at = list(height_section = seq(1, 44, 0.5)))

tidy(EMM_by_height, conf.int = T) %>% ## get the confidence interval
  ggplot(aes(x = height_section)) + ## start the plot
  geom_line(aes(y = estimate)) + ## add a line
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "blue", alpha = 0.2) + ## plot the confidence interval
  scale_x_continuous(limits = c(0, 45), expand = c(0, 0)) + ## fix the x-axis range
  labs(
    x = "Height of section [m]", ## add axis labels and a title
    y = expression("Estimated mean firebrand volume [mm"^3 * "]"),
    title = "Effect of height vs volume"
  )

## Note for mod4d

plot(mod4d, pages = 1, scheme = 1, all.terms = TRUE)

emmeans(mod4a, ~condition)
emmeans(mod4a, ~fire_intensity)
emmeans(mod4a, ~fire_intensity)

plot(emmeans(mod4a, ~condition))
plot(emmeans(mod4a, ~fire_intensity))
