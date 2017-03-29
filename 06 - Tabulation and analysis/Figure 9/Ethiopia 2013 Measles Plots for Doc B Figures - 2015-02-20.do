*************************************************************************
* Make generic CI plots
*
* -Dale Rhoda, December 2014 
*
*************************************************************************
* This is the folder in the DropBox
global base C:\Users\Rhodad\Dropbox\LQAS Docs from Dale\Dales work

* This is the folder on my local hard drive
global base C:\Users\Dale\Dropbox (Biostat Global)\BGC Projects\BGC - WHO Document B Work\Ethiopia Measles 2013 Forest Plots\Generic CI plots

cd "$base"

use "C:\Users\Dale\Documents\- Projects\BMGF - 2013\Ethiopia Measles\Output\CI_blob_coordinates_50_pairs_using_svyp", clear

local NL 50

local clip 1
local equal_area 1

set more off

drop if region == ""

gen n = _n

*******************************************************
* restrict the dataset to rows we're going to plot
* 
* and sort in the appropriate order here
*******************************************************

* keep only regions and nation
keep if region=="Oromiya"
*replace lb_90pct = 94.9 if zone=="Nekemete City"
*replace ub_90pct = 85.1 if zone=="Bishoftu Town"

sort vcvg lb_90pct, stable

count
local bign = r(N)

* rescale the y-values, making the base of the distributions at y-0.4 
* and making the highest y value in the dataset fall at y + 0.4

gen y = _n
egen ymax = max(y1)

*do not scale to be equal-area unless that options is set to 1
replace ymax = y1 if `equal_area' != 1

gen m = ymax/y1

order y ymax m, first

forvalues i = 1/`NL' {
	replace y`i' = (y`i'/ymax)*0.8+(y-0.4)
}


********************************************************
*
* Assign colors
*
********************************************************

capture drop color
gen color=1 // red
replace color=2 if lb_90pct > 95
order color, after(m)

local m = .25

gen mfudgelo = lb_90pct + .35
gen mfudgehi = ub_90pct - .35

gen x = 100

********************************************************
********************************************************

* Make a string variable containing est & 3 useful 95% CIs

gen lb_str1 = string(lb_95pct, "%04.1f")
replace lb_str1 = "100" if lb_str1=="100.0"

gen ub_str1 = string(ub_95pct, "%04.1f")
replace ub_str1 = "100" if ub_str1=="100.0"

gen lb_str2 = "0"

gen ub_str2 = string(ub_90pct, "%04.1f")
replace ub_str2 = "100" if ub_str2=="100.0"

gen lb_str3 = string(lb_90pct, "%04.1f")
replace lb_str3 = "100" if lb_str3=="100.0"

gen ub_str3 = "100" 


gen cistringlong = string(vcvg, "%04.1f") + " (" + lb_str1 + "," + ub_str1 + ")" ///
                                      + " [" + lb_str2 + "," + ub_str2 + ")" ///
									  + " (" + lb_str3 + "," + ub_str3 + "] [N=150]" if _n != 12
replace cistringlong = string(vcvg, "%04.1f") + " (" + lb_str1 + "," + ub_str1 + ")" ///
                                      + " [" + lb_str2 + "," + ub_str2 + ")" ///
									  + " (" + lb_str3 + "," + ub_str3 + "] [N=3,600]" if _n == 12
									  
gen cistring = string(vcvg, "%04.1f") + " (" + lb_str1 + "," + ub_str1 + ") [N=150]" if _n != 12
replace cistring = string(vcvg, "%04.1f") + " (" + lb_str1 + "," + ub_str1 + ") [N=3,600]" if _n == 12

order cistring, after(color)
									  
* clip CI at 95% if user specifies it

if `clip' == 1 {

	forvalues i = 1/`NL' {
		replace l`i' = max(l`i',lb_95pct)
		replace u`i' = min(u`i',ub_95pct)
	}
}


****************************************
*
* Reshape dataset to long form
*
****************************************
forvalues i = 1/`NL' {
	gen xx`i' = l`=`NL'+1-`i''
	order xx`i', after(l`=`NL'+1-`i'')
	gen xx`=`NL'+`i'' = u`i'
	order xx`=`NL'+`i'', after(u`i')
	gen yy`i' = y`=`NL'+1-`i''
	gen yy`=`NL'+`i'' = y`i'
	order yy`i' yy`=`NL'+`i'', after(y`i')
}

reshape long xx yy , i(y) j(j)

aorder
drop l1-l`NL'
drop u1-u`NL'
drop lb_str* ub_str* y1-y`NL'
drop n x ymax

* add an empty row between distributions
set obs `=_N+`bign'-1'
replace j = `=2*`NL'+2' if xx==.
gsort - j
replace y = _n if _n < `bign'
sort y j

* calculate ymax for each distribution
gen ypemin = y - 0.4
bysort y: egen ypemax = max(yy)
sort y j

**************************************************
*
* make four sets of plotting commands to plot red, green, yellow, and blue distributions
*
**************************************************

local color1 red
local color2 green
local color3 gold
local color4 blue

local spike1
local spike2
local spike3
local spike4

forvalues i = 1/`NL' {
	forvalues j = 1/4 {
		local spike`j' `spike`j'' (area yy xx  if y == `i' & color == `j' & j > 0, fcolor(  `color`j''*0.5) lwidth(vvthin) lcolor(`color`j'')   nodropbase)
	}
}

forvalues j = 1/4 {
	local spike`j' `spike`j'' (rspike ypemin ypemax vcvg if color == `j' & j == 1, lcolor(`color`j'')) 
}

*******
label define ynames ///
1 "F" ///
2 "I" ///
3 "S" ///
4 "W" ///
5 "P" ///
6 "V" ///
7 "J" ///
8 "B" ///
9 "U" ///
10 "N" ///
11 "K" ///
12 "Province"   ///
13 "M" ///
14 "T" ///
15 "O" ///
16 "A" ///
17 "E" ///
18 "Q" ///
19 "D" ///
20 "R" ///
21 "X" ///
22 "G" ///
23 "H" ///
24 "L" ///
25 "C" ,replace

label values y ynames

tab y

gen x = 100

* put a string in each filename indicating whether the plots are 
* equal_height or equal_area
local estring equal_area
if `equal_area' != 1 local estring equal_height

* put a string in each filename indicating whether the distributions are clipped
local cstring clipped
if `clip' != 1 local cstring not_clipped

local plotit  graph twoway ///
	(rcap lb_90pct ub_90pct y , sort horizontal lcolor(gs7) lwidth(*0.5))  ///  // classification ticks 
	(rspike mfudgelo mfudgehi y , sort horizontal lcolor(white) lwidth(*0.5)) /// // cover much of the rcap line
		`spike1' ///
		`spike2' ///
		`spike3' ///
		`spike4' ///
 	(scatter y x, mlabel(cistringlong) m(i) mlabsize(*.65) mlabcolor(gs10) xscale(range(65 138)) ) ///
	(scatteri 0  95 26  95, connect(line) ms(none) lcolor(red)) ///
	(scatteri 0 100 26 100, connect(line) ms(none) lcolor(black)) ///
	, legend( off) ///
     ysize(15) xsize(15) ///
	 ylabel(1(1)25, ang(hor) nogrid valuelabel labsize(small)) graphregion(color(white)) ///	 
	 xscale(titlegap(*10)) yscale(titlegap(1)) ///
	 xtitle("Estimated Coverage %              ") ytitle("District") ///
	 yline(12, lcolor(gs15) lwidth(*16) lstyle(background)) ///
	 xline(100, lcolor(black) lstyle(foreground)) 
	 
`plotit'

graph export classify_equal_area_01_pass_gt_95_`estring'_`cstring'.png, width(2000) replace

  
capture drop color
gen color = 2 // green
replace color=1 if ub_90pct < 95
`plotit'

graph export classify_equal_area_02_fail_lt_95_`estring'_`cstring'.png, width(2000) replace



capture drop color
gen color = 2 // green
replace color=1 if vcvg < 95
`plotit'

graph export classify_equal_area_03_pass_pe_gt_95_`estring'_`cstring'.png, width(2000) replace


capture drop color
gen color = 2 // green
replace color=1 if ub_90pct < 95
replace color = 3 if lb_90pct < 95 & ub_90pct > 95
`plotit'

graph export classify_equal_area_04_three_colors_`estring'_`cstring'.png, width(2000) replace

replace color = 1

local color1 gs8
local color2 green
local color3 gold
local color4 blue

local spike1
local spike2
local spike3
local spike4

forvalues i = 1/`NL' {
	forvalues j = 1/4 {
		local spike`j' `spike`j'' (area yy xx  if y == `i' & color == `j' & j > 0, fcolor(  `color`j''*0.5) lwidth(vvthin) lcolor(`color`j'')   nodropbase)
	}
}

forvalues j = 1/4 {
	local spike`j' `spike`j'' (rspike ypemin ypemax vcvg if color == `j' & j == 1, lcolor(`color`j'')) 
}


local plotit  graph twoway ///
	(rcap lb_90pct ub_90pct y , sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // classification ticks 
	(rspike mfudgelo mfudgehi y , sort horizontal lcolor(white) lwidth(*0.5)) /// // cover much of the rcap line
		`spike1' ///
		`spike2' ///
		`spike3' ///
		`spike4' ///
 	(scatter y x, mlabel(cistringlong) m(i) mlabsize(*.65) mlabcolor(gs10) xscale(range(65 138)) ) ///
	(scatteri 0  95 26  95, connect(line) ms(none) lcolor(red)) ///
	(scatteri 0 100 26 100, connect(line) ms(none) lcolor(black)) ///
  , legend( off) ///
     ysize(15) xsize(15) ///
	 ylabel(1(1)25, ang(hor) nogrid valuelabel labsize(small)) graphregion(color(white)) ///	 
	 xscale(titlegap(*10)) yscale(titlegap(1)) ///
	 xtitle("Estimated Coverage %              ") ytitle("District") ///
	 yline(12, lcolor(gs15) lwidth(*16) lstyle(background)) 
	 
`plotit'

graph export classify_equal_area_05_all_gray_`estring'_`cstring'.png, width(2000) replace
