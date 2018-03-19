***********************************************************************
*    File: FastXtab.prg
* Version: 1.6
*  Author: Alexander Golovlev
* Country: Russian Federation
*   Email: avg.kedr@overta.ru , golovlev@yandex.ru
*
* Upgraded: Vilhelm-Ion Praisach
***********************************************************************
***********************************************************************
*
* Notes: On entry, a table should be open in the current work area,
*        and it should contain at most one record for each cell in
*        a cross-tabulation. This table may NOT be in row order.
*
*        The rowfld field in each record becomes the y-axis (rows) for
*        a cross-tab and the colfld field becomes the x-axis (columns)
*        The actual cross-tab results are saved to the database name
*        specified by "cOutFile" property.
*
*        The basic strategy goes like this. Using select query get all
*        unique values of rows and columns and totaling values for each
*        row/column pair. Then determine the column headings in the
*        output cursor. Next produce an empty cursor with one column
*        for each unique value of input field colfld, plus one additional
*        column for input field rowfld values. Finally, scan the temporary
*        cursor and put the cell values for the row/column intersections
*        into the output cursor.
*
* Usage: oXtab = NewObject("FastXtab", "FastXtab.prg")
*        oXtab.lCursorOnly = .T.
*        oXtab.lBrowseAfter = .T.
*        oXtab.RunXtab
*
***********************************************************************

*#include FastXtabRo.h	&& Romaneste
#include FastXtabEn.h	&& English
*#include FastXtabRu.h	&& Russian

External Array aFldArray

Define Class FastXtab As Custom
cOutFile = SYS(2015)	&& "xtabquery" The name of the output file
lCursorOnly = .F.		&& Specifies whether the input datasource is cursor
lCloseTable = .T.		&& Specifies whether to close the source datasource after the cross tab is generated
nPageField = 0			&& Specifies the field position in the datasource of the cross tab pages
nRowField = 1			&& Specifies the field position in the datasource of the cross tab rows
nRowField2 = 1			&& Specifies the field position in the datasource of the cross tab rows
nColField = 2			&& Specifies the field position in the datasource of the cross tab columns
nDataField = 3			&& Specifies the field position in the datasource of the cross tab data
lTotalRows = .F.		&& Specifies whether to total rows in the cross tab output
lDisplayNulls = .F.		&& Specifies whether to display null values in the cross tab output
lBrowseAfter = .F.		&& Specifies whether to open a Browse window on the cross tab output

cPageField = ""			&& Specifies the field name in the datasource of the cross tab pages
cRowField = ""			&& Specifies the field name in the datasource of the cross tab rows
cColField = ""			&& Specifies the field name in the datasource of the cross tab columns
cDataField = ""			&& Specifies the field name in the datasource of the cross tab data

nFunctionType = 1		&& 1 Sum 2 Count 3 Avg 4 Min 5 Max 6 Custom
nAvePrec = 3			&& Average precision
cFunctionExp=''			&& For nFunctionType=6
cCondition=""			&& ex "period>date(2000,1,1)"
cHaving=""				&& ex "COUNT(summa)>20"
nMultiDataField=1		&& For multiple nDataField / nFunctionType / cFunctionExp
DIMENSION anDataField[1],anFunctionType[1],acFunctionExp[1],acDataField[1]
anDataField[1] = 3		&& Specifies the field position in the datasource of the cross tab data
acDataField[1] = ""		&& Specifies the field name in the datasource of the cross tab data
anFunctionType[1] = 1	&& 1 Sum 2 Count 3 Avg 4 Min 5 Max 6 Custom
acFunctionExp[1]=''		&& For anFunctionType=6

Protected BadChars		&& String of symbols not allowed in field name
Protected RepChars		&& String of symbols to replace bad chars

PROTECTED cCells		&& cursor for cells
PROTECTED cColumns		&& cursor for columns
PROTECTED cRows			&& cursor for rows
PROTECTED cPages		&& cursor for pages

**********************************************************************************
PROCEDURE nMultiDataField_assign
	LPARAMETERS tNewValue
	LOCAL oldValue,lni
	IF m.tNewValue < 1
		RETURN
	ENDIF
	oldValue=This.nMultiDataField
	DIMENSION This.anDataField[m.tNewValue],This.acDataField[m.tNewValue],This.anFunctionType[m.tNewValue],This.acFunctionExp[m.tNewValue]
	This.nMultiDataField=m.tNewValue
	FOR lni=m.oldValue+1 TO m.tNewValue
		This.anDataField[m.lni]=This.anDataField[1]
		This.acDataField[m.lni]=This.acDataField[1]
		This.anFunctionType[m.lni]=This.anFunctionType[1]
		This.acFunctionExp[m.lni]=This.acFunctionExp[1]
	NEXT
ENDPROC

**********************************************************************************
Procedure Init			&& Constructor
	If VERSION(3) $ "81 82 86 88"
		This.BadChars = "/,-=:;!@#$%&*.<>()?[]\+"+Chr(34)+Chr(39)+" "
	Else
*		This.BadChars = "ÅÇÉÑÖÜáàâSãOéèêëíìîïñóòôs†°¢£§•/\,-=:;{}[]!@#$%^&*.<>()?"+;
			"+|ÄõoùûY¶ß©™´¨≠Æ_∞±Ii'µ∂∑,1∫ªºΩ_øAAAAƒ≈∆«E…EEIIII"+;
			"D—OOOO÷xOUUU‹Y_ﬂ‡·‚a‰ÂÊÁËÈÍÎÏÌÓÔdÒÚÛÙoˆ˜o˘˙˚¸y_"+Chr(34)+Chr(39)+" "
		This.BadChars = "ÅÇÉÑÖÜáàâãéèêëíìîïñóòô†°¢£§•/\,-=:;{}[]!@#$%^&*.<>()?"+;
			"+|Äõùû¶ß©™´¨≠Æ_∞±'µ∂∑,∫ªºΩ_øƒ≈∆«…"+;
			"—÷‹_ﬂ‡·‚‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙˆ˜˘˙˚¸_"+Chr(34)+Chr(39)+" "
	EndIf
	This.RepChars = Replicate("_", Len(This.BadChars) - 1)
	This.cCells=SYS(2015)
	This.cColumns=SYS(2015)
	This.cRows=SYS(2015)
	This.cPages=SYS(2015)
EndProc

**********************************************************************************
Procedure Destroy		&& Destructor
	If Used(This.cCOLUMNS)
	   Use In (This.cColumns)
	EndIf
	If Used(This.cRows)
	   Use In (This.cRows)
	EndIf
	If Used(This.cPages)
	   Use In (This.cPages)
	EndIf
	If Used(This.cCELLS)
	   Use In (This.ccells)
	EndIf
EndProc

**********************************************************************************
Function RunXtab		&& Generates a cross tab
	Local cTalkStat		&& SET TALK status
	Local cNullStat		&& SET NULL status
	Local cOutStem		&& Output cursor name
	Local DbfName		&& Input table file name
	Local nGroupFields	&& Number of grouping fields

	LOCAL lcCondition
	LOCAL lcHaving
	LOCAL lcFunctionExp
	LOCAL lni
	LOCAL lnGood
	LOCAL lnGoodR
	LOCAL lnGoodP
	LOCAL lcChar
	LOCAL pagefldvalue
	LOCAL pagefldvalue2
	LOCAL rowfldvalue
	LOCAL rowfldvalue2
	LOCAL colfldvalue
	LOCAL colfldvalue2
	LOCAL cellfldvalue
	LOCAL replcolumn
	LOCAL pagefldname
	LOCAL rowfldname
	LOCAL colfldname
	LOCAL laRows[1]
	LOCAL laPages[1]
	LOCAL lcSql
	LOCAL lcGrup
	LOCAL lcRightPar
	LOCAL cC1
	LOCAL laTempArr[1,1]
	LOCAL lColMax
	LOCAL laCells[1]
	LOCAL loErr as Exception
	LOCAL llSqlErr
	LOCAL lnCurrTop
	LOCAL lnNo
	****************

	*Wait Window "Running Cross Tab Query" NoWait
	cTalkStat = Set("TALK")
	Set Talk Off
	cNullStat = Set("NULL")

	* Check object properties
	If Type("This.cOutFile") != "C"
		This.cOutFile = SYS(2015) &&"xtabquery"
	ENDIF
	If Type("This.lCursorOnly") != "L"
		This.lCursorOnly = .F.
	EndIf
	If Type("This.lCloseTable") != "L"
		This.lCloseTable = .T.
	EndIf
	If Type("This.nPageField") != "N"
		This.nPageField = 0
	EndIf
	If Type("This.nRowField") != "N"
		This.nRowField = 1
	EndIf
	If Type("This.nColField") != "N"
		This.nColField = 2
	EndIf
	If Type("This.nDataField") != "N"
		This.nDataField = 3
	EndIf
	If Type("This.lTotalRows") != "L"
		This.lTotalRows = .F.
	ENDIF
	If Type("This.lDisplayNulls") != "L"
		This.lDisplayNulls = .F.
	EndIf
	If Type("This.lBrowseAfter") != "L"
		This.lBrowseAfter = .F.
	ENDIF

	If Type("This.nFunctionType") != "N"
		This.nFunctionType = 1
	ELSE
		IF !BETWEEN(This.nFunctionType,1,6)
			This.nFunctionType=1
		ENDIF
	ENDIF
	If Type("This.nAvePrec") != "N"
		This.nAvePrec = 3
	ENDIF
	IF This.nAvePrec<0
		This.nAvePrec = 3
	ENDIF
	
	lcFunctionExp=''
	If Type("This.cFunctionExp") != "C"
		This.cFunctionExp = ""
	ELSE
		lcFunctionExp=This.cFunctionExp
	ENDIF
	IF EMPTY(m.lcFunctionExp) AND This.nFunctionType=6
		This.nFunctionType = 1
	ENDIF
	
	lcCondition=''
	If Type("This.cCondition") != "C"
		This.cCondition = ""
	ELSE
		IF !EMPTY(This.cCondition)
			lcCondition="WHERE "+This.cCondition
		ENDIF
	ENDIF
	
	lcHaving=''
	If Type("This.cHaving") != "C"
		This.cHaving = ""
	ELSE
		IF !EMPTY(This.cHaving)
			lcHaving=" HAVING "+This.cHaving
		ENDIF
	ENDIF

	IF This.nMultiDataField>1
		FOR lni=1 TO This.nMultiDataField
			If VARType(This.anDataField[m.lni]) != "N"
				This.anDataField[m.lni] = 3
			ENDIF
			If VarType(This.anFunctionType[m.lni]) != "N"
				This.anFunctionType[m.lni] = 1
			ELSE
				IF !BETWEEN(This.anFunctionType[m.lni],1,6)
					This.anFunctionType[m.lni]=1
				ENDIF
			ENDIF
			If VarType(This.acFunctionExp[m.lni]) != "C"
				This.acFunctionExp[m.lni] = ""
			ENDIF
			IF EMPTY(This.acFunctionExp[m.lni]) AND This.anFunctionType[m.lni]=6
				This.anFunctionType[m.lni] = 1
			ENDIF
		NEXT
	ENDIF

	If This.lDisplayNulls
		Set Null On
	Else
		Set Null Off
	EndIf

	* Make sure that table is open in current work area
	If !Used()
		m.DbfName = GetFile('DBF',C_LOCATEDBF)
		If Empty(m.DbfName)
			* User canceled out of dialog
			Return .F.
		Else
			Use (m.DbfName)
		EndIf
	EndIf
	* Check for input table properties
	If FullPath(DefaultExt(Alias(),'DBF')) == FullPath(DefaultExt(THIS.cOutFile,'DBF'))
		This.Alert(C_OUTPUT)
		Return .F.
	ENDIF

	* Gather information on the currently selected database fields
	Dimension InpFields[FCOUNT(),4]
	m.numflds = AFields(InpFields)

	* None of these fields are allowed to be memo fields
	IF This.nRowField<>0 OR !EMPTY(This.cRowField) 
		lnGoodP=1 && Expression PageField
		IF !EMPTY(This.cPageField)
			IF ASCAN(InpFields,This.cPageField,-1,-1,-1,1+2+4+8)>0
				This.nPageField=ASCAN(InpFields,This.cPageField,-1,-1,-1,1+2+4+8)
			ELSE
				lnGoodP=0
				FOR lni=1 TO LEN(This.cPageField)
					lcChar=SUBSTR(This.cPageField,m.lni,1)
					IF NOT ISALPHA(m.lcChar) AND NOT (ISDIGIT(m.lcChar) AND m.lni>1) AND m.lcChar<>"_"
						lnGoodP=2
						EXIT
					ENDIF
				NEXT
			ENDIF
		ENDIF
		IF m.lnGoodP<>2
			If This.nPageField > 0 
				If InpFields[THIS.nPageField,2] $ 'MGP'
					This.Alert(C_BADPAGEFLD)
					Return .F.
				ENDIF
			EndIf
		EndIf

		lnGoodR=1 && Expression RowField
		IF !EMPTY(This.cRowField)
			IF ASCAN(InpFields,This.cRowField,-1,-1,-1,1+2+4+8)>0
				THIS.nRowField=ASCAN(InpFields,This.cRowField,-1,-1,-1,1+2+4+8)
			ELSE
				lnGoodR=0
				FOR lni=1 TO LEN(This.cRowField)
					lcChar=SUBSTR(This.cRowField,m.lni,1)
					IF NOT ISALPHA(m.lcChar) AND NOT (ISDIGIT(m.lcChar) AND m.lni>1) AND m.lcChar<>"_"
						lnGoodR=2
						EXIT
					ENDIF
				NEXT
			ENDIF
		ENDIF
		IF m.lnGoodR<>2
			If InpFields[THIS.nRowField,2] $ 'MGP'
			   This.Alert(C_BADROWFLD)
			   Return .F.
			ENDIF
		ENDIF
	ENDIF
	
	If FCount() < 3 AND NOT (This.nRowField=0 AND EMPTY(This.cRowField)) AND NOT (This.nRowField2 = 0 AND !EMPTY(This.cRowField))
    	This.Alert(C_NEED3FLDS)
    	Return .F.
    EndIf
	If RecCount() = 0
	    This.Alert(C_EMPTYDBF)
		Return .F.
	EndIf

	IF (This.nRowField<>0 OR !EMPTY(This.cRowField)) AND (This.nRowField2<>0 OR !EMPTY(This.cRowField))
		lcCondition=m.lcCondition+m.lcHaving
	ENDIF

	lnGood=1 && Expression ColField
	IF !EMPTY(This.cColField)
		IF ASCAN(InpFields,This.cColField,-1,-1,-1,1+2+4+8)>0
			THIS.nColField=ASCAN(InpFields,This.cColField,-1,-1,-1,1+2+4+8)
		ELSE
			lnGood=0
			FOR lni=1 TO LEN(This.cColField)
				lcChar=SUBSTR(This.cColField,m.lni,1)
				IF NOT ISALPHA(m.lcChar) AND NOT (ISDIGIT(m.lcChar) AND m.lni>1) AND m.lcChar<>"_"
					lnGood=2
					EXIT
				ENDIF
			NEXT
		ENDIF
	ENDIF
	If m.lnGood<>2 
		IF InpFields[THIS.nColField,2] $ 'MGP' 
		   This.Alert(C_BADCOLFLD)
		   Return .F.
		ENDIF
	ENDIF
	
	IF This.nMultiDataField=1
		IF !EMPTY(This.cDataField)
			IF ASCAN(InpFields,This.cDataField,-1,-1,-1,1+2+4+8)>0
				THIS.nDataField=ASCAN(InpFields,This.cDataField,-1,-1,-1,1+2+4+8)
			ENDIF
		ENDIF
		IF This.nFunctionType < 6
			If InpFields[THIS.nDataField,2] $ 'MGP'
			   This.Alert(C_BADCELLFLD)
			   Return .F.
			ENDIF
		EndIf

		This.anDataField[1] = This.nDataField
		This.acDataField[1] = This.cDataField
		This.anFunctionType[1] = This.nFunctionType
		This.acFunctionExp[1]= This.cFunctionExp
	ELSE
		FOR lni=1 TO This.nMultiDataField
			IF !EMPTY(This.acDataField[m.lni])
				IF ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)>0
					THIS.anDataField[m.lni]=ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)
				ENDIF
			ENDIF
			IF This.anFunctionType[m.lni] < 6
				If InpFields[THIS.anDataField[m.lni],2] $ 'MGP'
				   This.Alert(C_BADCELLFLD)
				   Return .F.
				ENDIF
			EndIf
		NEXT
	ENDIF


*****************************************
*****************************************

	DO CASE
	CASE This.nRowField2=0 AND !EMPTY(This.cRowField) 
		m.DbfName = Alias()
		m.rowfldname = IIF(m.lnGoodR=1,InpFields[This.nRowField,1],IIF(m.lnGoodR=2,This.cRowField,""))
		m.colfldname  = IIF(m.lnGood=1,InpFields[This.nColField,1],IIF(m.lnGood=2,This.cColField,""))

		lcSql='Select '
		If This.nPageField > 0 OR m.lnGoodP=2
			m.pagefldname = IIF(m.lnGoodP=1,InpFields[This.nPageField,1],IIF(m.lnGoodP=2,This.cPageField,""))
			nGroupFields = 2
			lcOrder = '1,2,3'
			lcSql=m.lcSql+m.pagefldname+' as pagefld,'
		Else
			nGroupFields = 1
			lcOrder = '1,2'
		ENDIF


		
		lcSql=m.lcSql+m.rowfldname+' as rowfld,'+m.colfldname+' as colfld'
		FOR lni=1 TO This.nMultiDataField
			IF !EMPTY(This.acDataField[m.lni])
				IF ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)>0
					THIS.anDataField[m.lni]=ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)
				ENDIF
			ENDIF
			IF This.anFunctionType[m.lni]=6
				lcSql=m.lcSql+','+This.acFunctionExp[m.lni]
			ELSE
				m.cellfldname = InpFields[This.anDataField[m.lni],1]
				lcSql=m.lcSql+','+m.cellfldname
			ENDIF
			lcSql=m.lcSql+' As cellfld'+TRANSFORM(m.lni)
		NEXT
		lcSql=m.lcSql+' From '+m.DbfName+' ORDER by '+lcOrder+m.lcCondition+' Into Cursor '+This.cCells
		IF VERSION(5)>=800
			llSqlErr=.F.
			TRY
				&lcSql
			CATCH TO loErr
				llSqlErr=.T.
				MESSAGEBOX(loErr.Message,16,'SQL Error')
			ENDTRY
			IF llSqlErr
				RETURN .F.
			ENDIF
		ELSE
			&lcSql
		ENDIF
		
		* Check cells datatypes
		=AFIELDS(laCells,This.cCells)
		* Generate pages names
		If This.nPageField > 0 OR m.lnGoodP=2
			Select Distinct pagefld as pagevalue From (This.cCells) Group by 1 Into Cursor (This.cPages)
			Index On pagevalue Tag pagevalue
			=AFIELDS(laPages,This.cPages)
		ENDIF
		* Generate rows names
*		Select Distinct rowfld as rowvalue From (This.cCells) Group by 1 Into Cursor (This.cRows)
		cC1=SYS(2015)
		SELECT rowfld,colfld,COUNT(*) as No FROM (This.cCells) GROUP BY rowfld,colfld INTO CURSOR (cC1)
		SELECT (cC1)
		GO TOP 
		SELECT rowfld as rowvalue,MAX(No) as no FROM (cC1) GROUP BY rowfld INTO CURSOR (This.cRows)
		USE IN (cC1)

		SELECT (This.cRows)
		Index On rowvalue Tag rowvalue
		=AFIELDS(laRows,This.cRows)

		Select Distinct colfld as colvalue From (This.cCells) Group by 1 Into Cursor (This.cColumns)
		Index On colvalue TAG colvalue 

		Do Case
		Case _TALLY*This.nMultiDataField > 254
			This.Alert(C_XSVALUES)
			Return .F.
		Case _TALLY = 0
			This.Alert(C_NOCOLS)
			Return .F.
		EndCase

		* Create output table
		Dimension OutFields[m.nGroupFields+_TALLY*This.nMultiDataField,4]
		* Page and Row fields are the same as in input table
		If This.nPageField > 0 OR m.lnGoodP=2
			IF m.lnGoodP=2
				SELECT (This.cPages)
				pagefldname=This.GenName(pagevalue, laPages[1,4])
				OutFields[1,1] = m.pagefldname
				OutFields[1,2] = laPages[1,2]
				OutFields[1,3] = laPages[1,3]
				OutFields[1,4] = laPages[1,4]
			ELSE
				OutFields[1,1] = InpFields[This.nPageField,1]
				OutFields[1,2] = InpFields[This.nPageField,2]
				OutFields[1,3] = InpFields[This.nPageField,3]
				OutFields[1,4] = InpFields[This.nPageField,4]
			ENDIF
		ENDIF
		IF m.lnGoodR=2
			SELECT (This.cRows)
			rowfldname=This.GenName(rowvalue, laRows[1,4])
			If This.nPageField > 0 OR m.lnGoodP=2 AND m.pagefldname==m.rowfldname
				rowfldname=m.rowfldname+'_1'
			ENDIF
			OutFields[m.nGroupFields,1] = m.rowfldname
			OutFields[m.nGroupFields,2] = laRows[1,2]
			OutFields[m.nGroupFields,3] = laRows[1,3]
			OutFields[m.nGroupFields,4] = laRows[1,4]
		ELSE
			OutFields[m.nGroupFields,1] = InpFields[This.nRowField,1]
			OutFields[m.nGroupFields,2] = InpFields[This.nRowField,2]
			OutFields[m.nGroupFields,3] = InpFields[This.nRowField,3]
			OutFields[m.nGroupFields,4] = InpFields[This.nRowField,4]
		ENDIF
		
		SELECT (This.cColumns)
		Scan
			FOR lni=1 TO This.nMultiDataField
				OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,1] = This.GenName(colvalue, IIF(m.lnGood=2,-1,InpFields[This.nColField,4]))+IIF(m.lni>1,'_'+TRANSFORM(m.lni),"")
				DO CASE
				CASE This.anFunctionType[m.lni] = 2 && count => Integer
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = "I"
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = 4
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = 0
				CASE This.anFunctionType[m.lni] = 3 && average => double precision
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = "B"
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = 25
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = This.nAvePrec
				CASE INLIST(This.anFunctionType[m.lni],1,6) && formula => data type taken from result
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = laCells[m.nGroupFields+m.lni+1,2]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = laCells[m.nGroupFields+m.lni+1,3]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = laCells[m.nGroupFields+m.lni+1,4]
				OTHERWISE
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = InpFields[This.anDataField[m.lni],2]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = InpFields[This.anDataField[m.lni],3]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = InpFields[This.anDataField[m.lni],4]
				ENDCASE
			NEXT
		EndScan


		This.CheckNames(@OutFields)


		* Make sure that the output file is not already in use somewhere
		cOutStem = JustStem(This.cOutFile)
		If Used(m.cOutStem)
			Use In (m.cOutStem)
		EndIf
		If !This.lCursorOnly
		   Create Table (This.cOutFile) FREE From Array OutFields
		   cOutStem = Alias()
		Else
		   Create Cursor (m.cOutStem) From Array OutFields
		EndIf

		* Fill the output table
		lnCurrTop=1
		Select (This.cCells)
		If This.nPageField > 0 OR m.lnGoodP=2
			pagefldvalue = pagefld 
			rowfldvalue = rowfld
			colfldvalue = colfld 
			Seek m.rowfldvalue In (This.cColumns)
			SELECT (This.cRows)
			lnNo=no
			SELECT (This.cCells)
			FOR lni=1 TO m.lnNo
				Insert Into (m.cOutStem) ((pagefldname), (rowfldname)) Values (m.pagefldvalue, m.rowfldvalue)
			NEXT
			GO m.lnCurrTop IN (m.cOutStem)
			DO WHILE !EOF(This.cCells)
				pagefldvalue2 = pagefld 
				rowfldvalue2 = rowfld 
				colfldvalue2 = colfld 
				If (m.pagefldvalue != m.pagefldvalue2) or (m.rowfldvalue != m.rowfldvalue2)
					lnCurrTop=RECCOUNT(m.cOutStem)+1
					pagefldvalue = m.pagefldvalue2 
					rowfldvalue = m.rowfldvalue2 
					colfldvalue = m.colfldvalue2
					Seek m.rowfldvalue In (This.cRows)
					SELECT (This.cRows)
					lnNo=no
					SELECT (This.cCells)
					FOR lni=1 TO m.lnNo
						Insert Into (m.cOutStem) ((pagefldname), (rowfldname)) Values (m.pagefldvalue, m.rowfldvalue)
					NEXT
					GO m.lnCurrTop IN (m.cOutStem)
				ELSE
					IF m.colfldvalue != m.colfldvalue2
						colfldvalue = m.colfldvalue2
						GO m.lnCurrTop IN (m.cOutStem)
					ENDIF
				EndIf

				* Translate a field value of any type into a column field name
				Seek m.colfldvalue In (This.cColumns)
				
				SELECT (This.cCells)
				DO WHILE colfld==m.colfldvalue
					FOR lni=1 TO This.nMultiDataField
						replcolumn = Field((RecNo((This.cColumns))-1)*This.nMultiDataField+m.lni + m.nGroupFields, m.cOutStem)
						cellfldvalue=EVALUATE('cellfld'+LTRIM(STR(m.lni))) 
						Replace (m.replcolumn) With m.cellfldvalue In (m.cOutStem)
					NEXT
					SKIP IN (m.cOutStem)
					IF !EOF(This.cCells) 
						SKIP
					ENDIF
				ENDDO
				SELECT (This.cCells)
			ENDDO
		Else
			rowfldvalue = rowfld 
			colfldvalue = colfld 
			Seek m.rowfldvalue In (This.cRows)
			SELECT (This.cRows)
			lnNo=no
			SELECT (This.cCells)
			FOR lni=1 TO m.lnNo
				Insert Into (m.cOutStem) ((rowfldname)) Values (m.rowfldvalue)
			NEXT
			GO m.lnCurrTop IN (m.cOutStem)
			DO WHILE !EOF(This.cCells)
				rowfldvalue2 = rowfld 
				colfldvalue2 = colfld 
				If m.rowfldvalue != m.rowfldvalue2
					lnCurrTop=RECCOUNT(m.cOutStem)+1
					rowfldvalue = m.rowfldvalue2 
					colfldvalue = m.colfldvalue2
					Seek m.rowfldvalue In (This.cRows)
					SELECT (This.cRows)
					lnNo=no
					SELECT (This.cCells)
					FOR lni=1 TO m.lnNo
						Insert Into (m.cOutStem) ((rowfldname)) Values (m.rowfldvalue)
					NEXT
					GO m.lnCurrTop IN (m.cOutStem)
				ELSE
					IF m.colfldvalue != m.colfldvalue2
						colfldvalue = m.colfldvalue2
						GO m.lnCurrTop IN (m.cOutStem)
					ENDIF
				ENDIF

				* Translate a field value of any type into a column field name
				Seek m.colfldvalue In (This.cColumns)
				
				SELECT (This.cCells)
				DO WHILE colfld==m.colfldvalue
					FOR lni=1 TO This.nMultiDataField
						replcolumn = Field((RecNo((This.cColumns))-1)*This.nMultiDataField+m.lni + m.nGroupFields, m.cOutStem)
						cellfldvalue=EVALUATE('cellfld'+LTRIM(STR(m.lni))) 
						Replace (m.replcolumn) With m.cellfldvalue In (m.cOutStem)
					NEXT
					SKIP IN (m.cOutStem)
					IF !EOF(This.cCells) 
						SKIP
					ENDIF
				ENDDO
				SELECT (This.cCells)
			ENDDO
		EndIf


		Select (m.cOutStem)
		Go Top

		* Close the input database
		If This.lCloseTable
			Use In (m.DbfName)
		EndIf
		Use In (This.cColumns)
		Use In (This.cCells)
		Use In (This.cRows)
		If Used(This.cPages)
			Use In (This.cPages)
		ENDIF

************************************************************
************************************************************
	CASE This.nRowField=0 AND EMPTY(This.cRowField) 
		m.DbfName = Alias()
		m.colfldname  = IIF(m.lnGood=1,InpFields[This.nColField,1],IIF(m.lnGood=2,This.cColField,""))
		
		lcSql='Select '+m.colfldname+' as colfld'
		FOR lni=1 TO This.nMultiDataField
			IF !EMPTY(This.acDataField[m.lni])
				IF ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)>0
					THIS.anDataField[m.lni]=ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)
				ENDIF
			ENDIF
			IF This.anFunctionType[m.lni]=6
				lcSql=m.lcSql+','+This.acFunctionExp[m.lni]
			ELSE
				m.cellfldname = InpFields[This.anDataField[m.lni],1]
				lcSql=m.lcSql+','+m.cellfldname
			ENDIF
			lcSql=m.lcSql+' As cellfld'+TRANSFORM(m.lni)
		NEXT
		lcSql=m.lcSql+' From '+m.DbfName+' ORDER by 1 '+m.lcCondition+' Into Cursor '+This.cCells
		IF VERSION(5)>=800
			llSqlErr=.F.
			TRY
				&lcSql
			CATCH TO loErr
				llSqlErr=.T.
				MESSAGEBOX(loErr.Message,16,'SQL Error')
			ENDTRY
			IF llSqlErr
				RETURN .F.
			ENDIF
		ELSE
			&lcSql
		ENDIF
		
		* Check cells datatypes
		=AFIELDS(laCells,This.cCells)
		* Generate rows names
		cC1=SYS(2015)
		SELECT TOP 1 colfld,COUNT(*) as No FROM (This.cCells) GROUP BY 1 ORDER BY 2 DESC INTO CURSOR (cC1)
		SELECT (cC1)
		GO TOP 
		lColMax=colfld
		USE IN (cC1)

		Select Distinct colfld as colvalue From (This.cCells) Group by 1 Into Cursor (This.cColumns)
		Index On colvalue TAG colvalue 
		
		Do Case
		Case _TALLY*This.nMultiDataField > 254
			This.Alert(C_XSVALUES)
			Return .F.
		Case _TALLY = 0
			This.Alert(C_NOCOLS)
			Return .F.
		EndCase

		* Create output table
		Dimension OutFields[_TALLY*This.nMultiDataField,4]
		
		SELECT (This.cColumns)
		Scan
			FOR lni=1 TO This.nMultiDataField
				OutFields[This.nMultiDataField*(RECNO()-1)+m.lni,1] = This.GenName(colvalue, IIF(m.lnGood=2,-1,InpFields[This.nColField,4]))+'_'+TRANSFORM(m.lni)
				IF This.anFunctionType[m.lni] = 6 
					OutFields[This.nMultiDataField*(RECNO()-1)+m.lni,2] = laCells[m.lni+1,2]
					OutFields[This.nMultiDataField*(RECNO()-1)+m.lni,3] = laCells[m.lni+1,3]
					OutFields[This.nMultiDataField*(RECNO()-1)+m.lni,4] = laCells[m.lni+1,4]
				ELSE
					OutFields[This.nMultiDataField*(RECNO()-1)+m.lni,2] = InpFields[This.anDataField[m.lni],2]
					OutFields[This.nMultiDataField*(RECNO()-1)+m.lni,3] = InpFields[This.anDataField[m.lni],3]
					OutFields[This.nMultiDataField*(RECNO()-1)+m.lni,4] = InpFields[This.anDataField[m.lni],4]
				ENDIF
			NEXT
		EndScan
		
		This.CheckNames(@OutFields)

		* Make sure that the output file is not already in use somewhere
		cOutStem = JustStem(This.cOutFile)
		If Used(m.cOutStem)
			Use In (m.cOutStem)
		EndIf
		If !This.lCursorOnly
		   Create Table (This.cOutFile) FREE From Array OutFields
		   cOutStem = Alias()
		Else
		   Create Cursor (m.cOutStem) From Array OutFields
		ENDIF
		
		SELECT (This.cColumns)
		SEEK lColMax
		
		DIMENSION laTempArr[1,This.nMultiDataField]
		laTempArr=.Null.
		lcFunctionExp='cellfld1'
		replcolumn=Field((RecNo((This.cColumns))-1)*This.nMultiDataField+1, m.cOutStem)
		FOR lni=2 TO This.nMultiDataField
			lcFunctionExp=lcFunctionExp+",cellfld"+TRANSFORM(m.lni)
			replcolumn=m.replcolumn+","+Field((RecNo((This.cColumns))-1)*This.nMultiDataField+m.lni, m.cOutStem)
		NEXT
		SELECT &lcFunctionExp FROM (This.cCells) WHERE colfld==m.lColMax INTO ARRAY laTempArr
		SELECT (m.cOutStem)
		APPEND FROM ARRAY laTempArr FIELDS &replcolumn
		
		SELECT (This.cColumns)
		SCAN
			IF colvalue==lColMax
				LOOP
			ENDIF
			colfldvalue=colvalue
			DIMENSION laTempArr[1,This.nMultiDataField]
			laTempArr=.Null.
			lcFunctionExp='cellfld1'
			replcolumn=Field((RecNo((This.cColumns))-1)*This.nMultiDataField+1, m.cOutStem)+" WITH laTempArr[RECNO(),1]"
			FOR lni=2 TO This.nMultiDataField
				lcFunctionExp=lcFunctionExp+",cellfld"+LTRIM(STR(m.lni))
				replcolumn=m.replcolumn+","+Field((RecNo((This.cColumns))-1)*This.nMultiDataField+m.lni, m.cOutStem)+" WITH laTempArr[RECNO(),"+LTRIM(STR(m.lni))+"]"
			NEXT
			SELECT &lcFunctionExp FROM (This.cCells) WHERE colfld==m.colfldvalue INTO ARRAY laTempArr
			SELECT (m.cOutStem)
			GO TOP
			REPLACE ALL &replcolumn WHILE RECNO()<=ALEN(laTempArr,1)
			SELECT (This.cColumns)
		ENDSCAN

		Select (m.cOutStem)
		Go Top

		* Close the input database
		If This.lCloseTable
			Use In (m.DbfName)
		EndIf
		Use In (This.cColumns)
		Use In (This.cCells)

***************************************		
***************************************		
***************************************		
	OTHERWISE
		m.DbfName = Alias()
		m.rowfldname = IIF(m.lnGoodR=1,InpFields[This.nRowField,1],IIF(m.lnGoodR=2,This.cRowField,""))
		m.colfldname  = IIF(m.lnGood=1,InpFields[This.nColField,1],IIF(m.lnGood=2,This.cColField,""))

		lcSql='Select '
		If This.nPageField > 0 OR m.lnGoodP=2
			m.pagefldname = IIF(m.lnGoodP=1,InpFields[This.nPageField,1],IIF(m.lnGoodP=2,This.cPageField,""))
			nGroupFields = 2
			lcGrup = '1,2,3'
			lcSql=m.lcSql+m.pagefldname+' as pagefld,'
		Else
			nGroupFields = 1
			lcGrup = '1,2'
		ENDIF

		*************************
		lcSql=m.lcSql+m.rowfldname+' as rowfld,'+m.colfldname+' as colfld'
		
		FOR lni=1 TO This.nMultiDataField
			IF !EMPTY(This.acDataField[m.lni])
				IF ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)>0
					THIS.anDataField[m.lni]=ASCAN(InpFields,This.acDataField[m.lni],-1,-1,-1,1+2+4+8)
				ENDIF
			ENDIF
			m.cellfldname = InpFields[This.anDataField[m.lni],1]
			lcRightPar=m.cellfldname+')'

		  	If NOT (InpFields[THIS.anDataField[m.lni],2] $ "NFYBI" OR INLIST(This.anFunctionType[m.lni],2,4,6))
		  		This.anFunctionType[m.lni]=5 && for non numeric data types by default the MAX function
	  		ENDIF
			DO CASE
		*		1 Sum 2 Count 3 Avg 4 Min 5 Max 6 Custom
			CASE This.anFunctionType[m.lni]=1
				lcSql=m.lcSql+',SUM('
			CASE This.anFunctionType[m.lni]=2
				lcSql=m.lcSql+',COUNT('
			CASE This.anFunctionType[m.lni]=3
				lcSql=m.lcSql+',AVG('
			CASE This.anFunctionType[m.lni]=4
				lcSql=m.lcSql+',MIN('
			CASE This.anFunctionType[m.lni]=5
				lcSql=m.lcSql+',MAX('
			CASE This.anFunctionType[m.lni]=6
				lcSql=m.lcSql+','+This.acFunctionExp[m.lni]
				lcRightPar=''
			ENDCASE
			lcSql=m.lcSql+m.lcRightPar+' As cellfld'+TRANSFORM(m.lni)
		NEXT
		lcSql=m.lcSql+' From '+m.DbfName+' Group by '+m.lcGrup+m.lcCondition+' Into Cursor '+This.cCells
		
		IF VERSION(5)>=800
			llSqlErr=.F.
			TRY
				&lcSql
			CATCH TO loErr
				llSqlErr=.T.
				MESSAGEBOX(loErr.Message,16,'SQL Error')
			ENDTRY
			IF llSqlErr
				RETURN .F.
			ENDIF
		ELSE
			&lcSql
		ENDIF

		* Check cells datatypes
		=AFIELDS(laCells,This.cCells)
		* Generate pages names
		If This.nPageField > 0 OR m.lnGoodP=2
			Select Distinct pagefld as pagevalue From (This.cCells) Group by 1 Into Cursor (This.cPages)
			Index On pagevalue Tag pagevalue
			=AFIELDS(laPages,This.cPages)
		ENDIF
		* Generate rows names
		Select Distinct rowfld as rowvalue From (This.cCells) Group by 1 Into Cursor (This.cRows)
		Index On rowvalue Tag rowvalue
		=AFIELDS(laRows,This.cRows)
		* Generate column names
		Select Distinct colfld as colvalue From (This.cCells) Group by 1 Into Cursor (This.cColumns)
		Index On colvalue TAG colvalue 

		Do Case
		Case _TALLY*This.nMultiDataField > 254
			This.Alert(C_XSVALUES)
			Return .F.
		Case _TALLY = 0
			This.Alert(C_NOCOLS)
			Return .F.
		EndCase

		* Create output table
		Dimension OutFields[m.nGroupFields+_TALLY*This.nMultiDataField,4]
		* Page and Row fields are the same as in input table
		If This.nPageField > 0 OR m.lnGoodP=2
			IF m.lnGoodP=2
				SELECT (This.cPages)
				pagefldname=This.GenName(pagevalue, laPages[1,4])
				OutFields[1,1] = m.pagefldname
				OutFields[1,2] = laPages[1,2]
				OutFields[1,3] = laPages[1,3]
				OutFields[1,4] = laPages[1,4]
			ELSE
				OutFields[1,1] = InpFields[This.nPageField,1]
				OutFields[1,2] = InpFields[This.nPageField,2]
				OutFields[1,3] = InpFields[This.nPageField,3]
				OutFields[1,4] = InpFields[This.nPageField,4]
			ENDIF
		ENDIF
		IF m.lnGoodR=2
			SELECT (This.cRows)
			rowfldname=This.GenName(rowvalue, laRows[1,4])
			If This.nPageField > 0 OR m.lnGoodP=2 AND m.pagefldname==m.rowfldname
				rowfldname=m.rowfldname+'_1'
			ENDIF
			OutFields[m.nGroupFields,1] = m.rowfldname
			OutFields[m.nGroupFields,2] = laRows[1,2]
			OutFields[m.nGroupFields,3] = laRows[1,3]
			OutFields[m.nGroupFields,4] = laRows[1,4]
		ELSE
			OutFields[m.nGroupFields,1] = InpFields[This.nRowField,1]
			OutFields[m.nGroupFields,2] = InpFields[This.nRowField,2]
			OutFields[m.nGroupFields,3] = InpFields[This.nRowField,3]
			OutFields[m.nGroupFields,4] = InpFields[This.nRowField,4]
		ENDIF
		
		SELECT (This.cColumns)
		Scan
			FOR lni=1 TO This.nMultiDataField
				OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,1] = This.GenName(colvalue, IIF(m.lnGood=2,-1,InpFields[This.nColField,4]))+IIF(m.lni>1,'_'+TRANSFORM(m.lni),"")
				DO CASE
				CASE This.anFunctionType[m.lni] = 2 && count => Integer
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = "I"
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = 4
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = 0
				CASE This.anFunctionType[m.lni] = 3 && average => double precision
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = "B"
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = 25
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = This.nAvePrec
				CASE INLIST(This.anFunctionType[m.lni],1,6) && formula => data type taken from result
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = laCells[m.nGroupFields+m.lni+1,2]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = laCells[m.nGroupFields+m.lni+1,3]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = laCells[m.nGroupFields+m.lni+1,4]
				OTHERWISE
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,2] = InpFields[This.anDataField[m.lni],2]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,3] = InpFields[This.anDataField[m.lni],3]
					OutFields[m.nGroupFields+This.nMultiDataField*(RECNO()-1)+m.lni,4] = InpFields[This.anDataField[m.lni],4]
				ENDCASE
			NEXT
		EndScan
		
		This.CheckNames(@OutFields)

		* Make sure that the output file is not already in use somewhere
		cOutStem = JustStem(This.cOutFile)
		If Used(m.cOutStem)
			Use In (m.cOutStem)
		EndIf
		If !This.lCursorOnly
		   Create Table (This.cOutFile) FREE From Array OutFields
		   cOutStem = Alias()
		Else
		   Create Cursor (m.cOutStem) From Array OutFields
		EndIf

		* Fill the output table
		Select (This.cCells)
		If This.nPageField > 0 OR m.lnGoodP=2
			pagefldvalue = pagefld 
			rowfldvalue = rowfld 
			Insert Into (m.cOutStem) ((pagefldname), (rowfldname)) Values (m.pagefldvalue, m.rowfldvalue)
			Scan
				pagefldvalue2 = pagefld 
				rowfldvalue2 = rowfld 
				colfldvalue=colfld 
				If (m.pagefldvalue != m.pagefldvalue2) or (m.rowfldvalue != m.rowfldvalue2)
					pagefldvalue = m.pagefldvalue2 
					rowfldvalue = m.rowfldvalue2 
					Insert Into (m.cOutStem) ((pagefldname), (rowfldname)) Values (m.pagefldvalue, m.rowfldvalue)
				EndIf

				* Translate a field value of any type into a column field name
				Seek m.colfldvalue In (This.cColumns)
				FOR lni=1 TO This.nMultiDataField
					replcolumn = Field((RecNo((This.cColumns))-1)*This.nMultiDataField+m.lni + m.nGroupFields, m.cOutStem)
					cellfldvalue=EVALUATE('cellfld'+LTRIM(STR(m.lni))) 
					Replace (m.replcolumn) With m.cellfldvalue In (m.cOutStem)
				NEXT
			EndScan
		Else
			rowfldvalue = rowfld 
			Insert Into (m.cOutStem) ((rowfldname)) Values (m.rowfldvalue)
			Scan
				rowfldvalue2 = rowfld 
				colfldvalue=colfld 
				If m.rowfldvalue != m.rowfldvalue2
					rowfldvalue = m.rowfldvalue2 
					Insert Into (m.cOutStem) ((rowfldname)) Values (m.rowfldvalue)
				EndIf

				* Translate a field value of any type into a column field name
				Seek m.colfldvalue In (This.cColumns)
				
				FOR lni=1 TO This.nMultiDataField
					replcolumn = Field((RecNo((This.cColumns))-1)*This.nMultiDataField+m.lni + m.nGroupFields, m.cOutStem)
					cellfldvalue=EVALUATE('cellfld'+LTRIM(STR(m.lni))) 
					Replace (m.replcolumn) With m.cellfldvalue In (m.cOutStem)
				NEXT
			EndScan
		EndIf


		Select (m.cOutStem)
		Go Top

		* Close the input database
		If This.lCloseTable
			Use In (m.DbfName)
		EndIf
		Use In (This.cColumns)
		Use In (This.cCells)
		Use In (This.cRows)
		If Used(This.cPages)
			Use In (This.cPages)
		ENDIF
	ENDCASE
	IF This.lTotalRows
		LOCAL cTotal,laToF[1],lnTof,lniToF,lcField,lcToTField,laToTF[1],lnToTf
		cTotal=SYS(2015)
		TOTAL TO (m.cTotal) ON .T.
		USE (m.cTotal) IN 0
		APPEND BLANK IN (m.cOutStem)
		lnToTF = AFIELDS(laToTF,m.cTotal)
		lnToF = AFIELDS(laToF,m.cOutStem)
		FOR lniToF = 1 TO m.lnToF
			IF laToF[lniToF,2] $ 'NFIYB'
				lcField = laToF[lniToF,1]
				lcToTField = laToTF[lniToF,1]
				replace &lcField WITH &cTotal..&lcToTField IN (m.cOutStem)
			ENDIF
		NEXT
*		INSERT INTO (m.cOutStem) VALUES (SELECT * FROM (cTotal))
		USE IN (cTotal)
		ERASE (FORCEEXT(cTotal,'dbf'))
		ERASE (FORCEEXT(cTotal,'fpt'))
		GO TOP IN (m.cOutStem) 
	ENDIF

	Set Talk &cTalkStat
	Set Null &cNullStat
	Wait Clear

	If This.lBrowseAfter
		Browse NoWait Normal
	EndIf
EndProc

Protected Function GenName(in_name, in_dec)
* Generate a valid field name from field value of any type
	Local RetVal, cFldType

	If Parameters() = 1
		m.in_dec = 0
	EndIf
	cFldType = Type("m.in_name")
	Do Case
	Case IsNull(m.in_name)
		m.RetVal = 'NULL'
	Case m.cFldType $ 'CM'
		Do Case
		Case Empty(m.in_name)
			m.RetVal = 'C_BLANK'
		Otherwise
			m.RetVal = IIf(IsAlpha(m.in_name), ALLTRIM(m.in_name), 'C_'+ALLTRIM(m.in_name))
			* Now have to truncate to 10 bytes
			If This.lCursorOnly
*			m.RetVal=Left(m.RetVal, 10)
				If Len(RightC(m.RetVal, 1)) = 1 AND IsLeadByte(RightC(m.RetVal,1))	&& last byte is Double byte
					m.RetVal = Left(m.RetVal,LEN(m.RetVal)-1) &&Left(m.RetVal,9)
				EndIf
			ELSE
				m.RetVal=Left(m.RetVal, 10)
				If Len(RightC(m.RetVal, 1)) = 1 AND IsLeadByte(RightC(m.RetVal,1))	&& last byte is Double byte
					m.RetVal = Left(m.RetVal,9) &&Left(m.RetVal,9)
				ENDIF
			ENDIF
		EndCase
	Case m.cFldType $ 'NFIYB'
		IF m.in_dec=-1
			in_dec=MAX(LEN(TRANSFORM(ABS(m.in_name-int(m.in_name))))-2,0)
		ENDIF
		If This.lCursorOnly
			m.RetVal = 'N_'+AllTrim(Str(m.in_name, 25, Min(m.in_dec,7)))&&AllTrim(Str(m.in_name, 8, Min(in_dec,7)))
		ELSE
			m.RetVal = 'N_'+AllTrim(Str(m.in_name, 8, Min(m.in_dec,7)))&&AllTrim(Str(m.in_name, 8, Min(in_dec,7)))
		ENDIF
	Case m.cFldType $ 'DT'
		m.RetVal = IIf(Empty(m.in_name), 'D_BLANK', 'D_' + DToS(m.in_name))
	Case m.cFldType = 'L'
		m.RetVal = IIf(m.in_name, 'True', 'False')
	Otherwise
		* Should never happen
		This.Alert(C_UNKNOWNFLD)
		Return "Unknown"
	EndCase

	* We need to replace bad characters here with "_"
	m.RetVal = ChrTranC(m.RetVal, This.BadChars, This.RepChars)
	Return Upper(AllTrim(m.RetVal))
EndFunc

Protected Procedure CheckNames(aFldArray)
* Checks to see if field names are unique, else assigns a new one
	Local nTmpCnt, cTmpCntStr, cOldValue, lni, cCheckValue

	For m.lni = 1 To ALen(aFldArray, 1)
		Store AllTrim(aFldArray[m.lni,1]) To m.cOldValue, m.cCheckValue
		nTmpCnt = 1
		Do While !This.FldUnique(@aFldArray, m.cCheckValue, m.lni)
			cTmpCntStr = "_"+AllTrim(Str(m.nTmpCnt))
			If This.lCursorOnly
*			cCheckValue = Left(m.cOldValue, 10 - Len(m.cTmpCntStr)) + m.cTmpCntStr
				cCheckValue = m.cOldValue + m.cTmpCntStr
			ELSE
				cCheckValue = Left(m.cOldValue, 10 - Len(m.cTmpCntStr)) + m.cTmpCntStr
			ENDIF
			nTmpCnt = m.nTmpCnt + 1
		EndDo
		aFldArray[m.lni,1] = m.cCheckValue
	EndFor
EndProc

Protected Function FldUnique(aFldArray, cCheckValue, nPos)
* Checks to see if field name is unique
	Local lni

	For lni = 1 To m.nPos - 1
		If aFldArray[m.lni,1] == m.cCheckValue
			Return .F.
		EndIf
	EndFor

	Return .T.
EndFunc

Procedure Error(nError, cMethod, nLine)
This.Alert("Line: "+AllTrim(Str(m.nLine))+Chr(13) ;
	   +"Program: "+m.cMethod+Chr(13) ;
	   +"Error: "+AllTrim(Str(nError))+Chr(13) ;
	   +"Message: "+Message()+Chr(13);
	   +"Code: "+Message(1))
   Return To RunXtab
ENDPROC

Protected Procedure Alert(strg)
	MessageBox(m.strg, 16, "FastXtab")
EndProc

EndDefine
