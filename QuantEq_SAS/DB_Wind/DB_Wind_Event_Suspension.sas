/* Event Suspension Í£ÅÆ */
%macro DB_Wind_Event_Suspension(	table = TB_OBJECT_1674,
																			eventDate=,
																			startDate=,
																			endDate=,
																			outset=_Event_Suspension,
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
		t_event.F2_1674 							as Date,
		'Trade Suspension'						as Event,
		t_event.F1_1674 							as SecID,
		t_ID.F16_1090 								as TradeID,
		t_ID.OB_OBJECT_NAME_1090 	as SecName,
		T_Event.F4_1674 							as Comment
	from
		TB_OBJECT_1674 t_event,
		TB_OBJECT_1090 t_ID
	where
		t_event.F1_1674 = t_ID.F2_1090
		AND t_ID.F4_1090='A'							/*Sec Type = A share */ 		
		%if "&eventDate"^="" %then %do; 
			AND t_event.F2_1674 = &eventDate
		%end;
		%else %do;
			%if "&startDate"^="" %then %do; 
				AND t_event.F2_1674 >= &startDate
			%end;
			%if "&endDate"^="" %then %do; 
				AND t_event.F2_1674 <= &endDate
			%end;
		%end;
	order by
		t_event.F2_1674, /* Date */
		t_ID.F16_1090;	/* TradeID */
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
%mend DB_Wind_Event_Suspension;
