// This twoway command was automatically generated 
// on 23 Feb 2015 at 23:52:35 by the following command:
// catwoway line yy xx y if j > 0, toptions(name(lines, replace) ylabel(1(1)5) yline(0.6 1.6 2.6 3.6 4.6, lwidth(vvthin) lcolor(gs14)) ) poptions(msymbol(x)) save("dots.do", replace) 

graph twoway ///
    (line yy xx  if y == 1 ,  msymbol(x) ) ///
    (line yy xx  if y == 2 ,  msymbol(x) ) ///
    (line yy xx  if y == 3 ,  msymbol(x) ) ///
    (line yy xx  if y == 4 ,  msymbol(x) ) ///
    (line yy xx  if y == 5 ,  msymbol(x) ) ///
    (line yy xx  if y == 6 ,  msymbol(x) ) ///
    (line yy xx  if y == 7 ,  msymbol(x) ) ///
    (line yy xx  if y == 8 ,  msymbol(x) ) ///
if j > 0  , legend( ///
    label(1         1) ///
    label(2         2) ///
    label(3         3) ///
    label(4         4) ///
    label(5         5) ///
    label(6         6) ///
    label(7         7) ///
    label(8         8) ///
  ) name(lines, replace) ylabel(1(1)5) yline(0.6 1.6 2.6 3.6 4.6, lwidth(vvthin) lcolor(gs14)) 

