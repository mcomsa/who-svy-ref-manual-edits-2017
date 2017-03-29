/*******************************************************************************
Program Name:	Sample size calculations - stata program.do
Purpose:		
Project:		BMGF - Document B static sample size tables for appendices
Charge Number:  
Date Created:	10/14/14
Date Modified:  10/22/14
Input Data:		NA
Output:	     	table of sample sizes which are copied into Excel spreadsheet
Comments:       
Author:         Mary Prier

Stata version:	13.1
*******************************************************************************/

****THIS TABLE IS NOT USED - DROPPED FOR TABLE 1C SINCE THOSE #S ARE LARGER & THEREFORE MORE CONSERVATIVE****

* Table 2c.  Effective Sample Sizes (ESS) for Surveys to Classify Measles Coverage
* Testing if coverage is above hypothesized value.  (This test protects the population, i.e., null states coverage is < hypothesized value.)
capture drop handle
postfile handle alph beta p0 p1 icc0 m c N_clustered N_effective using handle_out, replace
/*
foreach a in .05 .10 {
	foreach b in .80 .90 {  /* Note: this is power, not beta so use z_b as critical value, not z_1-b */
		foreach p0 in .5 .55 .6 .65 .7 .75 .8 .85 .9 {
			foreach diff in .1 .15 {
			*foreach diff in .05 {
*/


foreach b in .80 .90 {  /* Note: this is power, not beta so use z_b as critical value, not z_1-b */
	foreach a in .1 .05 {
		foreach diff in .01 .05 .1 .15 {
			foreach p0 in .5 .55 .6 .65 .7 .75 .8 .85 .9 .95 {
			
				local m = 10
				local icc0 = 0
				*local a = .05
				*local b = .80
				*local p0 = .50
				*local diff = .1
				
				quietly {
					local p1 = `p0' + `diff'
					local ess_notcorrected = ((invnormal(1-`a')*sqrt(`p0'*(1-`p0')) + invnormal(`b')*sqrt(`p1'*(1-`p1')))/(`p1'-`p0'))^2
					local ess_corrected = (`ess_notcorrected'/4)*(1+sqrt(1+2/(`ess_notcorrected'*abs(`p1'-`p0'))))^2
					
					local c = ceil(`ess_corrected'*(1-`icc0')/`m' + `icc0'*`ess_corrected')
					local N = `m'*`c'
					local N_eff = ceil(`ess_corrected')

					*di "p0=`p0'; p1=`p1'; c=`c'" 
					post handle (`a') (`b') (`p0') (`p1') (`icc0') (`m') (`c') (`N') (`N_eff')
				}
			}
		}
	}
}

postclose handle
use handle_out, clear

********************************************************************************
	
* Table 2b.  Effective Sample Sizes (ESS) for Surveys to Classify Measles Coverage
* Testing if coverage is below 95%.  (This test assumes coverage is high, i.e., null states coverage is >95%.)
capture drop handle
postfile handle alph beta p0 p1 icc0 m c N_clustered N_effective using handle_out, replace

foreach a in .05 .10 {
	foreach b in .80 .90 {  /* Note: this is power, not beta so use z_b as critical value, not z_1-b */
		foreach p0 in .5 .55 .6 .65 .7 .75 .8 .85 .9 .95 {
			*foreach diff in .15 .1 {
			*foreach diff in .05  {
			foreach diff in .01  {
			
				local m = 10
				local icc0 = 0
				*local a = .05
				*local b = .80
				*local p0 = .50
				*local diff = .1
				
				quietly {
					local p1 = `p0' - `diff'
					local ess_notcorrected = ((invnormal(1-`a')*sqrt(`p0'*(1-`p0')) + invnormal(`b')*sqrt(`p1'*(1-`p1')))/(`p1'-`p0'))^2
					local ess_corrected = (`ess_notcorrected'/4)*(1+sqrt(1+2/(`ess_notcorrected'*abs(`p1'-`p0'))))^2
					
					local c = ceil(`ess_corrected'*(1-`icc0')/`m' + `icc0'*`ess_corrected')
					local N = `m'*`c'
					local N_eff = ceil(`ess_corrected')

					*di "p0=`p0'; p1=`p1'; c=`c'" 
					post handle (`a') (`b') (`p0') (`p1') (`icc0') (`m') (`c') (`N') (`N_eff')
				}
			}
		}
	}
}


postclose handle
use handle_out, clear

********************************************************************************

* Table F??.  Effective Sample Sizes (ESS) for surveys to test for difference in coverage over time
*  Looking at increase over time (i.e., p2>p1)
capture drop handle
postfile handle alph beta p1 p2 icc0 m c N_clustered N_effective using handle_out, replace

foreach diff in .01 .05 .1 .15 {
	foreach b in .80 .90 {  /* Note: this is power, not beta so use z_b as critical value, not z_1-b */
		foreach a in .1 .05 {
			foreach p1 in .5 .55 .6 .65 .7 .75 .8 .85 .9 .95 {
			
				local m = 10
				local icc0 = 0
				*local a = .05
				*local b = .80
				*local p1 = .50
				*local diff = .1
				
				quietly {
					local p2 = `p1' + `diff'
					local pbar = (`p1' + `p2')/2
					* One-sided test: alpha (using this for tables as coverage should increase over time)
					local ess_notcorrected = ((invnormal(1-`a')*sqrt(2*`pbar'*(1-`pbar')) + invnormal(`b')*sqrt(`p1'*(1-`p1')+`p2'*(1-`p2')))/(`p2'-`p1'))^2
					* Two-sided test: alpha/2 (equals table for b/t 2 places when r=1 in those calculations)
					*local ess_notcorrected = ((invnormal(1-`a'/2)*sqrt(2*`pbar'*(1-`pbar')) + invnormal(`b')*sqrt(`p1'*(1-`p1')+`p2'*(1-`p2')))/(`p2'-`p1'))^2
					
					local ess_corrected = (`ess_notcorrected'/4)*(1+sqrt(1+4/(`ess_notcorrected'*abs(`p2'-`p1'))))^2
					
					local c = ceil(`ess_corrected'*(1-`icc0')/`m' + `icc0'*`ess_corrected')
					local N = `m'*`c'
					local N_eff = ceil(`ess_corrected')

					*di "p1=`p1'; p2=`p2'; c=`c'" 
					post handle (`a') (`b') (`p1') (`p2') (`icc0') (`m') (`c') (`N') (`N_eff')
				}
			}
		}
	}
}


postclose handle
use handle_out, clear

********************************************************************************

* Table G??.  Effective Sample Sizes (ESS) to test for difference in coverage between 2 places
*  Equal ESS in each place (i.e., r=1)
capture drop handle
postfile handle alph beta p1 p2 icc0 m c N_clustered ratioo N1_effective N2_effective using handle_out, replace

foreach diff in .01 .05 .1 .15 {
	foreach b in .80 .90 {  /* Note: this is power, not beta so use z_b as critical value, not z_1-b */
		foreach a in .1 .05 {
			foreach p1 in .5 .55 .6 .65 .7 .75 .8 .85 .9 .95 {
			
				local m = 10
				local icc0 = 0
				local r = 1
				*local a = .05
				*local b = .80
				*local p1 = .70
				*local diff = .1
				
				quietly {
					local p2 = `p1' + `diff'
					local pbar = (`p1' + `r'*`p2')/(`r'+1)
					local ess_notcorrected = ((invnormal(1-`a'/2)*sqrt((`r'+1)*`pbar'*(1-`pbar')) + invnormal(`b')*sqrt(`r'*`p1'*(1-`p1')+`p2'*(1-`p2'))))^2 / (`r'*(`p2'-`p1')^2)
					local ess_notcorrected_n2 = `r'*`ess_notcorrected'
					local ess_corrected = (`ess_notcorrected'/4)*(1+sqrt(1+(2*(`r'+1))/(`ess_notcorrected'*`r'*abs(`p2'-`p1'))))^2
					local ess_corrected_n2 = `r'*`ess_corrected'
					
					local c = ceil(`ess_corrected'*(1-`icc0')/`m' + `icc0'*`ess_corrected')
					local N = `m'*`c'
					local N_eff = ceil(`ess_corrected')
					local N_eff_n2 = ceil(`ess_corrected_n2')

					*di "n1eff: `N_eff'; n2eff: `N_eff_n2'"
					
					post handle (`a') (`b') (`p1') (`p2') (`icc0') (`m') (`c') (`N') (`r') (`N_eff') (`N_eff_n2')
				}
			}
		}
	}
}


postclose handle
use handle_out, clear
