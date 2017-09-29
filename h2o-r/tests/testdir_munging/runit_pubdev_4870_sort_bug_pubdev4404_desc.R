setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source("../../scripts/h2o-r-test-setup.R")
library(testthat)

# test float sort with more than one columns.  A bug was found in PUBDEV-4870.
test.sort = function() {

  X = h2o.uploadFile(locate("smalldata/synthetic/smallIntFloats.csv.zip"))
  sorted_column_indices = c(1,2)
  print("Performing descending sort....")
  X_sorted = h2o.arrange(X, C1, C10, sortDir="DESC")
  check_sorted_two_columns(X_sorted, sorted_column_indices, prob=0.001, sortDir="DESC")
  print("Performing ascending sort....")
  X_sorted = h2o.arrange(X, C1, C10, sortDir="ASC")
  check_sorted_two_columns(X_sorted, sorted_column_indices, prob=0.001)
}

check_sorted_two_columns <- function(frame, column_indices, prob=0.5, sortDir="ASC") {
  for (colInd in column_indices) {
    for (rowInd in c(1:(h2o.nrow(frame)-1))) {
      if (runif(1,0,1) < prob) {
        if (colInd == column_indices[1]) {  # comparison for first column
          if ("ASC" %in% sortDir) {
            expect_true(frame[rowInd, colInd] <= frame[rowInd+1, colInd], info="Wrong sorting")
          } else {
            expect_true(frame[rowInd, colInd] >= frame[rowInd+1, colInd], info="Wrong sorting")
          }
        } else {
          if (frame[rowInd, column_indices[1]] == frame[rowInd+1, column_indices[1]]) {
            if ("ASC" %in% sortDir) {
              expect_true(frame[rowInd, colInd] <= frame[rowInd+1, colInd], info="Wrong sorting")
            } else {
              expect_true(frame[rowInd, colInd] >= frame[rowInd+1, colInd], info="Wrong sorting")              
            }
          }
        }
      }
    }
  }
}

doTest("Test sort H2OFrame", test.sort)

