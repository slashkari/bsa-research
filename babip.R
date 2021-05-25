library(tidyverse)
library(rvest)
library(coin)

source("bsa_funs.R")

run_pct <- read_csv("data/run_pct.csv")
hr_pct <- read_csv("data/hr_pct.csv")
rates <- read_csv("data/rates.csv")

# read in babip data created from babip_data.py
babip <- read_csv("data/babip_data.csv")
woba <- read_csv("data/woba_data.csv")
wrc <- read_csv("data/wrcplus_data.csv")



# maybe compare team babips to overall franchise babip? different teams might have different 
# franchise babips because there's a specific type of player profile they sign, or because of 
# their park factors. # fangraphs says certain players can maintain babips that differ a lot from
# league average of .300, the same MIGHT be true for teams.

# could also look a pull%, center%, oppo% on fangraphs. if left field is moved in significantly
# right handed batters might try to go oppo more. try to look at splits (e.g. oppo% for right handed
# batters, pull% for lefties if left field is moved in)


# add flag variable
flag <- run_pct %>% filter(location == "home") %>% select(flag)
flag <- flag[-c(85, 86), ] # don't include MIN 2000 and 2001 because no BABIP, wOBA, wRC+ data on it
babip <- cbind(babip, flag)
woba <- cbind(woba, flag)
wrc <- cbind(wrc, flag)

colnames(wrc)[2] <- "wRCplus" # change for ggplot


# plot side by side boxplots for each team for df of given stat
plot_side <- function(data) {
  copy <- data
  copy$flag <- factor(copy$flag, levels = c("before", "after"))

  p <- ggplot(copy, aes_string(x = "flag", y = colnames(copy)[2], fill = "flag"))
  p <- p + geom_boxplot() + facet_wrap(~ Team)
  p <- p + labs(xlab = "Time Relative to Fence Change", fill = "flag")
  p
}

plot_side(babip)
plot_side(woba)
plot_side(wrc)

colnames(wrc)[2] <- "wRC+" # change back

# print out means of each team before and after
# stat is a string of how you want the stat displayed when printing (e.g. "BB%", "BABIP", "wRC+")
# percent = FALSE means stat is a real number and will be rounded to 3 places
# percent = TRUE means stat is a percentage, % will be appended to stat when printing
print_means <- function(data, stat, percent = FALSE, prec = 3) {
  for(team in unique(data$Team)) {
    before <- data %>% filter(Team == team, flag == "before")
    after <- data %>% filter(Team == team, flag == "after")

    if(team == unique(data$Team)[1]) {
      cat("Mean Team ", stat, " Before and After Dimension Change:", "\n", sep = "")
    }
    if(percent == FALSE) {
      cat(team, ": ", "Before - ", format(round(mean(before[, stat]), prec), nsmall = prec), ", ", 
          "After - ", format(round(mean(after[, stat]), prec), nsmall = prec), "\n", sep = "")
    }
    else {
      cat(team, ": ", "Before - ", paste0(stat, "%"), ", ", "After - ", paste0(stat, "%"), "\n", sep = "")
    }
  }
}


print_means(babip, "BABIP", percent = FALSE)
print_means(woba, "wOBA", percent = FALSE)
print_means(wrc, "wRC+", percent = FALSE, prec = 0)


###################################################################################################
#
# BABIP 
#
###################################################################################################

# plot resampled distributions overlayed each other
# PERMUTATION FOR BABIP
# some teams commented out because perm_func() took too long (need to optimize)
astros <- filter(babip, Team == "HOU")
astros_perm <- perm_func(astros, "BABIP")
astros_perm_dist <- sapply(astros_perm, extract_stat, stat = "BABIP")

marlins <- filter(babip, Team == "MIA")
marlins_perm <- perm_func(marlins, "BABIP")
marlins_perm_dist <- sapply(marlins_perm, extract_stat, stat = "BABIP")

padres <- filter(babip, Team == "SDP")
# padres_perm <- perm_func(padres, "BABIP")
# padres_perm_dist <- sapply(padres_perm, extract_stat, stat = "BABIP")

braves <- filter(babip, Team == "ATL")
braves_perm <- perm_func(braves, "BABIP")
braves_perm_dist <- sapply(braves_perm, extract_stat, stat = "BABIP")

mariners <- filter(babip, Team == "SEA")
# mariners_perm <- perm_func(mariners, "BABIP")
# mariners_perm_dist <- sapply(mariners_perm, extract_stat, stat = "BABIP")

twins <- filter(babip, Team == "MIN")
# twins_perm <- perm_func(twins, "BABIP")
# twins_perm_dist <- sapply(twins_perm, extract_stat, stat = "BABIP")


# plot cdfs
par(mfrow = c(1, 3))
cdf_overlayed(astros_perm_dist, color = "orange", team = "HOU")
cdf_overlayed(marlins_perm_dist, color = "turquoise", team = "MIA")
cdf_overlayed(braves_perm_dist, color = "navy", team = "ATL")

# plot hists
par(mfrow = c(1, 3))
hist_overlayed(astros_perm_dist, color = "orange", team = "HOU")
hist_overlayed(marlins_perm_dist, color = "turquoise", team = "MIA")
hist_overlayed(braves_perm_dist, color = "navy", team = "ATL")

# for hist plot critical value cutoff



# BOOTSTRAPPING FOR BABIP
set.seed(123)
hou_boot_diffs <- replicate(5000, mean(bootstrap_all(astros, "BABIP")[["after"]]) - 
                          mean(bootstrap_all(astros, "BABIP")[["before"]]))
mia_boot_diffs <- replicate(5000, mean(bootstrap_all(marlins, "BABIP")[["after"]]) - 
                          mean(bootstrap_all(marlins, "BABIP")[["before"]]))
sdp_boot_diffs <- replicate(5000, mean(bootstrap_all(padres, "BABIP")[["after"]]) - 
                          mean(bootstrap_all(padres, "BABIP")[["before"]]))
sea_boot_diffs <- replicate(5000, mean(bootstrap_all(mariners, "BABIP")[["after"]]) - 
                          mean(bootstrap_all(mariners, "BABIP")[["before"]]))
atl_boot_diffs <- replicate(5000, mean(bootstrap_all(braves, "BABIP")[["after"]]) - 
                          mean(bootstrap_all(braves, "BABIP")[["before"]]))
min_boot_diffs <- replicate(5000, mean(bootstrap_all(twins, "BABIP")[["after"]]) - 
                          mean(bootstrap_all(twins, "BABIP")[["before"]]))



# plot cdfs
par(mfrow = c(2, 3))
cdf_overlayed(hou_boot_diffs, color = "orange", team = "HOU")
cdf_overlayed(mia_boot_diffs, color = "turquoise", team = "MIA")
cdf_overlayed(sdp_boot_diffs, color = "brown", team = "SDP")
cdf_overlayed(sea_boot_diffs, color = "forestgreen", team = "SEA")
cdf_overlayed(atl_boot_diffs, color = "navy", team = "ATL")
cdf_overlayed(min_boot_diffs, color = "red", team = "MIN")

# plot hists
par(mfrow = c(2, 3))
hist_overlayed(hou_boot_diffs, color = "orange", team = "HOU")
hist_overlayed(mia_boot_diffs, color = "turquoise", team = "MIA")
hist_overlayed(sdp_boot_diffs, color = "brown", team = "SDP")
hist_overlayed(sea_boot_diffs, color = "forestgreen", team = "SEA")
hist_overlayed(atl_boot_diffs, color = "navy", team = "ATL")
hist_overlayed(min_boot_diffs, color = "red", team = "MIN")


###################################################################################################
#
# wOBA
#
###################################################################################################

# PERMUTATION TESTS
astros <- filter(woba, Team == "HOU")
astros_perm <- perm_func(astros, "wOBA")
astros_perm_dist <- sapply(astros_perm, extract_stat, stat = "wOBA")

marlins <- filter(woba, Team == "MIA")
marlins_perm <- perm_func(marlins, "wOBA")
marlins_perm_dist <- sapply(marlins_perm, extract_stat, stat = "wOBA")

padres <- filter(woba, Team == "SDP")
# padres_perm <- perm_func(padres, "wOBA")
# padres_perm_dist <- sapply(padres_perm, extract_stat, stat = "wOBA")

braves <- filter(woba, Team == "ATL")
braves_perm <- perm_func(braves, "wOBA")
braves_perm_dist <- sapply(braves_perm, extract_stat, stat = "wOBA")

mariners <- filter(woba, Team == "SEA")
# mariners_perm <- perm_func(mariners, "wOBA")
# mariners_perm_dist <- sapply(mariners_perm, extract_stat, stat = "wOBA")

twins <- filter(woba, Team == "MIN")
# twins_perm <- perm_func(twins, "wOBA")
# twins_perm_dist <- sapply(twins_perm, extract_stat, stat = "wOBA")


# plot cdfs
par(mfrow = c(1, 3))
cdf_overlayed(astros_perm_dist, color = "orange", team = "HOU")
cdf_overlayed(marlins_perm_dist, color = "turquoise", team = "MIA")
cdf_overlayed(braves_perm_dist, color = "navy", team = "ATL")

# plot hists
par(mfrow = c(1, 3))
hist_overlayed(astros_perm_dist, color = "orange", team = "HOU")
hist_overlayed(marlins_perm_dist, color = "turquoise", team = "MIA")
hist_overlayed(braves_perm_dist, color = "navy", team = "ATL")


# BOOTSTRAPPING FOR wOBA
set.seed(123)
hou_boot_diffs <- replicate(5000, mean(bootstrap_all(astros, "wOBA")[["after"]]) - 
                              mean(bootstrap_all(astros, "wOBA")[["before"]]))
mia_boot_diffs <- replicate(5000, mean(bootstrap_all(marlins, "wOBA")[["after"]]) - 
                              mean(bootstrap_all(marlins, "wOBA")[["before"]]))
sdp_boot_diffs <- replicate(5000, mean(bootstrap_all(padres, "wOBA")[["after"]]) - 
                              mean(bootstrap_all(padres, "wOBA")[["before"]]))
sea_boot_diffs <- replicate(5000, mean(bootstrap_all(mariners, "wOBA")[["after"]]) - 
                              mean(bootstrap_all(mariners, "wOBA")[["before"]]))
atl_boot_diffs <- replicate(5000, mean(bootstrap_all(braves, "wOBA")[["after"]]) - 
                              mean(bootstrap_all(braves, "wOBA")[["before"]]))
min_boot_diffs <- replicate(5000, mean(bootstrap_all(twins, "wOBA")[["after"]]) - 
                              mean(bootstrap_all(twins, "wOBA")[["before"]]))



# plot cdfs
par(mfrow = c(2, 3))
cdf_overlayed(hou_boot_diffs, color = "orange", team = "HOU")
cdf_overlayed(mia_boot_diffs, color = "turquoise", team = "MIA")
cdf_overlayed(sdp_boot_diffs, color = "brown", team = "SDP")
cdf_overlayed(sea_boot_diffs, color = "forestgreen", team = "SEA")
cdf_overlayed(atl_boot_diffs, color = "navy", team = "ATL")
cdf_overlayed(min_boot_diffs, color = "red", team = "MIN")

# plot hists
# none of these are centered around zero
# padres might not even be normal (looks skewed)
par(mfrow = c(2, 3))
hist_overlayed(hou_boot_diffs, color = "orange", team = "HOU")
hist_overlayed(mia_boot_diffs, color = "turquoise", team = "MIA")
hist_overlayed(sdp_boot_diffs, color = "brown", team = "SDP")
hist_overlayed(sea_boot_diffs, color = "forestgreen", team = "SEA")
hist_overlayed(atl_boot_diffs, color = "navy", team = "ATL")
hist_overlayed(min_boot_diffs, color = "red", team = "MIN")


####################################################################################################
#
# wRC+
#
####################################################################################################

colnames(wrc)[2] <- "wrcplus"
# PERMUTATION TESTS
astros <- filter(wrc, Team == "HOU")
astros_perm <- perm_func(astros, "wrcplus")
astros_perm_dist <- sapply(astros_perm, extract_stat, stat = "wrcplus")

marlins <- filter(wrc, Team == "MIA")
marlins_perm <- perm_func(marlins, "wrcplus")
marlins_perm_dist <- sapply(marlins_perm, extract_stat, stat = "wrcplus")

padres <- filter(wrc, Team == "SDP")
# padres_perm <- perm_func(padres, "wrcplus")
# padres_perm_dist <- sapply(padres_perm, extract_stat, stat = "wrcplus")

braves <- filter(wrc, Team == "ATL")
braves_perm <- perm_func(braves, "wrcplus")
braves_perm_dist <- sapply(braves_perm, extract_stat, stat = "wrcplus")

mariners <- filter(wrc, Team == "SEA")
# mariners_perm <- perm_func(mariners, "wrcplus")
# mariners_perm_dist <- sapply(mariners_perm, extract_stat, stat = "wrcplus")

twins <- filter(wrc, Team == "MIN")
# twins_perm <- perm_func(twins, "wrcplus")
# twins_perm_dist <- sapply(twins_perm, extract_stat, stat = "wrcplus")

# plot cdfs
par(mfrow = c(1, 3))
cdf_overlayed(astros_perm_dist, color = "orange", team = "HOU")
cdf_overlayed(marlins_perm_dist, color = "turquoise", team = "MIA")
cdf_overlayed(braves_perm_dist, color = "navy", team = "ATL")

# plot hists
par(mfrow = c(1, 3))
hist_overlayed(astros_perm_dist, color = "orange", team = "HOU")
hist_overlayed(marlins_perm_dist, color = "turquoise", team = "MIA")
hist_overlayed(braves_perm_dist, color = "navy", team = "ATL")


# BOOTSTRAPPING FOR wRC+
set.seed(123)
hou_boot_diffs <- replicate(5000, mean(bootstrap_all(astros, "wrcplus")[["after"]]) - 
                              mean(bootstrap_all(astros, "wrcplus")[["before"]]))
mia_boot_diffs <- replicate(5000, mean(bootstrap_all(marlins, "wrcplus")[["after"]]) - 
                              mean(bootstrap_all(marlins, "wrcplus")[["before"]]))
sdp_boot_diffs <- replicate(5000, mean(bootstrap_all(padres, "wrcplus")[["after"]]) - 
                              mean(bootstrap_all(padres, "wrcplus")[["before"]]))
sea_boot_diffs <- replicate(5000, mean(bootstrap_all(mariners, "wrcplus")[["after"]]) - 
                              mean(bootstrap_all(mariners, "wrcplus")[["before"]]))
atl_boot_diffs <- replicate(5000, mean(bootstrap_all(braves, "wrcplus")[["after"]]) - 
                              mean(bootstrap_all(braves, "wrcplus")[["before"]]))
min_boot_diffs <- replicate(5000, mean(bootstrap_all(twins, "wrcplus")[["after"]]) - 
                              mean(bootstrap_all(twins, "wrcplus")[["before"]]))



# plot cdfs
par(mfrow = c(2, 3))
cdf_overlayed(hou_boot_diffs, color = "orange", team = "HOU")
cdf_overlayed(mia_boot_diffs, color = "turquoise", team = "MIA")
cdf_overlayed(sdp_boot_diffs, color = "brown", team = "SDP")
cdf_overlayed(sea_boot_diffs, color = "forestgreen", team = "SEA")
cdf_overlayed(atl_boot_diffs, color = "navy", team = "ATL")
cdf_overlayed(min_boot_diffs, color = "red", team = "MIN")

# plot hists
par(mfrow = c(2, 3))
hist_overlayed(hou_boot_diffs, color = "orange", team = "HOU")
hist_overlayed(mia_boot_diffs, color = "turquoise", team = "MIA")
hist_overlayed(sdp_boot_diffs, color = "brown", team = "SDP")
hist_overlayed(sea_boot_diffs, color = "forestgreen", team = "SEA")
hist_overlayed(atl_boot_diffs, color = "navy", team = "ATL")
hist_overlayed(min_boot_diffs, color = "red", team = "MIN")


# one way permutation test and wilcox test for each team

# BABIP
# NO SIGNIFICANT RESULTS
for(team in unique(babip$Team)) {
  df <- filter(babip, Team == team)
  df$flag <- factor(df$flag, levels = c("before", "after"))
  cat(team, "\n", "\n")
  print(oneway_test(BABIP ~ flag, data = df, distribution = "exact"))
  cat("\n", "\n")
  print(wilcox_test(BABIP ~ flag, data = df, distribution = "exact"))
  cat("\n", "\n")
}

# wOBA
for(team in unique(woba$Team)) {
  df <- filter(woba, Team == team)
  df$flag <- factor(df$flag, levels = c("before", "after"))
  cat(team, "\n", "\n")
  print(oneway_test(wOBA ~ flag, data = df, distribution = "exact"))
  cat("\n", "\n")
  print(wilcox_test(wOBA ~ flag, data = df, distribution = "exact"))
  cat("\n", "\n")
}

# wRC+
colnames(wrc)[2] <- "wRCplus"

for(team in unique(wrc$Team)) {
  df <- filter(wrc, Team == team)
  df$flag <- factor(df$flag, levels = c("before", "after"))
  cat(team, "\n", "\n")
  print(oneway_test(wRCplus ~ flag, data = df, distribution = "exact"))
  cat("\n", "\n")
  print(wilcox_test(wRCplus ~ flag, data = df, distribution = "exact"))
  cat("\n", "\n")
}

colnames(wrc)[2] <- "wRC+"


# read fangraphs article and past research projects
# think of ways to nicely format visuals and everything for report


# latex tables for output from print_means()
# make boxplots team colors


# for models predicting offense from various ballpark characteristics, some possible covariates are:
# distance to each of 5 points in outfield, average fence distance, deepest part, avg temp of park,
# fence height, fair territory area, foul territory area, size of batter's eye, 
# orientation of home plate (facing west, east, etc.)
