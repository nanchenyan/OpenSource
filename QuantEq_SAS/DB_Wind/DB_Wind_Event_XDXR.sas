%macro DB_Wind_Event_XDXR(dsn=&DBWIND_dsn.,
						database=&DBWIND_database.,
						uid=&DBWIND_uid.,
						pwd=&DBWIND_pwd.,								
						table = TB_OBJECT_1427,
						startDate=,
						endDate=&today.,
						eventDate=,
						outset=_Event_XDXR,
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
*Database; 		%local dsn database uid pwd;
*Table;			%local table;
*Parameters; 	%local startDate endDate eventDate outset;

* Get ST List from DB;
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
			select
				F2_1427				as "DATE",			/* 除权除息日 */
				'XDXR'				as "EVENT",
				OB_REVISIONS_1090	as ComID,
				F1_1427 			as SecID,
				F16_1090 			as TradeID,
				OB_OBJECT_NAME_1090 
									as SecName,
				F12_1427			as XRType,
				substring(F6_1427,2,4)				
									as XRTable,
				F3_1427				as XDRatio,			/* 派息比例 */
				F4_1427				as SGRatio,			/* 送股比例 */
				F5_1427				as ZZRatio,			/* 转增比例 */
				F11_1427			as PGRatio,			/* 配股比例	*/
				F7_1427				as PGPrice,			/* 配股价格 */
				F8_1427				as ZFRatio,			/* 增发比例 */
				F9_1427				as ZFPrice,			/* 增发价格 */
				F10_1427			as Comment
			from
				TB_OBJECT_1427 left join TB_OBJECT_1090 on F1_1427 = F2_1090
			where
				F4_1090 = 'A' 
				%if "&eventDate"^="" %then %do; 
					AND F2_1427 = &eventDate.
				%end;
				%else %do;
					%if "&startDate"^="" %then %do; 
						AND F2_1427 >= &startDate.
					%end;
					%if "&endDate"^="" %then %do; 
						AND F2_1427 <= &endDate.
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
%mend DB_Wind_Event_XDXR;