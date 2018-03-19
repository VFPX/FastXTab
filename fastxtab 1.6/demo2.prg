* Demo 2
* A table with inputs and outputs from some companies for each month of the each year. Some values are missing
* Un tabel cu intrarile si iesirile lunare pe parcursul mai multor ani ale unor companii. In unele luni lipsesc date

RAND(-1)
CREATE CURSOR cTest (cName C(10),nYear I,nInput N(10,2),nOutput N(10,2))
FOR lnC=1 TO 5
	FOR lnY=2010 TO 2014
		INSERT INTO cTest VALUES ('Company '+TRANSFORM(m.lnC),m.lnY,100000*RAND(),100000*RAND())
	NEXT
NEXT
BROWSE

* 1. Get total / year (inputs)
* 1. Obtinerea intrarilor totale pe fiecare an / companie
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele contin anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 2. Get average / month (inputs)
* 2. Obtinerea intrarilor medii pe fiecare an / companie
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele contin anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.nFunctionType = 3
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 3. Count the months with data for each company in every year (inputs)
* 3. Numarul lunilor cu date per companie / an
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele contin anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.nFunctionType = 2
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 4. Get worst (minimum) monthly input value from each year / each company
* 4. Obtinerea intrarilor lunare minime pe fiecare an / companie
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele contin anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.nFunctionType = 4
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 5. Get the best (maximum) monthly input value from each year / each company
* 5. Obtinerea intrarilor lunare maxime pe fiecare an / companie
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele contin anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.nFunctionType = 5
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'
return


* 6. Get total / semester (inputs)
* 6. Obtinerea intrarilor totale pe fiecare an / semestru
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'PADL(nYear,4)+[_sem]+iif(nMonth<7,[1],[2])' && columns are semesters && coloanele sunt semestrele
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 7. Get quarterly average for nInputs - nOutputs 
* 7. Obtinerea mediilor trimestriale ale nInputs - nOutputs 
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'PADL(nYear , 4) + [_qtr] + PADL(1 + FLOOR((nMonth - 1) / 3) , 1)' && columns are quarters && coloanele sunt trimestrele
oXtab.nFunctionType = 6
oXtab.cFunctionExp = 'AVG(nInput - nOutput)'
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 8. Get quarterly average for nInputs - nOutputs, but columns are companies, and rows are quarters
* 8. Obtinerea mediilor trimestriale ale nInputs - nOutputs, dar coloanele sunt companiile si randurile sunt trimestrele
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cPageField = 'nYear' && 'pages' are years
oXtab.cRowField = '1 + FLOOR((nMonth - 1) / 3)' && rows are quarters && randurile sunt trimestrele
oXtab.cColField = 'cName' && columns are company names && coloanele sunt numele companiilor
oXtab.nFunctionType = 6
oXtab.cFunctionExp = 'AVG(nInput - nOutput)'
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 9. Get quarterly average for nInputs - nOutputs, columns are companies, and rows are quarters but only for quarters with results < 0
* 9. Obtinerea mediilor trimestriale < 0 ale nInputs - nOutputs, dar coloanele sunt companiile si randurile sunt trimestrele
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cPageField = 'nYear' && 'pages' are years && "paginile" sunt anii
oXtab.cRowField = '1 + FLOOR((nMonth - 1) / 3)' && rows are quarters && randurile sunt trimestrele
oXtab.cColField = 'cName' && columns are company names && coloanele sunt numele companiilor
oXtab.nFunctionType = 6
oXtab.cFunctionExp = 'AVG(nInput - nOutput)'
oXtab.cHaving = 'AVG(nInput - nOutput) < 0' && Having
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 10. Get quarterly average for nInputs - nOutputs, columns are companies, and rows are quarters, for quarters with results < 0 but only for first company
* 10. Obtinerea mediilor trimestriale < 0 ale nInputs - nOutputs, dar coloanele sunt companiile si randurile sunt trimestrele, doar pentru prima companie
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cPageField = 'nYear' && 'pages' are years && "paginile" sunt anii
oXtab.cRowField = '1 + FLOOR((nMonth - 1) / 3)' && rows are quarters && randurile sunt trimestrele
oXtab.cColField = 'cName' && columns are company names && coloanele sunt numele companiilor
oXtab.nFunctionType = 6
oXtab.cFunctionExp = 'AVG(nInput - nOutput)'
oXtab.cHaving = 'AVG(nInput - nOutput) < 0' && Having
oXtab.cCondition = 'cName==[Company 1]'     && Where
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
