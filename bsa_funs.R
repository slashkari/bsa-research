library(dplyr)




#' extract_stat()
#'
#' Extracts desired test statistic from dataframe
#'
#' @param x dataframe to get stat from
#' @param stat string of desired statistic, needs to match column name in df 
#'
#' @return numeric vector length 1
#' 
extract_stat <- function(x, stat) {
  before <- filter(x, flag == "before")
  before <- before[, stat]
  after <- filter(x, flag == "after")
  after <- after[, stat]
  output <- mean(after) - mean(before)
  output
}





# could cap it if num of permutations is too large
perm_func <- function(df, stat) {
  k <- nrow(filter(df, flag == "before"))
  n <- choose(nrow(df), k) # number of permutations of data
  perms <- list()
  index <- 0
  while(length(perms) != n) {
    index <- index + 1
    
    # generate new possible permutation
    possible_perm <- data.frame(stat = sample(df[, stat]), "flag" = df$flag)
    colnames(possible_perm)[1] <- stat
    
    # special condition when list is empty
    if(length(perms) == 0) { 
      perms[[index]] <- possible_perm
    } 
    else {
      
      # check if possible df is equal to any other current dfs in output list
      for(i in 1:length(perms)) {
        if(identical(possible_perm, perms[[i]])) break 
        if(i == length(perms)) perms[[i + 1]] <- possible_perm
      }
    }
  }
  
  perms
}






bootstrap_all <- function(data, stat) {
  before_n <- nrow(filter(data, flag == "before"))
  after_n <- nrow(filter(data, flag == "after"))
  before <- filter(data, flag == "before")
  after <- filter(data, flag == "after")
  before_i <- sample(before_n, replace = TRUE)
  after_i <- sample(after_n, replace = TRUE)
  before <- before[before_i, ]
  after <- after[after_i, ]
  output <- list("before" = before[, stat], "after" = after[, stat])
  output
}






cdf_overlayed <- function(dist, color, team) {
  s <- seq(range(dist)[1], range(dist)[2], by = 0.0001)
  plot(s, pnorm(s, mean = mean(dist), sd = sd(dist)), col = color, lwd = 3, xlab = "x",
       ylab = "probability", main = team)
  lines(ecdf(dist), cex = 0.5)
}






hist_overlayed <- function(dist, color, team) {
  s <- seq(range(dist)[1], range(dist)[2], by = 0.00001)
  hist(dist, xlab = "x", ylab = "density", main = team, freq = FALSE)
  lines(s, dnorm(s, mean = mean(dist), sd = sd(dist)), col = color, lwd = 2)
}






cdf_overlayed_test <- function(dist, color, team) {
  s <- seq(range(dist)[1], range(dist)[2], by = 0.0001)
  plot(s, pnorm(s, mean = mean(dist), sd = sd(dist)), col = color, lwd = 3, xlab = "x",
       ylab = "probability", main = team)
  lines(ecdf(dist), cex = 0.5)
}
