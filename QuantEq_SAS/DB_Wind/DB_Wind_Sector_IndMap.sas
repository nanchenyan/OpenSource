%macro DB_Wind_Sector_IndMap(dsn=&DBWIND_dsn.,
																database=&DBWIND_database.,
																uid=&DBWIND_uid.,
																pwd=&DBWIND_pwd.,
																table = Tb_OBJECT_5014 TB_OBJECT_1022,
																IndName=申万行业分类,
																IndLevel=3,
																outset=_Sector_IndMap,
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
*Table;			%local table;
*Parameters; %local IndName IndLevel outset;


* Get Industry Code Prefix;
%local strIndName; %let strIndName = %BQUOTE(')&IndName%BQUOTE(');
%put DEBUG: strIndName = &strIndName;

proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..IndLevel0 as select * from connection to ODBC 
	(
		select 
			distinct 
			code			as IndCode, 
			name 			as IndLevel,
			levelNum	as LevelNum
		from 
			TB_OBJECT_1022
		where
 			name = &strIndName.
		order by
			levelNum
	);
disconnect from ODBC;
quit; run; 


/* Get Industry Code Prefix, determine subsequent IndLevel Code Name from table 5014 */
%local IndCode;
data _NULL_; set &libRef..IndLevel0(Where=(LevelNum=1)); 
	if _N_ = 1 then call symputx("IndCode", substr(IndCode,1,2));
run;

%local strIndCode; %let strIndCode = %BQUOTE(')&IndCode%BQUOTE(');
%put DEBUG: IndCode = &strIndCode;

* Raw Industry Map;
%local n; 
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..IndMap as select * from connection to ODBC 
	(
		select 
			distinct 
			%do n=0 %to 10; 
				substring(CODE,1,%eval((&n.+1)*2)) + substring('00000000000000000000000000000000000000',%eval((&n.+1)*2+1),%eval(38-(&n.+1)*2))
								as IndCode&n,
			%end; 
			F1_1022 as Description
		from 
			TB_OBJECT_1022
		where
			substring(CODE,1,2) = &strIndCode.
	);
disconnect from ODBC;
quit; run; 

*Industry Map;
data &libRef..IndMap; set &libRef..IndMap;
		%do n=1 %to 5; 
		if (IndCode&n=IndCode%eval(&n-1) or IndCode%eval(&n-1)="") then IndCode&n="";  
		%end; 
run;

* Get Industry Code, Name, ID List;
proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
	create table &libRef..IndRef as select * from connection to ODBC 
	(
		select 
			distinct 
			code				as IndCode, 
			name 				as IndLevel,
			levelNum		as LevelNum
		from 
			TB_OBJECT_1022
		where
 			substring(code,1,2) = &strIndCode.
		order by
			levelNum
	);
disconnect from ODBC;
quit; run; 

* Real Indlevel = IndLevel in table 1022 minus 1;
data &libRef..IndRef; set &libRef..IndRef; LevelNum = LevelNum-1; run;

* Finally, we aggregate all;
proc sort data=&libRef..IndRef nodupkey; by IndCode; run; 
data &libRef..outset; set &libRef..IndMap; run; 

%do n=0 %to 10; 

	data &libRef..outset; set &libRef..outset; IndCode = IndCode&n.; drop IndCode&n.; run; 
	proc sort data=&libRef..outset; by IndCode; run; 

	data &libRef..outset;
		merge 
		 	&libRef..outset(in=inOrg)
			&libRef..IndRef(Keep=IndCode IndLevel)
		; 
		by IndCode; 
		if inOrg; 
		rename 
			IndCode = IndCode&n.
			IndLevel = IndLevel&n.
		;
	run;

%end; 

proc sort data=&libref..outset nodupkey; by IndCode&IndLevel.; run;
data &libref..outset; set &libref..outset; 
	keep 
		%do n=0 %to &IndLevel.; 
			IndCode&n. IndLevel&n.
		%end;
	;
	/* If indlevel too large there may be no data */
	%if &IndLevel. <=3 %then %do;
		if missing(IndCode&IndLevel.) then delete;
	%end;
run;

%ClearLabel(lib=&libRef., data=outset); 
data &outset.; set &libref..outset; run;

*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Sector_IndMap;
/*
IndName:
标普全球指数分类体系
银行理财产品板块
中信行业分类
申万行业分类
证监会行业分类(2012版)
概念板块
地域板块
国信行业分类(旧)
上证所行业分类
万得全球行业分类标准
债券板块
新闻
巨潮行业分类
国信行业分类
其他板块
荣正企业属性
荣正行业分类
股票板块
利率板块
富时全球指数分类体系
基金
指数
指数板块
PEVC行业分类
外汇板块
公司分类
万得中国行业分类标准
期货商品板块
GICS(全球行业分类标准)
中证行业分类
MSCICHINAA
权证板块
证监会行业分类
ICB全球行业分类基准
富时全球行业分类体系
同系板块
基金板块
*/