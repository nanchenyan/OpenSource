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
			F2_1090 							as SecID,								/*֤ȯID*/
			OB_REVISIONS_1090 		as ComID,							/*��˾ID */
			F16_1090 							as TradeID,							/*���״���*/
			F22_1090							as TradeID2,						/*���״���2*/
			OB_OBJECT_NAME_1090	
														as SecNameSm,				/*֤ȯ���*/
			F3_1090	 							as PinyinSm,						/*���ƴ��*/
			F4_1090	 							as SecType	,						/*֤ȯ���ʹ���*/
			F23_1090 							as Currency,						/*���׻��Ҵ���*/
			F5_1090	 							as Exchange,						/*������*/
			F27_1090							as ExchangeCode,			/*����������*/
			F6_1090 							as ExgBan,							/*���а�*/
			F26_1090							as ExgBanCode,				/*���а����*/
			F21_1090 							as IsPostIPO,						/*�Ƿ��Ѿ�����*/
			F17_1090 							as IPODate	,						/*����ʱ��*/
			F19_1090 							as IsDelist,							/*�Ƿ�ժ��*/
			F18_1090							as DelistDate						/*ժ������*/
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