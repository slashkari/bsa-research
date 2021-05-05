library(dplyr)



# function to extract test statistic from a permuted dataframe
# test statistic is mean difference between run props before and after dim change
extract_stat <- function(x) {
  before <- filter(x, flag == "before")$run_percent
  after <- filter(x, flag == "after")$run_percent
  stat <- mean(after) - mean(before)
  stat
}






perm_func <- function(df) {
  k <- nrow(filter(df, flag == "before"))
  n <- choose(nrow(df), k) # number of permutations of data
  perms <- list()
  index <- 0
  while(length(perms) != n) {
    index <- index + 1
    
    # generate new possible permutation
    possible_perm <- data.frame("run_percent" = sample(df$run_percent), "flag" = df$flag)
    
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




bootstrap_all <- function(data) {
  before <- filter(data, flag == "before", location == "home")
  after <- filter(data, flag == "after", location == "home")
  before_i <- sample(before_n, replace = TRUE)
  after_i <- sample(after_n, replace = TRUE)
  before <- before[before_i, ]
  after <- after[after_i, ]
  output <- list("before" = before$run_percent, "after" = after$run_percent)
  output
}





