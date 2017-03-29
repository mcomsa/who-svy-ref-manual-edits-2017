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
set obs 2
gen neff = 105
replace neff=315 if _n > 1

gen vcvg = 74.3
replace vcvg = 81.3 if _n > 1


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
	replace y = 1 if _n < `n' * p
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

// make four sets of spike commands to plot red, green, yellow, and blue distributions

local spike1
local spike2
local spike3
local spike4

forvalues i = 1/`NL' {

	local tthin 1
	if `i' == `NL' local tthin 1
	if `i' == `=`NL'-1' local tthin 1
	
	local tthick 1
	if `i' == `NL' local tthick 1
		
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
/*
* add an observation at y = 0, so we can overwrite the vertical line with 
* a white line
set obs `=_N+`bign''
replace j = 0 if j == .
sort j
replace y = _n if _n <= `bign'
sort y j
replace xx = xx[_n+1] if j == 0
replace yy = 0 if j == 0
*/

catwoway scatter yy xx y if y == 1 & j > 0, toptions(name(dots1, replace) ) poptions(msymbol(x)) 
twoway (scatter yy xx if y == 1 & j > 0, connect(stairstep) lcolor(green)), name(p2, replace)
twoway (scatter yy xx if y == 1 & j > 0, connect(stairstep) lcolor(green)) (area yy xx if y == 1 & j > 0, nodropbase), name(p3, replace)
line yy xx if y == 1 & j > 0, name(line1, replace)
catwoway scatter yy xx y if j > 0, toptions(name(dots, replace) ylabel(1(1)5) yline(0.6 1.6 2.6 3.6 4.6, lwidth(vvthin) lcolor(gs14)) ) poptions(msymbol(x)) 
catwoway line yy xx y if j > 0, toptions(name(lines, replace) ylabel(1(1)5) yline(0.6 1.6 2.6 3.6 4.6, lwidth(vvthin) lcolor(gs14)) ) poptions(msymbol(x)) save("dots.do", replace)

catwoway area yy xx y if j > 0, toptions(name(b1, replace) ylabel(1(1)5)  yline(0.6 1.6 2.6 3.6 4.6, lwidth(vvthin) lcolor(gs14)) ) poptions(msymbol(x) nodropbase) 


graph twoway ///
	(rcap lb_90pct ub_90pct y if y == 5, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 5, sort horizontal lcolor(white) lwidth(*0.5)) ///
	(area yy xx  if y == 5 & j > 0, nodropbase  ) ///
    (rcap lb_90pct ub_90pct y if y == 4, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 4, sort horizontal lcolor(white) lwidth(*0.5)) ///
	(area yy xx  if y == 4 & j > 0, nodropbase  ) ///
    (rcap lb_90pct ub_90pct y if y == 3, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 3, sort horizontal lcolor(white) lwidth(*0.5)) ///
    (area yy xx  if y == 3 & j > 0 , nodropbase  ) ///
    (rcap lb_90pct ub_90pct y if y == 2, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 2, sort horizontal lcolor(white) lwidth(*0.5)) ///
    (area yy xx  if y == 2 & j > 0 , nodropbase  ) ///
    (rcap lb_90pct ub_90pct y if y == 1, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 1, sort horizontal lcolor(white) lwidth(*0.5)) ///
    (area yy xx  if y == 1 & j > 0 , nodropbase  ) ///
  , legend( off) ylabel(,nogrid) name(blobs,replace) 
  
  gen ypemin = y - 0.4
  bysort y: egen ypemax = max(yy)
  sort y j
  
  capture drop color
  gen color = 1
  replace color = 2 if y == 3
  replace color = 3 if y < 3
  
 graph twoway ///
	(rcap lb_90pct ub_90pct y if y == 5, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 5, sort horizontal lcolor(white) lwidth(*0.5)) ///
	(area yy xx  if y == 5 & j > 0, fcolor(green*0.5) lcolor(green) nodropbase  ) ///
	(rspike ypemin ypemax vcvg if y == 5 & j == 1, lcolor(green)) ///
    (rcap lb_90pct ub_90pct y if y == 4, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 4, sort horizontal lcolor(white) lwidth(*0.5)) ///
	(area yy xx  if y == 4 & j > 0, fcolor(green*0.5) lcolor(green) nodropbase  ) ///
	(rspike ypemin ypemax vcvg if y == 4 & j == 1, lcolor(green)) ///
    (rcap lb_90pct ub_90pct y if y == 3, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 3, sort horizontal lcolor(white) lwidth(*0.5)) ///
    (area yy xx  if y == 3 & j > 0 , fcolor(gold*0.5) lcolor(gold) nodropbase  ) ///
	(rspike ypemin ypemax vcvg if y == 3 & j == 1, lcolor(gold)) ///
    (rcap lb_90pct ub_90pct y if y == 2, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 2, sort horizontal lcolor(white) lwidth(*0.5)) ///
    (area yy xx  if y == 2 & j > 0 , fcolor(red*0.5) lcolor(red) nodropbase  ) ///
	(rspike ypemin ypemax vcvg if y == 2 & j == 1, lcolor(red)) ///
    (rcap lb_90pct ub_90pct y if y == 1, sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // visible 90% CI  
	(rspike mfudgelo mfudgehi y if y == 1, sort horizontal lcolor(white) lwidth(*0.5)) ///
    (area yy xx  if y == 1 & j > 0 , fcolor(red*0.5) lcolor(red) nodropbase  ) ///
	(rspike ypemin ypemax vcvg if y == 1 & j == 1, lcolor(red)) ///
  , legend( off) ylabel(,nogrid) name(blobs2,replace) 
  
  
  
 graph twoway ///
	(rcap lb_90pct ub_90pct y , sort horizontal lcolor(gs7) lwidth(*0.5)) ///  // classification ticks 
	(rspike mfudgelo mfudgehi y , sort horizontal lcolor(white) lwidth(*0.5)) /// // cover much of the rcap line
	(area yy xx  if y == 5 & j > 0, fcolor(green*0.5) lcolor(green) nodropbase  ) /// // plot the distribution at y=5
	(area yy xx  if y == 4 & j > 0, fcolor(green*0.5) lcolor(green) nodropbase  ) /// // ditto y=4
	(rspike ypemin ypemax vcvg if color == 1 & j == 1, lcolor(green)) ///  // overlay the green point estimate lines
    (area yy xx  if color == 2  , fcolor(gold*0.5) lcolor(gold) nodropbase  ) /// // plot the distribution for y=3
	(rspike ypemin ypemax vcvg if color == 2 & j == 1, lcolor(gold)) /// // overlay gold point estimate line
    (area yy xx  if y == 2 & j > 0 , fcolor(red*0.5) lcolor(red) nodropbase  ) /// // plot distribution for y=2
    (area yy xx  if y == 1 & j > 0 , fcolor(red*0.5) lcolor(red) nodropbase  ) /// // ditto y=1
	(rspike ypemin ypemax vcvg if color == 3 & j == 1, lcolor(red)) /// // overlay red point estimate lines
  , legend( off) ylabel(,nogrid) name(blobs3,replace) // plot options
  
graph export "C:\Users\Dale\Dropbox (Biostat Global)\BGC Projects\WHO EPI Guideline Update 2013-15\Document B Draft\JD Edits Dec 2014\Supporting materials\Some of Dale's Figures\test.png", width(2000) replace

/*

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
	   
*/
