%macro DB_Wind_CNYIdxFut_Price(table=TB_OBJECT_3517,
															startDate=,
															endDate=&today,
															outset=_CNYIdxFut_Price, 
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
			F15_3517		as SecID,					/*֤ȯID*/
			F2_3517	 		as Date,					/*��������*/
			F1_3517 		as Name, 				/* ָ������*/ 
			F7_3517	 		as Prcadj,				/*��Ȩ���̼�*/
			null					as prcadjFct,			/*��Ȩ����*/
			F6_3517			as prc,						/* ���̼� */
			F7_3517			as prcSet,				/* ����� */
			F14_3517		as prcSetPre,			/* ǰ����� */
			F8_3517 		as Volume,				/* �ɽ���(��) */
			F10_3517 		as VolumeCash, 	/* �ɽ���(��Ԫ) */
			F9_3517			as OpnInt,				/* �ֲ��� */
			F13_3517		as OpnIntChg		/* �ֲ����仯 */
		FROM
			TB_OBJECT_3517 left join TB_OBJECT_1090
			ON  F15_3517 = F2_1090 
		WHERE
			F4_1090='FU' 
			AND SUBSTRING(F1_3517,1,2) = 'IF'
			%if "&startDate"^="" %then %do; 
				AND F2_3517 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND F2_3517 <= &endDate
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
%mend DB_Wind_CNYIdxFut_Price; 