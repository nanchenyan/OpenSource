%macro DB_Wind_AShare_Price(dsn=&DBWIND_dsn.,
							database=&DBWIND_database.,
							uid=&DBWIND_uid.,
							pwd=&DBWIND_pwd.,
							table=TB_OBJECT_1425,
							startDate=,
							endDate=&today.,
							outset=_AShare_Price, 
optionon=0);
*------------------------------------;
%local optionon;
%if %eval(&optionon)=1 %then %do; 
options source notes errors=2;
options symbolgen mlogic mprint; 
%end;
%else %if %eval(&optionon)=0 %then %do; 
options source notes errors=1;
options NOSYMBOLGEN NOMLOGIC NOMPRINT;
%end; 
%local libRef; %let libRef=%MakeLocalFolder;;
	LibName &libRef list ;
*standard header for debugging and temporary data folder; 
*==========================================================; 
*Database; 		%local dsn database uid pwd;
*Table;			%local table;
*Parameters; 	%local startDate endDate outset;

proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		SELECT
			F2_1425	 		as Date,			/*交易日期*/
			F1_1425 		as SecID,			/*证券ID*/
			F16_1090		as TradeID,			/* 交易代码 */
			F3_1425			as PreCloseAdj,
			F4_1425			as OpenAdj,
			F5_1425			as HighAdj,
			F6_1425			as LowAdj,
			F7_1425	 		as PrcAdj,			/*复权收盘价*/
			F10_1425 		as PrcAdjFct,		/*复权因子*/
			F7_1425
				/F10_1425	as Prc,				/* 收盘价 */
			F8_1425 		as Volume,			/* 成交量(手) */
			F9_1425 		as VolumeCash 		/* 成交金额(千元) */
		FROM
			TB_OBJECT_1425 left join TB_OBJECT_1090
			ON  F1_1425 = F2_1090 
		WHERE
			F4_1090='A' 
			%if "&startDate"^="" %then %do; 
				AND F2_1425 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND F2_1425 <= &endDate
			%end;
		ORDER BY
			Date, SecID 
		);
	%put &sqlxmsg;
	disconnect from ODBC;
quit;
run; 


%ClearLabel(lib=&libRef, data=outset);
data &outset; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_AShare_Price; 