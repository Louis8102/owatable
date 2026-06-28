# wttplot

`wttplot` creates signed Hedges' g_av effect-size plots for multiple two independent-group Welch tests.

It is intended for research briefs, appendices, and preliminary group-difference reporting when many outcomes are analyzed at once.

Install from GitHub:

```stata
net install wttplot, from("https://raw.githubusercontent.com/Louis8102/wttplot/main/") replace
```

Example using block information embedded in variable labels:

```stata
sysuse auto, clear

label var price  "[B01 | Cost] Price"
label var mpg    "[B02 | Vehicle Performance] Mileage (mpg)"
label var weight "[B02 | Vehicle Performance] Weight (lbs.)"
label var length "[B02 | Vehicle Performance] Length (in.)"

wttplot price mpg weight length, by(foreign) blockfromlabel ///
    graphdir(figures) show(all) replace
```

Example using the included simulated survey dataset:

```stata
use example.dta, clear

wttplot item1-item60, by(gender) blockfromchar ///
    graphdir(figures_gender_vertical) show(all) ///
    combine(4) layout(vertical) labelmode(item) ///
    mapfile(gender_item_mapping.xlsx) replace

wttplot item1-item60, by(company) blockfromchar ///
    graphdir(figures_company_vertical) show(all) ///
    combine(4) layout(vertical) labelmode(item) ///
    mapfile(company_item_mapping.xlsx) replace
```

`example.dta` is a simulated 60-item organizational psychology survey with six 10-item blocks. It includes two grouping variables: `gender` (Female/Male) and `company` (Subsidiary/Headquarters). Several items were simulated to show clear group differences for demonstration.

Optional font-size tuning:

```stata
wttplot price mpg weight length, by(foreign) blockfromlabel ///
    graphdir(figures) show(all) ///
    titlesize(medsmall) blocksize(medsmall) labelsize(small) ///
    xlabsize(small) xtitlesize(small) notesize(vsmall) replace
```

Optional combined figures:

```stata
wttplot price mpg weight length, by(foreign) blockfromlabel ///
    graphdir(figures_h) show(all) combine(2) layout(horizontal) replace

wttplot price mpg weight length, by(foreign) blockfromlabel ///
    graphdir(figures_v) show(all) combine(2) layout(vertical) replace
```

Compact screening figure with item-number labels and an Excel mapping file:

```stata
wttplot item1-item50, by(gender) blockfromchar ///
    graphdir(figures_vertical) show(all) ///
    combine(4) layout(vertical) labelmode(item) ///
    mapfile(item_mapping.xlsx) replace
```

`combine(4) layout(vertical)` produces a compact two-column screening figure. `mapfile()` saves an Excel file linking Item numbers to variable names, block labels, and full outcome labels. The mapping file uses Times New Roman, 12 pt.

Mapping-file labels:

- `wttplot` uses the Stata variable label as the item label whenever a variable label exists.
- If a variable has no variable label, `wttplot` falls back to the variable characteristic `owatable_label`, if available.
- If variables are named `item1`, `item2`, ..., the mapping file displays them as `item01`, `item02`, ..., so one-digit and two-digit item names align cleanly.
- The mapping file has four columns: `No.`, `Item`, `Item label`, and `Block`; the header row is bold and centered, with dynamic column widths.

Author: Hao Ma
