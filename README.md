# FastXTab

This project is an upgrade to the FastXTab class, originally created by Alexander Golovlev, by Vilhelm-Ion Praisach. The original class can be downloaded from http://www.universalthread.com/ViewPageNewDownload.aspx?ID=9944.

FastXTab is a replacement for VFPXTab which comes with VFP. It expects to find a table or cursor with at least three columns. By default, the data in the first column becomes the rows in the result, the data in the second column becomes the columns in the result, and the data in the third column is aggregated (summed, by default) to form the data in the result. VFPXTab is quite slow and has limited capabilities. FastXTab is much faster and has a lot more functionality.

All of the source code is containing in FastXTab.prg. There are two folders containing source code and samples:

* FastXTab 1.6 is for VFP 9
* FastXTabs6 1.6 is for VFP 6.

## New properties
See the Properties section below for a complete list of properties.

- nAvePrec: precision when using AVE function (DEFAULT=3) The data type is Double precision
- cPageField: allow specifying the field used for page by using either a column name, either an expression
- cRowField: allow specifying the field used for rows by using either a column name, either an expression
- nRowField2: allow distribution by specifiyng cRowField (and cPageField if needed) when nRowField2=0
- cColField: allow specifying the field used for columns by using either a column name, either an expression
- cDataField: allow specifying the field used for cells by using a column name
- nFunctionType: aggregate function 1 Sum 2 Count 3 Avg 4 Min 5 Max 6 Custom (DEFAULT=1 for numeric fields and DEFAULT=5 for nonnumeric fields)
- cFunctionExp: expression when nFunctionType=6
- cCondition: WHERE condition
- cHaving: HAVING condition
- nMultiDataField: if nMultiDataField > 1 the for each column can be defined more DataField / FunctionType / FunctionExp
- anDataField[1],anFunctionType[1],acFunctionExp[1],acDataField[1]: equivalent properties for nDataField, nFunctionType, cFunctionExp, cDataField when nMultiDataField > 1

### New behavior
- When EMPTY(cRowField) and nRowField=0 the pivot only distribute the values by columns, according to cDataField, nFunctionType, cFunctionExp and cColField; (values for nFunctionType<> 6 are ignored)
- permission for aggregation functions on non-numeric fields (1 for Sum and 3 for Avg are ignored, Max is by default)

Resulting cursor data types:
1. When EMPTY(cRowField) and nRowField=0 (distribution by columns):
    - same with the field type when nFunctionType<>6
    - taken from results when nFunctionType=6

2. When !EMPTY(cRowField) or nRowField<>0:
    - Integer when nFunctionType=2 (COUNT)
    - Double precision when nFunctionType=3 (AVERAGE); decimal precision given by nAvePrec property
    - taken from results when nFunctionType=6 or nFunctionType=1 (to avoid data overflow)
    - same with the field type in rest

### Other upgrades
- improved mdot 
- added local variables declaration
- SYS(2015) for internal cursors name

### Some examples:
In the Test form in the sample Crosstab project, the Foxite1 method shows solutions for a few recent threads on Foxite. Other examples are posted as comment in the Click method of the cmdFastXtab command button.

1. For http://www.foxite.com/archives/sql-help-0000401315.htm:

    ```foxpro
    oXTab.cRowField='cstcode'
    oXtab.cColField = 'subj'
    oXtab.nMultiDataField=3
    oXtab.acDataField[1] = 'subj'
    oXtab.anFunctionType[1] = 2
    oXtab.anFunctionType[2] = 6
    oXtab.acFunctionExp[2]="SUM(IIF(attend='P',1,0))"
    oXtab.anFunctionType[3] = 6
    oXtab.acFunctionExp[3]="SUM(IIF(attend='P',1,0))/COUNT(attend)*100"
    ```

2. For http://www.foxite.com/archives/row-to-column-0000401353.htm:

    ```foxpro
	oXtab.nRowField = 0 
	oXtab.cRowField = ''
	oXtab.cColField='ids'
	oXtab.cDataField ='qty'
	```

3. For http://www.foxite.com/archives/split-numbers-2-0000400387.htm:
	
    ```foxpro
    oXtab.nRowField = 0 
	oXtab.cRowField = ''
	oXtab.cColField='floor(no/10)+1'
	oXtab.cDataField ='no'
	```

4. For http://www.foxite.com/archives/split-numbers-2-0000400495.htm:

    ```foxpro
    oXtab.nRowField = 0 
    oXtab.cRowField = ''
    oXtab.cColField='floor(no/100000)+1'
    oXtab.cDataField ='no'
	```

## Properties
| Property    | Description |
|-------------|-------------|
| **Input cursor / table** ||
| lCloseTable   | .T. the cursor / table which holds the data source is closed |
| **Output cursor / table** ||
| lCursorOnly   | .T. The result is stored in a cursor, otherwise in a free table |
| cOutFile      | Name of the cursor / table which holds the result |
| lDisplayNulls | .T. / .F. => Set null ON / OFF |
| lBrowseAfter  | Specifies whether to open a Browse window on the cross tab output |
| **CrossTab: a. Rows** ||
| cRowField     | Field name / Field expression for rows (group) |
| nRowField     | Field position (row number in AFIELDS(,cSource)) for rows (group) |
| cPageField    | Field name / Field expression for rows supergroup (optional) |
| nPageField    | Field position (row number in AFIELDS(,cSource)) for rows supergroup |
| **b. Columns** ||
| cColField     | Field name / Field expression for columns (group) |
| nColField     | Field position (row number in AFIELDS(,cSource)) for columns (group) |
| **c. Each column field holds a single data (cell) column** ||
| cDataField    | Field name for cells |
| nDataField    | Field position (row number in AFIELDS(,cSource)) for cells |
| nFunctionType | Aggregate function used for cells: 1 = Sum, 2 = Count, 3 = Avg, 4 = Min, 5 = Max, 6 = Custom |
| cFunctionExp  | The expression used for cells when nFunctionType=6 (ignored if nFunctionType<>6) |
| **d. Some columns contains more than a single data (cell) column** ||
| nMultiDataField | Number of data (cell) columns (default=1) |
| acDataField | Array with field names for cells |
| anDataField | Array with field positions (row number in AFIELDS(,cSource)) for cells |
| anFunctionType | Array with aggregate functions used for cells: 1 = Sum, 2 = Count, 3 = Avg, 4 = Min, 5 = Max, 6 = Custom |
| acFunctionExp | Array with the expressions used for cells when anFunctionType()=6 |
| **e. Miscellaneous** ||
| nAvePrec | Decimal precision when nFunctionType = 3 (average) |
| cCondition | Expression for a where condition |
| cHaving | Expression for a having condition |
| nRowField2 | When nRowField2 = 0 and !empty(cRowField), FastXTab distribute cells by columns and rows (according to cRowField and cColField). Ignored when nRowField2 <> 0 or empty(This.cRowField) |
| lTotalRows | When .T. a supplementary row with totals is added |

### Notes

There are three type of outputs:

1. When nRowField2 = 0 and !empty(cRowField), FastXTab distributes cells by columns and rows (according to cRowField and cColField); no aggregate functions are performed. If nFunctionType / anFunctionType = 6, cells contains the expression from cFunctionExp / acFunctionExp. Otherwise, cells contains the field from cDataField.
      
2. When nRowField = 0 and EMPTY(cRowField), FastXTab distributes cells by columns (according to cColField);  no aggregate functions are performed. If nFunctionType / anFunctionType = 6, cells contains the expression from cFunctionExp / acFunctionExp. Otherwise, cells contains the field from cDataField.

3. Otherwise FastXTab applies aggregate functions and distributes results by columns and rows (according to cPageField, cRowField and cColField).

    * If nFunctionType / anFunctionType = 1, cells contains SUM(cDataField).
    * If nFunctionType / anFunctionType = 2, cells contains COUNT(cDataField).
    * If nFunctionType / anFunctionType = 3, cells contains AVERAGE(cDataField).
    * If nFunctionType / anFunctionType = 4, cells contains MAX(cDataField)
    * If nFunctionType / anFunctionType = 5, cells contains MIN(cDataField)
    * If nFunctionType / anFunctionType = 6, cells contains the expression from cFunctionExp / acFunctionExp (must be valid expression from the point of the aggregation)
