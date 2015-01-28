/*starts with 20100824 */
%macro DB_Wind_Index_CSI300_StockWgt(table=TB_OBJECT_9008, 
																				eventDate=,
																				startDate=,
																				endDate=,
																				outset=_Index_CSI300_StockWgt, 
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
%local eventDate startDate endDate outset;

/* Query wind database*/
proc sql; 
	connect to ODBC (noprompt="dsn=&DBWIND_dsn;database=&DBWIND_database;uid=&DBWIND_uid;pwd=&DBWIND_pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(		
		SELECT 
			F3_9008		as Date, /*日期*/
			F1_9008 	as IdxID, /*指数id*/
			F5_9008 	as IdxName,
			F2_9008 	as SecID, /*成份股id*/
			F7_9008 	as TradeID,
			F8_9008 	as SecName,
			F19_9008 	as IdxWgt /*权重(%)*/
	FROM 
			TB_OBJECT_9008 
	WHERE 
		F19_9008 is not null
		%IF "&eventDate"^="" %then %do; 
			AND F3_9008 = &eventDate
		%end;
		%else %do;
			%IF "&startDate"^="" %then %do; 
				AND F3_9008 >= &startDate
			%end;
			%IF "&endDate"^="" %then %do; 
				AND F3_9008 <= &endDate
			%end;
		%end;
	);
quit; run; 
	
	PROC SORT DATA=&libRef..outset NODUPKEY; BY Date SecID; RUN;
	%GetStatsPtn(inset=&libRef..outset, 
								partition=Date, element=SecID, 
								vars=IdxWgt, stats=sum, weight=, 
								statset=&libRef..st, exportfolder=,
								outset=&libRef..outset, 
								optionon=0);

	DATA &outset; set &libRef..outset; 
		IdxWgt=IdxWgt/IdxWgt_SUM; 
	RUN;  

*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options nosymbolgen nomlogic nomprint; 
%mend DB_Wind_Index_CSI300_StockWgt;