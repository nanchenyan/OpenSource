%macro DB_Wind_Event_IPO(dsn=&DBWIND_dsn.,
													database=&DBWIND_database.,
													uid=&DBWIND_uid.,
													pwd=&DBWIND_pwd.,								
													table = TB_OBJECT_1095,
													startDate=,
													endDate=&today.,
													eventDate=,
													outset=_Event_IPO,
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
*Parameters; %local startDate endDate eventDate outset;

* Get ST List from DB;
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
			select
				F50_1095			as Date,				/* 公众发行部分上市日期 */
				F60_1095			as DateUpdate,			/* 上市公告日 */
				'IPO'				as "EVENT",
				OB_REVISIONS_1090	
									as ComID,
				F1_1095 			as SecID,
				F16_1090 			as TradeID,
				OB_OBJECT_NAME_1090 
									as SecName,
				F22_1095*10000 		
									as IssueNum,			/* 发行数量，万股*/
				F10_1095			as IssuePrice			/* 网上申购价格*/
				
			from
				TB_OBJECT_1095 left join TB_OBJECT_1090 on F1_1095 = F2_1090
			where
				F4_1090 = 'A' 
				%if "&eventDate"^="" %then %do; 
					AND F50_1095 = &eventDate.
				%end;
				%else %do;
					%if "&startDate"^="" %then %do; 
						AND F50_1095 >= &startDate.
					%end;
					%if "&endDate"^="" %then %do; 
						AND F50_1095 <= &endDate.
					%end;
				%end;
			order by 
				"DATE"
	);
%put &sqlxmsg;
disconnect from ODBC;
quit; run; 

proc sort data=&libRef..outset nodupkey; by Date SecID; run;

%ClearLabel(lib=&libRef, data=outset);
data &outset.; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Event_IPO;