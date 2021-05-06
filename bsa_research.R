library(tidyverse)
library(rvest)
library(car)
dims <- read_csv("data/ballpark_dims2.csv")
# first create simple model predicting wRC+ or percent runs scored at home
# from predictors deepest, mean distance change, absolute distance changes
# (one for left, left-center, etc.)

colnames(dims)[9] <- "years_active" # rename years column

# --------------get run info for 5 years before and 5 years after dimension change----------------


# vectors of team abbreviations and years to create vector of sites to loop through
team_abbrevs <- c(rep("HOU", 9), rep("FLA", 2), rep("MIA", 9), rep("SDP", 10), 
                  rep("SEA", 10), rep("ATL", 9), rep("MIN", 10))
years <- c(2012:2020, 2010:2020, 2008:2017, 2008:2017, 2012:2020, 2005:2014)

# map teams to their abbreviations to use in loop
# team_map <- data.frame(team = unique(dims$team), abbrev = c(unique(team_abbrevs)))


# sites to loop through
sites <- paste("https://www.baseball-reference.com/teams/tgl.cgi?team=", team_abbrevs, 
              "&t=b&year=", years, sep = "")


# initialize df to store percentage of runs and home runs scored at home and away for each
# team for a given year
rates_df <- data.frame(team = c(), location = c(), run_precent = c(), hr_percent = c(), year = c())




# fill rates_df
for(page in sites) {
  info <- page %>% read_html() # extract html from webpage
  
  # get runs, home runs, and location (home/away) for each game of season
  table <- info %>%
    html_nodes(".right:nth-child(9) , .right:nth-child(13) , .right:nth-child(4)") %>%
    html_text()
  
  # table is a character vector of the info, last element is html node info
  # delete unneeded last element
  table <- table[-length(table)]
  
  # format vector into tabular format
  # first col is location, second col is runs, third col is home runs
  table <- matrix(table, nrow = length(table) / 3, ncol = 3, byrow = TRUE)
  
  table <- gsub("@", "away", table)
  table <- gsub("^$", "home", table)
  
  # convert to matrix, clean up 
  table <- as_tibble(table, .name_repair = "minimal")
  colnames(table) <- c("location", "runs", "home_runs")
  table$runs <- as.numeric(table$runs)
  table$home_runs <- as.numeric(table$home_runs)
  
  # seasonal totals for computation of rates
  run_total <- sum(table$runs)
  hr_total <- sum(table$home_runs)
  
  # get team name and year from url
  team <- str_extract(page, "[A-Z]{3}")
  year <- str_extract(page, "\\d{4}")
  
  # compute run and home run rates for home and away games
  rates <- table %>% group_by(location) %>% summarise(run_percent = sum(runs) / run_total,
                                                      hr_percent = sum(home_runs) / hr_total)
  rates <- add_column(rates, team = rep(team, 2), .before = "location")
  rates <- add_column(rates, year = rep(year, 2), .after = "hr_percent")
  
  rates_df <- rbind(rates_df, rates)
}

# some histograms of run percentage and home run percentage
# both distributions appear normal which makes sense
hist(rates_df$run_percent)
hist(rates_df$hr_percent)

# idea (would take a lot of work): compute average fence distances for all 5 "points" of the fence
# for each team's opponent's ballpark.
# use these 5 averages as a predictor of run percentage, run lin reg 

# ----------------------------------------combine dfs--------------------------------------------
# first add average fence distance to column to dims 
dims <- add_column(dims, avg_dist = rowMeans(dims[, 3:7]), .before = "years_active")

# add avg distances to rates_df by corresponding year
rates_df <- add_column(rates_df, avg_dist = c(rep(362.4, 10), rep(357, 8), rep(375, 12),
                                              rep(372.8, 8), rep(370.4, 2), rep(371.6, 10),
                                              rep(367, 10), rep(367.4, 10), rep(363.4, 10),
                                              rep(367, 10), rep(364, 8), rep(366, 10),
                                              rep(363, 10)), .before = "year")


# create dfs for t tests of run pct and home run pct for each team
# create flag variable signifying if season was before or after dimension changes
run_pct <- cbind.data.frame(rates_df[, 1:3],
                            flag = factor(c(rep("before", 10), rep("after", 8),
                                            rep("before", 12), rep("after", 10),
                                            rep("before", 10), rep("after", 10),
                                            rep("before", 10), rep("after", 10),
                                            rep("before", 10), rep("after", 8),
                                            rep("before", 10), rep("after", 10))))

hr_pct <- cbind.data.frame(rates_df[, c(1, 2, 4)],
                           flag = factor(c(rep("before", 10), rep("after", 8),
                                           rep("before", 12), rep("after", 10),
                                           rep("before", 10), rep("after", 10),
                                           rep("before", 10), rep("after", 10),
                                           rep("before", 10), rep("after", 8),
                                           rep("before", 10), rep("after", 10))))

# t test
# test if mean run percentage of runs scored at home is different before and after dim change
# H_0: means are equal before and after dim change
# H_a: mean are not equal

x <- filter(run_pct, flag == "before", location == "home") %>% select(run_percent)
y <- filter(run_pct, flag == "after", location == "home") %>% select(run_percent)
t.test(x$run_percent, y$run_percent)

# FAILED TO REJECT NULL

# t test
# test if mean home run percentage at home is diff before and after dim change
# H_0: means are equal before and after dim change
# H_a: means are not equal

x <- filter(hr_pct, flag == "before", location == "home") %>% select(hr_percent)
y <- filter(hr_pct, flag == "after", location == "home") %>% select(hr_percent)
t.test(x$hr_percent, y$hr_percent)

# FAILED TO REJECT NULL



# t tests and boxplots for each team
# -----------------------------------------Houston Astros-----------------------------------------
# run_pct
x <- filter(run_pct, flag == "before", location == "home", team == "HOU") %>% select(run_percent)
y <- filter(run_pct, flag == "after", location == "home", team == "HOU") %>% select(run_percent)
t.test(x$run_percent, y$run_percent)
par(mfrow = c(1, 2))
# run pct boxplot
box_df <- run_pct %>% filter(location == "home", team == "HOU") # make df suitable for boxplots
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(run_percent ~ flag, col = "orange", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Runs Scored at Home",
        main = "Houston Astros")

# home run pct
x <- filter(hr_pct, flag == "before", location == "home", team == "HOU") %>% select(hr_percent)
y <- filter(hr_pct, flag == "after", location == "home", team == "HOU") %>% select(hr_percent)
t.test(x$hr_percent, y$hr_percent)
# statistically significant but home hr_pct after the change is less than before

# home run pct boxplot
box_df <- hr_pct %>% filter(location == "home", team == "HOU") # make df suitable for boxplots
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(hr_percent ~ flag, col = "orange", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Home Runs at Home",
        main = "Houston Astros")



# -----------------------------------------Miami Marlins------------------------------------------
# run_pct
x <- filter(run_pct, flag == "before", location == "home", team == c("FLA", "MIA")) %>% 
  select(run_percent)
y <- filter(run_pct, flag == "after", location == "home", team == c("FLA", "MIA")) %>% 
  select(run_percent)
t.test(x$run_percent, y$run_percent)

# run pct boxplot
box_df <- run_pct %>% filter(location == "home", team %in% c("FLA", "MIA"))
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(run_percent ~ flag, col = "cyan", data = box_df, 
        ylab = "Proportion of Runs Scored at Home",
        main = "Miami Marlins")

# home run pct
x <- filter(hr_pct, flag == "before", location == "home", team == c("FLA", "MIA")) %>% 
  select(hr_percent)
y <- filter(hr_pct, flag == "after", location == "home", team == c("FLA", "MIA")) %>% 
  select(hr_percent)
t.test(x$hr_percent, y$hr_percent)

# home run pct boxplot
box_df <- hr_pct %>% filter(location == "home", team %in% c("MIA", "FLA")) # make df suitable for boxplots
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(hr_percent ~ flag, col = "cyan", data = box_df, 
        ylab = "Proportion of Home Runs at Home",
        main = "Miami Marlins")





# ---------------------------------------San Diego Padres-----------------------------------------
# run_pct
x <- filter(run_pct, flag == "before", location == "home", team == "SDP") %>% select(run_percent)
y <- filter(run_pct, flag == "after", location == "home", team == "SDP") %>% select(run_percent)
t.test(x$run_percent, y$run_percent)

# run pct boxplot
box_df <- run_pct %>% filter(location == "home", team == "SDP")
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(run_percent ~ flag, col = "darkgoldenrod", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Runs Scored at Home",
        main = "San Diego Padres")

# home run pct
x <- filter(hr_pct, flag == "before", location == "home", team == "SDP") %>% select(hr_percent)
y <- filter(hr_pct, flag == "after", location == "home", team == "SDP") %>% select(hr_percent)
t.test(x$hr_percent, y$hr_percent)

# home run pct boxplot
box_df <- hr_pct %>% filter(location == "home", team == "SDP") # make df suitable for boxplots
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(hr_percent ~ flag, col = "darkgoldenrod", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Home Runs at Home",
        main = "San Diego Padres")





# --------------------------------------Seattle Mariners------------------------------------------
# run_pct
x <- filter(run_pct, flag == "before", location == "home", team == "SEA") %>% select(run_percent)
y <- filter(run_pct, flag == "after", location == "home", team == "SEA") %>% select(run_percent)
t.test(x$run_percent, y$run_percent)

# run pct boxplot
box_df <- run_pct %>% filter(location == "home", team == "SEA")
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(run_percent ~ flag, col = "darkslategray", data = box_df, 
        ylab = "Proportion of Runs Scored at Home",
        main = "Seattle Mariners")

# home run pct
x <- filter(hr_pct, flag == "before", location == "home", team == "SEA") %>% select(hr_percent)
y <- filter(hr_pct, flag == "after", location == "home", team == "SEA") %>% select(hr_percent)
t.test(x$hr_percent, y$hr_percent)

# home run pct boxplot
box_df <- hr_pct %>% filter(location == "home", team == "SEA") # make df suitable for boxplots
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(hr_percent ~ flag, col = "darkslategray", data = box_df, 
        ylab = "Proportion of Home Runs at Home",
        main = "Seattle Mariners")




# ---------------------------------------Atlanta Braves-------------------------------------------
# run_pct
x <- filter(run_pct, flag == "before", location == "home", team == "ATL") %>% select(run_percent)
y <- filter(run_pct, flag == "after", location == "home", team == "ATL") %>% select(run_percent)
t.test(x$run_percent, y$run_percent)

# run pct boxplot
box_df <- run_pct %>% filter(location == "home", team == "ATL")
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(run_percent ~ flag, col = "darkred", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Runs Scored at Home",
        main = "Atlanta Braves")

# home run pct
x <- filter(hr_pct, flag == "before", location == "home", team == "ATL") %>% select(hr_percent)
y <- filter(hr_pct, flag == "after", location == "home", team == "ATL") %>% select(hr_percent)
t.test(x$hr_percent, y$hr_percent)

# home run pct boxplot
box_df <- hr_pct %>% filter(location == "home", team == "ATL") # make df suitable for boxplots
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(hr_percent ~ flag, col = "darkred", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Home Runs at Home",
        main = "Atlanta Braves")




# -------------------------------------Minnesota Twins--------------------------------------------
# run_pct
x <- filter(run_pct, flag == "before", location == "home", team == "MIN") %>% select(run_percent)
y <- filter(run_pct, flag == "after", location == "home", team == "MIN") %>% select(run_percent)
t.test(x$run_percent, y$run_percent)

# run pct boxplot
box_df <- run_pct %>% filter(location == "home", team == "MIN")
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(run_percent ~ flag, col = "steelblue4", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Runs Scored at Home",
        main = "Minnesota Twins")

# home run pct
x <- filter(hr_pct, flag == "before", location == "home", team == "MIN") %>% select(hr_percent)
y <- filter(hr_pct, flag == "after", location == "home", team == "MIN") %>% select(hr_percent)
t.test(x$hr_percent, y$hr_percent)

# home run pct boxplot
box_df <- hr_pct %>% filter(location == "home", team == "MIN") # make df suitable for boxplots
box_df$flag <- factor(box_df$flag, levels = c("before", "after")) # intuitively order the plots
boxplot(hr_percent ~ flag, col = "steelblue4", data = box_df, 
        xlab = "Time Relative to Fence Change", ylab = "Proportion of Home Runs at Home",
        main = "Minnesota Twins")



# Conclusions: Hardly any of the t tests are significant. Samples sizes of 5 in each sample for the 
# test is likely too small though, so differences could still be detected.
# See if the samples are normal: Wilk-Shapiro test, see if the residuals are normally distributed?



# export run_pct, hr_pct and rates_df dataframes
# write.csv(run_pct, file = "run_pct.csv", row.names = FALSE)
# write.csv(hr_pct, file = "hr_pct.csv", row.names = FALSE)
# write.csv(rates_df, file = "rates.csv", row.names = FALSE)
