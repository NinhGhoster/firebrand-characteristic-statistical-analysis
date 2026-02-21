library(tidyverse) ## lots of useful utility functions and plotting routines
library(readxl) ## to read Excel files
library(mgcv) ## to fit GAMs
library(glmmTMB) ## to fit GLMMs
library(broom) ##
library(emmeans) ## to show some key estimates
library(performance) ## to compare performance of different models
library(MASS, exclude = "select") ## has negative binomial regression model

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
eucalyptus_vs_pine <- bind_rows(df_twig2, df_pine)
eucalyptus_vs_acacia <- bind_rows(df_twig2, df_acacia)
acacia_vs_pine <- bind_rows(df_pine, df_acacia)

## use subset here if want to remove based on density (not recommended)

## check that the data looks as expected
glimpse(leave_vs_noleave_branchlet)
glimpse(leave_vs_twig)
glimpse(eucalyptus_vs_pine)
glimpse(eucalyptus_vs_acacia)
glimpse(acacia_vs_pine)

## print summaries per variable
summary(leave_vs_noleave_branchlet)
summary(leave_vs_twig)
summary(eucalyptus_vs_pine)
summary(eucalyptus_vs_acacia)
summary(acacia_vs_pine)

## convert character variables to 'factor' representation
df1 <- mutate_if(leave_vs_noleave_branchlet, is.character, factor)
df2 <- mutate_if(leave_vs_twig, is.character, factor)
df3 <- mutate_if(eucalyptus_vs_pine, is.character, factor)
df4 <- mutate_if(eucalyptus_vs_acacia, is.character, factor)
df5 <- mutate_if(acacia_vs_pine, is.character, factor)

## Map column names to what the pseudocode expects
## ============================
## Columns:
## Source.Name, File (ID), Volume (mm3), Surface Area (mm2), Length (mm), Width (mm), Height (mm), Mass (g), Density (kg/m3)

## Make clean, consistent names for modeling
## restore variable names expected by the original script
df1 <- df1 %>%
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

df1 <- df1 %>%
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
    )
glimpse(df1)

df2 <- df2 %>%
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

df2 <- df2 %>%
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
    )
glimpse(df2)

df3 <- df3 %>%
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

df3 <- df3 %>%
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
    )
glimpse(df3)

df4 <- df4 %>%
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

df4 <- df4 %>%
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
    )
glimpse(df4)

df5 <- df5 %>%
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

df5 <- df5 %>%
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
    )
glimpse(df5)

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
df1$experiment <- factor(df1$experiment)

mod1a <- glmmTMB(mass ~ condition + (1 | experiment),
    data = df1,
    family = Gamma
) ## uses the default link='inverse'

mod1b <- glmmTMB(mass ~ condition + (1 | experiment),
    data = df1,
    family = Gamma(link = "log")
) ## another reasonable choice

mod1c <- glmmTMB(volume ~ condition,
    data = df1,
    family = Gamma(link = "identity")
) ## probably less relevant than the first two

## Now using the log-normal response distribution, conditional
## on the linear predictors
mod2 <- glmmTMB(mass ~ condition + (1 | experiment),
    data = df1,
    family = lognormal
) ## uses the default link = "log"

## Lower AIC is better (same for RMSE). Some people are interested in
## the RMSE (so I've added that), although I would probably select
## based on the AIC.
compare_performance(mod1a, mod1b, mod1c, mod2, metrics = c("AIC", "RMSE"))

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
    type = "response"
)
print(EMM)

tidy(EMM, conf.int = TRUE)

## make a plot
plot(EMM)

## show the differences between pairs of conditions
pairs(EMM)

## confidence intervals for these pairs
confint(pairs(EMM))

### ### ### Now look at the number of points per experiment

## make a summary of the number of points - using R 'pipe' functionality
## e.g., as explained here:
## https://biostats-r.github.io/biostats/workingInR/010-pipes.html

## You can get exactly the same result rearranging the code like this:

# Use experiment as grouping variable
df_npoints <-
    summarise(group_by(df1, experiment),
        condition = first(condition),
        n_points = n()
    )

## you should see the number of data points per experiment, with
## condition as another variable
glimpse(df_npoints)

## fit a Poisson regression model, which is appropriate when the
## response is a count variable (i.e., non-negative integer-valued)
mod3a <- glm(n_points ~ condition, data = df_npoints, family = poisson)

## fit a negative binomial model, which is _almost always_ a better
## fit for count data in real-world datasets.
mod3b <- glm.nb(n_points ~ condition, data = df_npoints)

## check for overdispersion in the two models
check_overdispersion(mod3a) ## if overdispersion is detected in the Poisson model, best use the NB model # nolint
check_overdispersion(mod3b) ## this one will probably be OK

## again, select based on the AIC
compare_performance(mod3a, mod3b, metrics = c("AIC", "RMSE"))

summary(mod3b)

EMM <- emmeans(mod3b, ~condition,
    type = "response"
)
print(EMM)
plot(EMM)

## show the differences between pairs of conditions
pairs(EMM)

#############################################
