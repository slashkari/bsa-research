library(dplyr)
library(readr)
library(rvest)
library(coin)

source("bsa_funs.R")

run_pct <- read_csv("data/run_pct.csv")
hr_pct <- read_csv("data/hr_pct.csv")
rates <- read_csv("data/rates.csv")

# read in babip data created from babip_data.py
babip <- read_csv("data/babip_data.csv")



# maybe compare team babips to overall franchise babip? different teams might have different 
# franchise babips because there's a specific type of player profile they sign, or because of 
# their park factors. # fangraphs says certain players can maintain babips that differ a lot from
# league average of .300, the same MIGHT be true for teams.

# could also look a pull%, center%, oppo% on fangraphs. if left field is moved in significantly
# right handed batters might try to go oppo more. try to look at splits (e.g. oppo% for right handed
# batters, pull% for lefties if left field is moved in)


# add flag variable
flag <- run_pct %>% filter(location == "home") %>% select(flag)
babip <- cbind(babip, flag)


# plot side by side boxplots for each team for df of given stat
plot_side <- function(data) {
  flag <- run_pct %>% filter(location == "home") %>% select(flag)
  data <- cbind(data, flag)
  
  copy <- data
  copy$flag <- factor(copy$flag, levels = c("before", "after"))

  p <- ggplot(copy, aes(x = flag, y = BABIP, fill = flag))
  p <- p + geom_boxplot() + facet_wrap(~ Team)
  p <- p + labs(xlab = "Time Relative to Fence Change", fill = "flag")
  p
}

plot_side(babip)

# print out means of each team before and after
# stat is a string of how you want the stat displayed when printing (e.g. "BB%", "BABIP", "wRC+")
# percent = FALSE means stat is a real number and will be rounded to 3 places
# percent = TRUE means stat is a percentage, % will be appended to stat when printing
print_means <- function(data, stat, percent = FALSE) {
  for(team in unique(data$Team)) {
    before <- data %>% filter(Team == team, flag == "before")
    after <- data %>% filter(Team == team, flag == "after")
  
    if(team == unique(data$Team)[1]) {
      cat("Mean Team", stat, "Before and After Dimension Change:", "\n", sep = "")
    }
    if(percent == FALSE) {
      cat(team, ": ", "Before - ", format(round(mean(before$BABIP), 3), nsmall = 3), ", ", 
          "After - ", format(round(mean(after$BABIP), 3), nsmall = 3), "\n", sep = "")
    }
    else {
      cat(team, ": ", "Before - ", paste0(stat, "%"), ", ", "After - ", paste0(stat, "%"), "\n", sep = "")
    }
  }
}

print_means(babip, "BABIP", percent = FALSE)


# plot distributions overlayed each other



# one way permutation test and wilcox test for each team
# NO SIGNIFICANT RESULTS
for(team in unique(babip$Team)) {
  df <- filter(babip, Team == team)
  df$flag <- factor(df$flag, levels = c("before", "after"))
  cat(team, "\n", "\n")
  print(oneway_test(BABIP ~ flag, data = df, distirbution = "exact"))
  cat("\n", "\n")
  print(wilcox_test(BABIP ~ flag, data = df, distribution = "exact"))
  cat("\n", "\n")
  
}

