/* China A share trading days 沪深交易所交易日*/
%macro DB_Wind_Calendar_Ashare (	dsn=&DBWIND_dsn.,
																database=&DBWIND_database.,
																uid=&DBWIND_uid.,
																pwd=&DBWIND_pwd.,
																table = TB_OBJECT_1010,
																startDate=,
																endDate=&today.,
																outset=_Date_TrdChinaA,
optionon=0);
*------------------------------------;
%local optionon;
%if %eval(&optionon)=1 %then %do; 
options source notes errors=2;
options symbolgen mlogic mprint; 
%end;
%else %if %eval(&optionon)=0 %then %do; 
options nosource nonotes errors=1;
options NOSYMBOLGEN NOMLOGIC NOMPRINT;
%end; 

%local libRef; %let libRef=%MakeLocalFolder;;
	LibName &libRef list ;
*standard header for debugging and temporary data folder; 
*==========================================================; 
*Database; 	%local dsn database uid pwd;
*Table;			%local table;
*Parameters; %local startDate endDate outset;

/* Query wind database*/
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		select F1_1010 AS Date from TB_OBJECT_1010 
		WHERE F1_1010 is NOT Null
		%if "&startDate"^="" %then %do; 
			AND F1_1010 >= &startDate
		%end;
		%if "&endDate"^="" %then %do; 
			AND F1_1010 <= &endDate
		%end;
		order by F1_1010 Asc;
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
%mend DB_Wind_Calendar_Ashare;
/* %DB_Wind_Date_TrdChinaA(endDate =&today); */
