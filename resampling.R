library(boot)
library(tidyverse)
library(coin)
library(gtools)
library(randomForest)

source("bsa_funs.R")

# make sure you're in bsa-research repo
run_pct <- read_csv("data/run_pct.csv")
hr_pct <- read_csv("data/hr_pct.csv")


# permutation tests for diff in props before and after dimension changes
# assumption of exchangeability should be satisfied


##################################################################################################
#
# Houston Astros
#
##################################################################################################
astros <- run_pct %>% filter(team == "HOU", location == "home")
astros$flag <- factor(astros$flag, levels = c("before", "after"))

# one way permutation test from coin package for proportion of runs scored at home for Astros 
# and wilcox test
oneway_test(run_percent ~ flag, data = astros, distribution = "exact")
wilcox_test(run_percent ~ flag, data = astros, distribution = "exact")



# above loop is probably not correct, empirical p-value is not the same as pval from coin tests
# hist and pvalue change everytime perm_func is called which shouldnt be happening

# distribution of all mean differences from permutation test
perm_list <- perm_func(astros)
perm_dist <- sapply(perm_func(astros), extract_stat)
hist(perm_dist, xlab = "mean difference", main = 
       "difference between mean run prop before and after dim change")

# empirical p-value
mean(sapply(perm_func(astros), extract_stat) >= 0.02008508)

# need to check if any of the dfs of perm_func(df) are equal to each other
for(i in 1:length(perm_list)) {
  equals <- sapply(perm_list, identical, perm_list[[i]])
  indices <- which(equals)
  cat("Indices of dfs same as element ", i, " of perm_list: ", indices, "\n", sep = "")
}
# everything checks out


###################################################################################################
#
# nonparametric bootstrapping for all teams (run_pct)
#
###################################################################################################



boot_diffs <- replicate(5000, mean(bootstrap_all(run_pct)[["after"]]) - 
                              mean(bootstrap_all(run_pct)[["before"]]))

hist(boot_diffs)
summary(boot_diffs)

# empirical pval
crit_val <- mean(filter(run_pct, flag == "after", location == "home")$run_percent) - 
            mean(filter(run_pct, flag == "before", location == "home")$run_percent)
mean(boot_diffs >= crit_val)



###################################################################################################
#
# random forest model to predict the proportion of runs scored at home
#
###################################################################################################


dims <- read_csv("data/ballpark_dims2.csv")

# only want home data for run_pct
# run_pct <- filter(run_pct, location == "home")

# change full team names to abbreviations in dims to be consistent with rates
dims$team <- dplyr::recode(dims$team, "Houston Astros" = "HOU")
dims$team <- dplyr::recode(dims$team, "Miami Marlins" = "MIA")
dims$team <- dplyr::recode(dims$team, "San Diego Padres" = "SDP")
dims$team <- dplyr::recode(dims$team, "Seattle Mariners" = "SEA")
dims$team <- dplyr::recode(dims$team, "Atlanta Braves" = "ATL")
dims$team <- dplyr::recode(dims$team, "Minnesota Twins" = "MIN")
run_pct$team <- dplyr::recode(run_pct$team, "FLA" = "MIA")


# convert years col of dims to datetime objects, append dim info to run_pct df
# need to append dims of correct year to run_pct df
dims <- dims[-5, ] # remove miami's most recent change because there's no data available 
dims$years[c(1, 3, 5, 7, 9, 11)] <- "before"
dims$years[c(2, 4, 6, 8, 10, 12)] <- "after"
dims <- dims[, -2]

# merge dims and run_pct
merged <- merge(run_pct, dims, by.x = c("team", "flag"), by.y = c("team", "years"))


model <- randomForest(run_percent ~ team + flag + left + left_center + center + right_center +
                        right + deepest, data = merged)





