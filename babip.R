library(dplyr)
library(readr)
library(rvest)

run_pct <- read_csv("data/run_pct.csv")
hr_pct <- read_csv("data/hr_pct.csv")
rates <- read_csv("data/rates.csv")

# read in babip data created from babip_data.py
babip <- read_csv("data/babip_data.csv")

