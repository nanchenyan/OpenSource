%macro DB_Wind_Ashare_RetMonthly(table=TB_OBJECT_5006,
																		startDate=,
																		endDate=&today,
																		outset=_Ashare_RetMonthly, 
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
			F2_5006	 	as Date,						/*截至日期*/
			F1_5006		as SecID,						/*证券id*/
			F16_1090	as TradeID,					/* 交易代码 */
			F4_5006		as Ret0b1m,				/*周收益率*/
			F5_5006		as Tnvrcum0b1m,		/*换手率(合计)*/
			F6_5006 	as Tnvravg0b1m,		/*换手率(算术平均)*/
			F7_5006	 	as VolumeCash0b1m,	/*成交金额(合计)*/
			F11_5006 	as Beta24m,				/*Beta(24个月)*/
			F8_5006 	as Beta60m,				/*Beta(60个月)*/
			F13_5006 	as Retstd24m,			/*月收益率标准差(24个月)*/
			F10_5006	as Retstd60m,			/*月收益率标准差(60个月)*/
			F14_5006 	as Retavg24m,			/*月收益率平均值(24个月)*/
			F15_5006 	as Retavg60m			/*月收益率平均值(60个月)*/
		FROM
			TB_OBJECT_5006 left join TB_OBJECT_1090
			ON  F1_5006 = F2_1090 
		WHERE
			F4_1090 = 'A'
			%if "&startDate"^="" %then %do; 
				AND F2_5006 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND F2_5006 <= &endDate
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
%mend DB_Wind_Ashare_RetMonthly; 