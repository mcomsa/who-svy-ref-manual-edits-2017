*************************************************************************
* Ethiopia 2013 Measles SIA Coverage Survey
*
* program to calculate LB and UB of 95 and 90% CIs
* This could be improved by checking to see whether the sample proportion
* is 0% or 100%, in which case the CI should be calculated using 
* Clopper-Pearson exact method, where the sample size = the survey 
* sample size, because when sample proportion is 0% or 100%, the estimated
* ICC is 0.  Clopper Pearson calculations can use the cii command with the 
* exact and level options
*
* Dale Rhoda, September 2014
*
*************************************************************************
* This is the folder in the DropBox
global base C:\Users\Rhodad\Dropbox\LQAS Docs from Dale\Dales work

* This is the folder on my local hard drive
global base C:\Users\Dale\Documents\- Projects\BMGF - 2013\Ethiopia Measles

cd "$base"

set more off



local lvl1 95.00
local lvl2 95.00
local lvl3 95.00
local lvl4 95.00
local lvl5 92.86
local lvl6 90.59
local lvl7 88.13
local lvl8 85.48
local lvl9 82.65
local lvl10 79.62
local lvl11 76.36
local lvl12 72.87
local lvl13 69.11
local lvl14 65.02
local lvl15 60.55
local lvl16 55.61
local lvl17 50.08
local lvl18 43.72
local lvl19 36.07
local lvl20 26.10
local lvl21 7.98


capture matrix drop table
matrix table = J(131,47,.)
matrix colnames table = vaccination_coverage lb_95pct ub_95pct lb_90pct ub_90pct l1 u1 l2 u2 l3 u3 l4 u4 l5 u5 l6 u6 l7 u7 l8 u8 l9 u9 l10 u10 l11 u11 l12 u12 l13 u13 l14 u14 l15 u15 l16 u16 l17 u17 l18 u18 l19 u19 l20 u20 l21 u21 
						
forvalues i = 1/131 {

	if length(`"`c`i''"') > 0 {
	
		di `"`c`i''"'

		qui svy: proportion gotvac if `c`i''
		matrix out = r(table)
		
		if out[1,1] == 1 {
		
			matrix table[`i',1] = 1
			
			cii 150 150, exact level(95)
			matrix table[`i',2] = r(lb)
			matrix table[`i',3] = r(ub)
			
			cii 150 150, exact level(90)
			matrix table[`i',4] = r(lb)
			matrix table[`i',5] = r(ub)
			
			local col 6
						
			forvalues j = 1/20 {
				cii 150 150, exact level(`lvl`j'')
				matrix table[`i',`col'] = r(lb)
				local ++col
				matrix table[`i',`col'] = r(ub)
				local ++col
			}
			
			cii 150 150, exact level(10)
			matrix table[`i',`col'] = max(0.0,1-.798*(1-r(lb)))
			local ++col
			matrix table[`i',`col'] = 1
			
			
		}
		else {
		
			matrix out = out[1..6,2]
			matrix table[`i',1] = out[1,1]
			matrix table[`i',2] = max(0.0,out[5,1])
			matrix table[`i',3] = min(1.0,out[6,1])

			qui svy: proportion gotvac if `c`i'', level(90)
			matrix out = r(table)
			matrix out = out[1..6,2]
			matrix table[`i',4] = max(0.0,out[5,1])
			matrix table[`i',5] = min(1.0,out[6,1])
			
			local col 6
			forvalues j = 1/20 {
				qui svy: proportion gotvac if `c`i'', level(`lvl`j'')
				matrix out = r(table)
				matrix out = out[1..6,2]
				matrix table[`i',`col'] = max(0.0,out[5,1])
				local ++col
				matrix table[`i',`col'] = min(1.0,out[6,1])
				local ++col
			}

			
			* Stata has a quirky feature where level cannot be smaller
			* than 10.00 and we need it for 7.98, so calculate for
			* 10.00 and then shave it back 
			qui svy: proportion gotvac if `c`i'', level(10)
			matrix out = r(table)
			matrix out = out[1..6,2]
			matrix table[`i',`col'] = max(0.0,out[1,1]-.798*(out[1,1]-out[5,1]))
			local ++col
			matrix table[`i',`col'] = min(1.0,out[1,1]+.798*(out[6,1]-out[1,1]))	
			
		}
		
	}
}
clear
svmat table, names(col) 

export excel using "C:\Users\Dale\Documents\- Projects\BMGF - 2013\Ethiopia Measles\Output\CI LCB UCB and 21 segments.xlsx", sheet(summary) cell(c7) sheetmodify firstrow(var)
