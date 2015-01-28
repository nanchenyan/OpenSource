/* Non Tradable Shares Unlock 股改限售股解禁 */
%macro DB_Wind_Event_NonTrdShrUnLock(	table = TB_OBJECT_1770,
																						eventDate=,
																						startDate=,
																						endDate=,
																						outset=_Event_NonTrdShrUnLock,
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
%local table inset_ID eventDate startDate endDate outset optionon;

/* Query wind database*/
proc sql; 
	connect to ODBC (noprompt="dsn=windconn;database=wind;uid=yscpb;pwd=yscpb123;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(
		select
			query.*,
			(
					select 
						top(1) F24_1432						/* 截止当条数据更新日流通A股数量 */ 
						from TB_OBJECT_1432			/* 股本表 */
						where 
							F46_1432 <= Date				/* 公告日期 */	
							and F1_1432 = FirmID
							and OB_IS_VALID_1432 = 1 	
						ORDER BY F46_1432 DESC
				)					
					as ShareNum_A_Freeflow,
				(
					select 
						top(1) F27_1432						/* 截止当条数据更新日总股本数量 */ 
						from TB_OBJECT_1432 
						where 
							F46_1432 <= Date 
							and F1_1432 = FirmID 
							and OB_IS_VALID_1432 = 1 
						ORDER BY F46_1432 DESC
				)					
					as ShareNum_Total

		from (
				select 
					F4_1770									as Date,					/* Unlock Date */
					F2_1770									as DateUpdate,
					'股票上市流通'					as "Event",
					F3_1770									as "Description",
					OB_REVISIONS_1090			as FirmID,
					F1_1770 								as SecID,
					F16_1090 								as TradeID,
					OB_OBJECT_NAME_1090 	as SecName,
					F6_1770									as ShareNum_Unlock
				from
					TB_OBJECT_1770,
					TB_OBJECT_1090
				where
					F1_1770 = F2_1090
					%if "&eventDate"^="" %then %do; 
						AND F4_1770 = &eventDate
					%end;
					%else %do;
						%if "&startDate"^="" %then %do; 
							AND F4_1770 >= &startDate
						%end;
						%if "&endDate"^="" %then %do; 
							AND F4_1770 <= &endDate
						%end;
					%end;
			) query
		order by 
			Date Desc,
			SecID;
		);
		%put &sqlxmsg;
		disconnect from ODBC;
quit;
run;


data &libRef..outset; set &libRef..outset;
	ShareNum_in_AshareFf = round(ShareNum_Unlock/ShareNum_A_Freeflow,0.01);
	ShareNum_in_TotalShare = round(ShareNum_Unlock/ ShareNum_Total,0.01);
run;

/* Reorder Table*/
PROC SQL;
   CREATE TABLE &libRef..outset AS 
   SELECT t1.Date, 
   		  t1.DateUpdate,
          t1.Event, 
          t1.Description, 
          t1.SecID, 
          t1.TradeID, 
          t1.SecName, 
          t1.ShareNum_Unlock, 
          t1.ShareNum_in_AshareFf, 
		  t1.ShareNum_in_TotalShare,
          t1.ShareNum_A_Freeflow, 
          t1.ShareNum_Total
      FROM &libRef..outset t1;
QUIT;

%ClearLabel(lib=&libRef, data=outset);
data &outset; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Event_NonTrdShrUnLock;
