library(tidyverse)
library(randomForest)

park <- read_csv("data/park_factors.csv")

# get rid of row 707 (NA for some reason)
park <- park[-707, ]

# get rid of % sign in BBrate and Krate
park$BBrate <- gsub("%$", "", park$BBrate)
park$Krate <- gsub("%$", "", park$Krate)

# get rid of % in average humidity
park$`Average Humidity` <- gsub("%$", "", park$`Average Humidity`)

# change BBrate, Krate, Average Humidity into numeric data type
park$BBrate <- as.numeric(park$BBrate)
park$Krate <- as.numeric(park$Krate)
park$`Average Humidity` <- as.numeric(park$`Average Humidity`)

# change categorical variables into factors
park$roof_status <- factor(park$roof_status, levels = c(0, 1, 2))

park$turf_status <- factor(park$turf_status, levels = c(0, 1))

# make all col names one word for randomForest()
colnames(park)[26:28] <- c("elevation", "humidity", "avg_temp_summer")


# df of just wRC+ and park factors (no other offensive stats)
park_wrc <- park[, -c(2:15, 17)]
wrc_mod <- randomForest(wRCplus ~ . - Team - Year, data = park_wrc)
importance(wrc_mod)

# HR df
park_hr <- park[, -c(2:3, 5:17)]
hr_mod <- randomForest(HR ~ . - Team - Year, data = park_hr)
class(importance(hr_mod))

# BABIP df
park_babip <- park[, -c(2:10, 12:17)]
babip_mod <- randomForest(BABIP ~ . - Team - Year, data = park_babip)
importance(babip_mod)

# ISO df
park_iso <- park[, -c(2:9, 11:17)]
iso_mod <- randomForest(ISO ~ . - Team - Year, data = park_iso)
importance(iso_mod)




sorted_names_hr <- c("fair_area", "foul_area", "Wind", "Deepest", "Elevation", "Temp", "Ocean", 
                     "Direction", "avg_summer_temp", "Humidity", "turf_status", "roof_status")
hr_imp <- data.frame(x = sorted_names_hr, 
                     y = sort(importance(hr_mod), decreasing = TRUE))

ggplot(hr_imp, aes(x = x, y = y)) + geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) + ylab("Node Purity") +
  coord_flip()

iso_imp <- data.frame(x = rownames(importance(iso_mod)), 
                      y = sort(importance(iso_mod)))

ggplot(iso_imp, aes(x = x, y = y)) + geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) + ylab("Node Purity") +
  coord_flip()
