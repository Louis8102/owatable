version 16.0
clear all
set more off

* Example: exactly three groups, multiple outcomes, standard Stata varlist.
sysuse auto, clear
keep if inlist(rep78, 3, 4, 5)

label define repair 3 "Repair 3" 4 "Repair 4" 5 "Repair 5", replace
label values rep78 repair

label variable price  "Price"
label variable mpg    "Mileage (mpg)"
label variable weight "Weight (lbs.)"
label variable length "Length (in.)"

char price[owatable_blockid] "B01"
char price[owatable_blocklabel] "Cost"
char mpg[owatable_blockid] "B02"
char mpg[owatable_blocklabel] "Vehicle Performance"
char weight[owatable_blockid] "B02"
char weight[owatable_blocklabel] "Vehicle Performance"
char length[owatable_blockid] "B02"
char length[owatable_blocklabel] "Vehicle Performance"

owatable price mpg weight length, ///
    by(rep78) ///
    blockfromchar ///
    saving("owatable_example.docx") ///
    results("owatable_example_results.dta") ///
    show(all) ///
    replace

return list
