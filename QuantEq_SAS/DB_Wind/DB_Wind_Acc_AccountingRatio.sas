%macro DB_Wind_Acc_AccountingRatio(dsn=&DBWIND_dsn.,
																database=&DBWIND_database.,
																uid=&DBWIND_uid.,
																pwd=&DBWIND_pwd.,
																table=TB_OBJECT_5034,
																startDate=,
																endDate=&today.,
																outset=_Acc_AccountingRatio, 
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
*Database; 	%local dsn database uid pwd;
*Table;			%local table;
*Parameters; %local startDate endDate outset;

proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		SELECT
			F1_5034 	as ComID,		 				/*	公司ID	*/
			F3_5034 	as RptDate, 					/*	报告期	*/
			CONVERT(char(10), 
				t1.RP_GEN_DATETIME,112)
								as RptGenDate,			/*	报告gen期	*/
			F14_5034	as FCFF,		 				/*	企业自由现金流量(FCFF)	*/
			F15_5034	as FCFE, 						/*	股权自由现金流量(FCFE)	*/
			F44_5034	as Profit_Margin, 		/*	净利润/营业总收入			*/
			F56_5034	as ROI, 						/*	投入资本回报率					*/
			F57_5034	as ROE_ann,				/*	年化净资产收益率				*/
			F58_5034	as ROA_ann,				/*	年化总资产报酬率				*/
			F69_5034	as D2A
		FROM
			TB_OBJECT_5034 t1 LEFT JOIN TB_OBJECT_1090 t2
			ON F1_5034 = Ob_revisions_1090
		WHERE
			F1_5034 is not null						/* ComID									*/
			AND F4_1090 = 'A'
			%if "&startDate"^="" %then %do; 
				AND F3_5034 >= &startDate.
			%end;
			%if "&endDate"^="" %then %do; 
				AND F3_5034 <= &endDate.
			%end;
		ORDER BY
			RptDate, ComID 
		);
	%put &sqlxmsg;
	disconnect from ODBC;
quit;
run; 

%ClearLabel(lib=&libRef, data=outset);
data &outset.; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Acc_AccountingRatio; 