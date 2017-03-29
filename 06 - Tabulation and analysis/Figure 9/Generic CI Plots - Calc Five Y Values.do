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
local lvl2  10
local lvl3  32.5
local lvl4  55
local lvl5  77.5
local lvl6  99.9



clear
set obs 4
gen neff = 105

gen vcvg = 98
replace vcvg = 95 in 2
replace vcvg = 80 in 3
replace vcvg = 65 in 4

local bign = _N

capture matrix drop yvals
matrix yvals = J(`bign',5,.)
matrix colnames yvals = y1 y2 y3 y4 y5 

capture matrix drop table
matrix table = J(`bign',16,.)
matrix colnames table = vcvg lb_95pct ub_95pct lb_90pct ub_90pct l1 u1 l2 u2 l3 u3 l4 u4 l5 u5 neff

forvalues i = 1/`bign' {
	matrix table[`i', 1] = vcvg[`i']
	matrix table[`i',16] = neff[`i']
}

forvalues i = 1/`bign' {

	clear
	local n = table[`i',16]
	scalar p = table[`i', 1]/100
	set obs `n'
	gen y = 0
	replace y = 1 if _n < `n' * p
	svyset _n
	

	local col 2
	scalar lastp = 0
	scalar lastu = 0

	forvalues j =  0/6 {
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

forvalues i = 1/5 {
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

forvalues i = 1/5 {

	local tthin 8
	if `i' == 5 local tthin 1
	if `i' == 4 local tthin 12
	
	local tthick 40
	if `i' == 5 local tthick 10
		
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

local spike1 `spike1'  (rspike y1 y5 vcvg if color==1  , sort lwidth(vthin) lcolor(red)  )
local spike2 `spike2'  (rspike y1 y5 vcvg if color==2  , sort lwidth(vthin) lcolor(green))
local spike3 `spike3'  (rspike y1 y5 vcvg if color==3  , sort lwidth(vthin) lcolor(gold) )
local spike4 `spike4'  (rspike y1 y5 vcvg if color==4  , sort lwidth(vthin) lcolor(blue) )



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
	   
