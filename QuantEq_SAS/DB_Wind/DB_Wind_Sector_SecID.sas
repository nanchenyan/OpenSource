%macro DB_Wind_Sector_SecID(dsn=&DBWIND_dsn.,
															database=&DBWIND_database.,
															uid=&DBWIND_uid.,
															pwd=&DBWIND_pwd.,
															table = TB_OBJECT_1400,
															insetDateSecID=inset._AShare_DateSecIDComID,
															insetMap=_Sector_IndMap_,
															IndName=,
															IndLevel=2,
															startDate=,
															outset=_Industry_SecID,
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
*Database; 	%local dsn database uid pwd;
*Table;			%local insetDateSecID insetMap;
*Parameters; %local IndName IndLevel startDate outset;


* Get Date Table;
data &libref..insetDateSecID; set &insetDateSecID.
	%if "&startDate" ^="" %then %do;
		(where=(Date >= "&startDate")) 
	%end;
	;
run;

%local startDate;
proc sort data=&libref..insetDateSecID nodupkey; By Date SecID; run;

data _NULL_; set &libref..insetDateSecID;
	if _N_ = 1 then call symputx("startDate",Date);
run;
%put DEBUG: StartDate is &startDate;


* Get Industry Code Prefix;
%local IndCode;
data &libRef..insetMap; set &insetMap.; 
	if _N_ = 1 then call symputx("IndCode", substr(IndCode0,1,2));
run;

%local strIndCode; %let strIndCode = %BQUOTE(')&IndCode%BQUOTE(');
%put DEBUG: IndCode = &strIndCode; 
%if "&IndName" ^= "" %then %do;
	%put DEBUG: Specific Sector: IndName = &IndName;
%end;

/* Get SecID match with the Industry ID */

/* General */
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..IndSecID as select * from connection to ODBC 
	(
		select 
			t2.LevelNUM - 1 	as LeveLNum	,
			t1.IndCode				as IndCode&IndLevel., 
			t2.Name 				as IndLevel&IndLevel.,
			t1.SecID, 
			t1.SecName,
			t1.IndType, 
			t1.StartDate, 
			t1.EndDate, 
			t1.IsRecent
		from
				(
					select 
						substring(F3_1400,1,%eval((&IndLevel.+1)*2)) + substring('00000000000000000000000000000000000000',%eval((&IndLevel.+1)*2+1),%eval(38-(&IndLevel.+1)*2)) 
																	as IndCode, 
						F2_1090								as SecID, 
						ob_object_name_1090	as SecName,
						F7_1400								as IndType,
						F4_1400								as StartDate, 
						F5_1400								as EndDate, 
						F6_1400								as IsRecent
					from 
						tb_object_1400 left join tb_object_1090 on F1_1400 = OB_REVISIONS_1090
					where 
						substring(F3_1400,1,%eval((&IndLevel.+1)*2)) + substring('00000000000000000000000000000000000000',%eval((&IndLevel.+1)*2+1),%eval(38-(&IndLevel.+1)*2))
						in (select CODE from TB_OBJECT_1022 where levelNum=%eval(&IndLevel.+1) and substring(CODE,1,2) = &strIndCode.) 
				) t1 
			left join
				(
					select * from TB_OBJECT_1022 where LevelNum = %eval(&IndLevel. +1) and substring(CODE,1,2) = &strIndCode.
				) t2
			on 
				t1.IndCode = t2.CODE
	);
	%put &sqlxmsg;
disconnect from ODBC;
quit; run; 


/* Rearrange IndSecID */
proc sort data=&libRef..IndSecID nodupkey; by SecID StartDate EndDate IndCode&IndLevel. ; run;

data &libRef..IndSecID_cln;
	set &libRef..IndSecID; 
	By SecID;
	if missing(EndDate) then EndDate="99999999";
	
	StartDate_Lag = lag(EndDate);
	/* first.SecID means the earliest record in table, there's no classification before this one. */
	if first.SecID then StartDate_Lag = "00000000";

	%if "&indName" ^= "" %then %do;
 		if IndLevel&IndLevel. = "&IndName.";
	%end;
run;

*���ȫ����ҵ�����׼; 
proc sql; 
create table &libRef..outset as 
select  
	a.Date,
	a.SecID,
	b.IndCode&IndLevel.
	from
		&libref..insetDateSecID a left join &libRef..IndSecID_cln b
		on 
			a.SecID=b.SecID 
			and (
						
						(a.Date >= b.StartDate and a.Date<=b.EndDate) 
						or (a.Date < b.StartDate and b.StartDate_Lag = '00000000')
					)
;
quit; run;

proc sort data=&libref..outset nodupkey; By Date SecID; run;

proc sort data=&libref..outset; By IndCode&IndLevel.; run;
proc sort data=&libref..insetMap; By IndCode&IndLevel.; run;

data &libref..outset; 
	merge
		&libref..outset(in=in1)
		&libref..insetMap(keep=IndCode0 - IndCode&IndLevel. IndLevel0 - IndLevel&IndLevel.)
	;
	By IndCode&IndLevel.;
	if in1;
	if missing(Date) then Delete;
	if missing (SecID) then delete;
	if missing(IndCode0) then delete;
	Keep Date SecID IndLevel0 - IndLevel&IndLevel.;
run;

%ClearLabel(lib=&libRef, data=outset);
proc sort data=&libref..outset nodupkey out=&outset.; By Date SecID; run;

*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Sector_SecID;
/*
 %DB_Wind_Sector_IndMap(IndName=������ҵ����,
													IndLevel=2,
													outset=_Sector_IndMap,
													optionon=0);

%DB_Wind_Sector_SecID(	insetDateSecID=inset._AShare_DateSecIDComID,
												insetMap=_Sector_IndMap,
												IndName=,
												IndLevel=2,
												startDate=20120101,
												outset=_Sector_SecID,
												optionon=0);

IndName:
����ȫ��ָ��������ϵ
������Ʋ�Ʒ���
������ҵ����
������ҵ����
֤�����ҵ����(2012��)
������
������
������ҵ����(��)
��֤����ҵ����
���ȫ����ҵ�����׼
ծȯ���
����
�޳���ҵ����
������ҵ����
�������
������ҵ����
������ҵ����
��Ʊ���
���ʰ��
��ʱȫ��ָ��������ϵ
����
ָ��
ָ�����
PEVC��ҵ����
�����
��˾����
����й���ҵ�����׼
�ڻ���Ʒ���
GICS(ȫ����ҵ�����׼)
��֤��ҵ����
MSCICHINAA
Ȩ֤���
֤�����ҵ����
ICBȫ����ҵ�����׼
��ʱȫ����ҵ������ϵ
ͬϵ���
������
*/
