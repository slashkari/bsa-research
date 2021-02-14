library(tidyverse)
library(rvest)
dims <- read_csv("ballpark_dims2.csv")
# first create simple model predicting wRC+ or percent runs scored at home
# from predictors deepest, mean distance change, absolute distance changes
# (one for left, left-center, etc.)

colnames(dims)[9] <- "years_active" # rename years column

# --------------get run info for 3 years before and 3 years after dimension change----------------


# vectors of team abbreviations and years to create vector of sites to loop through
team_abbrevs <- c(rep("HOU", 6), rep("MIA", 9), rep("SDP", 6), 
                  rep("SEA", 6), rep("ATL", 6), rep("MIN", 6))
years <- c(2014:2019, 2012:2020, 2010:2015, 2010:2015, 2014:2019, 2007:2012)

# map teams to their abbreviations to use in loop
team_map <- data.frame(team = unique(dims$team), abbrev = c(unique(team_abbrevs)))


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






