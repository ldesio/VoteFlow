// prerequisites
ssc install mat2txt
net install voteflow, from()

// Bologna: general 2022 election -> 2024 European Parliament election
import delimited "bologna_pol22_eur24.tsv", clear

// processing all units: some warnings are issued, and the analysis is not performed
voteflow *24, indeps(*22) 

// the "autoexclude" option enforces some default exclusions (see output), and the analysis is performed
voteflow *24, indeps(*22) autoexclude

// output is saved in text format; with XLSX extension it can be opened directly in Excel
voteflow *24, indeps(*22) autoexclude save("bo_22_24_output_stata.xlsx")

// output is saved in text format, screen output suppressed
voteflow *24, indeps(*22) autoexclude save("bo_22_24_output_stata.xlsx") nooutput

// altering dataset, to make it really problematic
foreach v of varlist (*22 *24) {
	replace `v' = `v'*10
}
keep in 100/445

voteflow *24, indeps(*22)
voteflow *24, indeps(*22) autoexclude
voteflow *24, indeps(*22) autoexclude force







