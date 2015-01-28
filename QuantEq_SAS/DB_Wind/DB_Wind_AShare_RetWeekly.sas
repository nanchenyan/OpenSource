%macro DB_Wind_Ashare_RetWeekly(table=TB_OBJECT_5005,
																	startDate=,
																	endDate=&today,
																	outset=_Ashare_RetWeekly, 
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
%local table startDate endDate outset optionon;

proc sql; 
	connect to ODBC (noprompt="dsn=&DBWIND_dsn;database=&DBWIND_database;uid=&DBWIND_uid;pwd=&DBWIND_pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		SELECT
			F2_5005	 	as Date,						/*截至日期*/
			F1_5005 	as SecID,						/*证券id*/
			F16_1090	as TradeID,					/* 交易代码 */
			F4_5005		as Ret0b1w,				/*周收益率*/
			F5_5005		as Tnvrcum0b1w,		/*换手率(合计)*/
			F6_5005	 	as Tnvravg0b1w,		/*换手率(算术平均)*/
			F7_5005	 	as VolumeCash0b1w,	/*成交金额(合计)*/
			F8_5005 	as Beta100w,				/*Beta(100周)*/
			F10_5005	as Retstd100w,			/*周收益率标准差(100周)*/
			F11_5005 	as Retavg100w			/*周收益率平均值(100周)*/
		FROM
			TB_OBJECT_5005 left join TB_OBJECT_1090
			ON  F1_5005 = F2_1090 
		WHERE
			F4_1090 = 'A'
			%if "&startDate"^="" %then %do; 
				AND F2_5005 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND F2_5005 <= &endDate
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
%mend DB_Wind_Ashare_RetWeekly; 