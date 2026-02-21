library(tidyverse) ## lots of useful utility functions and plotting routines
library(readxl)    ## to read Excel files
library(mgcv)      ## to fit GAMs
library(glmmTMB)   ## to fit GLMMs
library(emmeans)   ## to show some key estimates
library(performance) ## to compare performance of different models
library(MASS, exclude = 'select') ## has negative binomial regression model

## if your data is in a CSV, you can do something like this:
df <- read_csv('mydata.csv')

## if your data is in an Excel spreadsheet, you can use this function:
df <- read_xlsx('mydata.xlsx',
                ## the index or the name of the worksheet
                sheet = 1,
                ## The range of cells to read. If you want it to read
                ## the top-left rectangle of the worksheet, run with
                ## range = NULL or if you want to restrict it to a
                ## particular subset of the worksheet, change this to
                ## something like: range = 'A2:AY148'
                range = NULL)

## check that the data looks as expected
glimpse(df)

## print summaries per variable
summary(df)

## convert character variables to 'factor' representation
df <- mutate_if(df, is.character, factor)

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
mod1a <- glmmTMB(volume ~ condition + (1|experiment), data = df,
                family = Gamma) ## uses the default link='inverse'

mod1b <- glmmTMB(volume ~ condition + (1|experiment), data = df,
                family = Gamma(link = 'log')) ## another reasonable choice

mod1c <- glmmTMB(volume ~ condition + (1|experiment), data = df,
                family = Gamma(link = 'identity')) ## probably less relevant than the first two

## Now using the log-normal response distribution, conditional
## on the linear predictors
mod2 <- glmmTMB(volume ~ condition + (1|experiment), data = df,
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
summary(mod1a)

## Produce estimates of the mean for each group, based on the fitted model
EMM <- emmeans(mod1a, ~condition,
               ## this last line is important, as it converts it back to the
               ## original scale of the response data (for most GLMs, the
               ## model parameters are estimated on a different scale to the
               ## outcome variable).
               type = 'response')
print(EMM)

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
df_npoints <-
    summarise(group_by(df,experiment),
              condition = first(condition),
              n_points = n())

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
check_overdispersion(mod3a) ## if overdispersion is detected in the Poisson model, best use the NB model
check_overdispersion(mod3b) ## this one will probably be OK

## again, select based on the AIC 
compare_performance(mod3a, mod3b, metrics = c('AIC', 'RMSE'))

#############################################
## let's assume that you have data for experiments related to height

df_height <- read_csv('height_data.csv')

glimpse(df_height)

## the following two models treat height as a _linear_ predictor

## you can _EITHER_ fit a model that treats 'tree' as a random effect 
mod4a <- glmmTMB(volume ~ height + intensity + (1|tree),
                 data = df_height,
                 ## I would use the same exponential family as what
                 ## you decided upon for the earlier analyses for the
                 ## same response variable. Let's just say it's the
                 ## Gamma distribution with a log link function.
                 family = Gamma(link = 'log'))
## _OR_ you can estimate the effect of the hazard level
mod4b <- glmmTMB(volume ~ height + intensity + hazard_level,
                 data = df_height, family = Gamma(link = 'log'))

## If you want to fit height as a non-linear predictor, you can use
## one of these models. These are the analogues of the two models
## above, but using generalized additive models and assuming a
## smooth/spline term with respect to height.
mod4c <- gam(volume ~ s(height) + intensity + s(tree, bs = 're'),
             data = df_height, family = Gamma(link = 'log'))
mod4d <- gam(volume ~ s(height) + intensity + hazard_level,
             data = df_height, family = Gamma(link = 'log'))

summary(mod4c)
summary(mod4d)

## Plot the fitted smooth function, _on the scale of the linear predictor_
## which may not be the same as the scale of the original response data
plot(mod4c,
     select = 1) ## this make sure you're just plotting the same
















