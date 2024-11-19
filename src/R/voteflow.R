library(dplyr)
library(tidyr)
library(MASS)

cite_voteflow <- function() {
  cat("[Done with github.com/ldesio/VoteFlow (Corbetta, De Sio, and Schadee 2024)]\n")
	cat("Please cite:")
	cat("- Corbetta, Pier Giorgio, and Henri M. A Schadee. 1984. Metodi e modelli di analisi dei dati elettorali. Bologna: Il Mulino.")
	cat("- De Sio, Lorenzo, Corbetta, Pier Giorgio and Henri M.A. Schadee, 2024. 'VOTEFLOW: Vote flow estimation through Goodman ecological regression and coefficient adjustment via RAS iterative proportional fitting, as systematized by Corbetta and Schadee (1984)'', https://github.com/ldesio/VoteFlow")
}

voteflow <- function(data, deps, indeps, nooutput=FALSE, save_path=NULL, filter_expr=NULL, force=FALSE, autoexclude=FALSE, sankey=FALSE) {
  # Initialize variables
  data$indeptotal <- rowSums(data[ , indeps])
  data$deptotal <- rowSums(data[ , deps])
  data$variation <- abs((data$deptotal - data$indeptotal) / data$indeptotal)
  avgsize <- mean(data$indeptotal)
  data$relsize <- data$indeptotal / avgsize
  data$touse <- rep(TRUE, nrow(data))

  # Start processing
  cat("\nVOTEFLOW: Initializing...\n")

  # Calculating marginals on the entire dataset
  cat(sprintf("Calculating marginals on entire dataset (%d units)...\n", sum(data$touse)))

  # COL marginals (indeps)
  col_marginals <- colSums(data[ , indeps])
  total_col <- sum(col_marginals)
  col_margs <- (col_marginals / total_col) * 100

  # ROW marginals (deps)
  row_marginals <- colSums(data[ , deps])
  total_row <- sum(row_marginals)
  row_margs <- (row_marginals / total_row) * 100

  # Filtered dataset
  if (!is.null(filter_expr)) {
    # data <- data %>% filter(eval(parse(text=filter_expr)))
    cat(sprintf("Analysis will be performed on the filtered dataset (%d units).\n", nrow(data)))
  } else {
    cat(sprintf("Analysis will be performed on the unfiltered dataset (%d units).\n", nrow(data)))
    filter_expr <- "1==1"
  }

  proceed <- TRUE

  cat("\nPerforming basic checks (Schadee and Corbetta 1984):\n")

  # Average unit size check
  cat(sprintf("- Average unit size (sum of indeps) is %1.0f... ", avgsize))
  if (avgsize > 1200) {
    cat("\n  this is discouraged: large units increase risk of ecological fallacy (warning threshold is 1200).\n")
    proceed <- FALSE
  } else {
    cat("OK.\n")
  }

  # Units changed in size by more than 15%
  changed_units <- sum(data$variation >= 0.15 | is.na(data$variation))
  cat(sprintf("- %d units changed in size by more than 15%%... ", changed_units))
  if (changed_units > 0) {
    if (!autoexclude) {
      cat("\n  they should be excluded. Use 'autoexclude' option to exclude them automatically.\n")
      proceed <- FALSE
    } else {
      cat("\n  automatically excluding them, as 'autoexclude' option was specified.\n")
      
      newfilter <- "(data$variation < 0.15 | is.na(data$variation))"
    }
  } else {
    cat("OK.\n")
  }

  # Units with size less than 20% the average
  small_units <- sum(data$relsize < 0.20)
  cat(sprintf("- %d units have a size less than 20%% the average unit size... ", small_units))
  if (small_units > 0) {
    if (!autoexclude) {
      cat("\n  they should be excluded. Use 'autoexclude' option to exclude them automatically.\n")
      proceed <- FALSE
    } else {
      cat("\n  automatically excluding them, as 'autoexclude' option was specified.\n")
      newfilter <- paste(newfilter, "data$relsize >= 0.20", sep=" & ")
    }
  } else {
    cat("OK.\n")
  }

  data <- data %>% filter(eval(parse(text=paste(filter_expr,newfilter, sep=" & "))))
  
  
  # Check N
  num_coeff <- length(deps) * length(indeps)
  cat(sprintf("- You are trying to estimate (%d * %d) = %d coefficients with %d units... ", length(indeps), length(deps), num_coeff, nrow(data)))
  if ((num_coeff * 2) > nrow(data)) {
    cat("\n  this is not allowed (at least 2 units per coefficient are needed).\n")
    proceed <- FALSE
  } else {
    cat("OK.\n")
  }

  if (!proceed & !force) {
    cat("Exiting.\n")
    return(NULL)
  }
  if (!proceed) {
    cat("YOU CHOSE TO PROCEED BY IGNORING THE ABOVE WARNINGS: RESULTS WILL LIKELY BE INCORRECT. YOU HAVE BEEN WARNED.\n")
  }

  cat(sprintf("Analysis will be performed on %d units.\n", nrow(data)))
  cat("\nEstimating regression models:\n")

  # Running regression models
  rsq <- c()
  b_matrix <- NULL
  for (v in deps) {
    cat(sprintf("%s ", v))
    formula <- as.formula(paste(v, "~", paste(indeps, collapse = "+"), "-1"))
    # model <- lm(as.formula(paste(v, paste(indeps, collapse = " + "), sep = " ~ ")), data = data)
    model <- lm(formula, data = data)
    rsq <- c(rsq, summary(model)$r.squared)
    b <- coef(model) 
    if (is.null(b_matrix)) {
      b_matrix <- matrix(b, nrow=1)
    } else {
      b_matrix <- rbind(b_matrix, b)
    }
  }
  cat(".\n")

  # Converting b's to cell values in percentages over total
  b_abs <- b_matrix
  rownames(b_abs) <- deps
  colnames(b_abs) <- indeps

  # Multiply by col marginals to yield values in percentages over total
  for (i in seq_along(indeps)) {
    b_abs[, i] <- b_matrix[, i] * (col_margs[i])
  }

  if (!nooutput) {
    cat("\nRaw coefficients:\n")
    print((b_matrix))
    cat("\nRaw percentages (over total):\n")
    print((b_abs))
  }

  cat("\nResetting unacceptable coefficients...\n")
  # Resetting negative values to zero
  vr <- 0
  
  rcount <- nrow(b_abs)
  ccount <- ncol(b_abs)
  
  for (i in 1:rcount) {
    for (j in 1:ccount) {
      coeff <- b_abs[i, j]  # Access the element at (i, j)
      if (coeff < 0) {      # Check if the element is negative
        b_abs[i, j] <- 0    # Set the element to 0
        vr <- vr + abs(coeff)  # Add the absolute value of the negative element to `vr`
      }
    }
  }
  
  
  # Adjusting matrix through RAS
  maxdiff <- 100
  iter <- 1
  cat("RAS iterations: ")
  while (maxdiff > 0.001 & iter < 400) {
    cat(".")
    maxdiff1 <- 0
    for (i in 1:nrow(b_abs)) {
      row_sum <- sum(b_abs[i, ])
      ratio <- row_margs[i] / sum(b_abs[i, ])
      b_abs[i, ] <- b_abs[i, ] * ratio
      diff <- abs(row_margs[i] - row_sum)
      maxdiff1 <- max(maxdiff1, diff)
    }

    maxdiff2 <- 0
    for (i in 1:ncol(b_abs)) {
      col_sum <- sum(b_abs[, i])
      ratio <- col_margs[i] / sum(b_abs[, i])
      b_abs[, i] <- b_abs[, i] * ratio
      diff <- abs(col_margs[i] - col_sum)
      maxdiff2 <- max(maxdiff2, diff)
    }
    
    maxdiff <- max(maxdiff1, maxdiff2)
    iter <- iter + 1
  }
  cat(sprintf("%d iterations.\n", iter))

  # Creating matrices in destination (col) and source (row) percentages
  b_dest <- sweep(b_abs, 2, col_margs, "/") * 100
  b_src <- sweep(b_abs, 1, row_margs, "/") * 100

  if (!nooutput) {
    cat(sprintf("\nDiagnostic VR: %4.1f\n", vr))
    if (vr > 10) {
      cat("VR values above 10 suggest caution; above 15, results should be discarded.\n")
    }
    cat("\nAdjusted percentages (over total):\n")
    print(b_abs)
    cite_voteflow()
  }

# Helper function to write tables with initial tab before column headers
  write_table_with_tab <- function(mat, file_conn, title) {
    writeLines(title, file_conn)
    cat("\t", file = file_conn)  # Adds an initial tab before column headers
    write.table(mat, file = file_conn, sep = "\t", row.names = TRUE, col.names = TRUE, quote = FALSE, append = TRUE)
    writeLines("\n", file_conn)
  }
  
  # Write output to a single text file if save_path is specified
  if (!is.null(save_path)) {
    file_conn <- file(save_path, "w")
    
    # Write b_matrix with labels
    write_table_with_tab(b_matrix, file_conn, "Original Coefficients (b_matrix):")
    
    # Write R-squared values with an initial tab before column headers
    writeLines("R-squared values:", file_conn)
    cat("\t", file = file_conn)
    rsq_df <- data.frame(R_squared = rsq, row.names = deps)
    write.table(rsq_df, file = file_conn, sep = "\t", row.names = TRUE, col.names = TRUE, quote = FALSE, append = TRUE)
    writeLines("\n", file_conn)
    
    # Write b_abs with labels
    write_table_with_tab(b_abs, file_conn, "Adjusted Total Percentages Matrix (b_abs):")
    writeLines(sprintf("Diagnostic VR: %.1f\n", vr), file_conn)
    
    # Write b_src with labels
    write_table_with_tab(b_src, file_conn, "Adjusted Source Percentages Matrix (b_src):")
    
    # Write b_dest with labels
    write_table_with_tab(b_dest, file_conn, "Adjusted Destination Percentages Matrix (b_dest):")
    
    close(file_conn)
    cat("Output saved in", save_path, "\n")
  }
  
  # Return all matrices and diagnostics as a list
  list(b_matrix = b_matrix, b_abs = b_abs, b_src = b_src, b_dest = b_dest, rsq = rsq, vr = vr, iterations = iter)
}

