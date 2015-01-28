%macro DB_Wind_Acc_RptBS(	dsn=&DBWIND_dsn.,
														database=&DBWIND_database.,
														uid=&DBWIND_uid.,
														pwd=&DBWIND_pwd.,
														table=TB_OBJECT_1853,
														startDate=,
														endDate=&today.,
														outset=_Acc_RptBS, 
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
					F1_1853							as ComID,
					F5_1853							as ComType,
					F2_1853							as RptDate,			/*报告期*/
					F3_1853							as PubDate,			/*公告日期*/
					CONVERT(char(10), 
					t1.RP_GEN_DATETIME, 112)
															as GenDate,
					F4_1853							as RptType,		/*	报表类型*/
					F6_1853							as IsNewPolicy,
					coalesce(F9_1853,0)									/* General:货币资金*/
					+ coalesce(F47_1853,0)								/* Financial: 现金及存放中央银行款项*/
					+ coalesce(F48_1853,0)								/* Financial: 存放同业和其它金融机构款项 */
															as Cash,
					

					F74_1853						as TotalAsset,

					coalesce(F75_1853,0)								/* General: 短期借款*/
					+ coalesce(F104_1853,0)								/* Financial:同业和其它金融机构存放款项 */
					+ coalesce(F105_1853,0)								/* Financial: 向中央银行借款 */
					+ coalesce(F106_1853,0)								/* Financial: 拆入资金 */	
															as STBorrow, 
					coalesce(F77_1853,0)	as NotePayable,
					coalesce(F88_1853,0)	as DebtwIN1Yr,
					coalesce(F75_1853,0)
						+
					coalesce(F77_1853,0)
						+
					coalesce(F88_1853,0)
															as Debt_ST,
					F94_1853						as Debt_LT,
					F128_1853						as TotalDebt,

					F17_1853						as Inventory,	

					F28_1853						as InvstRE,
					F29_1853						as InvstStock,
					
					F30_1853						as LTRecievable,
					F140_1853						as EquityExMinor,
					F141_1853						as Equity,
					coalesce(F31_1853,0)	as FixedAsset,  
					coalesce(F32_1853,0)	as EngineeringAsset,
					coalesce(F33_1853,0)	as EngineeringinProgress, 
					coalesce(F34_1853,0)	as FixedAssetDisposal, 

					coalesce(F31_1853,0)
						+
					coalesce(F32_1853,0)
															as PPENet	/*FixedAsset+EngineeringAsset*/
				from
					tb_object_1853 t1 left join TB_OBJECT_1090
					on  F1_1853 = OB_REVISIONS_1090 
				WHERE
					substring(F4_1853,1,4) in ('合并报表','合并报表(调整)','合并报表(更正前)')
					and F4_1090='A'					/* ChinaA Share						*/
					and F3_1853 is not null		/* DisclosureDate is not null 	*/
					and F1_1853 is not null		/* ComID is not null					*/
					and F7_1853 = 1					/*  上市后数据 ,上市公司需公布上市前3年财务数据		*/
					and substring(F2_1853,1,4) >= 2003
																	/* Only stats after year 2003 */
					%if "&startDate"^="" %then %do; 
						and F2_1853>= &startDate.
					%end; 
					%if "&endDate."^="" %then %do; 
						and F2_1853 <= &endDate.
					%end; 
		);
	%put &sqlxmsg;
	disconnect from ODBC;
quit;

/* Exception 1: Eliminate multiple Disclosure Date*/
/*
	By Sorting Descending "IsNewPolicy", the NewPolicy ones will be ranked at first 
	and the old or missing one will be dropped. SOLVED.
	ex:
		SecID		ComID				RptDate		PubDate		GenDate		RptType						RptGenDate
	1.	S18541	0499CBBB66	1	20071231	20080411	20090416  	合并报表(更正前)	20080411
	2.	S18541	0499CBBB66	1	20071231	20090416	20090415  	合并报表(调整)		20090415
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
*/


%ClearLabel(lib=&libRef., data=outset);
data &outset.; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Acc_RptBS; 

/*


proc sql; 
	connect to ODBC (noprompt="dsn=&DBZYY_dsn;database=&DBZYY_database;uid=&DBZYY_uid;pwd=&DBZYY_pwd;");
    %put &sqlxmsg;
		create table &libRef..outset as select * from connection to ODBC
		(
			EXEC SP_QUERY_TEMPBALANCE &startdate., &enddate
		);
	%put &sqlxmsg;
	disconnect from ODBC;
quit;

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SP_QUERY_TEMPBALANCE' AND type = 'P')
	DROP PROCEDURE SP_QUERY_TEMPBALANCE
GO

CREATE PROCEDURE [dbo].[SP_QUERY_TEMPBALANCE]
@startDate varchar(8), @endDate varchar(8)
AS

	IF exists (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb..#TempSecurityList') and type = 'U')
		DROP TABLE #TempSecurityList
	SELECT DISTINCT 
		F2_1090				AS SecurityID,	-- 证券ID
		F16_1090			AS Symbol,
		OB_REVISIONS_1090	AS FirmID		-- 公司ID
	INTO #TempSecurityList
	FROM WindDB.wind.dbo.TB_OBJECT_1090,
		(SELECT distinct F1_1402, F2_1402, F3_1402, F4_1402 FROM WindDB.wind.dbo.TB_OBJECT_1402
		 WHERE F2_1402 IN ('1A0001', '2C01')) sec
	WHERE F2_1090 = F1_1402 AND F16_1090 NOT LIKE '900%'
	-- SELECT * FROM #TempSecurityList ORDER BY Symbol

	IF exists (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb..#TempReportDate') and type = 'U')
		DROP TABLE #TempReportDate
	SELECT
		cast(y.CurYear + d.CurDate as datetime) AS 'EndDate',
		cast(y.CurYear as int) AS 'EndYear',
		'QuaterNum' = CASE
			WHEN d.CurDate = '0331' THEN '1'
			WHEN d.CurDate = '0630' THEN '2'
			WHEN d.CurDate = '0930' THEN '3'
			WHEN d.CurDate = '1231' THEN '4'
		END
	INTO #TempReportDate
	FROM
		(SELECT distinct left(F1_1010, 4) AS CurYear FROM WindDB.wind.dbo.TB_OBJECT_1010) y, 
		(SELECT distinct right(F2_1853, 4) AS CurDate FROM WindDB.wind.dbo.TB_OBJECT_1853 WHERE F1_1853 = '1000002') d
	WHERE y.CurYear >= '2002' AND y.CurYear <= datepart(year, getdate())
	ORDER BY y.CurYear, d.CurDate
	--SELECT * FROM #TempReportDate ORDER BY EndDate

	-- 提取资产负债表中的信息
	IF exists (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb..#TempBalanceSheet') and type = 'U')
		DROP TABLE #TempBalanceSheet

	SELECT
		distinct 
		sec.FirmID,
		sec.SecurityID,
		F6_1853 AS IsNewPolicy,
		F2_1853						AS 'EndDate',
		F3_1853						AS 'IssueDate',
		F74_1853					AS 'TotalAsset',
		F128_1853					AS 'TotalDebt',
		F141_1853					AS 'Equity',
		F103_1853					AS 'LongTermDebt',	-- 杠杆类指标对金融类公司无意义
		CASE WHEN F141_1853!='0' THEN F128_1853/F141_1853 END AS 'DebtEquityRatio', -- 默认用合并报表计算，母公司报表更新，因为母公司为具体承担债务法人。
		CASE WHEN F74_1853 != '0' THEN F17_1853/F74_1853 ELSE F74_1853 END AS 'INVT_TO_TA',	-- 存货率,金融类股票无此指标
		(CASE WHEN F25_1853 IS NULL THEN
		isnull(F9_1853,0)+isnull(F10_1853,0)+isnull(F11_1853,0)+isnull(F12_1853,0)+isnull(F13_1853,0)+isnull(F14_1853,0)
		+isnull(F15_1853,0)+isnull(F16_1853,0)+isnull(F17_1853,0)+isnull(F18_1853,0)+isnull(F19_1853,0)+isnull(F20_1853,0)
		+isnull(F21_1853,0)	ELSE F25_1853 END) - 
		(CASE WHEN F93_1853 IS NULL THEN
		isnull(F75_1853,0)+isnull(F76_1853,0)+isnull(F77_1853,0)+isnull(F78_1853,0)+isnull(F79_1853,0)+isnull(F80_1853,0)
		+isnull(F81_1853,0)+isnull(F82_1853,0)+isnull(F83_1853,0)+isnull(F84_1853,0)+isnull(F85_1853,0)
		+isnull(F87_1853,0)+isnull(F88_1853,0)+isnull(F89_1853,0)
		ELSE F93_1853 END)			AS 'OperateCap',
	--	F25_1853-F93_1853			AS 'OperateCap',	-- 营运资本:流动资产-流动负债，金融类证券报表不公布流动资产，流动负债合计
		F140_1853								AS 'EquityExMinor',	-- 股东权益(不含少数股东)
		F74_1853										-- 总资产
		- (isnull(F77_1853,0)+isnull(F78_1853,0)+isnull(F79_1853,0)+isnull(F80_1853,0)+isnull(F81_1853,0)
			+isnull(F82_1853,0)+isnull(F83_1853,0)+isnull(F84_1853,0) +isnull(F85_1853,0)) -- 所有应付+预收+预提（流动无息）
		- (isnull(F103_1853,0)-isnull(F94_1853,0)-isnull(F95_1853,0)) -- 非流动合计负债-长期借款-应付债券（非流动无息）
														AS 'InvestCapital',	-- 投入资本，对金融类股票无效?（无流动非流动负债概念）
		isnull(F75_1853,0)+isnull(F76_1853,0)+isnull(F77_1853,0)+isnull(F94_1853,0)
		+isnull(F88_1853,0)+isnull(F95_1853,0)-isnull(F9_1853,0)AS 'NetDebt', -- 净债务，用于计算EV
		F74_1853 - isnull(F9_1853,0)	AS 'OperAsset',
		F128_1853 - isnull(F94_1853,0) - isnull(F75_1853,0)+isnull(F77_1853,0)+isnull(F88_1853,0) -- LTDebt,STBorrow,Notespayable,Debtin1Yr
									AS 'OperLiab',
		EndYear,
		QuaterNum,
		RP_GEN_DATETIME
	INTO #TempBalanceSheet
	FROM
		WindDB.wind.dbo.TB_OBJECT_1853,	-- 资产负债表
		(SELECT distinct FirmID, SecurityID FROM #TempSecurityList) sec,
		#TempReportDate d
	WHERE
		sec.FirmID collate Chinese_PRC_CI_AS = F1_1853 AND F7_1853 = '1' --是否上市后数据
		AND F2_1853 = d.EndDate
		AND F4_1853 = '合并报表' AND F3_1853 IS NOT NULL
		AND ((F3_1853 > @startDate AND F3_1853 <= @endDate) OR (F2_1853 > @startDate AND F2_1853 <= @endDate))

	UPDATE b1 SET IssueDate = b2.IssueDate
	FROM #TempBalanceSheet b1, #TempBalanceSheet b2
	WHERE
		b1.SecurityID = b2.SecurityID AND b1.EndDate = b2.EndDate 
		AND b1.IssueDate > b2.IssueDate AND b1.IsNewPolicy = '2' AND b2.IsNewPolicy = '1'

	DELETE b FROM 
		#TempBalanceSheet b, 
		(SELECT SecurityID, EndDate FROM #TempBalanceSheet GROUP BY SecurityID, EndDate HAVING count(IsNewPolicy) = '2') cb
	WHERE 
		b.SecurityID = cb.SecurityID AND b.EndDate = cb.EndDate AND b.IsNewPolicy != '2'

	DELETE b FROM 
		#TempBalanceSheet b, 
		(SELECT SecurityID, EndDate, IsNewPolicy, IssueDate, max(RP_GEN_DATETIME) AS RP_GEN_DATETIME FROM #TempBalanceSheet 
		 GROUP BY SecurityID, EndDate, IsNewPolicy, IssueDate) cb
	WHERE 
		b.SecurityID = cb.SecurityID AND b.EndDate = cb.EndDate AND b.IsNewPolicy = cb.IsNewPolicy AND b.RP_GEN_DATETIME != cb.RP_GEN_DATETIME
	--SELECT * FROM #TempBalanceSheet ORDER BY SecurityID, EndDate, IsNewPolicy, IssueDate

	UPDATE #TempBalanceSheet
	SET DebtEquityRatio = CASE WHEN F141_1853!='0' THEN F128_1853/F141_1853 END -- 母公司负债/母公司股东权益
	FROM #TempBalanceSheet b, WindDB.wind.dbo.TB_OBJECT_1853
	WHERE
		b.FirmID collate Chinese_PRC_CI_AS = F1_1853 AND F7_1853 = '1' -- 是否为上市后数据
		AND F3_1853 > @startDate AND F3_1853 <= @endDate
		AND b.EndDate collate Chinese_PRC_CI_AS = F2_1853
		AND F4_1853 = '母公司报表'

	-- Exception: 600703, 2007-12-31, 资本要素为0
	DELETE FROM #TempBalanceSheet WHERE TotalAsset='0' OR EquityExMinor IS NULL OR EquityExMinor = '0'
	DELETE FROM #TempBalanceSheet WHERE SecurityID = 'S3592424' AND EndDate < '20070101' -- wind中混入上市前数据

	SELECT * FROM #TempBalanceSheet ORDER BY EndDate, IssueDate, SecurityID

GO

*/
