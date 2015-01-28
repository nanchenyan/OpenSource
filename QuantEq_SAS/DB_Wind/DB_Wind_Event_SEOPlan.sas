/* Event SEO(Seasoned Equity Offering) 增发 */
/*
	 一、公司拟定初步方案，与中国证监会预沟通，获得同意;
　　二、公司召开董事会，公告定向增发预案，并提议召开股东大会;
　　三、公司召开股东大会，公告定向增发方案;将正式申报材料报中国证监会;
　　四、申请经中国证监会发审会审核通过，公司公告核准文件;
　　五、公司召开董事会，审议通过定向增发的具体内容，并公告;
　　六、执行定向增发方案;
　　七、公司公告发行情况及股份变动报告书。

		N.B. Accoring to communicaion with Wind consultant, it is possible some private placement in cash may not have IECApprove date.
		This is due to the fact that CSRC will not disclose the date of approval for this kind of transaction.
*/
%macro DB_Wind_Event_SEOPlan(	table = TB_OBJECT_1094,
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
					top(1) F24_1432				/* 截止当条数据更新日流通A股数量 */ 
					from TB_OBJECT_1432			/* 股本表 */
					where 
						F46_1432 <= Date		/* 公告日期 */	
						and F1_1432 = FirmID	
					ORDER BY F46_1432 DESC
			)					
				as ShareNum_A_Freeflow,
			(
				select 
					top(1) F27_1432				/* 截止当条数据更新日总股本数量 */ 
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
			DateIssue
		from
			(
				select
					F78_1094			as Date,				/* 董事会预案公告日 */
					F52_1094			as DateUpdate,
					'SEO'				as "EVENT",
					ProgressID = case			
									when OB_OBJECT_NAME_1214 = '实施' then '5'
									when OB_OBJECT_NAME_1214 = '证监会批准' then '4'
									when OB_OBJECT_NAME_1214 = '发审委通过' then '3'
									when OB_OBJECT_NAME_1214 = '国资委批准' then '2'
									when OB_OBJECT_NAME_1214 = '股东大会通过' then '1'
									when OB_OBJECT_NAME_1214 = '董事会预案' then '0'
									else 'Pending'
									end,
					OB_OBJECT_NAME_1214	as Progress,
					OB_REVISIONS_1090	as FirmID,
					F1_1094 			as SecID,
					F16_1090 			as TradeID,
					OB_OBJECT_NAME_1090 as SecName,
					F8_1094 			as IssueNum,
					F3_1094				as IssuePrice,			/* */
					F78_1094			as DateBoardPublish,
					F79_1094			as DateMeetingApprove,	/* 股东大会公告日*/
					F106_1094			as DateIECApprove,		/* 发审委(CSRC Issuance Examination Committee) 通过日 */
					F80_1094			as DateIssue
				from
					TB_OBJECT_1094 left join TB_OBJECT_1214 on F28_1094 = F1_1214 ,
					TB_OBJECT_1090
					
				where
					F1_1094 = F2_1090		
					%if "&eventDate"^="" %then %do; 
						AND F78_1094 = &eventDate
					%end;
					%else %do;
						%if "&startDate"^="" %then %do; 
							AND F78_1094 >= &startDate
						%end;
						%if "&endDate"^="" %then %do; 
							AND F78_1094 <= &endDate
						%end;
					%end;
					AND F28_1094 not in 
						(
							'12',	/* 停止实施 */
							'21',	/* 发审委未通过 */
							'22'	/* 股东大会未通过 */
						)
			) result
		group by
			Date,DateUpdate,"EVENT",
			ProgressID,Progress,
			FirmID,SecID,TradeID,
			SecName,
			DateBoardPublish,DateMeetingApprove,DateIECApprove,DateIssue
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
          t1.DateIssue
      FROM &libRef..outset t1;
QUIT;

%ClearLabel(lib=&libRef, data=outset);
data &outset; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Event_SEOPlan;
