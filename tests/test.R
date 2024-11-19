data <- read.csv("bologna_pol22_eur24.tsv");
deps <- grep("24$", names(data), value = TRUE)
indeps <- grep("22$", names(data), value = TRUE)
result <- voteflow(deps=deps, indeps=indeps, data=data,save_path="bo_22_24_output_R.xlsx", autoexclude=TRUE)