%macro DB_Wind_Ashare_RetDaily(table=TB_OBJECT_1425,
																startDate=,
																endDate=&today,
																outset=_Ashare_RetDaily, 
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
			F2_1425	 		as Date,							/*��������*/
			F1_1425 		as SecID,							/*֤ȯID*/
			F16_1090		as TradeID,						/* ���״��� */
			F7_1425			as Prcadj,						/* ��Ȩ���̼� */
			F3_1425			as PreadjPre,					/* ��Ȩ�����̼� */
			F7_1425	
				/F3_1425	as Ret0b1d,					/* ��������*/
			F9_1425 		as VolumeCash0b1d 	/* �ɽ����(ǧԪ) */
		FROM
			TB_OBJECT_1425 left join TB_OBJECT_1090
			ON  F1_1425 = F2_1090 
		WHERE
			F4_1090 = 'A'
			%if "&startDate"^="" %then %do; 
				AND F2_1425 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND F2_1425 <= &endDate
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
%mend DB_Wind_Ashare_RetDaily; 