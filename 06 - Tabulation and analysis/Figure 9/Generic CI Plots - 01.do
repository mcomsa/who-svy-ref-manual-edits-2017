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
local lvl0 95
local lvl1 90
local lvl2 99.99
local lvl3 98.66
local lvl4 96.94
local lvl5 95.00
local lvl6 92.86
local lvl7 90.59
local lvl8 88.13
local lvl9 85.48
local lvl10 82.65
local lvl11 79.62
local lvl12 76.36
local lvl13 72.87
local lvl14 69.11
local lvl15 65.02
local lvl16 60.55
local lvl17 55.61
local lvl18 50.08
local lvl19 43.72
local lvl20 36.07
local lvl21 26.10
local lvl22 7.98

clear
set obs 4
gen neff = 500

gen vcvg = 80
*replace vcvg = 50 in 4/6

local bign = _N

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

	forvalues j =  0/21 {
		qui svy: proportion y , level(`lvl`j'')
		matrix out = r(table)
		matrix out = out[1..6,2]
		matrix table[`i',`col'] = max(0.0,out[5,1])*100
		local ++col
		matrix table[`i',`col'] = min(1.0,out[6,1])*100
		local ++col
	}

	
	* Stata has a quirky feature where level cannot be smaller
	* than 10.00 and we need it for 7.98, so calculate for
	* 10.00 and then shave it back 
	qui svy: proportion y , level(10)
	matrix out = r(table)
	matrix out = out[1..6,2]
	matrix table[`i',1] = out[1,1]*100
	matrix table[`i',`col'] = max(0.0,out[1,1]-.798*(out[1,1]-out[5,1]))*100
	local ++col
	matrix table[`i',`col'] = min(1.0,out[1,1]+.798*(out[6,1]-out[1,1]))*100

}
clear
svmat table, names(col) 

export excel using "CI LCB UCB and 21 segments.xlsx", sheet(summary) cell(c1) sheetmodify firstrow(var)

replace l1 = 0
replace u1 = 100

gen n = _n
gen y = _n

// make four sets of spike commands to plot red, green, yellow, and blue distributions
local m 2.55

local spike1
local spike2
local spike3
local spike4

forvalues i = 1/21 {
	* generate y variables for lines in distributions
	* let's go from 0.4 below the index line to 0.4 above it; that's a vertical extent of 0.8
	* and let's do it in 20 steps (21 lines)
	gen y`i' = y -.4 + (`i'-1)*(0.8/20)
	
	* now update 4 spike commands
	local spike1 `spike1' (rspike l`i' u`i' y`i' if color==1 , horizontal lcolor(red*.5)    lwidth(*`m') ) 
	local spike2 `spike2' (rspike l`i' u`i' y`i' if color==2 , horizontal lcolor(green*.5)  lwidth(*`m') ) 
	local spike3 `spike3' (rspike l`i' u`i' y`i' if color==3 , horizontal lcolor(gold*.5) lwidth(*`m') ) 
	local spike4 `spike4' (rspike l`i' u`i' y`i' if color==4 , horizontal lcolor(blue*.5  ) lwidth(*`m') ) 
	
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
	   
forvalues i = 1/3 {
	replace u`i' = ub_90pct in 1
	
	replace l`i' = lb_95pct in 2
	replace u`i' = ub_95pct in 2

	replace l`i' = lb_90pct in 3
		
	replace l`i' = lb_95pct in 4
	replace u`i' = ub_95pct in 4
	
}

forvalues i = 4/7 {

	replace u`i' = min(u`i',ub_90pct) in 1
	replace l`i' = max(l`i',lb_95pct) in 2
	replace u`i' = min(u`i',ub_95pct) in 2
	replace l`i' = max(l`i',lb_90pct) in 3
	replace l`i' = max(l`i',lb_95pct) in 4
	replace u`i' = min(u`i',ub_95pct) in 4

}

twoway (rcap lb_90pct ub_90pct y, horizontal lcolor(none) ///  
         xlabel(0(25)100) ylabel(, ang(hor) nogrid valuelabel labsize(vsmall)) graphregion(color(white)) ///
		 xscale(titlegap(*10)) yscale(titlegap(1)) xtitle("Estimated Coverage %") ytitle("") legend(off) ) ///
	   (rcap lb_90pct ub_90pct y in 4, sort horizontal lcolor(gs7) lwidth(*`=`m'')) ///  // visible 90% CI  
	   (rspike mfudgelo mfudgehi y in 4, sort horizontal lcolor(white) lwidth(*`=`m'')) /// 
		`spike1' ///  // red fail zones
		`spike2' ///  // green pass zones
		`spike3' ///  // yellow regions
		`spike4' ///  // blue national
	   (scatter y x, mlabel(cistring) m(i) mlabsize(vsmall) xscale(range(0 150)) mlabcolor(black)) ///
	  ,  xline(100, lstyle(foreground) lcolor(black)) name(newer,replace)
	   
