%macro DB_Wind_Acc_RptCashFlow(	dsn=&DBWIND_dsn.,
																database=&DBWIND_database.,
																uid=&DBWIND_uid.,
																pwd=&DBWIND_pwd.,
																table=TB_OBJECT_1855,
																startDate=,
																endDate=&today,
																outset=_Acc_RptCashFlow, 
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
*Parameters; %local startDate endDate outset;

proc sql; 
	connect to ODBC (noprompt="dsn=&dsn;database=&database;uid=&uid;pwd=&pwd;");
    %put &sqlxmsg;
		create table &libRef..query as select * from connection to ODBC
		(
			SELECT
				F2_1090							as SecID,
				F1_1855							as ComID,
				F5_1855							as ComType,
				F2_1855							as RptDate,			/*报告期*/
				F3_1855							as PubDate,			/*公告日期*/
				CONVERT(char(10), 
				t1.RP_GEN_DATETIME, 112)
														as GenDate,
				F4_1855							as RptType,		/*	报表类型*/
				F6_1855							as IsNewPolicy,
				F39_1855						as OperCF,				/* 经营产生的现金流量净额 */
				F49_1855						as CapitalExp	,
				coalesce(F87_1855,0)
					+ coalesce(F88_1855,0)
					+ coalesce(F89_1855, 0)
														as DepAmort
				from
					tb_object_1855 t1 left join TB_OBJECT_1090
					on  F1_1855 = OB_REVISIONS_1090 
				WHERE
					substring(F4_1855,1,4) = '合并报表'
					and F4_1090='A'					/* ChinaA Share						*/
					and F3_1855 is not null		/* DisclosureDate is not null 	*/
					and F1_1855 is not null		/* ComID is not null					*/
					and F7_1855 = 1					/*  上市后数据 ,上市公司需公布上市前3年财务数据		*/
					and substring(F2_1855,1,4) >= 2003
																	/* Only stats after year 2003 */
					%if "&startDate"^="" %then %do; 
						and F2_1855 >= &startDate.
					%end; 
					%if "&endDate."^="" %then %do; 
						and F2_1855 <= &endDate.
					%end; 
		);
	%put &sqlxmsg;
	disconnect from ODBC;
quit;



/* Exception 1: Eliminate multiple Disclosure Date*/
/*
	By Sorting Descending "IsNewPolicy", the NewPolicy ones will be ranked at first 
	and the old or missing one will be dropped. SOLVED.
*/
data &libRef..outset; 
	Retain SecID ComID ComType RptDate RptGenDate;
	set &libRef..query; 
	RptGenDate = put(min(PubDate, GenDate),$8.);
	Drop
		 PubDate GenDate;
run;

/* Exception 2: New Policy and Old Policy */
/*
	By Sorting Descending "IsNewPolicy", the NewPolicy ones will be ranked at first 
	and the old or missing one will be dropped. SOLVED.
*/
proc sort data=&libRef..outset nodupkey; By SecID RptDate RptGenDate DESCENDING IsNewPolicy; run;

/* Add YEAR and Quarter as VARCHAR2 */
data &libRef..outset; 
	Retain Year Quarter;
	set &libRef..outset;

	YEAR = put(SUBSTR(TRIM(RptDate),1,4), $8.);

	IF SUBSTR(TRIM(RptDate),5,2) = "03" THEN Quarter = "1";
	IF SUBSTR(TRIM(RptDate),5,2) = "06" THEN Quarter = "2";
	IF SUBSTR(TRIM(RptDate),5,2) = "09" THEN Quarter = "3";
	IF SUBSTR(TRIM(RptDate),5,2) = "12" THEN Quarter = "4";
run;


%ClearLabel(lib=&libRef., data=outset);
data &outset.; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Acc_RptCashFlow; 
/*
%let libref = inset;
%let inset_prc=mktData._asharedateprc;
%let outset=noa;
%let exportfolder=;
*/

/*

	-- 提取现金流量表中的信息
	SELECT
		distinct 
		SecurityID,
		F6_1855 AS IsNewPolicy,
		convert(varchar(8), dateadd(year, -1, cast(F2_1855 as datetime)), 112) AS 'StartDate',
		F2_1855						AS 'EndDate',
		F3_1855						AS 'IssueDate',
		F39_1855					AS 'NetOperateCF',	-- 经营产生的现金流量净额
		isnull(F49_1855,0)			AS 'CapExp',
		isnull(F87_1855,0)+isnull(F88_1855,0)+isnull(F89_1855, 0) AS 'DA',	-- 资本性支出 ：固定资产折旧与无形资产、长期待摊费用摊销
		EndYear,
		QuaterNum,
		RP_GEN_DATETIME
	INTO #TempCashFlow
	FROM
		WindDB.wind.dbo.TB_OBJECT_1855,	-- 现金流量表
		(SELECT distinct FirmID, SecurityID FROM #TempSecurityList) sec,
		#TempReportDate d
	WHERE
		sec.FirmID collate Chinese_PRC_CI_AS = F1_1855 AND F7_1855 = '1' -- 是否上市后数据
		AND ((F3_1855 > @startDate AND F3_1855 <= @endDate) OR (F2_1855 > @startDate AND F2_1855 <= @endDate))
		AND F2_1855 = d.EndDate
		AND F4_1855 = '合并报表' AND F3_1855 IS NOT NULL

	UPDATE cf1 SET IssueDate = cf2.IssueDate
	FROM #TempCashFlow cf1, #TempCashFlow cf2
	WHERE
		cf1.SecurityID = cf2.SecurityID AND cf1.EndDate = cf2.EndDate 
		AND cf1.IssueDate > cf2.IssueDate AND cf1.IsNewPolicy = '2' AND cf2.IsNewPolicy = '1'

	DELETE cf FROM 
		#TempCashFlow cf, 
		(SELECT SecurityID, EndDate FROM #TempCashFlow GROUP BY SecurityID, EndDate HAVING count(IsNewPolicy) = '2') ccf
	WHERE 
		cf.SecurityID = ccf.SecurityID AND cf.EndDate = ccf.EndDate AND cf.IsNewPolicy != '2'

	DELETE cf FROM 
		#TempCashFlow cf, 
		(SELECT SecurityID, EndDate, IsNewPolicy, IssueDate, max(RP_GEN_DATETIME) AS RP_GEN_DATETIME FROM #TempCashFlow 
		 GROUP BY SecurityID, EndDate, IsNewPolicy, IssueDate) ccf
	WHERE 
		cf.SecurityID = ccf.SecurityID AND cf.EndDate = ccf.EndDate AND cf.IsNewPolicy = ccf.IsNewPolicy AND cf.RP_GEN_DATETIME != ccf.RP_GEN_DATETIME
	--SELECT * FROM #TempCashFlow ORDER BY EndDate, IssueDate, SecurityID

	-- 计算SQ、ttm cashflow 数据
	ALTER TABLE #TempCashFlow ADD SQNetOperateCF decimal(20,4)
	ALTER TABLE #TempCashFlow ADD ttmNetOperateCF decimal(20,4)
	ALTER TABLE #TempCashFlow ADD ttmCapExp decimal(20,4)
	ALTER TABLE #TempCashFlow ADD ttmDA decimal(20,4)

	UPDATE #TempCashFlow
	SET
		SQNetOperateCF = CASE WHEN cf.QuaterNum != '1' THEN cf.NetOperateCF - lq.NetOperateCF ELSE cf.NetOperateCF END
	FROM 
		#TempCashFlow cf,
		(SELECT SecurityID, EndYear, QuaterNum, NetOperateCF FROM #TempCashFlow) lq	-- 上个季度的现金流量表
	WHERE
		lq.SecurityID = cf.SecurityID
		AND lq.EndYear = cf.EndYear
		AND (cf.QuaterNum = '1' or cf.QuaterNum%4 = (lq.QuaterNum+1)%4)
		AND cf.SecurityID IN (SELECT SecurityID FROM #TempSecurityList)

	UPDATE #TempCashFlow
	SET
		ttmNetOperateCF = cf.NetOperateCF + d.DeltaCF,
		ttmCapExp = cf.CapExp + d.DeltaCapExp,
		ttmDA= cf.DA + d.DeltaDA
	FROM 
		#TempCashFlow cf,
		(SELECT 
			a.SecurityID, a.EndYear, a.QuaterNum,
			(b.NetOperateCF - a.NetOperateCF) AS DeltaCF,
			(b.CapExp - a.CapExp) AS DeltaCapExp, (b.DA - a.DA) AS DeltaDA
		 FROM #TempCashFlow a, #TempCashFlow b		-- 去年CashFlow Table，用于计算ttmCF
		 WHERE
			a.SecurityID = b.SecurityID
			AND a.EndYear = b.EndYear
			AND b.QuaterNum = '4') d
	WHERE
		d.SecurityID = cf.SecurityID
		AND (cf.EndYear = d.EndYear+1 AND cf.QuaterNum = d.QuaterNum)
		AND cf.SecurityID IN (SELECT SecurityID FROM #TempSecurityList)

	UPDATE #TempCashFlow SET ttmNetOperateCF = cf.NetOperateCF, ttmCapExp = cf.CapExp, ttmDA = cf.DA
	FROM #TempCashFlow cf WHERE cf.QuaterNum = '4'

	UPDATE cf1 SET ttmDA = cf2.ttmDA
	FROM #TempCashFlow cf1, #TempCashFlow cf2 
	WHERE cf1.QuaterNum = '1' AND cf2.QuaterNum = '4' AND cf1.EndYear = cf2.EndYear+1
		AND cf1.SecurityID = cf2.SecurityID 

	UPDATE cf1 SET ttmDA = cf2.ttmDA
	FROM #TempCashFlow cf1, #TempCashFlow cf2 
	WHERE cf1.QuaterNum = '3' AND cf2.QuaterNum = '2' AND cf1.EndYear = cf2.EndYear
		AND cf1.SecurityID = cf2.SecurityID 

	SELECT * FROM #TempCashFlow ORDER BY EndDate, IssueDate, SecurityID

GO

*/
