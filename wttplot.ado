program define wttplot, rclass
    version 19.5

    syntax varlist(numeric min=1) [if] [in], ///
        BY(varname) GRAPHDIR(string) ///
        [ REPLACE ALPHA(real 0.05) ///
          BLOCKFILE(string) BLOCKFROMLABEL BLOCKFROMCHAR ///
          SHOW(string) ///
          MINCELL(integer 2) ///
          GRAPHBY(string) COMBINE(integer 1) COLumns(integer 0) LAYOUT(string) ///
          LABELMODE(string) MAPFILE(string) ///
          FORMATS(string) ///
          ORIENTation(string) PNGWidth(integer 3200) ///
          RESULTS(string) ///
          TITLE(string) XTITLE(string) NOTE(string) ///
          TITLESIZE(string) BLOCKSIZE(string) ///
          LABELSIZE(string) XLABSIZE(string) XTITLESIZE(string) NOTESIZE(string) ]

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
    if !inlist(`"`show'"', "significant", "all") {
        di as err "show() must be significant or all"
        exit 198
    }

    local graphby = lower(strtrim(`"`graphby'"'))
    if `"`graphby'"' == "" local graphby "block"
    if !inlist(`"`graphby'"', "block", "all") {
        di as err "graphby() must be block or all"
        exit 198
    }
    if `combine' > 1 & `"`graphby'"' == "all" {
        di as err "combine() may not be combined with graphby(all)"
        exit 198
    }
    if `combine' < 1 | `combine' > 6 {
        di as err "combine() must be between 1 and 6"
        exit 198
    }
    if `columns' < 0 | `columns' > 4 {
        di as err "columns() must be between 0 and 4"
        exit 198
    }
    local layout = lower(strtrim(`"`layout'"'))
    if `"`layout'"' == "" local layout "auto"
    if !inlist(`"`layout'"', "auto", "horizontal", "vertical") {
        di as err "layout() must be auto, horizontal, or vertical"
        exit 198
    }

    local labelmode = lower(strtrim(`"`labelmode'"'))
    if `"`labelmode'"' == "" {
        if `combine' > 1 & `"`layout'"' == "vertical" local labelmode "item"
        else local labelmode "full"
    }
    if !inlist(`"`labelmode'"', "full", "item", "varname") {
        di as err "labelmode() must be full, item, or varname"
        exit 198
    }

    local formats = lower(strtrim(`"`formats'"'))
    if `"`formats'"' == "" local formats "pdf png"
    foreach fmt of local formats {
        if !inlist(`"`fmt'"', "pdf", "png") {
            di as err "formats() may contain only pdf and/or png"
            exit 198
        }
    }

    local orientation = lower(strtrim(`"`orientation'"'))
    if `"`orientation'"' == "" local orientation "auto"
    if !inlist(`"`orientation'"', "landscape", "portrait", "auto") {
        di as err "orientation() must be landscape, portrait, or auto"
        exit 198
    }

    if `pngwidth' < 1200 {
        di as err "pngwidth() must be at least 1200"
        exit 198
    }

    if `"`title'"' == "" local title "Two-Group Effect-Size Comparisons"
    if `"`xtitle'"' == "" local xtitle "Signed Hedges' {it:g}{sub:av}"
    if `"`titlesize'"' == "" local titlesize "medsmall"
    if `"`blocksize'"' == "" local blocksize "medsmall"
    if `"`labelsize'"' == "" local labelsize "small"
    if `"`xlabsize'"' == "" local xlabsize "small"
    if `"`xtitlesize'"' == "" local xtitlesize "small"
    if `"`notesize'"' == "" local notesize "vsmall"
    local usernote `"`note'"'

    local n_block_sources = (`"`blockfile'"' != "") + (`"`blockfromlabel'"' != "") + (`"`blockfromchar'"' != "")
    if `n_block_sources' > 1 {
        di as err "only one of blockfile(), blockfromlabel, or blockfromchar may be specified"
        exit 198
    }

    capture mkdir `"`graphdir'"'
    capture confirm file `"`graphdir'"'

    if `"`results'"' != "" {
        capture confirm new file `"`results'"'
        if _rc & `"`replace'"' == "" {
            di as err `"file `results' already exists; specify replace"'
            exit 602
        }
    }
    if `"`mapfile'"' != "" {
        capture confirm new file `"`mapfile'"'
        if _rc & `"`replace'"' == "" {
            di as err `"file `mapfile' already exists; specify replace"'
            exit 602
        }
    }

    marksample touse, novarlist
    markout `touse' `by', strok
    markout `touse' `varlist'

    quietly count if `touse'
    if r(N) == 0 {
        di as err "no observations in the analysis sample"
        exit 2000
    }

    preserve
        keep if `touse'

        tempvar gid
        quietly egen `gid' = group(`by') if !missing(`by'), label
        quietly levelsof `gid', local(gids)
        local ngroups : word count `gids'
        if `ngroups' != 2 {
            di as err "by() must identify exactly two observed groups in the analysis sample"
            restore
            exit 198
        }
        local g1 : word 1 of `gids'
        local g2 : word 2 of `gids'

        quietly levelsof `by' if `gid' == `g1', local(orig1) clean
        quietly levelsof `by' if `gid' == `g2', local(orig2) clean
        local group_name1 "`orig1'"
        local group_name2 "`orig2'"
        capture confirm numeric variable `by'
        if !_rc {
            local vallab : value label `by'
            if `"`vallab'"' != "" {
                local first1 : word 1 of `orig1'
                local first2 : word 1 of `orig2'
                local lab1 : label `vallab' `first1'
                local lab2 : label `vallab' `first2'
                if `"`lab1'"' != "" local group_name1 `"`lab1'"'
                if `"`lab2'"' != "" local group_name2 `"`lab2'"'
            }
        }

        if `"`usernote'"' == "" {
            local g1note = lower(`"`group_name1'"')
            local g2note = lower(`"`group_name2'"')
            local note1 `"{it:Note.} Positive values indicate that the `g1note' mean is greater than the `g2note' mean; negative values indicate the reverse."'
            local note2 `"Bars show approximate `=100*(1-`alpha')'% CIs for signed Hedges' {it:g}{sub:av}."'
        }
        else {
            local note1 `"{it:Note.} `usernote'"'
            local note2 ""
        }

        tempfile blockmapclean rawresults prefdr fdrvalues plotdata
        tempname rawpost

        if `"`blockfile'"' != "" {
            capture confirm file `"`blockfile'"'
            if _rc {
                di as err `"blockfile() not found: `blockfile'"'
                restore
                exit 601
            }
            preserve
                quietly use `"`blockfile'"', clear
                foreach needed in varname blockid blocklabel {
                    capture confirm variable `needed'
                    if _rc {
                        di as err "blockfile() must contain variable `needed'"
                        restore
                        restore
                        exit 111
                    }
                }
                capture confirm string variable varname
                if _rc {
                    di as err "varname in blockfile() must be a string variable"
                    restore
                    restore
                    exit 109
                }
                capture confirm string variable blocklabel
                if _rc {
                    di as err "blocklabel in blockfile() must be a string variable"
                    restore
                    restore
                    exit 109
                }
                keep varname blockid blocklabel
                quietly replace varname = strtrim(varname)
                quietly replace blocklabel = strtrim(blocklabel)
                quietly count if missing(varname) | missing(blockid) | missing(blocklabel)
                if r(N) > 0 {
                    di as err "blockfile() contains missing varname, blockid, or blocklabel"
                    restore
                    restore
                    exit 459
                }
                quietly save `"`blockmapclean'"', replace
            restore
        }

        quietly postfile `rawpost' int item_no ///
            str32 variable str32 label_blockcode str244 label_blocklabel str244 rowlabel ///
            str80 group1 str80 group2 ///
            double n1 mean1 sd1 n2 mean2 sd2 t df p gav se_gav lb_gav ub_gav ///
            using `"`rawresults'"', replace

        local item = 0
        foreach y of varlist `varlist' {
            local ++item
            local ylab : variable label `y'
            local rowlab `"`ylab'"'
            if `"`rowlab'"' == "" local rowlab "`y'"
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
                if substr(`"`ylab'"', 1, 1) == "[" & `closepos' > 0 & `pipepos' > 0 & `pipepos' < `closepos' {
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

            quietly summarize `y' if `gid' == `g1'
            local n1 = r(N)
            local mean1 = r(mean)
            local sd1 = r(sd)
            quietly summarize `y' if `gid' == `g2'
            local n2 = r(N)
            local mean2 = r(mean)
            local sd2 = r(sd)

            local t = .
            local df = .
            local p = .
            local gav = .
            local se_gav = .
            local lb_gav = .
            local ub_gav = .
            if `n1' >= `mincell' & `n2' >= `mincell' & `sd1' > 0 & `sd2' > 0 {
                local v1 = `sd1'^2
                local v2 = `sd2'^2
                local se = sqrt(`v1'/`n1' + `v2'/`n2')
                local t = (`mean1' - `mean2') / `se'
                local df = (`v1'/`n1' + `v2'/`n2')^2 / ((`v1'/`n1')^2/(`n1'-1) + (`v2'/`n2')^2/(`n2'-1))
                local p = 2 * ttail(`df', abs(`t'))
                local sdav = sqrt((`v1' + `v2') / 2)
                local esdf = `n1' + `n2' - 2
                local J = 1 - 3/(4 * `esdf' - 1)
                local gav = `J' * ((`mean1' - `mean2') / `sdav')
                local se_gav = sqrt((`n1' + `n2') / (`n1' * `n2') + (`gav'^2) / (2 * (`n1' + `n2' - 2)))
                local zcrit = invnormal(1 - `alpha'/2)
                local lb_gav = `gav' - `zcrit' * `se_gav'
                local ub_gav = `gav' + `zcrit' * `se_gav'
            }

            post `rawpost' (`item') (`"`y'"') (`"`label_blockcode'"') (`"`label_blocklabel'"') ///
                (`"`rowlab'"') (`"`group_name1'"') (`"`group_name2'"') ///
                (`n1') (`mean1') (`sd1') (`n2') (`mean2') (`sd2') ///
                (`t') (`df') (`p') (`gav') (`se_gav') (`lb_gav') (`ub_gav')
        }
        quietly postclose `rawpost'

        quietly use `"`rawresults'"', clear

        if `"`blockfile'"' != "" {
            quietly drop label_blockcode label_blocklabel
            quietly merge 1:1 variable using `"`blockmapclean'"', keep(master match)
            quietly count if _merge == 1
            if r(N) > 0 {
                di as err "blockfile() does not map all variables in varlist"
                restore
                exit 459
            }
            quietly drop _merge
            capture confirm numeric variable blockid
            if _rc quietly encode blockid, gen(blockid_num)
            else quietly generate double blockid_num = blockid
            quietly drop blockid
            quietly rename blockid_num blockid
            quietly generate str32 blockcode = string(blockid)
        }
        else if `"`blockfromlabel'"' != "" | `"`blockfromchar'"' != "" {
            quietly generate str32 blockcode = label_blockcode
            quietly generate str244 blocklabel = label_blocklabel
            quietly count if missing(blockcode) | missing(blocklabel)
            if r(N) > 0 {
                di as err "could not parse block information for all variables"
                restore
                exit 198
            }
            capture destring blockcode, generate(blockid) ignore("B b _-") force
            quietly count if missing(blockid)
            if r(N) > 0 {
                quietly encode blockcode, generate(blockid2)
                quietly drop blockid
                quietly rename blockid2 blockid
            }
            quietly drop label_blockcode label_blocklabel
        }
        else {
            quietly generate double blockid = 1
            quietly generate str32 blockcode = "B01"
            quietly generate str244 blocklabel = "All outcomes"
            quietly drop label_blockcode label_blocklabel
        }

        quietly generate long result_id = _n
        quietly save `"`prefdr'"', replace

        quietly keep result_id p
        quietly keep if !missing(p)
        quietly sort p result_id
        quietly generate long fdr_rank = _n
        quietly count
        quietly generate long fdr_m = r(N)
        quietly generate double q = p * fdr_m / fdr_rank
        quietly gsort -fdr_rank
        quietly replace q = min(q, q[_n-1]) if _n > 1
        quietly replace q = min(q, 1)
        quietly keep result_id q
        quietly save `"`fdrvalues'"', replace

        quietly use `"`prefdr'"', clear
        quietly merge 1:1 result_id using `"`fdrvalues'"', nogen
        quietly generate byte fdr_sig = !missing(q) & q < `alpha'
        quietly sort blockid item_no

        if `"`results'"' != "" {
            quietly save `"`results'"', replace
        }
        quietly save `"`plotdata'"', replace

        if `"`mapfile'"' != "" {
            quietly keep if !missing(gav)
            if `"`show'"' == "significant" quietly keep if fdr_sig
            quietly sort blockid gav item_no
            quietly generate long No = _n
            quietly generate str32 Item = variable
            quietly replace Item = "item" + string(real(substr(variable, 5, .)), "%02.0f") if regexm(variable, "^item[0-9]+$")
            quietly generate str244 Item_label = rowlabel
            quietly generate str244 Block = blocklabel
            quietly keep No Item Item_label Block
            quietly label variable No "No."
            quietly label variable Item "Item"
            quietly label variable Item_label "Item label"
            quietly label variable Block "Block"
            tempvar maplen
            quietly generate double `maplen' = length(Item)
            quietly summarize `maplen', meanonly
            local w_item = min(18, max(8, r(max) + 2))
            quietly replace `maplen' = length(Item_label)
            quietly summarize `maplen', meanonly
            local w_label = min(72, max(24, r(max) + 2))
            quietly replace `maplen' = length(Block)
            quietly summarize `maplen', meanonly
            local w_block = min(34, max(14, r(max) + 2))
            quietly count
            local maprows = r(N) + 1
            local w_no = min(8, max(5, length("`maprows'") + 2))
            quietly drop `maplen'
            quietly export excel using `"`mapfile'"', firstrow(varlabels) replace
            putexcel set `"`mapfile'"', modify
            quietly putexcel A1:D`maprows', font("Times New Roman", 12)
            quietly putexcel A1:D1, bold hcenter font("Times New Roman", 12)
            capture noisily _wttplot_xlsx_widths `"`mapfile'"' `w_no' `w_item' `w_label' `w_block'
            quietly use `"`plotdata'"', clear
        }

        quietly count if missing(gav)
        if r(N) > 0 {
            di as txt "warning: one or more outcomes had too few observations or zero variance; effect sizes were not plotted for those rows"
        }

        if `"`graphby'"' == "all" {
            quietly generate double plotblock = 1
            local blocks "1"
        }
        else {
            quietly generate double plotblock = blockid
            quietly levelsof plotblock, local(blocks)
        }

        local nblocks_total : word count `blocks'
        if 1 {
            local effective_panels = `combine'
            quietly use `"`plotdata'"', clear
            quietly keep if !missing(gav)
            if `"`show'"' == "significant" quietly keep if fdr_sig
            quietly generate double rowlabel_len = ustrlen(rowlabel)
            quietly summarize rowlabel_len
            local combine_labwidth = r(max)
            quietly summarize lb_gav
            local panel_xmin = min(r(min), 0)
            quietly summarize ub_gav
            local panel_xmax = max(r(max), 0)
            local panel_xpad = (`panel_xmax' - `panel_xmin') * .10
            if `panel_xpad' <= 0 | missing(`panel_xpad') local panel_xpad = .25
            local panel_xmin = `panel_xmin' - `panel_xpad'
            local panel_xmax = `panel_xmax' + `panel_xpad'
            local panel_xabs = max(abs(`panel_xmin'), abs(`panel_xmax'))
            if `panel_xabs' <= .8 {
                local panel_xstep = .2
            }
            else if `panel_xabs' <= 1.5 {
                local panel_xstep = .5
            }
            else {
                local panel_xstep = 1
            }
            local panel_xbound = ceil(`panel_xabs' / `panel_xstep') * `panel_xstep'
            if `panel_xbound' <= 0 | missing(`panel_xbound') local panel_xbound = .5
            local panel_xmin = -`panel_xbound'
            local panel_xmax = `panel_xbound'
            local panel_xmin_txt : display %5.2f `panel_xmin'
            local panel_xmax_txt : display %5.2f `panel_xmax'
            local panel_xstep_txt : display %5.2f `panel_xstep'
            local panel_xticks `"`panel_xmin_txt'(`panel_xstep_txt')`panel_xmax_txt'"'
            if `columns' > 0 {
                local panel_cols = `columns'
            }
            else if `"`layout'"' == "vertical" {
                local panel_cols = 1
            }
            else if `"`layout'"' == "horizontal" {
                local panel_cols = `effective_panels'
            }
            else if `effective_panels' <= 3 {
                local panel_cols = `effective_panels'
            }
            else {
                local panel_cols = 2
            }
            local panel_page = 1
            local panel_count = 0
            local panel_graphs ""
        }

        local exported ""
        local graphcount = 0
        local outcount = 0
        local blocknum = 0
        if `combine' > 1 & `"`layout'"' == "vertical" {
            local panel_page = 1
            while `blocknum' < `nblocks_total' {
                local page_blocks ""
                local panel_count = 0
                while `panel_count' < `combine' & `blocknum' < `nblocks_total' {
                    local ++blocknum
                    local b : word `blocknum' of `blocks'
                    local page_blocks `"`page_blocks' `b'"'
                    local ++panel_count
                }

                local left_blocks ""
                local right_blocks ""
                local split = ceil(`panel_count' / 2)
                local j = 0
                foreach pb of local page_blocks {
                    local ++j
                    if `j' <= `split' local left_blocks `"`left_blocks' `pb'"'
                    else local right_blocks `"`right_blocks' `pb'"'
                }

                local vstack_graphs ""
                forvalues side = 1/2 {
                    if `side' == 1 local side_blocks `"`left_blocks'"'
                    else local side_blocks `"`right_blocks'"'
                    if `"`side_blocks'"' == "" continue

                    quietly use `"`plotdata'"', clear
                    quietly keep if !missing(gav)
                    if `"`show'"' == "significant" quietly keep if fdr_sig
                    quietly generate byte __sidekeep = 0
                    foreach pb of local side_blocks {
                        quietly replace __sidekeep = 1 if blockid == `pb'
                    }
                    quietly keep if __sidekeep
                    quietly drop __sidekeep
                    quietly count
                    if r(N) == 0 continue

                    local ++graphcount
                    quietly sort blockid gav item_no
                    quietly generate double yaxis = .
                    local ylabels ""
                    local y = 0
                    foreach pb of local side_blocks {
                        quietly count if blockid == `pb'
                        if r(N) == 0 continue
                        quietly levelsof blocklabel if blockid == `pb', local(blocktitle) clean
                        local ++y
                        local ylabels `"`ylabels' `y' `"{bf:`blocktitle'}"'"'
                        local ++y
                        quietly count
                        local nobs = r(N)
                        forvalues i = 1/`nobs' {
                            if blockid[`i'] == `pb' {
                                local ++y
                                quietly replace yaxis = `y' in `i'
                                if `"`labelmode'"' == "full" {
                                    local lab = rowlabel[`i']
                                }
                                else if `"`labelmode'"' == "varname" {
                                    local lab = variable[`i']
                                }
                                else {
                                    local lab = "Item " + string(item_no[`i'], "%02.0f")
                                }
                                local ylabels `"`ylabels' `y' `"`lab'"'"'
                            }
                        }
                        local y = `y' + 2
                    }
                    local ymax = `y'
                    local graphname "wttplot_vstack_`panel_page'_`side'"

                    twoway ///
                        (rcap lb_gav ub_gav yaxis if !missing(yaxis), horizontal lcolor(gs7) lwidth(medthin)) ///
                        (scatter yaxis gav if !missing(yaxis), msymbol(O) mcolor(black) msize(small)), ///
                        yscale(reverse range(.5 `ymax')) ///
                        ylabel(`ylabels', angle(0) labsize(`labelsize') noticks nogrid) ///
                        xlabel(`panel_xticks', labsize(`xlabsize') nogrid) ///
                        xline(0, lcolor(gs10) lwidth(thin)) ///
                        xscale(range(`panel_xmin' `panel_xmax')) ///
                        xtitle("") ///
                        ytitle("") ///
                        legend(off) ///
                        graphregion(color(white)) plotregion(color(white)) ///
                        name(`graphname', replace) ///
                        xsize(5.60) ysize(7.20) nodraw
                    local vstack_graphs `"`vstack_graphs' `graphname'"'
                }

                if `"`vstack_graphs'"' == "" continue
                local page_suffix : display %02.0f `panel_page'
                local vstack_xtitle "{space 14}`xtitle'"
                graph combine `vstack_graphs', col(2) xcommon imargin(zero) ///
                    title(`"`title'"', size(`titlesize') margin(zero)) ///
                    b1title(`"`vstack_xtitle'"', size(vsmall)) ///
                    note(`"`note1'"' `"`note2'"', size(`notesize') margin(medsmall)) ///
                    graphregion(color(white)) ///
                    name(wttplot_vstack, replace) ///
                    xsize(11.50) ysize(8.60)
                foreach fmt of local formats {
                    local outfile `"`graphdir'/combined_`page_suffix'.`fmt'"'
                    capture confirm new file `"`outfile'"'
                    if _rc & `"`replace'"' == "" {
                        di as err `"file `outfile' already exists; specify replace"'
                        restore
                        exit 602
                    }
                    if `"`fmt'"' == "png" {
                        quietly graph export `"`outfile'"', width(`pngwidth') replace
                    }
                    else {
                        quietly graph export `"`outfile'"', as(pdf) replace
                    }
                    local exported `"`exported' `"`outfile'"'"'
                }
                capture graph drop `vstack_graphs'
                local ++outcount
                local ++panel_page
            }
        }
        else if 0 {
            local panel_page = 1
            while `blocknum' < `nblocks_total' {
                local page_blocks ""
                local panel_count = 0
                while `panel_count' < `combine' & `blocknum' < `nblocks_total' {
                    local ++blocknum
                    local b : word `blocknum' of `blocks'
                    local page_blocks `"`page_blocks' `b'"'
                    local ++panel_count
                }

                quietly use `"`plotdata'"', clear
                quietly keep if !missing(gav)
                if `"`show'"' == "significant" quietly keep if fdr_sig
                quietly generate byte __pagekeep = 0
                foreach pb of local page_blocks {
                    quietly replace __pagekeep = 1 if blockid == `pb'
                }
                quietly keep if __pagekeep
                quietly drop __pagekeep
                quietly count
                if r(N) == 0 continue

                local ++graphcount
                quietly sort blockid gav item_no
                quietly generate double yaxis = .
                local ylabels ""
                local y = 0
                foreach pb of local page_blocks {
                    quietly count if blockid == `pb'
                    if r(N) == 0 continue
                    quietly levelsof blocklabel if blockid == `pb', local(blocktitle) clean
                    local ++y
                    local ylabels `"`ylabels' `y' `"{bf:`blocktitle'}"'"'
                    quietly count
                    local nobs = r(N)
                    forvalues i = 1/`nobs' {
                        if blockid[`i'] == `pb' {
                            local ++y
                            quietly replace yaxis = `y' in `i'
                            if `"`labelmode'"' == "item" {
                                local lab = "Item " + string(item_no[`i'], "%02.0f")
                            }
                            else if `"`labelmode'"' == "varname" {
                                local lab = variable[`i']
                            }
                            else {
                                local lab = rowlabel[`i']
                            }
                            local ylabels `"`ylabels' `y' `"{space 4}`lab'"'"'
                        }
                    }
                    local ++y
                }
                local ymax = `y'
                quietly count if !missing(yaxis)
                local nplot = r(N)
                local height = max(5.20, min(8.20, 1.60 + .17 * `ymax'))
                local gx = 11.20
                local gxtxt : display %4.2f `gx'
                local heighttxt : display %4.2f `height'
                local page_suffix : display %02.0f `panel_page'
                local vert_labelsize `"`labelsize'"'
                if `"`labelsize'"' == "small" local vert_labelsize "vsmall"

                twoway ///
                    (rcap lb_gav ub_gav yaxis if !missing(yaxis), horizontal lcolor(gs7) lwidth(medthin)) ///
                    (scatter yaxis gav if !missing(yaxis), msymbol(O) mcolor(black) msize(small)), ///
                    yscale(reverse range(.5 `ymax')) ///
                    ylabel(`ylabels', angle(0) labsize(`vert_labelsize') noticks nogrid) ///
                    xlabel(`panel_xticks', labsize(`xlabsize') nogrid) ///
                    xline(0, lcolor(gs10) lwidth(thin)) ///
                    xscale(range(`panel_xmin' `panel_xmax')) ///
                    xtitle(`"`xtitle'"', size(`xtitlesize')) ///
                    ytitle("") ///
                    title(`"`title'"', size(`titlesize') color(black) margin(medsmall)) ///
                    note(`"`note1'"' `"`note2'"', size(`notesize')) ///
                    legend(off) ///
                    graphregion(color(white)) plotregion(color(white)) ///
                    name(wttplot_combined, replace) ///
                    xsize(`gxtxt') ysize(`heighttxt')

                foreach fmt of local formats {
                    local outfile `"`graphdir'/combined_`page_suffix'.`fmt'"'
                    capture confirm new file `"`outfile'"'
                    if _rc & `"`replace'"' == "" {
                        di as err `"file `outfile' already exists; specify replace"'
                        restore
                        exit 602
                    }
                    if `"`fmt'"' == "png" {
                        quietly graph export `"`outfile'"', width(`pngwidth') replace
                    }
                    else {
                        quietly graph export `"`outfile'"', as(pdf) replace
                    }
                    local exported `"`exported' `"`outfile'"'"'
                }
                local ++outcount
                local ++panel_page
            }
        }
        else {
        foreach b of local blocks {
            local ++blocknum
            quietly use `"`plotdata'"', clear
            if `"`graphby'"' == "all" {
                quietly keep if !missing(gav)
                if `"`show'"' == "significant" quietly keep if fdr_sig
                local blocktitle `"`title'"'
                local filesuffix "all"
            }
            else {
                quietly keep if blockid == `b' & !missing(gav)
                if `"`show'"' == "significant" quietly keep if fdr_sig
                quietly levelsof blocklabel, local(blocktitle) clean
                local filesuffix : display %02.0f `blocknum'
                local filesuffix "block_`filesuffix'"
            }

            quietly count
            if r(N) == 0 continue

            local ++graphcount
            quietly sort gav item_no
            quietly generate double yaxis = _n
            quietly count
            local nplot = r(N)
            local ylabels ""
            forvalues i = 1/`nplot' {
                local yy = yaxis[`i']
                if `"`labelmode'"' == "item" {
                    local lab = "Item " + string(item_no[`i'], "%02.0f")
                }
                else if `"`labelmode'"' == "varname" {
                    local lab = variable[`i']
                }
                else {
                    local lab = rowlabel[`i']
                }
                if `combine' > 1 {
                    local lablen = ustrlen(`"`lab'"')
                    local labpad = `combine_labwidth' - `lablen'
                    if `labpad' > 0 {
                        local lab `"{space `labpad'}`lab'"'
                    }
                }
                local ylabels `"`ylabels' `yy' `"`lab'"'"'
            }

            quietly summarize lb_gav
            local xmin = min(r(min), 0)
            quietly summarize ub_gav
            local xmax = max(r(max), 0)
            local xpad = (`xmax' - `xmin') * .10
            if `xpad' <= 0 | missing(`xpad') local xpad = .25
            local xmin = `xmin' - `xpad'
            local xmax = `xmax' + `xpad'
            local xmin = `panel_xmin'
            local xmax = `panel_xmax'

            if `"`orientation'"' == "portrait" {
                local gx = 5.80
                local height = max(3.00, min(10.50, 1.55 + .25 * `nplot'))
            }
            else if `"`orientation'"' == "auto" {
                if `nplot' > 24 {
                    local gx = 6.20
                    local height = max(5.00, min(10.50, 1.45 + .22 * `nplot'))
                }
                else if `nplot' <= 4 {
                    local gx = 5.80
                    local height = max(2.15, min(3.10, 1.55 + .16 * `nplot'))
                }
                else {
                    local gx = 6.20
                    local height = max(2.70, min(6.80, 1.55 + .20 * `nplot'))
                }
            }
            else {
                local gx = 6.20
                local height = max(2.30, min(6.80, 1.55 + .22 * `nplot'))
            }
            local gxtxt : display %4.2f `gx'
            local heighttxt : display %4.2f `height'

            if `combine' > 1 {
                local graphname "wttplot_panel_`blocknum'"
                local thistitle `"`blocktitle'"'
                local thissubtitle ""
                local thisnote ""
                local thisxtitle ""
                local thismsize = cond(`"`show'"' == "all", "small", "vsmall")
                local thislabsize `"`labelsize'"'
                local thistitlesize `"`blocksize'"'
                local thissubtitlesize `"`blocksize'"'
            }
            else {
                local graphname "wttplot_graph"
                local thistitle `"`title'"'
                local thissubtitle `"`blocktitle'"'
                local thisnote `"`note1'"' `"`note2'"'
                local thisxtitle `"`xtitle'"'
                local thismsize "small"
                local thislabsize `"`labelsize'"'
                local thistitlesize `"`titlesize'"'
                local thissubtitlesize `"`blocksize'"'
            }
            local drawopt ""
            if `combine' > 1 local drawopt "nodraw"

            twoway ///
                (rcap lb_gav ub_gav yaxis, horizontal lcolor(gs7) lwidth(medthin)) ///
                (scatter yaxis gav, msymbol(O) mcolor(black) msize(`thismsize')), ///
                yscale(reverse) ///
                ylabel(`ylabels', angle(0) labsize(`thislabsize') noticks nogrid) ///
                xlabel(`panel_xticks', labsize(`xlabsize') nogrid) ///
                xline(0, lcolor(gs10) lwidth(thin)) ///
                xscale(range(`xmin' `xmax')) ///
                xtitle(`"`thisxtitle'"', size(`xtitlesize')) ///
                ytitle("") ///
                title(`"`thistitle'"', size(`thistitlesize') color(black) margin(small)) ///
                subtitle(`"`thissubtitle'"', size(`thissubtitlesize') color(black) margin(medsmall)) ///
                note(`"`thisnote'"', size(`notesize')) ///
                legend(off) ///
                graphregion(color(white)) plotregion(color(white)) ///
                name(`graphname', replace) ///
                xsize(`gxtxt') ysize(`heighttxt') ///
                `drawopt'

            if `combine' > 1 {
                local panel_graphs `"`panel_graphs' `graphname'"'
                local ++panel_count
                if `panel_count' == `effective_panels' | `blocknum' == `nblocks_total' {
                    local page_suffix : display %02.0f `panel_page'
                    local panel_rows = ceil(`panel_count' / `panel_cols')
                    local panel_xsize = cond(`panel_cols' == 1, 6.2, cond(`panel_cols' == 2, 8.0, 9.5))
                    local panel_ysize = min(10.5, max(4.2, 2.70 * `panel_rows' + 1.45))
                    local panel_xsizetxt : display %4.2f `panel_xsize'
                    local panel_ysizetxt : display %4.2f `panel_ysize'
                    graph combine `panel_graphs', col(`panel_cols') xcommon ///
                        title(`"`title'"', size(`titlesize') margin(small)) ///
                        note(`"`note1'"' `"`note2'"', size(`notesize')) ///
                        graphregion(color(white)) ///
                        name(wttplot_combined, replace) ///
                        xsize(`panel_xsizetxt') ysize(`panel_ysizetxt')
                    foreach fmt of local formats {
                        local outfile `"`graphdir'/combined_`page_suffix'.`fmt'"'
                        capture confirm new file `"`outfile'"'
                        if _rc & `"`replace'"' == "" {
                            di as err `"file `outfile' already exists; specify replace"'
                            restore
                            exit 602
                        }
                        if `"`fmt'"' == "png" {
                            quietly graph export `"`outfile'"', width(`pngwidth') replace
                        }
                        else {
                            quietly graph export `"`outfile'"', as(pdf) replace
                        }
                        local exported `"`exported' `"`outfile'"'"'
                    }
                    capture graph drop `panel_graphs'
                    local ++outcount
                    local ++panel_page
                    local panel_count = 0
                    local panel_graphs ""
                }
            }
            else {
                foreach fmt of local formats {
                    local outfile `"`graphdir'/wttplot_`filesuffix'.`fmt'"'
                    capture confirm new file `"`outfile'"'
                    if _rc & `"`replace'"' == "" {
                        di as err `"file `outfile' already exists; specify replace"'
                        restore
                        exit 602
                    }
                    if `"`fmt'"' == "png" {
                        quietly graph export `"`outfile'"', width(`pngwidth') replace
                    }
                    else {
                        quietly graph export `"`outfile'"', as(pdf) replace
                    }
                    local exported `"`exported' `"`outfile'"'"'
                }
                local ++outcount
            }
        }
        }

        if `graphcount' == 0 {
            if `"`show'"' == "significant" {
                di as txt "No FDR-significant outcomes were found; no plots were exported."
                di as txt "Specify show(all) to plot all analyzable outcomes."
                return scalar n_graphs = 0
                return local graphdir `"`graphdir'"'
                return local files ""
                restore
                exit
            }
            di as err "no plottable effect sizes were produced"
            restore
            exit 2000
        }

        di as txt "wttplot complete"
        di as txt "Graphs exported to:"
        foreach f of local exported {
            local flabel `"`f'"'
            if regexm(`"`f'"', "[/\\]([^/\\]+)$") local flabel = regexs(1)
            local ftarget `"`f'"'
            if !regexm(`"`ftarget'"', "^([A-Za-z]:|/|\\)") local ftarget `"`c(pwd)'/`ftarget'"'
            local ftarget = subinstr(`"`ftarget'"', "\", "/", .)
            if regexm(`"`ftarget'"', "^[A-Za-z]:") local ftarget `"file:///`ftarget'"'
            else if substr(`"`ftarget'"', 1, 1) == "/" local ftarget `"file://`ftarget'"'
            di as result `"  {browse "`ftarget'":`flabel'}"'
        }
        if `"`mapfile'"' != "" {
            local mlabel `"`mapfile'"'
            if regexm(`"`mapfile'"', "[/\\]([^/\\]+)$") local mlabel = regexs(1)
            local mtarget `"`mapfile'"'
            if !regexm(`"`mtarget'"', "^([A-Za-z]:|/|\\)") local mtarget `"`c(pwd)'/`mtarget'"'
            local mtarget = subinstr(`"`mtarget'"', "\", "/", .)
            if regexm(`"`mtarget'"', "^[A-Za-z]:") local mtarget `"file:///`mtarget'"'
            else if substr(`"`mtarget'"', 1, 1) == "/" local mtarget `"file://`mtarget'"'
            di as txt "Mapping file saved to:"
            di as result `"  {browse "`mtarget'":`mlabel'}"'
        }

        return scalar n_graphs = `outcount'
        return local graphdir `"`graphdir'"'
        return local files `"`exported'"'
    restore
end

program define _wttplot_xlsx_widths
    version 19.5
    args xlsx w1 w2 w3 w4

    local oldpwd `"`c(pwd)'"'
    tempfile zbase
    local workdir `"`zbase'_xlsx"'
    quietly capture mkdir `"`workdir'"'
    capture erase `"`workdir'/book.zip"'
    quietly copy `"`xlsx'"' `"`workdir'/book.zip"'
    quietly cd `"`workdir'"'
    quietly unzipfile "book.zip", replace

    local sheet "xl/worksheets/sheet1.xml"
    capture confirm file `"`sheet'"'
    if _rc {
        quietly cd `"`oldpwd'"'
        exit
    }

    tempfile newsheet
    file open inxml using `"`sheet'"', read text
    file open outxml using `"`newsheet'"', write text
    local cols `"<cols><col min="1" max="1" width="`w1'" customWidth="1"/><col min="2" max="2" width="`w2'" customWidth="1"/><col min="3" max="3" width="`w3'" customWidth="1"/><col min="4" max="4" width="`w4'" customWidth="1"/></cols>"'
    local wrote 0
    file read inxml line
    while r(eof) == 0 {
        if !`wrote' & strpos(`"`line'"', "<sheetData") {
            local line = subinstr(`"`line'"', "<sheetData", `"`cols'<sheetData"', 1)
            local wrote 1
        }
        file write outxml `"`line'"' _n
        file read inxml line
    }
    file close inxml
    file close outxml

    quietly copy `"`newsheet'"' `"`sheet'"', replace
    quietly erase "book.zip"
    quietly zipfile "[Content_Types].xml" "_rels" "docProps" "xl", saving("book.zip", replace)
    quietly copy "book.zip" `"`xlsx'"', replace
    quietly cd `"`oldpwd'"'
end
