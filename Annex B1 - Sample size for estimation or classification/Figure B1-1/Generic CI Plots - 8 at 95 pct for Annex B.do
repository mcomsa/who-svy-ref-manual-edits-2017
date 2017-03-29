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

local NL 50

local clip 1

set more off
local lvl0  95
local lvl1  90

forvalues i = 2/`=1+`NL'' {
	di "`i'"
	local lvl`i' = 10 + (`=(`i'-2)*((99.9-10)/(`=`NL'-1'))')
	local lvl`i' = substr("`lvl`i''",1,4)
	di "`lvl`i''"
}



clear
set obs 8
gen neff = 354
replace neff = 227 in 2
replace neff = 162 in 3
replace neff = 132 in 4
replace neff = 110 in 5
replace neff = 93 in 6
replace neff = 81 in 7
replace neff = 70 in 8


gen vcvg = 95


local bign = _N

capture matrix drop yvals
matrix yvals = J(`bign',`NL',.)
local ylabels
forvalues i = 1/`NL' {
	local ycols `ycols' y`i'
}
matrix colnames yvals = `ycols'

local ntcols = 6 + 2*`NL'

capture matrix drop table
matrix table = J(`bign',`ntcols',.)
local tcols vcvg lb_95pct ub_95pct lb_90pct ub_90pct
forvalues i = 1/`NL' {
	local tcols `tcols' l`i' u`i'
}
local tcols `tcols' neff
matrix colnames table = `tcols'

forvalues i = 1/`bign' {
	matrix table[`i', 1] = vcvg[`i']
	matrix table[`i',`ntcols'] = neff[`i']
}

forvalues i = 1/`bign' {

	clear
	local n = table[`i',`ntcols']
	scalar p = table[`i', 1]/100
	set obs `n'
	gen y = 0
	replace y = 1 if _n <= `n' * p
	svyset _n
	

	local col 2
	scalar lastp = 0
	scalar lastu = 0

	forvalues j =  0/`=`NL'+1' {
		scalar ai = `lvl`j''
	
		qui svy: proportion y , level(`lvl`j'')

		matrix out = r(table)
		matrix out = out[1..6,2]
		matrix table[`i', 1] = out[1,1]*100
		matrix table[`i',`col'] = max(0.0,out[5,1])*100
		scalar li = max(0.0,out[5,1])*100
		local ++col
		matrix table[`i',`col'] = min(1.0,out[6,1])*100
		scalar ui = min(1.0,out[6,1])*100
		scalar uimli = ui -li
		local ++col
		
		* calculate the appropriate y value for this interval
		if `j' == 2 {
			scalar yi = ai / ( uimli )
			matrix yvals[`i',1] = yi
			scalar lastuimli = uimli
		}
		if `j' > 2 {
			di "`=scalar(ai)' `lvl`=`j'-1'' `=scalar(uimli)' `=scalar(lastuimli)' "
			scalar yi = (ai - `lvl`=`j'-1'') / (uimli - lastuimli)
			matrix yvals[`i',`=`j'-1'] = yi
		*	matrix list yvals
			scalar lastuimli = uimli
		}
	}
}

* pull the y values into a dataset 
matrix list yvals

clear
svmat yvals
save yvals, replace

* merge ucb and lcb with y values
clear
svmat table, names(col) 
merge 1:1 _n using yvals, nogen

* rescale the y-values, making the base of the distributions at y-0.4 
* and making the highest y value in the dataset fall at y + 0.4

gen y = _n
egen ymax = max(yvals1)
gen m = ymax/yvals1

forvalues i = 1/`NL' {
	rename yvals`i' y`i'
	replace y`i' = (y`i'/ymax)*0.8+(y-0.4)
}

*export excel using "CI LCB UCB and 21 segments.xlsx", sheet(summary) cell(c1) sheetmodify firstrow(var)

*replace l21 = 0
*replace u21 = 100

gen n = _n


local m = .25

gen mfudgelo = lb_90pct + .35
gen mfudgehi = ub_90pct - .35

gen x = 65



* Make a string variable containing est & 3 useful 95% CIs


gen lb_str1 = string(lb_95pct, "%04.1f")
replace lb_str1 = "100" if lb_str1=="100.0"

gen ub_str1 = string(ub_95pct, "%04.1f")
replace ub_str1 = "100" if ub_str1=="100.0"

gen lb_str2 = "0.0"

gen ub_str2 = string(ub_90pct, "%04.1f")
replace ub_str2 = "100" if ub_str2=="100.0"

gen lb_str3 = string(lb_90pct, "%04.1f")
replace lb_str3 = "100" if lb_str3=="100.0"

gen ub_str3 = "100" 


gen cistringlong = string(vcvg, "%04.1f") + " (" + lb_str1 + "," + ub_str1 + ")" ///
                                      + " (" + lb_str2 + "," + ub_str2 + ")" ///
									  + " (" + lb_str3 + "," + ub_str3 + ")"
									  
gen cistring = string(vcvg, "%04.1f") + " (" + lb_str1 + "," + ub_str1 + ")" 

gen color = 1
*replace color = 1 in 5

* clip CI at 95% if user specifies it
if `clip' == 1 {
*	gen yyy = yy
*	gen xxx = xx
	forvalues i = 1/`NL' {
		replace l`i' = max(l`i',lb_95pct)
		replace u`i' = min(u`i',ub_95pct)
	}
}

forvalues i = 1/`NL' {
	gen xx`i' = l`=`NL'+1-`i''
	order xx`i', after(l`=`NL'+1-`i'')
	gen xx`=`NL'+`i'' = u`i'
	order xx`=`NL'+`i'', after(u`i')
	gen yy`i' = y`=`NL'+1-`i''
	gen yy`=`NL'+`i'' = y`i'
	order yy`i' yy`=`NL'+`i'', after(y`i')
}
*gen xx`=2*`NL'+1' = xx1
*gen yy`=2*`NL'+1' = yy1


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

  label define ynames ///
1 "ESS = 354" ///
2 "ESS = 227" ///
3 "ESS = 162" ///
4 "ESS = 132" ///
5 "ESS = 110" ///
6 "ESS = 93" ///
7 "ESS = 81" ///
8 "ESS = 70" , replace


label values y ynames

*replace vcvg = 95


**************************************************
*
* make four sets of plotting commands to plot red, green, yellow, and blue distributions
*
**************************************************

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
  , legend( off) ///
     ysize(15) xsize(15) ///
	 ylabel(1(1)8, ang(hor) nogrid valuelabel labsize(small)) graphregion(color(white)) ///	 
	 xscale(titlegap(*10)) yscale(titlegap(1)) ///
	 xtitle("Estimated Coverage %") ytitle("") ///
	 xline(85, lcolor(gs12) lstyle(foreground))
	 
`plotit'

graph export coverage_95_8_ess_values.png, width(2000) replace


