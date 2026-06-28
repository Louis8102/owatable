clear all
set more off

* Example data included with the GitHub package.
use example.dta, clear

* Six simulated organizational-psychology blocks, 60 items total.
* group variables:
*   gender:  0 = Female, 1 = Male
*   company: 0 = Subsidiary, 1 = Headquarters

wttplot item1-item60, by(gender) blockfromchar ///
    graphdir(figures_gender_byblock) show(all) replace

wttplot item1-item60, by(gender) blockfromchar ///
    graphdir(figures_gender_vertical) show(all) ///
    combine(4) layout(vertical) labelmode(item) ///
    mapfile(gender_item_mapping.xlsx) replace

wttplot item1-item60, by(company) blockfromchar ///
    graphdir(figures_company_vertical) show(all) ///
    combine(4) layout(vertical) labelmode(item) ///
    mapfile(company_item_mapping.xlsx) replace
