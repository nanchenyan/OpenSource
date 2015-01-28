%macro DB_Wind_Event_ST(dsn=&DBWIND_dsn.,
													database=&DBWIND_database.,
													uid=&DBWIND_uid.,
													pwd=&DBWIND_pwd.,								
													table = TB_OBJECT_1010 tb_object_1123 tb_object_1090,
													startDate=,
													endDate=,
													outset=_Event_ST,
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
*Table;		%local table;
*Parameters; %local startDate endDate outset;

* Get ST List from DB;
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		SELECT * FROM
			(	SELECT distinct F1_1010 As Date 
				FROM 
					TB_OBJECT_1010 
				WHERE 
					F1_1010 <= &endDate.
					%if "&startDate"^="" %then %do; 
						AND F1_1010>=&startDate. 
					%end;
			) d,
			(SELECT 
				F16_1090 									As TradeID, 
				OB_OBJECT_NAME_1090 						AS SecName, 
				F2_1090 									AS SecID, 
				F3_1123 									AS StartDate, 
				F7_1123 									AS EndDate,
				F11_1123 									AS IssueDate, 
				F12_1123 									AS EventType, 
				F4_1123 									AS Details
			 FROM 
				tb_object_1123, 
				tb_object_1090
			 WHERE F2_1090 = F2_1123 AND F4_1090='A'
			) s
		WHERE 
			((EndDate IS NULL AND IssueDate < d.Date) OR (EndDate IS NOT NULL AND StartDate < d.Date)) 
			AND (EndDate > d.Date OR EndDate IS NULL) AND Details NOT LIKE '%Œ¸ ’∫œ≤¢%'
	);
%put &sqlxmsg;
disconnect from ODBC;
quit; run; 

proc sort data=&libRef..outset nodupkey; by date secid StartDate; run;

%ClearLabel(lib=&libRef, data=outset);
data &outset; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Event_ST;