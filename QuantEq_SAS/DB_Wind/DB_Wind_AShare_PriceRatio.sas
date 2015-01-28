%macro DB_Wind_AShare_PriceRatio(dsn=&DBWIND_dsn.,
																database=&DBWIND_database.,
																uid=&DBWIND_uid.,
																pwd=&DBWIND_pwd.,
																table=TB_OBJECT_5004,
																startDate=,
																endDate=&today.,
																outset=_AShare_PriceRatio, 
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
			F2_5004	 		as Date,				/* 交易日期									*/
			F1_5004 		as SecID,				/* 证券ID										*/
			OB_REVISIONS_1090 		
									as ComID,			/* 公司ID 										*/
			F16_1090		as TradeID,			/* 交易代码 									*/
			F9_5004 		as Mktcap,			/* 总市值										*/
			F10_5004		as Mktcapff,		/* 流通市值									*/
			F4_5004 		as abPrcRatio, 	/*	AB股比价(%)							*/
			F5_5004			as avgPrc,			/*	均价											*/
			F6_5004 		as Tnvr0b1d, 		/*	换手率(%)									*/
			F7_5004			as Ret0b1d,		/*	涨跌幅(%)									*/
			F8_5004			as Range0b1d, 	/*	震幅(%)										*/
			F11_5004		as High0b52w, 	/*	52周最高价								*/
			F12_5004		as Low0b52w, 	/*	52周最低价								*/
			F13_5004		as adv3m,			/*最近3个月平均成交量			*/
			1/F14_5004 	as Ep1,				/*	 市盈率1									*/
			1/F15_5004	as Bp,					/*	 市净率										*/
			1/F16_5004 	as EpTTM,			/*	 市盈率(ttm)								*/
			1/F17_5004 	as CFop,				/*	 股价/每股现金流					*/
			1/F18_5004 	as CFopTTM,		/*	 股价/每股现金流(ttm)			*/
			1/F19_5004 	as Sp,					/*	 股价/每股主营收入				*/
			1/F20_5004	as SpTTM,			/*	 股价/每股主营收入 (ttm)	*/
			1/F21_5004	as Dp					/*	 股价/每股派息						*/
		FROM
			TB_OBJECT_5004 left join TB_OBJECT_1090
			ON  F1_5004 = F2_1090 
		WHERE
			F4_1090='A' 
			%if "&startDate"^="" %then %do; 
				AND F2_5004 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND F2_5004 <= &endDate
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
%mend DB_Wind_AShare_PriceRatio; 