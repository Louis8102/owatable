# owatable

`owatable` creates a compact Word table for multiple outcomes compared across
exactly three groups.

Version 1.0.0 is intentionally narrow:

- exactly three groups in `by()`;
- standard Stata numeric `varlist`;
- common complete-case sample by default;
- optional `availablecase`;
- Welch one-way ANOVA for each outcome;
- Benjamini-Hochberg FDR q-values across omnibus tests;
- Games-Howell pairwise comparisons only after FDR-significant omnibus tests;
- absolute Hedges' g_av in the Word table;
- signed Hedges' g_av in the optional results dataset.

Rows use Stata variable labels when available; if a variable has no label,
`owatable` falls back to the variable name.

For multi-block instruments, the recommended no-mapping-file workflow is
`blockfromchar`. Keep the ordinary variable label as the item label and add
block metadata with variable characteristics:

```stata
label variable q1 "Gender"
char q1[owatable_blockid] "B01"
char q1[owatable_blocklabel] "Student Characteristics"

label variable q2 "Age"
char q2[owatable_blockid] "B01"
char q2[owatable_blocklabel] "Student Characteristics"

label variable q3 "Chronic Absence Rate"
char q3[owatable_blockid] "B02"
char q3[owatable_blocklabel] "Attendance"
```

Then run:

```stata
owatable q1-q3, by(group3) blockfromchar saving(table1.docx) replace
```

`owatable` also supports `blockfile()` for users who prefer a separate mapping
dataset, and `blockfromlabel` for short labels formatted as
`[B01 | Block Label] Display Label`. With any block method, block labels are
inserted as subheadings, and the first-column width is computed from both the
outcome labels and the block labels.

Important: Stata variable labels are limited to 80 characters. If the block
prefix plus the display label would exceed 80 characters, Stata truncates the
label before `owatable` reads it. For long item labels, prefer `blockfromchar`
or `blockfile()`.

Basic use:

```stata
owatable y1-y30 y35-y105, by(group3) saving(table1.docx) replace
```

With a saved analytic dataset:

```stata
owatable y1-y30 y35-y105, by(group3) ///
    saving(table1.docx) results(owatable_results.dta) replace
```

Install from a local directory:

```stata
net install owatable, from("path/to/owatable") replace
```

Author: Xuelian Wu  
Version: 1.0.0, 26 June 2026
