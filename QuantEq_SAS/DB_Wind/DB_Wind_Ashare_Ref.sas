%macro DB_Wind_AShare_Ref(table=TB_OBJECT_1090,
													outset=_AShare_ID, 
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
			F2_1090 							as SecID,								/*证券ID*/
			OB_REVISIONS_1090 		as ComID,							/*公司ID */
			F16_1090 							as TradeID,							/*交易代码*/
			F22_1090							as TradeID2,						/*交易代码2*/
			OB_OBJECT_NAME_1090	
														as SecNameSm,				/*证券简称*/
			F3_1090	 							as PinyinSm,						/*简称拼音*/
			F4_1090	 							as SecType	,						/*证券类型代码*/
			F23_1090 							as Currency,						/*交易货币代码*/
			F5_1090	 							as Exchange,						/*交易所*/
			F27_1090							as ExchangeCode,			/*交易所代码*/
			F6_1090 							as ExgBan,							/*上市板*/
			F26_1090							as ExgBanCode,				/*上市板代码*/
			F21_1090 							as IsPostIPO,						/*是否已经上市*/
			F17_1090 							as IPODate	,						/*上市时间*/
			F19_1090 							as IsDelist,							/*是否摘牌*/
			F18_1090							as DelistDate						/*摘牌日期*/
		FROM
			TB_OBJECT_1090
		WHERE
			F4_1090 = 'A'
		ORDER BY
			SecID 
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
%mend DB_Wind_AShare_Ref; 