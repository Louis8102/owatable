{smcl}
{* *! version 1.0.0  26jun2026}{...}
{vieweralsosee "[R] oneway" "help oneway"}{...}
{vieweralsosee "[R] ttest" "help ttest"}{...}
{vieweralsosee "[R] putdocx" "help putdocx"}{...}

{title:Title}

{phang}
{bf:owatable} {hline 2} Word table for three-group Welch one-way ANOVA,
FDR adjustment, Games-Howell comparisons, and Hedges' g_av

{title:Syntax}

{p 8 17 2}
{cmd:owatable} {it:varlist} {ifin}{cmd:,}
{opt by(varname)}
{opt saving(filename)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt by(varname)}}three-level grouping variable{p_end}
{p2coldent :* {opt saving(filename)}}Word .docx file to create{p_end}
{synopt:{opt replace}}replace existing output files{p_end}
{synopt:{opt alpha(#)}}significance level; default is {cmd:alpha(.05)}{p_end}
{synopt:{opt show(significant|omnibus|all)}}select rows shown in the Word table{p_end}
{synopt:{opt showdf}}display Welch degrees of freedom with F{p_end}
{synopt:{opt availablecase}}use outcome-specific available cases instead of a common complete-case sample{p_end}
{synopt:{opt blockfile(filename)}}map variables to block/subscale headings{p_end}
{synopt:{opt blockfromchar}}extract block/subscale headings from variable characteristics{p_end}
{synopt:{opt blockfromlabel}}extract block/subscale headings from variable labels{p_end}
{synopt:{opt showblock}}show a block heading even when only one block is present{p_end}
{synopt:{opt results(filename)}}save machine-readable analytic results{p_end}
{synopt:{opt mincell(#)}}minimum group-specific N required for an outcome; default is {cmd:mincell(2)}{p_end}
{synopt:{opt title(text)}}set the italic table title{p_end}
{synopt:{opt tablenumber(text)}}set the table identifier; default is {cmd:Table 1}{p_end}
{synopt:{opt note(text)}}append text to the table note{p_end}
{synoptline}
{p 4 6 2}* {opt by()} and {opt saving()} are required.{p_end}

{title:Description}

{pstd}
{cmd:owatable} creates a landscape Word table for multiple numeric outcomes
compared across exactly three groups.  The table reports group means and
standard deviations, Welch one-way ANOVA results, Benjamini-Hochberg
FDR-adjusted omnibus p-values, Games-Howell pairwise comparisons, and absolute
Hedges' g_av effect sizes.

{pstd}
The command is intentionally narrow.  Version 1 supports exactly three groups
because the resulting Word table is designed as a compact APA-style wide table:
G1, G2, and G3 descriptive statistics; F, p, and FDR q; and the three pairwise
comparisons G1-G2, G1-G3, and G2-G3.

{pstd}
By default, {cmd:owatable} uses a common complete-case sample across all
outcomes in {it:varlist} and the grouping variable specified in {opt by()}.
This keeps the analytic sample consistent across rows of the multi-outcome
table.  Specify {opt availablecase} only when outcome-specific samples are
desired.

{pstd}
By default, a row is displayed only when the FDR-adjusted Welch omnibus test is
significant and at least one Games-Howell comparison is significant.  Pairwise
tests are performed only for outcomes passing the FDR-adjusted omnibus rule.

{pstd}
When {opt blockfromchar}, {opt blockfromlabel}, or {opt blockfile()} is
specified, {cmd:owatable} inserts block headings above groups of outcomes.
The first-column width is estimated from both outcome labels and block labels,
with minimum and maximum limits to preserve the wide-table layout.

{title:Options}

{phang}
{opt by(varname)} specifies the grouping variable.  The analysis sample must
contain exactly three observed groups.  Numeric and string grouping variables
are allowed; value labels are used in the table note when available.

{phang}
{opt saving(filename)} specifies the Word document to create.  A {cmd:.docx}
extension is recommended.

{phang}
{opt replace} permits replacement of existing output files.

{phang}
{opt alpha(#)} sets the significance level used for the FDR-adjusted omnibus
decision and the Games-Howell pairwise decisions.  The default is
{cmd:alpha(.05)}.

{phang}
{opt show(significant)} displays outcomes with a significant FDR-adjusted
omnibus test and at least one significant Games-Howell comparison.  This is the
default.

{phang}
{opt show(omnibus)} displays every outcome with a significant FDR-adjusted
omnibus test.

{phang}
{opt show(all)} displays all analyzable outcomes.  This is useful for checking
the full output or for reporting nonsignificant results.

{phang}
{opt showdf} displays Welch degrees of freedom in the F column as
{it:F} (df1, df2).  The default table omits df to keep the Word table compact.

{phang}
{opt availablecase} uses all nonmissing observations available for each outcome.
With this option, sample sizes may vary across outcomes; the Word table note
states this explicitly.  Without this option, {cmd:owatable} uses a common
complete-case sample.

{phang}
{opt blockfile(filename)} specifies a Stata dataset that maps outcome variables
to block or subscale headings.  The block file must contain string variable
{cmd:varname}, numeric variable {cmd:blockid}, and string variable
{cmd:blocklabel}.  Every variable in {it:varlist} must appear in
{cmd:blockfile()}.  Blocks are displayed in ascending {cmd:blockid} order.
{opt blockfile()} may not be combined with {opt blockfromchar} or
{opt blockfromlabel}.

{phang}
{opt blockfromchar} extracts block information from variable characteristics.
This is the recommended no-mapping-file method when item labels are long,
because the original variable labels remain unchanged.  Define characteristics
as follows:

{phang2}{cmd:. char q1[owatable_blockid] "B01"}{p_end}
{phang2}{cmd:. char q1[owatable_blocklabel] "Student Characteristics"}{p_end}

{pstd}
The table row label is taken from the Stata variable label.  Optionally, a
display label can be supplied with:

{phang2}{cmd:. char q1[owatable_label] "Full display label for q1"}{p_end}

{pstd}
{opt blockfromchar} may not be combined with {opt blockfile()} or
{opt blockfromlabel}.

{phang}
{opt blockfromlabel} extracts block information directly from variable labels.
Variable labels must use the following format:

{phang2}{cmd:[block_id | block_label] display_label}{p_end}

{pstd}
For example:

{phang2}{cmd:. label variable q1 "[B01 | Student Characteristics] Gender"}{p_end}
{phang2}{cmd:. label variable q2 "[B01 | Student Characteristics] Age"}{p_end}
{phang2}{cmd:. label variable q3 "[B02 | Attendance] Chronic Absence Rate"}{p_end}

{pstd}
With {opt blockfromlabel}, the Word table displays {cmd:Student Characteristics}
and {cmd:Attendance} as block headings and displays {cmd:Gender}, {cmd:Age},
and {cmd:Chronic Absence Rate} as row labels.  This option lets users keep
their original variable names and avoid creating a separate block mapping file.
{opt blockfromlabel} may not be combined with {opt blockfile()} or
{opt blockfromchar}.

{pstd}
Note that Stata variable labels are limited to 80 characters.  If the block
prefix plus the display label would exceed that limit, Stata truncates the
variable label before {cmd:owatable} reads it.  For long item labels, prefer
{opt blockfromchar} or {opt blockfile()}.

{phang}
{opt showblock} displays the block heading even when only one block is present.
Without {opt showblock}, a single-block mapping is treated as a flat table.

{phang}
{opt results(filename)} saves one observation per outcome with descriptive
statistics, Welch-test results, FDR values, Games-Howell p-values, and signed
Hedges' g_av values.  The Word table reports absolute Hedges' g_av values.

{phang}
{opt mincell(#)} specifies the minimum group-specific sample size required for
an outcome to be analyzable.  The default is {cmd:mincell(2)}.  Outcomes with
too few observations in any group are kept in the saved results but are not
analyzable.

{phang}
{opt title(text)}, {opt tablenumber(text)}, and {opt note(text)} customize the
Word table title, table number, and note.

{title:Examples}

{pstd}
Use standard Stata varlist notation.  The variables do not need to be
contiguous.

{phang2}{cmd:. owatable y1-y30 y35-y105, by(schoolgroup) saving(table1.docx) replace}{p_end}

{pstd}
Show all analyzable outcomes and save the analytic results:

{phang2}{cmd:. owatable math1-math10 reading1-reading8, by(condition) ///}{p_end}
{phang2}{cmd:    saving(anova_table.docx) results(anova_results.dta) show(all) replace}{p_end}

{pstd}
Display Welch degrees of freedom:

{phang2}{cmd:. owatable y1-y20, by(group3) saving(table1_df.docx) showdf replace}{p_end}

{pstd}
Use outcome-specific available cases:

{phang2}{cmd:. owatable y1-y20, by(group3) saving(table1_available.docx) availablecase replace}{p_end}

{pstd}
Use block headings for a multi-subscale instrument without changing item labels:

{phang2}{cmd:. label variable item1 "I felt calm and emotionally steady during the past week"}{p_end}
{phang2}{cmd:. char item1[owatable_blockid] "B01"}{p_end}
{phang2}{cmd:. char item1[owatable_blocklabel] "Emotional Well-Being"}{p_end}
{phang2}{cmd:. char item11[owatable_blockid] "B02"}{p_end}
{phang2}{cmd:. char item11[owatable_blocklabel] "Anxiety Responses"}{p_end}

{phang2}{cmd:. owatable item1-item50, by(group3) ///}{p_end}
{phang2}{cmd:    blockfromchar ///}{p_end}
{phang2}{cmd:    saving(table1_blocks.docx) replace}{p_end}

{pstd}
Alternatively, use {opt blockfromlabel} for short labels, or use a separate
block mapping dataset:

{phang2}{cmd:. owatable item1-item50, by(group3) ///}{p_end}
{phang2}{cmd:    blockfile(blockmap.dta) ///}{p_end}
{phang2}{cmd:    saving(table1_blocks.docx) replace}{p_end}

{pstd}
The block mapping dataset should contain one row per outcome:

{phang2}{cmd:. list varname blockid blocklabel in 1/5}{p_end}
{phang2}{cmd:     varname    blockid    blocklabel}{p_end}
{phang2}{cmd:     item1      1          Emotional Well-Being}{p_end}
{phang2}{cmd:     item2      1          Emotional Well-Being}{p_end}
{phang2}{cmd:     item11     2          Anxiety and Stress Responses}{p_end}

{title:Stored results}

{pstd}
{cmd:owatable} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(N)}}analysis-sample size{p_end}
{synopt:{cmd:r(N_groups)}}number of groups, always 3{p_end}
{synopt:{cmd:r(N_outcomes)}}number of requested outcomes{p_end}
{synopt:{cmd:r(N_displayed)}}number of rows displayed{p_end}
{synopt:{cmd:r(alpha)}}significance level{p_end}
{synopt:{cmd:r(mincell)}}minimum group-specific N{p_end}
{synopt:{cmd:r(N_group1)}}sample size for G1 in the analysis sample{p_end}
{synopt:{cmd:r(N_group2)}}sample size for G2 in the analysis sample{p_end}
{synopt:{cmd:r(N_group3)}}sample size for G3 in the analysis sample{p_end}
{synopt:{cmd:r(group1)}}display label for G1{p_end}
{synopt:{cmd:r(group2)}}display label for G2{p_end}
{synopt:{cmd:r(group3)}}display label for G3{p_end}
{synopt:{cmd:r(sample)}}{cmd:completecase} or {cmd:availablecase}{p_end}
{synopt:{cmd:r(saving)}}Word output filename{p_end}
{synopt:{cmd:r(results)}}results-data filename, if requested{p_end}

{title:Methods and interpretation}

{pstd}
Welch's one-way ANOVA is used because it does not require equal group
variances.  FDR adjustment uses the Benjamini-Hochberg procedure across all
analyzable omnibus tests requested in the command.

{pstd}
For outcomes with FDR-adjusted omnibus {it:q} less than {cmd:alpha()}, the
three pairwise comparisons are tested using the Games-Howell procedure.  The
pairwise columns display absolute Hedges' g_av effect sizes with significance
stars.  Direction should be interpreted from the group means.  Signed Hedges'
g_av values are retained in the saved {opt results()} dataset.

{title:Author}

{pstd}
HaO Ma

{pstd}
Version 1.0.0, 26 June 2026.
