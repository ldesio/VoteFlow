
# Title
**voteflow** — Vote flow estimation through Goodman ecological regression and coefficient adjustment via RAS iterative proportional fitting, as systematized by Schadee and Corbetta (1984)

# Installation
```
// install mat2txt, used for outputting matrices
ssc install mat2txt                                           

net install voteflow, from("https://raw.githubusercontent.com/ldesio/VoteFlow/refs/heads/main/src/stata/") replace

```



---

# Syntax
```
voteflow varlist, indeps(varlist) [nooutput] [save(string)] [filter(string)]
```

---

# Description
The `voteflow` command performs vote-flow estimation on ecological electoral-results data (ideally at the polling-station level).

It estimates a vote flow matrix by:
1. Performing Goodman ecological regression (Goodman 1953, 1959).
2. Correcting unacceptable coefficients.
3. Redistributing the corrections through the iterative proportional fitting RAS algorithm.

This three-step procedure was first presented by Mannheimer and Micheli (1976) and later structured and systematized by Schadee and Corbetta (1984).

It requires:
- `varlist`: The list of dependent variables (votes cast to each possible vote choice, typically including abstention, at t1).
- `indeps`: The list of independent variables (votes cast to each possible vote choice, typically including abstention, at t0).

Additionally, it provides options to:
- Save the results for further processing.
- Apply filters.
- Control the verbosity of output.

---

# Options

- `indeps(varlist)`  
  Specifies the list of independent variables (votes cast to each possible vote choice, typically including abstention, at t0).

- `nooutput`  
  Suppresses screen matrix output.

- `save(string)`  
  Saves the estimated matrices to an external (Excel-readable) tab-delimited text file specified by `string`.

- `filter(string)`  
  Applies a filter condition to the data before running the calculations.

---

# Remarks
The application of Goodman ecological regression requires relatively strong assumptions:
- **Constancy of vote flow parameters** across precincts is assumed, with random variations uncorrelated to unobserved variables.
- Recommendations from Schadee and Corbetta (1984):
  - Analyze areas that are relatively **homogeneous** in terms of sociodemographic composition. Avoid over-aggregation but ensure sufficient polling stations per coefficient (e.g., an 8x8 matrix requires at least 128 polling stations).
  - Exclude **special polling stations** (e.g., hospitals) or those with unusual voter counts or large changes in voter numbers between elections.
  - Avoid **ecological fallacy** by analyzing data at the smallest possible level, such as polling stations.
- Use the **VR diagnostic index** to detect unacceptable coefficients in the original matrix. High values (VR > 15) suggest a potential violation of model assumptions.

---

# Citation
We kindly ask users to acknowledge the use of this package through the following citations:
- Schadee, Henri M. A. and Pier Giorgio Corbetta. 1984. *Metodi e modelli di analisi dei dati elettorali.* Bologna: Il Mulino.
- De Sio, Lorenzo, Corbetta, Pier Giorgio, and Henri M. A. Schadee. 2024. *VOTEFLOW: Vote flow estimation through Goodman ecological regression and coefficient adjustment via RAS iterative proportional fitting, as systematized by Corbetta and Schadee (1984). https://github.com/ldesio/VoteFlow/

---

# Examples

Run the Goodman analysis on variables `y1`, `y2`, with independent variables `x1` and `x2`:
```
voteflow y1 y2, indeps(x1 x2)
```

Run the analysis with verbose output and save the results to `"results.txt"`:
```
voteflow y1 y2, indeps(x1 x2) verbose save("results.txt")
```

Exclude polling stations with fewer than 200 voters at t1:
```
voteflow y1 y2, indeps(x1 x2) filter("voters_t1 > 200")
```

---

# References
- Schadee, Henri M. A. and Pier Giorgio Corbetta. 1984. *Metodi e modelli di analisi dei dati elettorali.* Bologna: Il Mulino.
- Goodman, L. A. 1953. “Ecological regressions and behavior of individuals.” *American Sociological Review,* 18(6): 663–64.
- Goodman, L. A. 1959. “Some alternatives to ecological correlation.” *American Journal of Sociology,* 64(6): 610–25.
- Micheli, Giuseppe. 1976. “Il comportamento individuale nell’analisi sociologica del dato aggregato.” *Il giornale degli economisti ed annali di economia,* XXV: 429–48.
- Robinson, William S. 1950. “Ecological correlations and the behavior of individuals.” *American Sociological Review,* 15(3): 351–57.
