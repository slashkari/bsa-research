# sources:
# https://ballparks.com/baseball/
# https://www.baseball-almanac.com/stadium/fenway_park.shtml
dim_changes <- data.frame("team" = c("Baltimore Orioles", "Baltimore Orioles",
                                     rep("Boston Red Sox", 11),
                          "name" = c("Camden Yards", "Camden Yards",
                                     rep("Fenway Park", 11)),
                          "left" = c(333, 337, 333, 324),
                          "left_center" = c(364, 376, 364, ),
                          "center" = c(400, 407, 400),
                          "right_center" = c(373, 391, 373),
                          "right" = c(318, 320, 318),
                          "deepest" = c(410, 417, 410)
                          "years_active" = c("1992-2000", "2001", "2002-present"))