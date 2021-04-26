library(dplyr)
library(readr)
library(rvest)

run_pct <- read_csv("data/run_pct.csv")
hr_pct <- read_csv("data/hr_pct.csv")
rates <- read_csv("data/rates.csv")

# get babip data from fangraphs
babip <- data.frame("team" = c(rep("HOU", 9), rep("MIA", 9)), 
                    "location" = rep("home", 59),
                    "babip" = c(0.292, 0.292, 0.303, 0.292, 0.291, 0.302, 0.282, 0.308, 0.270,
                                ),
                    "year" = c(2012:2020, 2012:2020))
# twins

