// This twoway command was automatically generated 
// on 20 Jan 2015 at 21:59:40 by the following command:
// catwoway area yy xx y if j > 0, toptions(name(dots, replace) ylabel(1(1)5)  yline(0.6 1.6 2.6 3.6 4.6, lwidth(vvthin) lcolor(gs14)) ) poptions(msymbol(x) nodropbase) save("b1.do", replace) 

graph twoway ///
    (area yy xx  if y == 1 ,  msymbol(x) nodropbase ) ///
    (area yy xx  if y == 2 ,  msymbol(x) nodropbase ) ///
    (area yy xx  if y == 3 ,  msymbol(x) nodropbase ) ///
    (area yy xx  if y == 4 ,  msymbol(x) nodropbase ) ///
    (area yy xx  if y == 5 ,  msymbol(x) nodropbase ) ///
if j > 0  , legend( ///
    label(1         1) ///
    label(2         2) ///
    label(3         3) ///
    label(4         4) ///
    label(5         5) ///
  ) name(dots, replace) ylabel(1(1)5) yline(0.6 1.6 2.6 3.6 4.6, lwidth(vvthin) lcolor(gs14)) 

