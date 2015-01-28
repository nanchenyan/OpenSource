/* Daily Fluctuation Limit  ÕÇµøÍ£ */
%macro DB_Wind_Event_FluctLimit(	table = TB_OBJECT_1093,
																		eventDate=,
																		startDate=,
																		endDate=,
																		outset=_Event_FluctLimit,
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
			Date						as Date,
			"EVENT"=case
				when ret0b1d >= 0.09 then 'ÕÇÍ£'
				when ret0b1d <= -0.09 then 'µøÍ£'
			end,
			SecID	 					as SecID,
			F16_1090 					as TradeID,
			OB_OBJECT_NAME_1090			as SecName,
			ret0b1d						as Ret0b1d
		from
			(
				select 
					F2_1425						as Date,
					F1_1425						as SecID,
					F3_1425						as Prc_PreCloseAdj,
					F7_1425						as Prc_CloseAdj,
					round(F7_1425/F3_1425-1,4)	as ret0b1d
				from 
					TB_OBJECT_1425 t1 
					left join TB_OBJECT_1120 on (F1_1120 = F1_1425 and F2_1120 = F2_1425)
				where 
					F22_1120 = 'A'
					AND F3_1425 <> 0
					%if "&eventDate"^="" %then %do; 
						AND F2_1425 = &eventDate 
					%end;
					%else %do;
						%if "&startDate"^="" %then %do; 
							AND  F2_1425 >= &startDate
						%end;
						%if "&endDate"^="" %then %do; 
							AND F2_1425 <= &endDate
						%end;
					%end;
			)query left join TB_OBJECT_1090 on query.SecID = F2_1090
		order by 
			"EVENT",
			TradeID
	);
	%put &sqlxmsg;
	disconnect from ODBC;
quit;
run;

data &libRef..outset; set &libRef..outset;
	if event ^="";
run;
	
%ClearLabel(lib=&libRef, data=outset);
data &outset; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Event_FluctLimit;
/* DB_Wind_Event_FluctLimit */