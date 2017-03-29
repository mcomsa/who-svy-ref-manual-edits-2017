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

set more off
local lvl0  95
local lvl1  90
local lvl22 99.99
local lvl21 98.66
local lvl20 96.94
local lvl19 95.00
local lvl18 92.86
local lvl17 90.59
local lvl16 88.13
local lvl15 85.48
local lvl14 82.65
local lvl13 79.62
local lvl12 76.36
local lvl11 72.87
local lvl10 69.11
local lvl9  65.02
local lvl8  60.55
local lvl7  55.61
local lvl6  50.08
local lvl5  43.72
local lvl4  36.07
local lvl3  26.10
local lvl2  10

clear
set obs 4
gen neff = 105

gen vcvg = 98
replace vcvg = 95 in 2
replace vcvg = 80 in 3
replace vcvg = 65 in 4

local bign = _N

capture matrix drop yvals
matrix yvals = J(`bign',21,.)
matrix colnames yvals = y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 15 y16 y17 y18 y19 y20

capture matrix drop table
matrix table = J(`bign',48,.)
matrix colnames table = vcvg lb_95pct ub_95pct lb_90pct ub_90pct l1 u1 l2 u2 l3 u3 l4 u4 l5 u5 l6 u6 l7 u7 l8 u8 l9 u9 l10 u10 l11 u11 l12 u12 l13 u13 l14 u14 l15 u15 l16 u16 l17 u17 l18 u18 l19 u19 l20 u20 l21 u21 neff

forvalues i = 1/`bign' {
	matrix table[`i', 1] = vcvg[`i']
	matrix table[`i',48] = neff[`i']
}

forvalues i = 1/`bign' {

	clear
	local n = table[`i',48]
	scalar p = table[`i', 1]/100
	set obs `n'
	gen y = 0
	replace y = 1 if _n < `n' * p
	svyset _n
	

	local col 2
	scalar lastp = 0
	scalar lastu = 0

	forvalues j =  0/22 {
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
		* no...this assumes symmetry...gotta deal with the area on both sides...
		if `j' == 2 {
			scalar yi = ai / ( uimli )
			matrix yvals[`i',1] = yi
			scalar lastuimli = uimli
		}
		if `j' > 2 {
		*	di "`=scalar(ai)' `lvl`=`j'-1'' `=scalar(uimli)' `=scalar(lastuimli)' "
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

forvalues i = 1/21 {
	rename yvals`i' y`i'
	replace y`i' = (y`i'/ymax)*0.8+(y-0.4)
}

*export excel using "CI LCB UCB and 21 segments.xlsx", sheet(summary) cell(c1) sheetmodify firstrow(var)

*replace l21 = 0
*replace u21 = 100

gen n = _n

// make four sets of spike commands to plot red, green, yellow, and blue distributions

local spike1
local spike2
local spike3
local spike4

forvalues i = 1/21 {

	local tthin 1.0
	if `i' == 21 local tthin 0.5
	if `i' == 20 local tthin 2.7
	
	local tthick 3
	if `i' == 21 local tthick 0.5
		
	* now update 4 spike commands
	local spike1 `spike1' (rspike l`i' u`i' y`i' if color==1 & m <2 , horizontal lcolor(red*.5)    lwidth(*`tthick') ) 
	local spike2 `spike2' (rspike l`i' u`i' y`i' if color==2 & m <2 , horizontal lcolor(green*.5)  lwidth(*`tthick') ) 
	local spike3 `spike3' (rspike l`i' u`i' y`i' if color==3 & m <2 , horizontal lcolor(gold*.5)   lwidth(*`tthick') ) 
	local spike4 `spike4' (rspike l`i' u`i' y`i' if color==4 & m <2 , horizontal lcolor(blue*.5  ) lwidth(*`tthick') ) 

	local spike1 `spike1' (rspike l`i' u`i' y`i' if color==1 & m >=2 , horizontal lcolor(red*.5)    lwidth(*`tthin') ) 
	local spike2 `spike2' (rspike l`i' u`i' y`i' if color==2 & m >=2 , horizontal lcolor(green*.5)  lwidth(*`tthin') ) 
	local spike3 `spike3' (rspike l`i' u`i' y`i' if color==3 & m >=2 , horizontal lcolor(gold*.5)   lwidth(*`tthin') ) 
	local spike4 `spike4' (rspike l`i' u`i' y`i' if color==4 & m >=2 , horizontal lcolor(blue*.5  ) lwidth(*`tthin') ) 
	
}

local spike1 `spike1'  (rspike y1 y21 vcvg if color==1  , sort lwidth(vthin) lcolor(red)  )
local spike2 `spike2'  (rspike y1 y21 vcvg if color==2  , sort lwidth(vthin) lcolor(green))
local spike3 `spike3'  (rspike y1 y21 vcvg if color==3  , sort lwidth(vthin) lcolor(gold) )
local spike4 `spike4'  (rspike y1 y21 vcvg if color==4  , sort lwidth(vthin) lcolor(blue) )



local m = .25

gen mfudgelo = lb_90pct + .35
gen mfudgehi = ub_90pct - .35

gen x = 100


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


gen cistring = string(vcvg, "%04.1f") + " (" + lb_str1 + "," + ub_str1 + ")" ///
                                      + " (" + lb_str2 + "," + ub_str2 + ")" ///
									  + " (" + lb_str3 + "," + ub_str3 + ")"

gen color = _n


twoway (rcap lb_90pct ub_90pct y, horizontal lcolor(none) ///  
         xlabel(0(25)100) ylabel(, ang(hor) nogrid valuelabel labsize(vsmall)) graphregion(color(white)) ///
		 xscale(titlegap(*10)) yscale(titlegap(1)) xtitle("Estimated Coverage %") ytitle("") legend(off) ) ///
	   (rcap lb_90pct ub_90pct y , sort horizontal lcolor(gs7) lwidth(*`=`m'')) ///  // visible 90% CI  
	   (rspike mfudgelo mfudgehi y , sort horizontal lcolor(white) lwidth(*`=`m'')) /// 
		`spike1' ///  // red fail zones
		`spike2' ///  // green pass zones
		`spike3' ///  // yellow regions
		`spike4' ///  // blue national
	   (scatter y x, mlabel(cistring) m(i) mlabsize(vsmall) xscale(range(0 150)) mlabcolor(black)) ///
	  ,  xline(100, lstyle(foreground) lcolor(black)) name(old,replace)
	   
