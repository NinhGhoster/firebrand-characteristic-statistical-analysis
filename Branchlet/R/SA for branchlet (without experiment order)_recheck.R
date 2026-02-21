library(tidyverse) ## lots of useful utility functions and plotting routines
library(readxl)    ## to read Excel files
library(mgcv)      ## to fit GAMs
library(glmmTMB)   ## to fit GLMMs
library(broom)     ## 
library(emmeans)   ## to show some key estimates
library(performance) ## to compare performance of different models
library(MASS, exclude = 'select') ## has negative binomial regression model

## load data from Excel and assign condition for each sheet

excel_path <- "/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Branchlet/branchlet raw data.xlsx"

df_twig2 <- read_excel(excel_path, sheet = "twigs (2)") %>% mutate(condition = "twig_2")
df_100k <- read_excel(excel_path, sheet = "100 kW") %>% mutate(condition = "100kW")
df_50k <- read_excel(excel_path, sheet = "50 kW") %>% mutate(condition = "50kW")

## combine them, they are all data groups for comparison

fi_150kW_vs_50kW <- bind_rows(df_twig2, df_50k)
fi_150kW_vs_100kW <- bind_rows(df_twig2, df_100k)
fi_100kW_vs_50kW <- bind_rows(df_100k, df_50k)

## remove unwanted data, only apply for ones which have density column, run each test from here
df1 <- fi_150kW_vs_50kW

## check that the data looks as expected
glimpse(df1)

## print summaries per variable
summary(df1)

## convert character variables to 'factor' representation
df <- mutate_if(df1, is.character, factor)

## Map column names to what the pseudocode expects
## ============================
## Columns:
## Source.Name, File (ID), Volume (mm3), Surface Area (mm2), Length (mm), Width (mm), Height (mm), Mass (g), Density (kg/m3)

## Make clean, consistent names for modeling
## restore variable names expected by the original script
df <- df %>%
  rename(
    volume_mm3       = `Volume (mm3)`,
    surface_area_mm2 = `Surface Area (mm2)`,
    length_mm        = `Length (mm)`,
    width_mm         = `Width (mm)`,
    height_mm        = `Height (mm)`,
    mass_g           = `Mass (g)`,
    density_kg_m3    = `Density (kg/m3)`,
    experiment_order = `Experiment order`,
  )

df <- df %>%
  mutate(
    volume       = volume_mm3,
    surface_area = surface_area_mm2,
    length       = length_mm,
    width        = width_mm,
    height       = height_mm,
    mass         = mass_g,
    density      = density_kg_m3,
    condition    = factor(condition),
    experiment  = experiment_order,
  )

glimpse(df)

## Example 1: say, are looking at volume (the response variable) as a
## function of a categorical variable 'condition' ('with leaves' or
## 'without leaves'). You have lots of measurements per experiment.

## This one uses a gamma-distributed exponential family; the 'family'
## of the response variable relates to its distribution conditional on
## the linear predictors (on the righ-hand side of the '~' sign
## For more on exponential families, see the table in this Wikipedia page:
## https://en.wikipedia.org/wiki/Generalized_linear_model#Link_function
## Or this table:
## https://en.wikipedia.org/wiki/Exponential_family#Table_of_distributions

## There are two obvious choices to try - Gamma and inverse Gaussian,
## both of which are appropriate for non-negative continuous variables

mod1a <- glmmTMB(volume ~ condition, data = df,
                 family = Gamma) ## uses the default link='inverse'

mod1b <- glmmTMB(volume ~ condition, data = df,
                 family = Gamma(link = 'log')) ## another reasonable choice

mod1c <- glmmTMB(volume ~ condition, data = df,
                 family = Gamma(link = 'identity')) ## probably less relevant than the first two

## Now using the log-normal response distribution, conditional
## on the linear predictors

mod2 <- glmmTMB(volume ~ condition, data = df,
                family = lognormal) ## uses the default link = "log"

## Lower AIC is better (same for RMSE). Some people are interested in
## the RMSE (so I've added that), although I would probably select
## based on the AIC.
compare_performance(mod1a, mod1b, mod1c, mod2, metrics = c('AIC', 'RMSE'))

## Suppose you go with the structure for mod1a. Print the summary
## table for the model.
## If you have a single pair of treatments, the p-value for the
## 'condition' term provides a test of whether the two conditions are
## statistically significantly different.
summary(mod2)

## Produce estimates of the mean for each group, based on the fitted model
EMM <- emmeans(mod2, ~condition,
               ## this last line is important, as it converts it back to the
               ## original scale of the response data (for most GLMs, the
               ## model parameters are estimated on a different scale to the
               ## outcome variable).
               type = 'response')
print(EMM)
tidy(EMM, conf.int = TRUE)

## make a plot
plot(EMM)

## show the differences between pairs of conditions
pairs(EMM)

## confidence intervals for these pairs
confint(pairs(EMM))

#############################################