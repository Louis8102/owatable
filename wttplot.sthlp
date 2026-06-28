{smcl}
{* *! version 1.0.0  28jun2026}{...}
{vieweralsosee "wtttable" "help wtttable"}{...}
{vieweralsosee "owablock" "help owablock"}{...}

{title:Title}

{phang}
{bf:wttplot} {hline 2} Effect-size plots for two-group Welch independent-samples tests

{title:Syntax}

{p 8 17 2}
{cmd:wttplot} {it:varlist} {ifin}{cmd:,}
{opt by(varname)}
{opt graphdir(dirname)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt by(varname)}}two-level grouping variable{p_end}
{p2coldent :* {opt graphdir(dirname)}}folder to receive exported graphs{p_end}
{synopt:{opt replace}}replace existing graph/results files{p_end}
{synopt:{opt alpha(#)}}significance level for FDR decisions and confidence intervals; default is {cmd:alpha(.05)}{p_end}
{synopt:{opt blockfile(filename)}}map variables to block/subscale headings{p_end}
{synopt:{opt blockfromchar}}extract block/subscale headings from variable characteristics{p_end}
{synopt:{opt blockfromlabel}}extract block/subscale headings from variable labels{p_end}
{synopt:{opt mincell(#)}}minimum group-specific N required for an outcome; default is {cmd:mincell(2)}{p_end}
{synopt:{opt show(significant|all)}}select outcomes shown in plots; default is {cmd:show(significant)}{p_end}
{synopt:{opt graphby(block|all)}}export one graph per block or one graph for all outcomes; default is {cmd:graphby(block)}{p_end}
{synopt:{opt combine(#)}}place # blocks in each exported figure; default is {cmd:combine(1)}{p_end}
{synopt:{opt layout(auto|horizontal|vertical)}}layout for multi-block figures; default is {cmd:layout(auto)}{p_end}
{synopt:{opt labelmode(full|item|varname)}}labels used on the graph; default is {cmd:full}, or {cmd:item} for combined vertical figures{p_end}
{synopt:{opt mapfile(filename.xlsx)}}save an Excel item-label mapping file; cells use Times New Roman 12 pt, with bold centered headers{p_end}
{synopt:{opt columns(#)}}number of columns when {cmd:combine(#)} is greater than 1; default is automatic{p_end}
{synopt:{opt formats(pdf png)}}graph formats to export; default is both {cmd:pdf png}{p_end}
{synopt:{opt orientation(auto|landscape|portrait)}}graph aspect ratio; default is {cmd:orientation(auto)}{p_end}
{synopt:{opt pngwidth(#)}}PNG export width in pixels; default is {cmd:pngwidth(3200)}{p_end}
{synopt:{opt results(filename)}}save machine-readable analytic results{p_end}
{synopt:{opt title(text)}}set the graph subtitle describing the comparison{p_end}
{synopt:{opt xtitle(text)}}set the x-axis title{p_end}
{synopt:{opt note(text)}}set the graph note{p_end}
{synopt:{opt titlesize(text)}}set main-title font size; default is {cmd:titlesize(medsmall)}{p_end}
{synopt:{opt blocksize(text)}}set block/subtitle font size; default is {cmd:blocksize(medsmall)}{p_end}
{synopt:{opt labelsize(text)}}set outcome-label font size; default is {cmd:labelsize(small)}{p_end}
{synopt:{opt xlabsize(text)}}set x-axis tick-label font size; default is {cmd:xlabsize(small)}{p_end}
{synopt:{opt xtitlesize(text)}}set x-axis-title font size; default is {cmd:xtitlesize(small)}{p_end}
{synopt:{opt notesize(text)}}set graph-note font size; default is {cmd:notesize(vsmall)}{p_end}
{synoptline}
{p 4 6 2}* {opt by()} and {opt graphdir()} are required.{p_end}

{title:Description}

{pstd}
{cmd:wttplot} creates signed Hedges' g_av effect-size plots for multiple
numeric outcomes compared across exactly two independent groups.  It uses the
same Welch t-test, Benjamini-Hochberg FDR, block metadata, and Hedges' g_av
logic as {cmd:wtttable}, but it is a graphing command rather than a Word-table
command.

{pstd}
By default, {cmd:wttplot} exports one graph per block/subscale when block
metadata are supplied.  Without block metadata, all outcomes are placed in a
single graph.  Specify {cmd:graphby(all)} to force a single graph.

{pstd}
The plotted effect size is signed.  Positive values indicate higher scores for
G1 than G2.  Horizontal bars are approximate normal-approximation confidence
intervals for Hedges' g_av and are intended as visual summaries.

{title:Options}

{phang}
{opt by(varname)} specifies the grouping variable.  The analysis sample must
contain exactly two observed groups.

{phang}
{opt graphdir(dirname)} specifies the output folder.  The folder is created if
possible.

{phang}
{opt replace} permits replacement of existing graph and results files.

{phang}
{opt alpha(#)} sets the significance level used for FDR decisions and graph
intervals.  The default is {cmd:alpha(.05)}.

{phang}
{opt blockfromchar} reads block metadata written by {cmd:owablock}.  Each
outcome variable must contain characteristics {cmd:owatable_blockid} and
{cmd:owatable_blocklabel}.  For item labels, {cmd:wttplot} first uses the
Stata variable label.  If the variable label is empty, {cmd:wttplot} then
uses characteristic {cmd:owatable_label}, if present.  This avoids replacing
valid variable labels with stale or incorrectly written characteristics.

{phang}
{opt blockfromlabel} extracts block metadata from variable labels formatted as
{cmd:[block_id | block_label] display_label}.

{phang}
{opt blockfile(filename)} specifies a Stata dataset mapping variables to block
headings.  The dataset must contain {cmd:varname}, {cmd:blockid}, and
{cmd:blocklabel}.

{phang}
{opt graphby(block)} exports one graph per block.  This is the default.

{phang}
{opt show(significant)} plots only outcomes with FDR-adjusted p-values below
{cmd:alpha()}.  This is the default and is recommended for research briefs and
appendix materials.

{phang}
{opt show(all)} plots all analyzable outcomes.  This is useful for full
appendices or diagnostics, especially when no FDR-significant outcomes are
found.

{phang}
{opt graphby(all)} exports one graph containing all outcomes.

{phang}
{opt combine(#)} controls how many blocks are placed in each exported figure.
The default is {cmd:combine(1)}, meaning one block per figure.  For example,
{cmd:combine(2)} places two blocks in each figure, and {cmd:combine(3)} places
three blocks in each figure.  Values larger than two should be used cautiously
because outcome labels can become difficult to read.

{phang}
{opt layout(horizontal)} places separate block panels side by side with a
common x-axis scale.  It is not a true shared-axis graph.
{opt layout(vertical)} creates a compact vertical screening figure.  With
{cmd:combine(#)}, each page is split into two vertical stacks; each stack
contains one or more blocks and uses the same x-axis scale.  This layout is
designed for many outcomes and is best used with {cmd:labelmode(item)} and
{cmd:mapfile()}.
{opt layout(auto)} uses an automatic compact layout.  This option applies only
when {cmd:combine(#)} is greater than 1.

{phang}
{opt labelmode(full)} uses the variable label or display label on the graph.
{opt labelmode(item)} displays {cmd:Item 01}, {cmd:Item 02}, and so on.  This is
recommended for compact screening figures.  {opt labelmode(varname)} displays
Stata variable names.

{phang}
{opt mapfile(filename.xlsx)} saves an Excel mapping file linking graph item
numbers to variable names, block labels, and full outcome labels.  If variables
are named {cmd:item1}, {cmd:item2}, ..., the mapping file displays them as
{cmd:item01}, {cmd:item02}, ..., so one-digit and two-digit item names align.
The mapping file has four columns: {cmd:No.}, {cmd:Item}, {cmd:Item label}, and
{cmd:Block}.  It is formatted in Times New Roman, 12 pt, with bold centered
headers and dynamic column widths.

{phang}
{opt columns(#)} sets the number of columns when {cmd:combine(#)} is greater
than 1.  By default, {cmd:wttplot} uses a compact automatic layout based on
the number of blocks requested in {cmd:combine(#)}.  If both {cmd:layout()} and
{cmd:columns()} are specified, {cmd:columns()} takes precedence.

{phang}
{opt titlesize(text)} controls the main graph-title font size.  The default is
{cmd:titlesize(medsmall)}.

{phang}
{opt blocksize(text)} controls the block-heading font size.  In the default
one-block-per-figure layout, this controls the subtitle.  In combined figures,
this controls each block title.  The default is {cmd:blocksize(medsmall)}.

{phang}
{opt labelsize(text)} controls the font size of outcome labels on the y axis.
The default is {cmd:labelsize(small)}, which is intended to keep long item
labels readable without overwhelming the plot.  Common Stata graph sizes such
as {cmd:tiny}, {cmd:vsmall}, {cmd:small}, and {cmd:medsmall} may be used.

{phang}
{opt xlabsize(text)} controls the x-axis tick-label font size.  The default is
{cmd:xlabsize(small)}.

{phang}
{opt xtitlesize(text)} controls the x-axis-title font size.  The default is
{cmd:xtitlesize(small)}.

{phang}
{opt notesize(text)} controls the graph-note font size.  The default is
{cmd:notesize(vsmall)}.

{phang}
{opt formats(pdf png)} specifies the exported graph formats.  The default is to
save both PDF and high-resolution PNG files.  PDF is recommended for formal
figure files; PNG is useful for Word insertion and preview.

{phang}
{opt orientation(auto)} uses a compact layout for short blocks and a taller
layout for blocks with many outcomes.  This is the default and is recommended
for research briefs and appendix materials.

{phang}
{opt orientation(landscape)} creates wide figures, which can be useful for long
outcome labels.

{phang}
{opt orientation(portrait)} creates a narrower, taller figure.

{phang}
{opt pngwidth(#)} sets the exported PNG width in pixels.  The default is
{cmd:pngwidth(3200)} for high-resolution output.  PDF output remains vector
based and is not controlled by this option.

{phang}
{opt results(filename)} saves a Stata dataset containing the analytic results,
including signed Hedges' g_av and its approximate confidence interval.

{title:Examples}

{pstd}Auto example with two blocks:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. owablock, blocks("Cost: price" "Vehicle Performance: mpg weight length") replace}{p_end}
{phang2}{cmd:. local outcomes `r(varlist)'}{p_end}
{phang2}{cmd:. wttplot `outcomes', by(foreign) blockfromchar graphdir(figures) replace}{p_end}

{pstd}Single graph rather than one graph per block:{p_end}
{phang2}{cmd:. wttplot `outcomes', by(foreign) blockfromchar graphdir(figures) graphby(all) show(all) replace}{p_end}

{pstd}Put two blocks in one shared-axis vertical figure:{p_end}
{phang2}{cmd:. wttplot `outcomes', by(foreign) blockfromchar graphdir(figures) combine(2) layout(vertical) replace}{p_end}

{pstd}Put two block panels side by side:{p_end}
{phang2}{cmd:. wttplot `outcomes', by(foreign) blockfromchar graphdir(figures) combine(2) layout(horizontal) replace}{p_end}

{pstd}High-resolution landscape PNG and vector PDF output:{p_end}
{phang2}{cmd:. wttplot `outcomes', by(foreign) blockfromchar graphdir(figures) formats(pdf png) orientation(landscape) pngwidth(3600) replace}{p_end}

{title:Saved results}

{pstd}
{cmd:wttplot} returns:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(n_graphs)}}number of graphs exported{p_end}
{synopt:{cmd:r(graphdir)}}graph output folder{p_end}
{synopt:{cmd:r(files)}}exported graph files{p_end}

{title:Author}

{pstd}
Hao Ma
