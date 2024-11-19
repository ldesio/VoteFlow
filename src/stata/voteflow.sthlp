
{smcl}
*! version 1.0.0 2024-10-26

{title:Title}
    {pstd} {hi:voteflow} — Vote flow estimation through Goodman ecological regression and coefficient adjustment via RAS iterative proportional fitting, as systematized by Corbetta and Schadee (1984)
    {p_end}

{title:Syntax}
    {cmd:voteflow} {it:varlist} {cmd:,} {cmd:indeps(}{it:varlist}{cmd:)} [{cmd:nooutput}] [{cmd:save(}{it:string}{cmd:)}] [{cmd:filter(}{it:string}{cmd:)}]

{title:Description}
    {pstd} The {cmd:voteflow} command performs vote-flow estimation on ecological electoral-results data (ideally at the polling-station level).
    {p_end}
    {pstd} It estimates a vote flow matrix by (1) performing Goodman ecological regression (Goodman 1953, 1959); (2) correcting unacceptable coefficients; (3) redistributing the corrections through the iterative proportional fitting RAS algorithm. It implements a three step procedure first presented by Mannheimer and Micheli (1976) and later structured and systematized by Corbetta and Schadee (1984).
    {p_end}
    {pstd} It requires {it:varlist} as the list of dependent variables (votes cast to each possible vote choice, typically including abstention, at t1), {cmd:indeps} as the list of independent variables (votes cast to each possible vote choice, typically including abstention, at t0). 
    It also provides options to save the results for further processing, apply filters, and control the verbosity of output.
    {p_end}

{title:Options}
    {pstd}
    {cmd:indeps(}{it:varlist}{cmd:)} specifies the list of independent variables (votes cast to each possible vote choice - typically including abstention - at t0).
    {p_end}
    {pstd}
    {cmd:nooutput} suppresses screen matrix output.
    {p_end}
    {pstd}
    {cmd:save(}{it:string}{cmd:)} saves the estimated matrices to an external (Excel-readable) tab-delimited text file specified by {it:string}.
    {p_end}
    {pstd}
    {cmd:filter(}{it:string}{cmd:)} applies a filter condition to the data before running the calculations.
    {p_end}

{title:Remarks}
    {pstd} The application of Goodman ecological regression requires that relatively strong assumptions are satisfied.
    Most importantly, vote flow parameters (e.g. share of voters from party A that move towards party B between the two elections) are assumed to be constant across all precincts, with random variations that are uncorrelated with any precinct-level unobserved variable.
    This and other assumptions and concerns lead to the following recommendations (Corbetta and Schadee 1984):
    {p_end}
    {pstd} - It is recommended to {bf:only analyse areas that are relatively homogenous} in terms of sociodemographic composition, possibly splitting large cities into smaller subdivisions. This has to be balanced, however, with the necessity to preserve at least two polling stations per coefficient to estimate. As an example, an 8x8 estimated matrix requires at least 8x8x2 = 128 polling stations to be included.
    {p_end}
    {pstd} - For the aforementioned reason, it is of special importance to {bf:exclude special polling stations} that might not be representative of the overall geographical area under scrutiny, thus with very different vote flow parameters (e.g. hospital polling stations, etc.). Even when not directly identifiable, these can be often identified as having a much smaller size (number of voters) or significant variation in the overall number of voters between two elections. This latter variation can also suggest that precinct borders might have changed, again suggesting exclusion of that unit.
    {p_end}
    {pstd} - A more severe issue might arise with ecological fallacy, i.e. the possibility that - even when constant across polling stations - vote-flow parameters at this level do not correspond at all to actual individual-level parameters. This is the well-known problem of ecological fallacy (Robinson 1950). Hence the strong recommendation to {bf:analyse ecological units at the smallest possible level} - typically the polling station level. Applications at higher levels might present severe ecological fallacy issues.
    {p_end}
    {pstd} - The VR diagnostic index (Corbetta and Schadee 1984) provides a summary measure of the presence (and size) of unacceptable regression coefficients (below 0 or above 1) in the originally estimated coefficient matrix, that were later corrected through the RAS algorithm. {bf:Estimated matrices with a VR above 15 should be seen with suspect}, possibly suggesting a clear violation of the model's assumptions.
    {p_end}

{title:Citation}
    {pstd}We kindly ask users to acknowledge use of this package through the following citations:{p_end}
    {pstd} - Corbetta, Pier Giorgio, and Henri M. A Schadee. 1984. Metodi e modelli di analisi dei dati elettorali. Bologna: Il Mulino.{p_end}
    {pstd} - De Sio, Lorenzo, Corbetta, Pier Giorgio and Henri M.A. Schadee, 2024. "VOTEFLOW: Vote flow estimation through Goodman ecological regression and coefficient adjustment via RAS iterative proportional fitting, as systematized by Corbetta and Schadee (1984)," Statistical Software Components SXXXXXX, Boston College Department of Economics, revised XX XX 2024. <https://ideas.repec.org/c/boc/bocode/sXXXX.html>{p_end}
    
{title:Examples}
    {pstd} Run the Goodman analysis on variables y1, y2, with independent variables x1 and x2:

        {cmd:voteflow y1 y2, indeps(x1 x2)}
    
    {pstd} Run the Goodman analysis on variables y1, y2, with independent variables x1 and x2:

        {cmd:voteflow y1 y2, indeps(x1 x2)}
    
    {pstd} Run the analysis with verbose output and save the results to "results.txt":

        {cmd:voteflow y1 y2, indeps(x1 x2) verbose save("results.txt")}
    
    {pstd} Exclude polling stations with less than 200 voters at t1:

        {cmd:voteflow y1 y2, indeps(x1 x2) filter("voters_t1 > 200")}
    
{title:References}

{pstd} Corbetta, Pier Giorgio, and Henri M. A Schadee. 1984. Metodi e modelli di analisi dei dati elettorali. Bologna: Il Mulino.

{pstd} Goodman, L. A. 1953. «Ecological regressions and behavior of individuals». American Sociological Review 18(6): 663–64.

{pstd} Goodman, L. A. 1959. «Some alternatives to ecological correlation». American Journal of Sociology 64(6): 610–25.

{pstd} Micheli, Giuseppe. 1976. «Il comportamento individuale nell’analisi sociologica del dato aggregato». Il giornale degli economisti ed annali di economia XXV: 429–48.

{pstd} Robinson, William S. 1950. «Ecol