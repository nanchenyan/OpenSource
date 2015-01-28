/* Event Dividend 红利红股 note: eventDate should be yyyy0630 or yyyy1231*/


/* 深交所的相关规定，如股价异动发生在年度报告或半年度报告披露前10个交易日内，应当预披露分配方案预案。*/
/* Date Sequence
	: Date_PrePlan => Date_Plan => Date_Board => Date_Schedule => Date_ExDividend => Date_Settlement;
*/
%macro DB_Wind_Event_Dividend(	table = TB_OBJECT_1093,
																	startDate=,
																	endDate=,
																	period=,
																	outset=_Event_Dividend,
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
%local table startDate endDate period outset;

/* Query wind database*/
proc sql; 
	connect to ODBC (noprompt="dsn=&DBWIND_dsn;database=&DBWIND_database;uid=&DBWIND_uid;pwd=&DBWIND_pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		SELECT 
			F36_1093								as Date,		/* Event/New Update */
			'Dividend'								as Event,
			F1_1093									as SecID,
			F16_1090 								as TradeID,
			OB_OBJECT_NAME_1090	as SecName,
			F33_1093								as Date_PrePlan,
			F41_1093								as Date_Plan,
			F42_1093								as Date_Board,
			F43_1093								as Date_Schedule,
			F26_1093								as Date_ExDividend,
			F27_1093								as Date_Settlement,		
			F24_1093								as Period,
			F45_1093								as IsChanged,									/* 1 if plan has been changed */
			F2_0003									as Progress,
			1 - F37_1093							as Ctrl,												/* 1 if has cash div or stock div, 0 nothing */
			round(	
				F9_1093/F8_1093,4)		as Div_Cash_beforeTax,		
			round(
				F10_1093/F8_1093,4)		as Div_Cash_afterTax,						/* Declared cash dividend for current period */
			round(
				F5_1093/F4_1093,4)		as Div_Stock,										/* Declared stock dividend for current period */
			round(
				F7_1093/F6_1093,4)		as Capitalization						
		FROM
			TB_OBJECT_1093 left join TB_OBJECT_1090  ON F1_1093 = F2_1090,
			TB_OBJECT_0003
		WHERE
			F52_1093 = F3_0003
			%if "&startDate"^="" %then %do; 
				AND F36_1093 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND F36_1093 <= &endDate
			%end;
			%if "&period"^="" %then %do; 
				AND substring(F24_1093,1,8) = &period
			%end;
		ORDER BY
			F36_1093 desc,
			F24_1093 desc
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
%mend DB_Wind_Event_Dividend;
/*
%DB_Wind_Event_Dividend(table = TB_OBJECT_1093,
												startDate=20130101,
												endDate=&today,
												period=,
												outset=_Event_Dividend,
												optionon=0);
*/