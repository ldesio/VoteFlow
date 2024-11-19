voteflow <- function(deps, indeps, data, verbose = FALSE, save_path = NULL, filter = NULL) {
  
  # Prepare column and row margins
  col_totals <- sapply(indeps, function(var) sum(data[[var]], na.rm = TRUE))
  total_col_sum <- sum(col_totals)
  col_margins <- (col_totals / total_col_sum) * 100
  
  row_totals <- sapply(deps, function(var) sum(data[[var]], na.rm = TRUE))
  total_row_sum <- sum(row_totals)
  row_margins <- (row_totals / total_row_sum) * 100
  
  # Perform regressions and store coefficients
  b_matrix <- matrix(NA, nrow = length(deps), ncol = length(indeps), dimnames = list(deps, indeps))
  rsq_list <- numeric(length(deps))
  
  for (i in seq_along(deps)) {
    response_var <- deps[i]
    formula <- as.formula(paste(response_var, "~", paste(indeps, collapse = "+"), "-1"))
    if (!is.null(filter)) {
      fit <- lm(formula, data = subset(data, eval(parse(text = filter))))
    } else {
      fit <- lm(formula, data = data)
    }
    b_matrix[i, ] <- fit$coefficients
    rsq_list[i] <- summary(fit)$r.squared
  }
  
  # Convert coefficients to percentages over the total
  b_abs <- sweep(b_matrix, 2, col_margins, "*")
  
  if (verbose) {
    print("Raw Coefficients (b_matrix):")
    print(b_matrix)
    
    print("Percentage Coefficients (b_abs):")
    print(b_abs)
  }
  
  # Set negative values to zero and calculate diagnostic VR
  vr <- sum(abs(b_abs[b_abs < 0]))
  b_abs[b_abs < 0] <- 0
  
  # RAS algorithm
  maxdiff <- 100
  iter <- 0
  rcount <- nrow(b_abs)
  ccount <- ncol(b_abs)
  
  cat("RAS iterations: ")
  
  while (maxdiff > 0.001 && iter < 400) {
    iter <- iter + 1
    maxdiff1 <- maxdiff2 <- 0
    
    # Step 1: Adjust rows
    for (i in 1:rcount) {
      row_sum <- sum(b_abs[i, ])
      ratio <- row_margins[i] / row_sum
      b_abs[i, ] <- b_abs[i, ] * ratio
      diff <- abs(row_margins[i] - row_sum)
      maxdiff1 <- max(maxdiff1, diff)
    }
    
    # Step 2: Adjust columns
    for (j in 1:ccount) {
      col_sum <- sum(b_abs[, j])
      ratio <- col_margins[j] / col_sum
      b_abs[, j] <- b_abs[, j] * ratio
      diff <- abs(col_margins[j] - col_sum)
      maxdiff2 <- max(maxdiff2, diff)
    }
    
    maxdiff <- max(maxdiff1, maxdiff2)
    cat(".")
  }
  
  # Generate matrices in destination and source percentages
  b_dest <- sweep(b_abs, 2, col_margins, "/") * 100
  b_src <- sweep(b_abs, 1, row_margins, "/") * 100
  
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
    rsq_df <- data.frame(R_squared = rsq_list, row.names = deps)
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
  list(b_matrix = b_matrix, b_abs = b_abs, b_src = b_src, b_dest = b_dest, rsq = rsq_list, vr = vr, iterations = iter)
}
