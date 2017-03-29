// This twoway command was automatically generated 
// on 17 Jan 2015 at 15:57:29 by the following command:
// catwoway area yy xx y, save("acmd.do",replace) 

graph twoway ///
    (area yy xx  if y == 1 ,   ) ///
    (area yy xx  if y == 2 ,   ) ///
    (area yy xx  if y == 3 ,   ) ///
    (area yy xx  if y == 4 ,   ) ///
    (area yy xx  if y == 5 ,   ) ///
  , legend( ///
    label(1         1) ///
    label(2         2) ///
    label(3         3) ///
    label(4         4) ///
    label(5         5) ///
  )  

