*! version 1.0.0  26jun2026
program define owatable, rclass
    version 19.5

    syntax varlist(numeric min=1) [if] [in], ///
        BY(varname) SAVing(string) ///
        [ REPLACE ALPHA(real 0.05) ///
          SHOW(string) SHOWDF AVAILABLECASE ///
          BLOCKFILE(string) BLOCKFROMLABEL BLOCKFROMCHAR SHOWBLOCK ///
          RESULTS(string) ///
          MINCELL(integer 2) ///
          TITLE(string) TABLENUMber(string) ///
          NOTE(string) ]

    if `alpha' <= 0 | `alpha' >= 1 {
        di as err "alpha() must be strictly between 0 and 1"
        exit 198
    }
    if `mincell' < 2 {
        di as err "mincell() must be at least 2"
        exit 198
    }

    local show = lower(strtrim(`"`show'"'))
    if `"`show'"' == "" local show "significant"
    if !inlist(`"`show'"', "significant", "omnibus", "all") {
        di as err "show() must be significant, omnibus, or all"
        exit 198
    }

    if `"`title'"' == "" {
        local title "Welch One-Way ANOVA Results"
    }
    if `"`tablenumber'"' == "" {
        local tablenumber "Table 1"
    }
    local n_block_sources = (`"`blockfile'"' != "") + (`"`blockfromlabel'"' != "") + (`"`blockfromchar'"' != "")
    if `n_block_sources' > 1 {
        di as err "only one of blockfile(), blockfromlabel, or blockfromchar may be specified"
        exit 198
    }

    capture confirm new file `"`saving'"'
    if _rc & `"`replace'"' == "" {
        di as err `"file `saving' already exists; specify replace"'
        exit 602
    }
    if `"`results'"' != "" {
        capture confirm new file `"`results'"'
        if _rc & `"`replace'"' == "" {
            di as err `"file `results' already exists; specify replace"'
            exit 602
        }
    }

    local nvars : word count `varlist'

    marksample touse, novarlist
    markout `touse' `by', strok
    if `"`availablecase'"' == "" {
        markout `touse' `varlist'
    }

    quietly count if `touse'
    if r(N) == 0 {
        di as err "no observations in the analysis sample"
        exit 2000
    }
    local sample_N = r(N)

    tempname rawpost
    tempfile rawresults prefdr fdrvalues fullresults displayresults tabledata blockmapclean

    if `"`blockfile'"' != "" {
        capture confirm file `"`blockfile'"'
        if _rc {
            di as err `"blockfile() not found: `blockfile'"'
            exit 601
        }
        preserve
            quietly use `"`blockfile'"', clear
            capture confirm variable varname
            if _rc {
                di as err "blockfile() must contain variable varname"
                restore
                exit 111
            }
            capture confirm variable blockid
            if _rc {
                di as err "blockfile() must contain variable blockid"
                restore
                exit 111
            }
            capture confirm variable blocklabel
            if _rc {
                di as err "blockfile() must contain variable blocklabel"
                restore
                exit 111
            }
            capture confirm string variable varname
            if _rc {
                di as err "varname in blockfile() must be a string variable"
                restore
                exit 109
            }
            capture confirm string variable blocklabel
            if _rc {
                di as err "blocklabel in blockfile() must be a string variable"
                restore
                exit 109
            }
            keep varname blockid blocklabel
            replace varname = strtrim(varname)
            replace blocklabel = strtrim(blocklabel)
            quietly count if missing(varname) | missing(blockid) | missing(blocklabel)
            if r(N) > 0 {
                di as err "blockfile() contains missing varname, blockid, or blocklabel"
                restore
                exit 459
            }
            quietly duplicates tag varname, generate(__dup)
            quietly count if __dup
            if r(N) > 0 {
                di as err "blockfile() contains duplicate varname entries"
                restore
                exit 459
            }
            drop __dup
            rename varname variable
            save `"`blockmapclean'"', replace
        restore
    }

    preserve
        quietly keep if `touse'

        tempvar gid
        quietly egen long `gid' = group(`by'), label
        quietly levelsof `gid', local(groups)
        local ngroups : word count `groups'
        if `ngroups' != 3 {
            di as err "owatable v1 requires by() to have exactly three groups in the analysis sample"
            di as err "observed groups: `ngroups'"
            restore
            exit 498
        }

        local group_vallab : value label `gid'
        forvalues j = 1/3 {
            local group_name`j' : label `group_vallab' `j'
            if `"`group_name`j''"' == "" local group_name`j' "Group `j'"
            quietly count if `gid' == `j'
            local group_N`j' = r(N)
            if `"`availablecase'"' == "" & `group_N`j'' < `mincell' {
                di as err "group `j' has fewer than mincell(`mincell') observations in the complete-case sample"
                restore
                exit 2001
            }
        }

        postfile `rawpost' int item_no ///
            str32 variable str32 label_blockcode str244 label_blocklabel str244 rowlabel ///
            double n1 mean1 sd1 n2 mean2 sd2 n3 mean3 sd3 ///
            using `"`rawresults'"', replace

        local item = 0
        foreach y of local varlist {
            local ++item
            local ylab : variable label `y'
            if `"`ylab'"' == "" local ylab "`y'"
            local rowlab `"`ylab'"'
            local label_blockcode ""
            local label_blocklabel ""
            if `"`blockfromchar'"' != "" {
                local label_blockcode : char `y'[owatable_blockid]
                local label_blocklabel : char `y'[owatable_blocklabel]
                local char_rowlab : char `y'[owatable_label]
                local label_blockcode = strtrim(`"`label_blockcode'"')
                local label_blocklabel = strtrim(`"`label_blocklabel'"')
                if `"`char_rowlab'"' != "" local rowlab `"`char_rowlab'"'
                if `"`label_blockcode'"' == "" | `"`label_blocklabel'"' == "" {
                    di as err "blockfromchar requires variable characteristics:"
                    di as err `"char `y'[owatable_blockid] "B01""'
                    di as err `"char `y'[owatable_blocklabel] "Block label""'
                    restore
                    exit 198
                }
            }
            else if `"`blockfromlabel'"' != "" {
                local closepos = strpos(`"`ylab'"', "]")
                local pipepos = strpos(`"`ylab'"', "|")
                if substr(`"`ylab'"', 1, 1) == "[" & `closepos' > 0 & ///
                    `pipepos' > 2 & `pipepos' < `closepos' {
                    local label_blockcode = strtrim(substr(`"`ylab'"', 2, `pipepos' - 2))
                    local label_blocklabel = strtrim(substr(`"`ylab'"', `pipepos' + 1, `closepos' - `pipepos' - 1))
                    local rowlab = strtrim(substr(`"`ylab'"', `closepos' + 1, .))
                    if `"`rowlab'"' == "" local rowlab "`y'"
                }
                else {
                    di as err "blockfromlabel requires variable labels to follow:"
                    di as err "[block_id | block_label] display_label"
                    di as err "variable `y' has label: `ylab'"
                    restore
                    exit 198
                }
            }

            local statvals
            forvalues j = 1/3 {
                quietly summarize `y' if `gid' == `j'
                local this_n = r(N)
                local this_mean = r(mean)
                local this_sd = r(sd)
                local statvals `"`statvals' (`this_n') (`this_mean') (`this_sd')"'
            }
            post `rawpost' (`item') (`"`y'"') (`"`label_blockcode'"') (`"`label_blocklabel'"') (`"`rowlab'"') `statvals'
        }
        postclose `rawpost'

        use `"`rawresults'"', clear
        sort item_no

        if `"`blockfile'"' != "" {
            drop label_blockcode label_blocklabel
            merge 1:1 variable using `"`blockmapclean'"', keep(master match)
            quietly count if _merge == 1
            if r(N) > 0 {
                levelsof variable if _merge == 1, local(unmapped_vars) clean
                di as err "variables in varlist missing from blockfile(): `unmapped_vars'"
                restore
                exit 459
            }
            drop _merge
            generate str32 blockcode = string(blockid)
        }
        else if `"`blockfromlabel'"' != "" | `"`blockfromchar'"' != "" {
            generate str32 blockcode = label_blockcode
            generate str244 blocklabel = label_blocklabel
            quietly count if missing(blockcode) | missing(blocklabel)
            if r(N) > 0 {
                di as err "could not parse block information for all variables"
                restore
                exit 198
            }
            generate double blockid = .
            local current_block ""
            local next_block = 0
            sort item_no
            forvalues i = 1/`=_N' {
                local this_block = blockcode[`i']
                if `"`this_block'"' != `"`current_block'"' {
                    local ++next_block
                    local current_block `"`this_block'"'
                }
                replace blockid = `next_block' in `i'
            }
            drop label_blockcode label_blocklabel
        }
        else {
            generate double blockid = 1
            generate str32 blockcode = ""
            generate str244 blocklabel = ""
            drop label_blockcode label_blocklabel
        }

        generate byte analyzable = ///
            n1 >= `mincell' & n2 >= `mincell' & n3 >= `mincell' & ///
            sd1 > 0 & sd2 > 0 & sd3 > 0

        generate double variance1 = sd1^2
        generate double variance2 = sd2^2
        generate double variance3 = sd3^2
        generate double weight1 = n1 / variance1 if analyzable
        generate double weight2 = n2 / variance2 if analyzable
        generate double weight3 = n3 / variance3 if analyzable
        generate double sum_w = weight1 + weight2 + weight3 if analyzable
        generate double mean_w = ///
            (weight1*mean1 + weight2*mean2 + weight3*mean3) / sum_w if analyzable
        generate double welch_A = ///
            ((1-weight1/sum_w)^2/(n1-1)) + ///
            ((1-weight2/sum_w)^2/(n2-1)) + ///
            ((1-weight3/sum_w)^2/(n3-1)) if analyzable
        generate double F = ///
            ((weight1*(mean1-mean_w)^2 + ///
              weight2*(mean2-mean_w)^2 + ///
              weight3*(mean3-mean_w)^2) / 2) / ///
            (1 + (2*(3-2)/(3^2-1))*welch_A) if analyzable
        generate double df1 = 2 if analyzable
        generate double df2 = (3^2 - 1) / (3 * welch_A) if analyzable
        generate double p = Ftail(df1, df2, F) if analyzable

        generate long result_id = _n
        generate double q = .
        generate long fdr_rank = .
        generate long fdr_m = .

        save `"`prefdr'"', replace
        keep result_id p
        keep if !missing(p)
        sort p result_id
        generate long fdr_rank = _n
        quietly count
        generate long fdr_m = r(N)
        generate double q = p * fdr_m / fdr_rank
        gsort -fdr_rank
        replace q = min(q, q[_n-1]) if _n > 1
        replace q = min(q, 1)
        keep result_id q fdr_rank fdr_m
        save `"`fdrvalues'"', replace
        use `"`prefdr'"', clear
        drop q fdr_rank fdr_m
        merge 1:1 result_id using `"`fdrvalues'"', nogen

        generate byte omnibus_sig = q < `alpha' if !missing(q)

        foreach pp in 12 13 23 {
            local a = substr("`pp'", 1, 1)
            local b = substr("`pp'", 2, 1)
            generate double gh_df`pp' = ///
                (variance`a'/n`a' + variance`b'/n`b')^2 / ///
                ((variance`a'/n`a')^2/(n`a'-1) + ///
                 (variance`b'/n`b')^2/(n`b'-1)) if omnibus_sig
            generate double gh_q`pp' = abs(mean`a' - mean`b') / ///
                sqrt(.5 * (variance`a'/n`a' + variance`b'/n`b')) if omnibus_sig
            generate double gh_p`pp' = max(0, min(1, ///
                1 - tukeyprob(3, gh_df`pp', gh_q`pp'))) if omnibus_sig

            generate double sd_av`pp' = sqrt((variance`a' + variance`b') / 2) ///
                if omnibus_sig
            generate double es_df`pp' = n`a' + n`b' - 2 if omnibus_sig
            generate double J`pp' = 1 - 3/(4 * es_df`pp' - 1) if omnibus_sig
            generate double d_av`pp' = (mean`a' - mean`b') / sd_av`pp' ///
                if omnibus_sig
            generate double gav`pp' = J`pp' * d_av`pp' if omnibus_sig
        }

        generate byte pairwise_sig = ///
            gh_p12 < `alpha' | gh_p13 < `alpha' | gh_p23 < `alpha'
        generate byte displayed = omnibus_sig & pairwise_sig

        order item_no variable rowlabel n1 mean1 sd1 n2 mean2 sd2 n3 mean3 sd3 ///
            F df1 df2 p q gh_p12 gav12 gh_p13 gav13 gh_p23 gav23
        save `"`fullresults'"', replace
        if `"`results'"' != "" {
            save `"`results'"', `replace'
        }

        if `"`show'"' == "significant" keep if displayed
        else if `"`show'"' == "omnibus" keep if omnibus_sig
        quietly count
        local ndisplay = r(N)
        if `ndisplay' == 0 {
            di as err "no outcomes satisfy show(`show')"
            di as txt "use show(all) to display all analyzable outcomes"
            restore
            exit 2000
        }
        save `"`displayresults'"', replace

        local alpha01 = .01
        local alpha001 = .001

        use `"`displayresults'"', clear
        sort item_no

        forvalues j = 1/3 {
            generate str12 mean_txt`j' = ///
                cond(missing(mean`j'), ".", strtrim(string(mean`j', "%9.2f")))
            generate str14 sd_txt`j' = ///
                cond(missing(sd`j'), "(.)", "(" + strtrim(string(sd`j', "%9.2f")) + ")")
        }
        generate str18 F_txt = cond(missing(F), ".", strtrim(string(F, "%9.2f")))
        if `"`showdf'"' != "" {
            replace F_txt = strtrim(string(F, "%9.2f")) + " (" + ///
                strtrim(string(df1, "%9.0f")) + ", " + ///
                strtrim(string(df2, "%9.1f")) + ")" if !missing(F)
        }
        generate str12 p_txt = cond(missing(p), ".", ///
            cond(p < `alpha001', "<.001", ///
            subinstr(strtrim(string(p, "%9.3f")), "0.", ".", 1)))
        generate str12 q_txt = cond(missing(q), ".", ///
            cond(q < `alpha001', "<.001", ///
            subinstr(strtrim(string(q, "%9.3f")), "0.", ".", 1)))
        foreach pp in 12 13 23 {
            generate str20 gav_txt`pp' = ""
            replace gav_txt`pp' = strtrim(string(abs(gav`pp'), "%9.2f")) ///
                if gh_p`pp' < `alpha'
            replace gav_txt`pp' = gav_txt`pp' + "***" ///
                if gh_p`pp' < `alpha001'
            replace gav_txt`pp' = gav_txt`pp' + "**" ///
                if gh_p`pp' < `alpha01' & gh_p`pp' >= `alpha001'
            replace gav_txt`pp' = gav_txt`pp' + "*" ///
                if gh_p`pp' < `alpha' & gh_p`pp' >= `alpha01'
        }
        save `"`tabledata'"', replace

        generate int label_chars = ustrlen(rowlabel)
        generate int block_chars = ustrlen(blocklabel)
        generate int display_chars = max(label_chars, block_chars)
        quietly summarize display_chars
        local max_label_chars = r(max)
        drop label_chars block_chars display_chars

        quietly levelsof blockid if blocklabel != "", local(blocks_shown)
        local nblocks_shown : word count `blocks_shown'
        local use_blocks = ((`"`blockfile'"' != "" | `"`blockfromlabel'"' != "" | `"`blockfromchar'"' != "") & (`nblocks_shown' > 1 | `"`showblock'"' != ""))

        local doc_font "Times New Roman"
        local doc_font_size 10
        local header_rows = 2
        local var_width_min = 3.750
        local var_width_max = 4.100
        local char_width = 0.085
        local var_padding = 0.260
        local var_width = min(`var_width_max', max(`var_width_min', ///
            (`max_label_chars' * `char_width') + `var_padding'))
        local mean_width = 0.430
        local sd_width = 0.520
        local gap_width = 0.045
        local F_width = 0.420
        if `"`showdf'"' != "" local F_width = 0.920
        local p_width = 0.420
        local q_width = 0.520
        local pair_width = 0.540

        local nrows = _N + `header_rows' + 1 + `use_blocks' * `nblocks_shown'
        local widths `"`var_width' `mean_width' `sd_width' `gap_width' `mean_width' `sd_width' `gap_width' `mean_width' `sd_width' `gap_width' `F_width' `gap_width' `p_width' `gap_width' `q_width' `gap_width' `pair_width' `pair_width' `pair_width'"'
        local ncols : word count `widths'
        local width_total = 0
        foreach w of local widths {
            local width_total = `width_total' + `w'
        }
        local width_total_txt : display %6.3f `width_total'
        local width_total_txt = strtrim("`width_total_txt'") + "in"

        putdocx clear
        putdocx begin, pagesize(letter) landscape ///
            margin(left, .45) margin(right, .45) ///
            font("`doc_font'", `doc_font_size')
        putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
        putdocx text (`"`tablenumber'"'), bold
        putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
        putdocx text (`"`title'"'), italic
        putdocx table owatbl = (`nrows', `ncols'), ///
            width(`width_total_txt') halign(left) border(all, nil) ///
            cellmargin(top, .5pt) cellmargin(bottom, 0pt) ///
            cellmargin(left, 2pt) cellmargin(right, 2pt) ///
            headerrow(`header_rows')

        tokenize `"`widths'"'
        forvalues c = 1/`ncols' {
            local cw : display %6.3f `1'
            local cw = strtrim("`cw'") + "in"
            putdocx table owatbl(.,`c'), width(`cw')
            macro shift
        }

        local var_col = 1
        local sub1 = ustrunescape("\u2081")
        local sub2 = ustrunescape("\u2082")
        local sub3 = ustrunescape("\u2083")
        local g1_m = 2
        local g1_sd = 3
        local gap1 = 4
        local g2_m = 5
        local g2_sd = 6
        local gap2 = 7
        local g3_m = 8
        local g3_sd = 9
        local gap3 = 10
        local F_col = 11
        local gap4 = 12
        local p_col = 13
        local gap5 = 14
        local q_col = 15
        local gap6 = 16
        local p12_col = 17
        local p13_col = 18
        local p23_col = 19
        local gap_cols "`gap1' `gap2' `gap3' `gap4' `gap5' `gap6'"

        putdocx table owatbl(1,`var_col') = ("Variable")
        foreach c of local gap_cols {
            putdocx table owatbl(1,`c') = ("")
            putdocx table owatbl(2,`c') = ("")
            putdocx table owatbl(1,`c'), border(bottom, nil)
        }

        putdocx table owatbl(1,`F_col') = ("F")
        if `"`showdf'"' != "" putdocx table owatbl(1,`F_col') = ("F (df1, df2)")
        putdocx table owatbl(1,`p_col') = ("p")
        putdocx table owatbl(1,`p_col'), italic
        putdocx table owatbl(1,`q_col') = ("FDR q")
        putdocx table owatbl(1,`q_col'), italic

        putdocx table owatbl(1,`p12_col'), colspan(3) halign(center) border(bottom, single, black, .5pt)
        putdocx table owatbl(1,`p12_col') = ("Multiple Comparisons")
        if `"`availablecase'"' == "" {
            putdocx table owatbl(1,`g3_m'), colspan(2) halign(center) border(bottom, single, black, .5pt)
            putdocx table owatbl(1,`g3_m') = (`"G`sub3' (n`sub3'=`group_N3')"')
            putdocx table owatbl(1,`g2_m'), colspan(2) halign(center) border(bottom, single, black, .5pt)
            putdocx table owatbl(1,`g2_m') = (`"G`sub2' (n`sub2'=`group_N2')"')
            putdocx table owatbl(1,`g1_m'), colspan(2) halign(center) border(bottom, single, black, .5pt)
            putdocx table owatbl(1,`g1_m') = (`"G`sub1' (n`sub1'=`group_N1')"')
        }
        else {
            putdocx table owatbl(1,`g3_m'), colspan(2) halign(center) border(bottom, single, black, .5pt)
            putdocx table owatbl(1,`g3_m') = ("G`sub3'")
            putdocx table owatbl(1,`g2_m'), colspan(2) halign(center) border(bottom, single, black, .5pt)
            putdocx table owatbl(1,`g2_m') = ("G`sub2'")
            putdocx table owatbl(1,`g1_m'), colspan(2) halign(center) border(bottom, single, black, .5pt)
            putdocx table owatbl(1,`g1_m') = ("G`sub1'")
        }

        foreach c in `var_col' `F_col' `p_col' `q_col' {
            putdocx table owatbl(2,`c') = ("")
        }
        foreach c in `g1_m' `g2_m' `g3_m' {
            putdocx table owatbl(2,`c') = ("M")
            putdocx table owatbl(2,`c'), italic
        }
        foreach c in `g1_sd' `g2_sd' `g3_sd' {
            putdocx table owatbl(2,`c') = ("SD")
            putdocx table owatbl(2,`c'), italic
        }
        putdocx table owatbl(2,`p12_col') = ("G`sub1'-G`sub2'")
        putdocx table owatbl(2,`p13_col') = ("G`sub1'-G`sub3'")
        putdocx table owatbl(2,`p23_col') = ("G`sub2'-G`sub3'")

        local row = `header_rows'
        local section_rows ""
        if `use_blocks' {
            sort blockid item_no
            foreach b of local blocks_shown {
                local ++row
                local section_rows `"`section_rows' `row'"'
                quietly levelsof blocklabel if blockid == `b', local(thisblock) clean
                putdocx table owatbl(`row',`var_col') = (`"`thisblock'"')
                forvalues c = 2/`ncols' {
                    putdocx table owatbl(`row',`c') = ("")
                }
                forvalues i = 1/`=_N' {
                    if blockid[`i'] != `b' continue
                    local ++row
                    local thislabel `"`=rowlabel[`i']'"'
                    putdocx table owatbl(`row',`var_col') = (`"   `thislabel'"')
                    putdocx table owatbl(`row',`g1_m') = (mean_txt1[`i'])
                    putdocx table owatbl(`row',`g1_sd') = (sd_txt1[`i'])
                    putdocx table owatbl(`row',`g2_m') = (mean_txt2[`i'])
                    putdocx table owatbl(`row',`g2_sd') = (sd_txt2[`i'])
                    putdocx table owatbl(`row',`g3_m') = (mean_txt3[`i'])
                    putdocx table owatbl(`row',`g3_sd') = (sd_txt3[`i'])
                    putdocx table owatbl(`row',`F_col') = (F_txt[`i'])
                    putdocx table owatbl(`row',`p_col') = (p_txt[`i'])
                    putdocx table owatbl(`row',`q_col') = (q_txt[`i'])
                    putdocx table owatbl(`row',`p12_col') = (gav_txt12[`i'])
                    putdocx table owatbl(`row',`p13_col') = (gav_txt13[`i'])
                    putdocx table owatbl(`row',`p23_col') = (gav_txt23[`i'])
                    foreach c of local gap_cols {
                        putdocx table owatbl(`row',`c') = ("")
                    }
                }
            }
        }
        else {
            sort item_no
            forvalues i = 1/`=_N' {
                local ++row
                local thislabel `"`=rowlabel[`i']'"'
                putdocx table owatbl(`row',`var_col') = (`"`thislabel'"')
                putdocx table owatbl(`row',`g1_m') = (mean_txt1[`i'])
                putdocx table owatbl(`row',`g1_sd') = (sd_txt1[`i'])
                putdocx table owatbl(`row',`g2_m') = (mean_txt2[`i'])
                putdocx table owatbl(`row',`g2_sd') = (sd_txt2[`i'])
                putdocx table owatbl(`row',`g3_m') = (mean_txt3[`i'])
                putdocx table owatbl(`row',`g3_sd') = (sd_txt3[`i'])
                putdocx table owatbl(`row',`F_col') = (F_txt[`i'])
                putdocx table owatbl(`row',`p_col') = (p_txt[`i'])
                putdocx table owatbl(`row',`q_col') = (q_txt[`i'])
                putdocx table owatbl(`row',`p12_col') = (gav_txt12[`i'])
                putdocx table owatbl(`row',`p13_col') = (gav_txt13[`i'])
                putdocx table owatbl(`row',`p23_col') = (gav_txt23[`i'])
                foreach c of local gap_cols {
                    putdocx table owatbl(`row',`c') = ("")
                }
            }
        }

        local note_row = `nrows'
        local group_note `"G1 = `group_name1'; G2 = `group_name2'; G3 = `group_name3'"'
        local sample_text "A common complete-case sample was used across all outcomes and the grouping variable. "
        if `"`availablecase'"' != "" {
            local sample_text "Outcome-specific available cases were used; sample sizes may vary across outcomes. "
        }
        local df_text ""
        if `"`showdf'"' != "" {
            local df_text "Welch numerator and denominator degrees of freedom are shown in parentheses after F. "
        }

        putdocx table owatbl(`note_row',1), colspan(`ncols') ///
            halign(left) valign(top) border(top, single, black, 1.25pt)
        putdocx table owatbl(`note_row',1) = ("Note. "), italic
        putdocx table owatbl(`note_row',1) = ///
            (`"`group_note'. `sample_text'Welch one-way ANOVA was used. FDR q-values are Benjamini-Hochberg adjusted Welch omnibus p-values. Games-Howell pairwise comparisons were performed only for FDR-significant omnibus tests. Pairwise columns report absolute Hedges' g_av effect sizes; blank cells indicate nonsignificant Games-Howell comparisons. `df_text'*"'), append
        putdocx table owatbl(`note_row',1) = ("p"), append italic
        putdocx table owatbl(`note_row',1) = (" < .05. **"), append
        putdocx table owatbl(`note_row',1) = ("p"), append italic
        putdocx table owatbl(`note_row',1) = (" < .01. ***"), append
        putdocx table owatbl(`note_row',1) = ("p"), append italic
        putdocx table owatbl(`note_row',1) = (" < .001."), append
        if `"`note'"' != "" {
            putdocx table owatbl(`note_row',1) = (`" `note'"'), append
        }

        putdocx table owatbl(.,.), font("`doc_font'", `doc_font_size') valign(center)
        putdocx table owatbl(1/2,.), halign(center)
        putdocx table owatbl(2,`p12_col'), halign(center)
        putdocx table owatbl(2,`p13_col'), halign(center)
        putdocx table owatbl(2,`p23_col'), halign(center)
        putdocx table owatbl(1,.), border(top, single, black, 1.25pt)
        putdocx table owatbl(2,.), border(bottom, single, black, .5pt)
        putdocx table owatbl(3/`=`nrows'-1',1), halign(left)
        foreach sr of local section_rows {
            putdocx table owatbl(`sr',1), bold italic halign(left)
        }
        foreach c in `g1_m' `g1_sd' `g2_m' `g2_sd' `g3_m' `g3_sd' `F_col' `p_col' `q_col' {
            putdocx table owatbl(3/`=`nrows'-1',`c'), halign(right)
        }
        foreach c in `p12_col' `p13_col' `p23_col' {
            putdocx table owatbl(3/`=`nrows'-1',`c'), halign(left)
        }

        putdocx save `"`saving'"', `replace' nomsg

        return scalar N = `sample_N'
        return scalar N_groups = 3
        return scalar N_outcomes = `nvars'
        return scalar N_displayed = `ndisplay'
        return scalar alpha = `alpha'
        return scalar mincell = `mincell'
        return scalar N_group1 = `group_N1'
        return scalar N_group2 = `group_N2'
        return scalar N_group3 = `group_N3'
        return local cmd "owatable"
        return local by "`by'"
        return local varlist "`varlist'"
        return local show "`show'"
        return local saving `"`saving'"'
        return local results `"`results'"'
        return local group1 `"`group_name1'"'
        return local group2 `"`group_name2'"'
        return local group3 `"`group_name3'"'
        if `"`availablecase'"' != "" return local sample "availablecase"
        else return local sample "completecase"
    restore

    di as txt "owatable complete"
    if `"`availablecase'"' == "" {
        di as txt "Complete-case sample: " as result `sample_N'
        di as txt "Group sizes: " as result "G1=`group_N1', G2=`group_N2', G3=`group_N3'"
    }
    else {
        di as txt "Available-case mode was used; sample sizes may vary across outcomes."
    }
    di as txt "Word table saved to:"
    di as result `"  `saving'"'
    if `"`results'"' != "" {
        di as txt "Results data saved to:"
        di as result `"  `results'"'
    }
end
