*************************************************************************
* Make plots to introduce the idea of the new CI plots
*
* Dale Rhoda, December 2014
*
*************************************************************************
* This is the folder in the DropBox
global base C:\Users\Rhodad\Dropbox\LQAS Docs from Dale\Dales work

* This is the folder on my local hard drive
global base C:\Users\Dale\Dropbox (Biostat Global)\BGC Projects\BGC - WHO Document B Work\Ethiopia Measles 2013 Forest Plots\Generic CI plots

cd "$base"

set more off



clear
set obs 4
gen neff = 100

gen vcvg = 50
*replace vcvg = 50 in 4/6

local bign = _N

capture matrix drop table
matrix table = J(`bign',130,.)


local colnames vcvg lb_95pct ub_95pct lb_90pct ub_90pct 

forvalues i = 1/62 {
	local colnames `colnames' l`i' u`i'
}
local colnames `colnames' neff

matrix colnames table = `colnames'
	
forvalues i = 1/`bign' {
	matrix table[`i',  1] = vcvg[`i']
	matrix table[`i',130] = neff[`i']
}

forvalues i = 1/`bign' {

	clear
	local n = table[`i',130]
	scalar p = table[`i', 1]/100
	set obs `n'
	gen y = 0
	replace y = 1 if _n <= `n' * p
	svyset _n
	

	local col 2

	forvalues j =  0/62 {
		qui svy: proportion y , level(`lvl`j'')
		matrix out = r(table)
		matrix out = out[1..6,2]

		matrix table[`i',`col'] = max(0.0,out[5,1])*100
		local ++col
		matrix table[`i',`col'] = min(1.0,out[6,1])*100
		local ++col
	}

	
	* Stata has a quirky feature where level cannot be smaller
	* than 10.00 and we need it for 0.88, so calculate for
	* 10.00 and then shave it back 
	qui svy: proportion y , level(10)
	matrix out = r(table)
	matrix out = out[1..6,2]
	matrix table[`i',1] = out[1,1]*100
	matrix table[`i',`col'] = max(0.0,out[1,1]-.5*(out[1,1]-out[5,1]))*100
	local ++col
	matrix table[`i',`col'] = min(1.0,out[1,1]+.5*(out[6,1]-out[1,1]))*100

}
clear
svmat table, names(col) 

save dataset, replace

export excel using "CI LCB UCB and 21 segments.xlsx", sheet(summary) cell(c1) sheetmodify firstrow(var)

use dataset, clear

replace l1 = 0
replace u1 = 100

gen n = _n
gen y = _n

// make four sets of spike commands to plot red, green, yellow, and blue distributions
local m 1

local spike1
local spike2
local spike3
local spike4

forvalues i = 1/62 {
	* generate y variables for lines in distributions
	* let's go from 0.4 below the index line to 0.4 above it; that's a vertical extent of 0.8
	* and let's do it in 20 steps (21 lines)
	gen y`i' = y -.4 + (`i'-1)*(0.8/60)
	
	* now update 4 spike commands
	local spike1 `spike1' (rspike l`i' u`i' y`i' if color==1 , horizontal lcolor(red*.5)    lwidth(*`m') ) 
	local spike2 `spike2' (rspike l`i' u`i' y`i' if color==2 , horizontal lcolor(green*.5)  lwidth(*`m') ) 
	local spike3 `spike3' (rspike l`i' u`i' y`i' if color==3 , horizontal lcolor(gold*.5) lwidth(*`m') ) 
	local spike4 `spike4' (rspike l`i' u`i' y`i' if color==4 , horizontal lcolor(blue*.5  ) lwidth(*`m') ) 
	
}

local spike1 `spike1'  (rspike y1 y62 vcvg if color==1  , sort lwidth(vthin) lcolor(red)  )
local spike2 `spike2'  (rspike y1 y62 vcvg if color==2  , sort lwidth(vthin) lcolor(green))
local spike3 `spike3'  (rspike y1 y62 vcvg if color==3  , sort lwidth(vthin) lcolor(gold) )
local spike4 `spike4'  (rspike y1 y62 vcvg if color==4  , sort lwidth(vthin) lcolor(blue) )

local m = .25

gen mfudgelo = lb_90pct + .35
gen mfudgehi = ub_90pct - .35

gen x = 100


* Make a string variable containing est & 3 useful 95% CIs


gen lb_str1 = "[" + string(lb_95pct, "%04.1f")
replace lb_str1 = "[100" if lb_str1=="100.0"

gen ub_str1 = string(ub_95pct, "%04.1f") + "]"
replace ub_str1 = "100]" if ub_str1=="100.0"

gen lb_str2 = "(0.0"

gen ub_str2 = string(ub_90pct, "%04.1f") + "]"
replace ub_str2 = "100]" if ub_str2=="100.0"

gen lb_str3 = "[" + string(lb_90pct, "%04.1f")
replace lb_str3 = "[100" if lb_str3=="100.0"

gen ub_str3 = "100)" 

gen cistring = string(vcvg, "%04.1f") + "  " ///
                                       + lb_str1 + "," + ub_str1 + "  " ///
                                       + lb_str2 + "," + ub_str2 + "  " ///
									   + lb_str3 + "," + ub_str3

							  
									  
									  
									  
gen color = _n



twoway (rcap lb_90pct ub_90pct y, horizontal lcolor(none) ///  
         xlabel(0(25)100) ylabel(none) graphregion(color(white)) ///
		 xscale(titlegap(*10)) yscale(titlegap(1)) xtitle("Estimated Coverage %") ytitle("") legend(off) ) ///
	   (rcap lb_90pct ub_90pct y , sort horizontal lcolor(gs7) lwidth(*`=`m'')) ///  // visible 90% CI  
	   (rspike mfudgelo mfudgehi y , sort horizontal lcolor(white) lwidth(*`=`m'')) /// 
		`spike1' ///  // red fail zones
		`spike2' ///  // green pass zones
		`spike3' ///  // yellow regions
		`spike4' ///  // blue national
	   (scatter y x, mlabel(cistring) m(i) mlabsize(vsmall) xscale(range(0 150)) mlabcolor(black)) ///
	  ,  xline(100, lstyle(foreground) lcolor(black)) xline(`=lb_95pct[1]' `=ub_95pct[1]', lstyle(foreground) lcolor(gs14)) ///
	     name(new0,replace)

	   
forvalues i = 1/3 {
	replace u`i' = ub_90pct in 2
	
	replace l`i' = lb_95pct in 1
	replace u`i' = ub_95pct in 1

	replace l`i' = lb_90pct in 3
		
	replace l`i' = lb_95pct in 4
	replace u`i' = ub_95pct in 4
	
}

forvalues i = 4/62 {

	replace u`i' = min(u`i',ub_90pct) in 2
	replace l`i' = max(l`i',lb_95pct) in 1
	replace u`i' = min(u`i',ub_95pct) in 1
	replace l`i' = max(l`i',lb_90pct) in 3
	replace l`i' = max(l`i',lb_95pct) in 4
	replace u`i' = min(u`i',ub_95pct) in 4

}

local lb = lb_95pct[1]
local ub = ub_95pct[1]



twoway (rcap lb_90pct ub_90pct y, horizontal lcolor(none) ///  
         xlabel(0(25)100) ylabel(none) graphregion(color(white)) ///
		 xscale(titlegap(*10)) yscale(titlegap(1)) xtitle("Estimated Coverage %") ytitle("") legend(off) ) ///
	   (rcap lb_90pct ub_90pct y in 4, sort horizontal lcolor(black) lwidth(*`=`m'')) ///  // visible 90% CI  
	   (rspike mfudgelo mfudgehi y in 4, sort horizontal lcolor(white) lwidth(*`=`m'')) /// 
		`spike1' ///  // red fail zones
		`spike2' ///  // green pass zones
		`spike3' ///  // yellow regions
		`spike4' ///  // blue national
	   (scatter y x, mlabel(cistring) m(i) mlabsize(vsmall) xscale(range(0 150)) mlabcolor(black)) ///
	  ,  xline(100, lstyle(foreground) lcolor(black)) xline(`lb' `ub', lstyle(foreground) lcolor(gs14)) ///
		name(new1, replace)
		
graph export "Fig01 - Four 95pct CIs - `=vcvg[1]'.png", replace width(5000)

twoway (rcap lb_90pct ub_90pct y, horizontal lcolor(none) ///  
         xlabel(0(25)100) ylabel(none) graphregion(color(white)) ///
		 xscale(titlegap(*10)) yscale(titlegap(1)) xtitle("Estimated Coverage %") ytitle("") legend(off) ) ///
	   (rcap lb_90pct ub_90pct y in 4, sort horizontal lcolor(black) lwidth(*`=`m'')) ///  // visible 90% CI  
	   (rspike mfudgelo mfudgehi y in 4, sort horizontal lcolor(white) lwidth(*`=`m'')) /// 
		`spike1' ///  // red fail zones
		`spike2' ///  // green pass zones
		`spike3' ///  // yellow regions
		`spike4' ///  // blue national
	   (scatter y x, mlabel(cistring) m(i) mlabsize(vsmall) xscale(range(0 150)) mlabcolor(black)) ///
	  ,  xline(100, lstyle(foreground) lcolor(black))  ///
		name(new1, replace)
		
graph export "Fig01 - Four 95pct CIs - `=vcvg[1]' _no_ucb_lcb.png", replace width(5000)

********************************************
********************************************

local spike1 (rspike y25 y35 vcvg if color==1  , sort lwidth(thick) lcolor(red)  )
local spike2 (rspike y25 y35 vcvg if color==2  , sort lwidth(thick) lcolor(green))
local spike3 (rspike y25 y35 vcvg if color==3  , sort lwidth(thick) lcolor(gold) )
local spike4 (rspike y25 y35 vcvg if color==4  , sort lwidth(thick) lcolor(blue) )


twoway (rcap lb_90pct ub_90pct y, horizontal lcolor(none) ///  
         xlabel(0(25)100) ylabel(none) graphregion(color(white)) ///
		 xscale(titlegap(*10)) yscale(titlegap(1)) xtitle("Estimated Coverage %") ytitle("") legend(off) ) ///
		`spike1' ///  // red fail zones
		`spike2' ///  // green pass zones
		`spike3' ///  // yellow regions
		`spike4' ///  // blue national
	  ,  xline(100, lstyle(foreground) lcolor(black))  ///
		name(new2, replace)

graph export "Fig02 - Point Estimate - `=vcvg[1]'.png", replace width(5000)

		
		
twoway (rcap lb_90pct ub_90pct y, horizontal lcolor(none) ///  
         xlabel(0(25)100) ylabel(none) graphregion(color(white)) ///
		 xscale(titlegap(*10)) yscale(titlegap(1)) xtitle("Estimated Coverage %") ytitle("") legend(off) ) ///
		`spike1' ///  // red fail zones
		`spike2' ///  // green pass zones
		`spike3' ///  // yellow regions
		`spike4' ///  // blue national
	   (rcap lb_95pct ub_95pct y , sort horizontal lcolor(gs7) lwidth(thick)) ///  // visible 90% CI  
	  ,  xline(100, lstyle(foreground) lcolor(black))  ///
		name(new3, replace)

graph export "Fig03 - CI - `=vcvg[1]'.png", replace width(5000)
