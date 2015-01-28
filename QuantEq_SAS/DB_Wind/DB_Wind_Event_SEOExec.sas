/* Event SEO(Seasoned Equity Offering) ���� */
/*
	 һ����˾�ⶨ�������������й�֤���Ԥ��ͨ�����ͬ��;
����������˾�ٿ����»ᣬ���涨������Ԥ�����������ٿ��ɶ����;
����������˾�ٿ��ɶ���ᣬ���涨����������;����ʽ�걨���ϱ��й�֤���;
�����ġ����뾭�й�֤��ᷢ������ͨ������˾�����׼�ļ�;
�����塢��˾�ٿ����»ᣬ����ͨ�����������ľ������ݣ�������;
��������ִ�ж�����������;
�����ߡ���˾���淢��������ɷݱ䶯�����顣

		N.B. Accoring to communicaion with Wind consultant, it is possible some private placement in cash may not have IECApprove date.
		This is due to the fact that CSRC will not disclose the date of approval for this kind of transaction.
*/
%macro DB_Wind_Event_SEOExec(	table = TB_OBJECT_1094,
																		eventDate=,
																		startDate=,
																		endDate=,
																		outset=_WindDB_Event_SEO,
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
%local table outset eventDate startDate endDate ;

/* Query wind database*/
proc sql; 
	connect to ODBC (noprompt="dsn=windconn;database=wind;uid=yscpb;pwd=yscpb123;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		select 
			Date,
			DateUpdate,
			"EVENT",
			ProgressID,
			Progress,
			SecID,
			TradeID,
			SecName,
			sum(IssueNum)	
				as IssueNum,
			sum(IssueNum*IssuePrice)/sum(IssueNum)
				as IssuePrc,
			(
				select 
					top(1) F24_1432				/* ��ֹ�������ݸ�������ͨA������ */ 
					from TB_OBJECT_1432			/* �ɱ��� */
					where 
						F46_1432 <= Date		/* �������� */	
						and F1_1432 = FirmID	
					ORDER BY F46_1432 DESC
			)					
				as ShareNum_A_Freeflow,
			(
				select 
					top(1) F27_1432				/* ��ֹ�������ݸ������ܹɱ����� */ 
					from TB_OBJECT_1432 
					where 
						F46_1432 <= Date 
						and F1_1432 = FirmID 
					ORDER BY F46_1432 DESC
			)					
				as ShareNum_Total,
			DateBoardPublish,
			DateMeetingApprove,
			DateIECApprove,
			DateExecPublish
		from
			(
				select
					F80_1094			as Date,				/* ���»�Ԥ�������� */
					F52_1094			as DateUpdate,
					'SEO'					as "EVENT",
					ProgressID = case			
									when OB_OBJECT_NAME_1214 = 'ʵʩ' then '5'
									when OB_OBJECT_NAME_1214 = '֤�����׼' then '4'
									when OB_OBJECT_NAME_1214 = '����ίͨ��' then '3'
									when OB_OBJECT_NAME_1214 = '����ί��׼' then '2'
									when OB_OBJECT_NAME_1214 = '�ɶ����ͨ��' then '1'
									when OB_OBJECT_NAME_1214 = '���»�Ԥ��' then '0'
									else 'Pending'
									end,
					OB_OBJECT_NAME_1214	as Progress,
					OB_REVISIONS_1090	as FirmID,
					F1_1094 			as SecID,
					F16_1090 			as TradeID,
					OB_OBJECT_NAME_1090 as SecName,
					F8_1094 			as IssueNum,
					F3_1094				as IssuePrice,							/* */
					F78_1094			as DateBoardPublish,
					F79_1094			as DateMeetingApprove,	/* �ɶ���ṫ����*/
					F106_1094			as DateIECApprove,				/* ����ί(CSRC Issuance Examination Committee) ͨ���� */
					F80_1094			as DateExecPublish				/* ���������� */
				from
					TB_OBJECT_1094 left join TB_OBJECT_1214 on F28_1094 = F1_1214 ,
					TB_OBJECT_1090
				where
					F1_1094 = F2_1090		
					%if "&eventDate"^="" %then %do; 
						AND F80_1094 = &eventDate
					%end;
					%else %do;
						%if "&startDate"^="" %then %do; 
							AND F80_1094 >= &startDate
						%end;
						%if "&endDate"^="" %then %do; 
							AND F80_1094 <= &endDate
						%end;
					%end;
					AND F28_1094 not in 
						(
							'12',	/* ֹͣʵʩ */
							'21',	/* ����ίδͨ�� */
							'22'	/* �ɶ����δͨ�� */
						)
			) result
		group by
			Date,DateUpdate,"EVENT",
			ProgressID,Progress,
			FirmID,SecID,TradeID,
			SecName,
			DateBoardPublish,DateMeetingApprove,DateIECApprove,DateExecPublish
		order by 
			ProgressID DESC,
			DATE,
			TradeID
	);
	%put &sqlxmsg;
	disconnect from ODBC;
quit;
run;

data &libRef..outset; set &libRef..outset;
	IssueNum_in_AshareFf = round(IssueNum/ShareNum_A_Freeflow,0.01);
	IssueNum_in_TotalShare = round(IssueNum/ ShareNum_Total,0.01);
run;

/* Reorder Table*/
PROC SQL;
   CREATE TABLE &libRef..outset AS 
   SELECT t1.Date, 
   		  t1.DateUpdate,
          t1.Event, 
          t1.Progress, 
          t1.ProgressID, 
          t1.SecID, 
          t1.TradeID, 
          t1.SecName, 
          t1.IssueNum, 
          t1.IssuePrc, 
          t1.IssueNum_in_AshareFf, 
          t1.IssueNum_in_TotalShare, 
          t1.ShareNum_A_Freeflow, 
          t1.ShareNum_Total, 
          t1.DateBoardPublish, 
          t1.DateMeetingApprove, 
          t1.DateIECApprove, 
          t1.DateExecPublish
      FROM &libRef..outset t1;
QUIT;

%ClearLabel(lib=&libRef, data=outset);
data &outset; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Event_SEOExec;
