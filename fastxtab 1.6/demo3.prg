* Demo 3
* A table with athletes and their training results
* Un table cu sportivi si rezultatele de la antrenamente

RAND(-1)
CREATE CURSOR cTest (cName C(10),nResult N(8,2))
FOR lnA=1 TO 5
	FOR lnR=1 TO 20
		IF RAND()>0.2
			INSERT INTO cTest VALUES ('Athlete '+TRANSFORM(m.lnA),100*RAND())
		ENDIF
	NEXT
NEXT
BROWSE

* 1. Group each athlete's results by tens of seconds
* 1. Grupeaza (distribuie) rezultatele fiecarui sportiv pe zeci de secunde
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cPageField = ''
oXtab.cRowField = 'cName' && rows are athletes && randurile contin atletii
oXtab.nRowField2 = 0 && distribution && distribuire
oXtab.cColField = 'floor(nResult/10)' && columns are tens results && coloanele sunt zecile de secunde
oXtab.cDataField = 'nResult' && cells are results && celulele contin rezultatele
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lCloseTable = .F.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 2. Group the results by tens of seconds, regardless whose are
* 2. Grupeaza (distribuie) pe zeci de secunde, fara a tine cont de sportiv
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cPageField = '' && 'pages' are years
oXtab.cRowField = '' && rows are irrelevant && randurile sunt conteaza
oXtab.nRowField = 0 && distribution && distribuire
oXtab.cColField = 'floor(nResult/10)' && columns are tens results && coloanele sunt zecile de secunde
oXtab.cDataField = 'nResult' && cells are results && celulele contin rezultatele
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.lCloseTable = .F.
oXtab.RunXtab()
wait window 'Press any key to continue...'

* 3. Group each athlete's results by tens of seconds, In each column, only the fraction is shown
* 3. Grupeaza (distribuie) rezultatele fiecarui sportiv pe zeci de secunde ;  in fiecare celula sunt afisate doar fractiunile de secunda
select cTest
Local oXtab
oXtab = NewObject("FastXtab", "fastxtab.prg")
oXtab.cPageField = ''
oXtab.cRowField = 'cName' && rows are athletes && randurile contin atletii
oXtab.nRowField2 = 0 && distribution && distribuire
oXtab.cColField = 'floor(nResult/10)' && columns are tens results
oXtab.nFunctionType = 6
oXtab.cFunctionExp = 'nResult/10 - floor(nResult/10)' && coloanele sunt zecile de secunde
oXtab.lBrowseAfter = .T.
oXtab.cOutFile="xx"
oXtab.lCursorOnly = .T.
oXtab.RunXtab()
