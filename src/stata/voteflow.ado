capture program drop cite_voteflow
program define cite_voteflow
	di `"[Done with {browse "https://github.com/ldesio/VoteFlow":github.com/ldesio/VoteFlow} (Corbetta, De Sio and Schadee 2024)]"'
end
capture program drop voteflow
program define voteflow, rclass

	syntax varlist [if], indeps(varlist) [nooutput] [save(string)] [filter(string)] [force] [autoexclude] [sankey]
	
	marksample touse
	
	local deps `varlist'
	
	local numdeps : list sizeof deps
	local numindeps : list sizeof indeps
	
	tempvar indeptotal
	tempvar deptotal
	tempvar variation
	tempvar relsize
	
	qui egen `indeptotal' = rowtotal(`indeps')
	qui egen `deptotal' = rowtotal(`deps')
	
	tempvar tmp
	gen `tmp' =.	
	
	di ""
	di "{bf:VOTEFLOW: Initializing...}"
	
	qui gen `variation' = abs((`deptotal' - `indeptotal')/`indeptotal')
	
	qui summarize `indeptotal'
	local avgsize = r(mean)
	qui gen `relsize' = `indeptotal' / `avgsize'
	
	qui count if `touse'
	di _column(5) "{sf:Calculating marginals on entire dataset (`r(N)' units)...}"
	
	// BEGIN vectors with marginals

		// COL marginals (indeps)
			local total = 0

			// creating list of col marginals, plus total
			foreach v in `indeps' {
				qui sum `v' if `touse'
				local cm `cm' `r(sum)'
				local total = `total' + `r(sum)'
			}
			// to string, sep by commas
			local colmargstring = subinstr("`cm'", " ", ", ",.)
			// creating matrix (vector) of relative col marginals, in pcts
			matrix colmargs = (`colmargstring') / `total'
			matrix colmargs = colmargs * 100

		// ROW marginals (deps)
			local total = 0

			// creating list of row marginals, plus total
			foreach v in `deps' {
				qui sum `v' if `touse'
				local rm `rm' `r(sum)'
				local total = `total' + `r(sum)'
			}
			// to string, sep by commas
			local rowmargstring = subinstr("`rm'", " ", ", ",.)
			// creating matrix (vector) of relative row marginals, in pcts
			matrix rowmargs = (`rowmargstring') / `total'
			matrix rowmargs = rowmargs * 100

	// END vectors with marginals	
	
	// BEGIN running the subsequent regressions, saving into a matrix of b's and into a vector of rsq's
		// ADD HERE further criteria for restricting cases in regressions
		if ("`filter'"!="") {
			local thefilter = "& `filter'"
			qui count if `touse' `thefilter'
		di _column(5) "Analysis will be performed on the filtered dataset (`r(N)' units)."
		}
		else {
			qui count if `touse'
			di _column(5) "Analysis will be performed on the unfiltered dataset (`r(N)' units)."
			local thefilter = "& (1==1)"
		}
		
		local proceed = 1
		
		di ""
		di "{bf:Performing basic checks (Schadee and Corbetta 1984):}"
		
		di _column(5) "- Average unit size (sum of indeps) is " %1.0f `avgsize' "... " _
		if (`avgsize' > 1200) {
			di ""
			di _column(5) "  {red:this is discouraged: large units increase risk of ecological fallacy (warning threshold is 1200).}"
			local proceed = 0
		}
		else {
			di "OK."
		}
	
		qui count if `touse' `thefilter' & (`variation'>=0.15)
		di _column(5) "- `r(N)' units changed in size by more than 15%... " _
		
		if (`r(N)'>0) {
			if ("`autoexclude'"!="autoexclude"){
				di ""
				di _column(5) "  {red:they should be excluded. Use 'autoexclude' option to exclude them automatically.}"
				local proceed = 0
			}
			else {
				di ""
				di _column(5) "  automatically excluding them, as 'autoexclude' option was specified."
				local newfilter = "`newfilter' & `variation' < 0.15"
			}
		} 
		else {
			di "OK."
		}
		
		qui count if `touse' `thefilter' & (`relsize' < 0.20)
		di _column(5) "- `r(N)' units have a size less than 20% the average unit size... " _
		if (`r(N)'>0) {
			if ("`autoexclude'"!="autoexclude"){
				di ""
				di _column(5) "  {red:they should be excluded. Use 'autoexclude' option to exclude them automatically.}"
				local proceed = 0
			}
			else {
				di ""
				di _column(5) "  automatically excluding them, as 'autoexclude' option was specified."
				local newfilter = "`newfilter' & `avgsize' >= 0.20"
			}
		} 
		else {
			di "OK."
		}
		
		// end filters: check N
		local thefilter = "`thefilter' `newfilter'"
		qui count  if `touse' `thefilter'
		
		local numcoeff = `numdeps' * `numindeps'
		di _column(5) "- You are trying to estimate (`numindeps'*`numdeps')=`numcoeff' coefficients with `r(N)' units... " _
		
		if ((`numcoeff'*2 > `r(N)')) {
			di ""
			di _column(5) "  {red:this is not allowed (at least 2 units per coefficient are needed).}"
			local proceed = 0
		}
		else {
			di "OK."
		}
		
		if (`proceed'==0  & "`force'"!="force") {
			di "Exiting."
			exit
		}
		if (`proceed'==0){
			di "{break}{break}{red:YOU CHOSE TO PROCEED BY IGNORING THE ABOVE WARNINGS: RESULTS WILL LIKELY BE INCORRECT.}{break}{red:YOU HAVE BEEN WARNED.}"
		}
		
		qui count if `touse' `thefilter'
		di _column(5) "Analysis will be performed on `r(N)' units."
		
		di ""
		di "{bf:Estimating regression models:}"
	
		local i = 0
		foreach v in `deps' {
			
			di _column(5) "`v' " _
			qui regress `v' `indeps' if `touse' `thefilter', nocons
			local rsq `rsq' `e(r2)'
			
			local i = `i' + 1
			if(`i'==1) {
				matrix b = e(b)
			}
			else {
				matrix b = b \ e(b)
			}
		}
		di "."

	// END main regressions

	// BEGIN from b's to cell values in pcts over total
		matrix b_abs = b

		// assign row names
		matrix rownames b = `deps'
		matrix rownames b_abs = `deps'

		// mutiply by col marg, to yield values in pcts over total
		local i = 0
		foreach v in `indeps' {
			local i = `i' + 1
			
			// display el("colmargs",1,`i')
			matrix newcol = b[1..., `i'] * el("colmargs",1,`i')
			matrix b_abs[1, `i'] = newcol
		}

	// END from b's to cell values
	di ""
	
	if ("`output'"!="nooutput") {
		display "{bf:Raw coefficients:}"
		matrix list b, format(%4.3f)

		di ""
		
		display "{bf:Raw percentages (over total):}"
		matrix list b_abs, format(%3.1f)
		di ""
	}

	di "{bf:Resetting unacceptable coefficients...}"
	// BEGIN resetting negative values to zero
		
		local rcount = rowsof(b_abs)
		local ccount = colsof(b_abs)

		local vr = 0

		// reset zeros
		forval i = 1/`rcount' {
			forval j = 1/`ccount' {
				local coeff = el("b_abs",`i',`j')
				if (`coeff' <0) {
					matrix b_abs[`i',`j'] = 0
					local vr = `vr' + abs(`coeff')
				}
			}
		}

	// END resetting negative values to zero
	di ""
	
matrix b_old = b_abs

	di "{bf:Adjusting matrix through RAS}"


	// RAS
	local maxdiff = 100
	local iter = 1	

	display _column(5) "RAS iterations: " _continue
	while (`maxdiff' > 0.001 & `iter' < 400) {
		
		display "." _continue

		local maxdiff1 = 0
		forval i = 1/`rcount' {
			matrix row = b_abs[`i',1...]
			mata: tmp = rowsum(st_matrix("row"))
			mata: st_numscalar("r(rowsum)", tmp)
			local ratio = rowmargs[1,`i'] / `r(rowsum)'
			matrix newrow = row * `ratio'
			matrix b_abs[`i',1] = newrow
		
			local diff = abs(rowmargs[1,`i'] - `r(rowsum)')
			if (`diff' > `maxdiff1') local maxdiff1 = `diff'
		}

		local maxdiff2 = 0
		forval i = 1/`ccount' {
			matrix col = b_abs[1...,`i']
			mata: tmp = colsum(st_matrix("col"))
			mata: st_numscalar("r(colsum)", tmp)
			local ratio = colmargs[1,`i'] / `r(colsum)'
			matrix newcol = col * `ratio'
			matrix b_abs[1,`i'] = newcol
			
			local diff = abs(colmargs[1,`i'] - `r(colsum)')
			if (`diff' > `maxdiff2') local maxdiff2 = `diff'
		}
		
		local maxdiff = `maxdiff1'
		if (`maxdiff2' > `maxdiff1') local maxdiff = `maxdiff2'
		
		local iter = `iter' + 1
	}

	display "`iter' iterations."



	// create matrix in dest (col) pcts
		matrix b_dest = b_abs
		// divide by col marg
		local i = 0
		foreach v in `indeps' {
			local i = `i' + 1
			matrix newcol = b_abs[1..., `i'] / el("colmargs",1,`i')
			matrix b_dest[1, `i'] = newcol * 100
		}

		// create matrix in source (row) pcts
		matrix b_src = b_abs
		// divide by col marg
		local i = 0
		foreach v in `deps' {
			local i = `i' + 1
			matrix newrow = b_abs[`i',1...] / el("rowmargs",1,`i')
			matrix b_src[`i',1] = newrow * 100
		}
		
	
	if ("`output'"!="nooutput") {
		di ""
		display "Diagnostic VR:" %4.1f `vr'
		if (`vr'>10) {
			di "{red: VR values above 10 suggest caution; above 15, results should be discarded.}"
		}
		di ""
		display "{bf:Adjusted percentages (over total):}"
		matrix list b_abs, format(%3.1f)
		di ""
		cite_voteflow
	}		
		
		
// matrix list b_abs

// display "Diagnostic VR:" %4.1f `vr'

// matrix list b_src
// matrix list b_dest		

if ("`save'"!="") {
	
	di "{bf:Saving output:}"
	
	set more off
	
	
	local rsqstring = subinstr("`rsq'", " ", ", ",.)
	matrix rsqmat = (`rsqstring')
	matrix rsqmat = rsqmat'
	
	local vrstring = string(`vr',"%4.1f") 
	
	mat2txt , matrix(b) saving("`save'") replace title("Original b coefficients matrix:")
	
	file open out using "`save'", write append
	file write out _newline(2)
	file close out
	
	mat2txt , matrix(rsqmat) saving("`save'") append title("Regression R-sq's:")
	
	file open out using "`save'", write append
	file write out _newline(2)
	file close out
	
	mat2txt , matrix(b_abs) saving("`save'") append title("Adjusted total percentages matrix:") note("Diagnostic VR: `vrstring'")
	
	file open out using "`save'", write append
	file write out _newline(2)
	file close out
	
	mat2txt , matrix(b_src) saving("`save'") append title("Adjusted source percentages matrix:")
	
	file open out using "`save'", write append
	file write out _newline(2)
	file close out
	
	mat2txt , matrix(b_dest) saving("`save'") append title("Adjusted destination percentages matrix:")
	
	display _column(5) as smcl "Output written to {browse " `"`save'"' "}."
	
}

if ("`sankey'"!="") {
	preserve
	clear
	svmat double b_abs, names(matcol)
	
	* Retrieve the row names into a local macro
	local rownames : rownames b_abs

	* Add row names as a new variable
	gen rowname = ""
	gen roworder = .
	local i = 1
	foreach rowname of local rownames {
		replace rowname = "`rowname'" in `i'
		replace roworder = `i' in `i'
		local i = `i' + 1
	}
	reshape long b_abs , i(rowname) j(colname) string
	sort roworder 
	sankey b_abs, from(colname) to(rowname) format(%12.1f) /*valcond(1)*/ showtot boxwidth(5) noval palette(CET C6) laba(0) labpos(3) labg(-1) offset(10) 
	restore
}

return matrix b = b
return matrix b_abs = b_abs
return scalar vr = `vr'


end
