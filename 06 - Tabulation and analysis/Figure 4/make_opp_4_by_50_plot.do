
cd "Q:\BGC - WHO Document B Work\Organ Pipe Plots"

clear
set more off

set obs `=16*16*4'
egen stratum= seq(), b(`=16*16')
egen cluster=seq(), b(16) by(stratum)
bysort stratum cluster: gen respondent = _n
gen weight = 8

replace weight = 0.007 if cluster == 1
replace weight = 0.002 if cluster == 2
replace weight = 0.0032 if cluster == 3
replace weight = 0.0032 if cluster == 4
replace weight = 0.004 if cluster == 5
replace weight = 0.004 if cluster == 6
replace weight = 0.003945 if cluster == 7
replace weight = 0.00390625 if cluster == 8
replace weight = 0.00390625 if cluster == 9
replace weight = 0.00390625 if cluster == 10
replace weight = 0.00390625 if cluster == 11
replace weight = 0.00390625 if cluster == 12
replace weight = 0.00390625 if cluster == 13
replace weight = 0.00390625 if cluster == 14
replace weight = 0.00390625 if cluster == 15
replace weight = 0.00390625 if cluster == 16

*replace weight = cluster if cluster > 8
gen y = 0
replace y = (respondent <= 8) if stratum == 1
replace y = (cluster <=8) if stratum == 2

replace y = 1 if respondent < = 16 & cluster == 1 & stratum == 3
replace y = 1 if respondent < = 14 & cluster == 2 & stratum == 3
replace y = 1 if respondent < = 13 & cluster == 3 & stratum == 3
replace y = 1 if respondent < = 11 & cluster == 4 & stratum == 3
replace y = 1 if respondent < = 11 & cluster == 5 & stratum == 3
replace y = 1 if respondent < = 9 & cluster == 6 & stratum == 3
replace y = 1 if respondent < = 8 & cluster == 7 & stratum == 3
replace y = 1 if respondent < = 8 & cluster == 8 & stratum == 3
replace y = 1 if respondent < = 7 & cluster == 9 & stratum == 3
replace y = 1 if respondent < = 7 & cluster == 10 & stratum == 3
replace y = 1 if respondent < = 7 & cluster == 11 & stratum == 3
replace y = 1 if respondent < = 5 & cluster == 12 & stratum == 3
replace y = 1 if respondent < = 4 & cluster == 13 & stratum == 3
replace y = 1 if respondent < = 3 & cluster == 14 & stratum == 3
replace y = 1 if respondent < = 2 & cluster == 15 & stratum == 3
replace y = 1 if respondent < = 1 & cluster == 16 & stratum == 3

replace y = 1 if respondent < = 13 & cluster == 1 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 2 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 3 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 4 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 5 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 6 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 7 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 8 & stratum == 4
replace y = 1 if respondent < = 13 & cluster == 9 & stratum == 4
replace y = 1 if respondent < = 11 & cluster == 10 & stratum == 4
replace y = 1 if respondent < = 0 & cluster == 11 & stratum == 4
replace y = 1 if respondent < = 0 & cluster == 12 & stratum == 4
replace y = 1 if respondent < = 0 & cluster == 13 & stratum == 4
replace y = 1 if respondent < = 0 & cluster == 14 & stratum == 4
replace y = 1 if respondent < = 0 & cluster == 15 & stratum == 4
replace y = 1 if respondent < = 0 & cluster == 16 & stratum == 4


*keep stratum cvg_from cluster weight 

bysort stratum cluster: egen wclust = total(weight)

bysort stratum cluster: egen yd1 = total(weight) if y == 1
bysort stratum cluster: egen yden = min(yd1)
replace yden = 0 if yden == .

bysort stratum cluster: egen nd1 = total(weight) if y == 0
bysort stratum cluster: egen nden = min(nd1)
replace nden = 0 if nden == .

gen ypct = yden / wclust
gen npct = nden / wclust

bysort stratum: egen wtotal = total(weight)
gen wpct = wclust / wtotal

bysort stratum cluster: gen one = _n == 1

save opp4by50data, replace

capture program drop sopp
program sopp

	local dataset `1'
	local stratum `2'
	
	use `dataset', clear
	keep if stratum == `stratum'
	
	* calculate coverage & icc
	
	egen wall = total(weight)
	gen ywt = y * weight
	egen wyes = total(ywt)
	gen wcvg = wyes/wall
	local wcvg: di %5.1f `=100*wcvg[1]'
	
	loneway y cluster
	scalar icc = r(rho)
	if icc == . scalar icc = 1
	local icc: di %5.3f `=scalar(icc)'
	
	local title Coverage = `wcvg'%  ICC = `icc'
	
	keep if one == 1

	gsort -ypct -wpct
	
	foreach v in ypct npct wpct  {
		replace `v' = 100*`v'
	}
	replace npct = 100
	
	gen wx = sum(wpct)
	
	* add an extra row onto the dataset to make the x values work out correctly
	set obs `=_N+1'
	* shift the width up by one observation to make the x values work out correctly
	forvalues i = `=_N'(-1)2 {
		replace wx = `=wx[`=`i'-1']' in `i'
	}
	replace wx = 0 in 1
	
	local ytitle Percent of Cluster
	if inlist(stratum,2,4) local ytitle

	graph twoway (bar npct wx, bartype(spanning) fcolor(white) lpattern(solid) lcolor(gs8) lwidth(vvvthin) ) ///
	             (bar ypct wx, bartype(spanning) fcolor(gs8)   lpattern(solid) lcolor(gs8) lwidth(vvvthin) )  ,  ///
	graphregion(fcolor(white) color(white)) xtitle("") ytitle(`ytitle', size(*1.25)) ///
	ylabel(0(25)100, angle(h)) xlabel(none) ///
	legend(off) title(`title') name("s`stratum'", replace)
end

sopp opp4by50data 1
sopp opp4by50data 2
sopp opp4by50data 3
sopp opp4by50data 4

graph combine s1 s2 s3 s4, imargin(small) plotregion(style(none))

*graph export four_op_plots_at_50percent.png, width(2000) replace
