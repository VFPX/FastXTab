* Demo 1
* A table with inputs and outputs from some companies for each year.
* Un table cu intrarile si iesirile anuale ale unor companii

RAND(-1)
CREATE CURSOR cTest (cName C(10),nYear I,nInput N(10,2),nOutput N(10,2))
FOR lnC=1 TO 5
	FOR lnY=2010 TO 2014
		INSERT INTO cTest VALUES ('Company '+TRANSFORM(m.lnC),m.lnY,100000*RAND(),100000*RAND())
	NEXT
NEXT
BROWSE

* 1.  Get inputs and show (browse) the output. Result is a table with a random name
* 1.  Tabel pivot cu iesirile distribuite pe ani si companii, urmat de afisearea (browse) rezultatului. Rezultatul este un table cu nume aleator
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.cDataField = 'nInput' && Inputs && celulele contin intrarile
oXtab.lCloseTable = .F.
oXtab.lBrowseAfter = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 2. Choose a name for the output table
* 2. Alegerea unui nume pentru tabelul rezultat
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.cDataField = 'nInput' && Inputs && celulele contin intrarile
oXtab.lBrowseAfter = .T.
oXtab.lCloseTable = .F.
oXtab.cOutFile="xx" && table is named xx
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 3. Output into a cursor rather than a table
* 3. Rezultatul este cursor, nu tabel
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.cDataField = 'nInput' && Inputs && celulele contin intrarile
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCloseTable = .F.
oXtab.lCursorOnly = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 4. Show null values (if exists)
* 4. Afiseaza Null (daca e cazul)
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lCloseTable = .F.
oXtab.lDisplayNulls = .F.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 5. Add a supplementary row with total
* 5. Adauga un rand cu totaluri
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 6. Show both nInput and nOutput 
* 6. Afiseaza atat intrarile cat si iesirile
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.nMultiDataField = 2
oXtab.acDataField[1] = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.acDataField[2] = 'nOutput' && cells contains Outputs  && celulele contin iesirile
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 7. Show three columns : nInput, nOutput and nInput - nOutput. Note the use of SUM()
* 7. Afiseaza trei coloane : nInput, nOutput and nInput - nOutput. De remarcat utilizarea functiei SUM()
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.nMultiDataField = 3
oXtab.acDataField[1] = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.acDataField[2] = 'nOutput' && cells contains Outputs  && celulele contin iesirile
oXtab.anFunctionType[3] = 6
oXtab.acFunctionExp[3] = 'SUM(nInput - nOutput)'
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lDisplayNulls = .F.
oXtab.lCloseTable = .F.
oXtab.lTotalRows = .T.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 8. Close the input table after run
* 8. Inchide tabelul sursa 
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cRowField = 'cName' && rows are company names && randurile contin numele companiilor
oXtab.cColField = 'nYear' && columns are years && coloanele sunt anii
oXtab.cDataField = 'nInput' && cells contains Inputs && celulele contin intrarile
oXtab.lBrowseAfter = .T.
oXtab.lCloseTable = .T.
oXtab.RunXtab()
