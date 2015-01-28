/* 中信1级行业分类成分 */
%macro DB_Wind_Sector_CiticsLv2(dsn=windconn,
																database=wind,
																uid=yscpb,
																pwd=yscpb123,
																table = tb_object_1400 tb_object_1022,
																tableRef = tb_object_1090,
																outset=_Sector_CiticsLv1,
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
%local dsn database uid pwd table outset;

/* Query wind database*/
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn; database=&database; uid=&uid; pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..outset as select * from connection to ODBC 
	(		
			select 
				*
			from
			(
				Select 
					F2_1090									as SecID,
					ob_object_name_1090		as SecName,
					a.name									as Sector
				From 
					tb_object_1090
					Inner Join tb_object_1400 On F1_1400 = OB_REVISIONS_1090
					Inner Join tb_object_1022 a On substring(f3_1400,1,6)=substring(a.code,1,6)
				Where 
					a.code Like 'b1%'
					And a.levelnum='3'
					And F6_1400='1'
					And F4_1090 In ('A','B')
			) query
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
%mend DB_Wind_Sector_CiticsLv2;


/*
%DB_Wind_Sector_CiticsLv2(	dsn=windconn,
														database=wind,
														uid=yscpb,
														pwd=yscpb123,
														outset=_Sector_CiticsLv1,
														optionon=0);
*/