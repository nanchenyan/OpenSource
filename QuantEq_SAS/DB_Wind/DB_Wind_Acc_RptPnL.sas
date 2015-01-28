%macro DB_Wind_Acc_RptPnL(	dsn=&DBWIND_dsn.,
															database=&DBWIND_database.,
															uid=&DBWIND_uid.,
															pwd=&DBWIND_pwd.,
															table=TB_OBJECT_1854,
															startDate=,
															endDate=&today.,
															outset=_Acc_RptProfit, 
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
				F1_1854							as ComID,
				F5_1854							as ComType,
				F2_1854							as RptDate,									/*������*/
				F3_1854							as PubDate,									/*��������*/
				CONVERT(char(10), 
				t1.RP_GEN_DATETIME, 112)
														as GenDate,
				F4_1854							as RptType,									/*	��������*/
				F6_1854							as IsNewPolicy,
				F9_1854							as OperIncome,							/*	 Ӫҵ����*/
				CASE 
					WHEN F10_1854 IS NOT NULL THEN F10_1854			/* Ӫҵ�ɱ� F10_1854	*/
					ELSE F27_1854																	/* ������ҵΪӪҵ֧�� F27_1854 */		
				END	
														as OperCost,		
																	
				F48_1854						as OperPnL,									/* Ӫҵ���� (preTax)*/
				F24_1854						as OthOperPnL,							/* ������Ӫ������	 */
				CASE 
					WHEN F55_1854 > 0.1 THEN 
						F48_1854*(1 - coalesce(F56_1854,0) / F55_1854)	/* Deduct Tax */
					ELSE
						F48_1854 																		/* No Tax */
				END			
														as NOPAT,										/* ˰��Ӫҵ����NOPAT��*/
			
				F60_1854						as NI,												/*	 ������Total��*/
				F61_1854						as NIexMinor,								/*	 ������ȥ�������ɶ����棩*/
				F55_1854 						as TotalProfit,								/* ˰ǰ�����ܶȥ��˰ǰ�����ɶ����棩*/
				F56_1854						as IncomeTax,								/*	 ����˰ */
				coalesce
				(
					F18_1854, 																			/* ��:������� */
					F14_1854																			/* ��Ϣ������ for financial*/
				)										as InterestExp,								/*  ��Ϣ����*/
				/* Other Key Figures */
				F80_1854						as EPS,
				F81_1854						as EPSdilut
				
				from
					tb_object_1854 t1 left join TB_OBJECT_1090
					on  F1_1854 = OB_REVISIONS_1090 
				WHERE
					substring(F4_1854,1,4) = '�ϲ�����'
					and F4_1090='A'					/* ChinaA Share						*/
					and F3_1854 is not null		/* DisclosureDate is not null 	*/
					and F1_1854 is not null		/* ComID is not null					*/
					and F7_1854 = 1					/*  ���к����� ,���й�˾�蹫������ǰ3���������		*/
					and substring(F2_1854,1,4) >= 2003
																	/* Only stats after year 2003 */
					%if "&startDate"^="" %then %do; 
						and F2_1854>= &startDate.
					%end; 
					%if "&endDate."^="" %then %do; 
						and F2_1854 <= &endDate.
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
*/

%ClearLabel(lib=&libRef., data=outset);
data &outset.; set &libRef..outset; run;

%ClearLabel(lib=&libRef, data=outset);
data &outset; set &libRef..outset; run;
*==========================================================; 
*standard header for debugging and temporary data folder; 
%DeleteLocalFolder(LibRef=&libRef, KeepTempLib=&optionon);
options source notes errors=1;
options symbolgen mlogic mprint; 
%mend DB_Wind_Acc_RptPnL; 
/*
%let startDate = 20041231;
%let endDate = &today;
%let libref = inset;
%let inset_prc=mktData._asharedateprc;
%let outset=noa;
%let exportfolder=;
*/

/*

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SP_QUERY_TEMPPROFIT' AND type = 'P')
	DROP PROCEDURE SP_QUERY_TEMPPROFIT
GO

CREATE PROCEDURE [dbo].[SP_QUERY_TEMPPROFIT]
@startDate varchar(8), @endDate varchar(8)
AS	

	IF exists (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb..#TempSecurityList') and type = 'U')
		DROP TABLE #TempSecurityList
	SELECT DISTINCT 
		F2_1090				AS SecurityID,	-- ֤ȯID
		F16_1090			AS Symbol,
		OB_REVISIONS_1090	AS FirmID		-- ��˾ID
	INTO #TempSecurityList
	FROM 
		WindDB.wind.dbo.TB_OBJECT_1090,
		(SELECT distinct F1_1402, F2_1402, F3_1402, F4_1402 FROM WindDB.wind.dbo.TB_OBJECT_1402
		 WHERE F2_1402 IN ('1A0001', '2C01')) sec
	WHERE F2_1090 = F1_1402 AND F16_1090 NOT LIKE '900%'

	--SELECT * FROM #TempSecurityList WHERE SecurityID = 'S3883219' ORDER BY Symbol

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
	--SELECT * FROM #TempReportDate

	-- ��ȡ������е���Ϣ
	IF exists (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb..#TempProfit') and type = 'U')
		DROP TABLE #TempProfit

	SELECT
		distinct 
		SecurityID,
		F6_1854 AS IsNewPolicy,
		convert(varchar(8), dateadd(year, -1, cast(F2_1854 as datetime)), 112) AS 'StartDate',
		F2_1854							AS 'EndDate',
		F3_1854							AS 'IssueDate',
		F9_1854							AS 'OperateIncome',		-- Ӫҵ����
		CASE 
			WHEN F10_1854 IS NULL THEN F27_1854 
			ELSE F10_1854 END	AS 'OperateCost',					-- ������ҵΪӪҵ֧����F27_1854������ΪӪҵ�ɱ���F10_1854
		F48_1854						AS 'OperateProfit',				-- Ӫҵ����˰ǰ��
		CASE 
			WHEN F55_1854 > 0.1 THEN F48_1854*(1-isnull(F56_1854,0)/F55_1854)
			ELSE F48_1854 END			AS 'OperateProfitAT',	-- ˰��Ӫҵ����NOPAT��
		F61_1854						AS 'NetProfit',						-- ������ȥ�������ɶ����棩
		CASE 
			WHEN F55_1854 > 0.1 THEN F55_1854-isnull(F62_1854,0)/(1-isnull(F56_1854,0)/F55_1854)
			ELSE F55_1854 END			AS 'TotalProfit',				-- ˰ǰ�����ܶȥ��˰ǰ�����ɶ����棩
		isnull(F18_1854, F14_1854)		AS 'InterestFee',	-- ��Ϣ����
		EndYear,
		QuaterNum,
		RP_GEN_DATETIME
	INTO #TempProfit
	FROM
		WindDB.wind.dbo.TB_OBJECT_1854,						-- �����
		(SELECT distinct FirmID, SecurityID FROM #TempSecurityList) sec,
		#TempReportDate d
	WHERE
		sec.FirmID collate Chinese_PRC_CI_AS = F1_1854 AND F7_1854 = '1' 
																								--�Ƿ����к����ݣ����й�˾�蹫������ǰ3���������
		AND F2_1854 = d.EndDate
		AND F4_1854 = '�ϲ�����' AND F3_1854 IS NOT NULL
		AND ((F3_1854 > @startDate AND F3_1854 <= @endDate) OR (F2_1854 > @startDate AND F2_1854 <= @endDate))

	-- ���ж�ݼ�¼����p.IsNewPolicy = '2'�ļ�¼�Ĺ���ʱ��Ϊ׼
	UPDATE p1
	SET IssueDate = p2.IssueDate
	FROM #TempProfit p1, #TempProfit p2
	WHERE
		p1.SecurityID = p2.SecurityID AND p1.EndDate = p2.EndDate 
		AND p1.IssueDate > p2.IssueDate AND p1.IsNewPolicy = '2' AND p2.IsNewPolicy = '1'

	-- ���ж�ݼ�¼����p.IsNewPolicy = '2'�ļ�¼Ϊ׼
	DELETE p FROM 
		#TempProfit p, 
		(SELECT SecurityID, EndDate FROM #TempProfit GROUP BY SecurityID, EndDate HAVING count(IsNewPolicy) = '2') cp
	WHERE
		p.SecurityID = cp.SecurityID AND p.EndDate = cp.EndDate AND p.IsNewPolicy != '2'

	-- ���ж�ݼ�¼���Բ���ʱ�俿��ļ�¼Ϊ׼
	DELETE p FROM 
		#TempProfit p, 
		(SELECT SecurityID, EndDate, IsNewPolicy, IssueDate, max(RP_GEN_DATETIME) AS RP_GEN_DATETIME FROM #TempProfit 
		 GROUP BY SecurityID, EndDate, IsNewPolicy, IssueDate) cp
	WHERE 
		p.SecurityID = cp.SecurityID AND p.EndDate = cp.EndDate AND p.IsNewPolicy = cp.IsNewPolicy AND p.RP_GEN_DATETIME != cp.RP_GEN_DATETIME
	
	--SELECT * FROM #TempProfit ORDER BY IssueDate, SecurityID, EndDate

	-- ����SQ��ttm profit ����
	ALTER TABLE #TempProfit ADD NetProfitEx decimal(20,4)
	ALTER TABLE #TempProfit ADD SQNetProfit decimal(20,4)
	ALTER TABLE #TempProfit ADD SQNetProfitEx decimal(20,4)
	ALTER TABLE #TempProfit ADD SQOperateIncome decimal(20,4)
	ALTER TABLE #TempProfit ADD SQOperateProfit decimal(20,4)
	ALTER TABLE #TempProfit ADD EBIT decimal(20,4)

	ALTER TABLE #TempProfit ADD ttmNetProfit decimal(20,4)
	ALTER TABLE #TempProfit ADD ttmNetProfitEx decimal(20,4)
	ALTER TABLE #TempProfit ADD ttmOperateIncome decimal(20,4)
	ALTER TABLE #TempProfit ADD ttmOperateProfit decimal(20,4)

	UPDATE #TempProfit SET NetProfitEx = isnull(F17_1158,0)			-- �۳��Ǿ����������ľ�����
	FROM #TempProfit p, WindDB.wind.dbo.TB_OBJECT_1158, (SELECT distinct FirmID, SecurityID FROM #TempSecurityList) sec
	WHERE sec.FirmID collate Chinese_PRC_CI_AS = F1_1158 AND sec.SecurityID = p.SecurityID
		AND F3_1158 collate Chinese_PRC_CI_AS = p.EndDate
		AND p.SecurityID IN (SELECT SecurityID FROM #TempSecurityList)

	-- ����SQ������EBIT��EBI
	UPDATE #TempProfit
	SET
		SQNetProfit = CASE WHEN p.QuaterNum != '1' THEN p.NetProfit - lq.NetProfit ELSE p.NetProfit END,
		SQNetProfitEx = CASE WHEN p.QuaterNum != '1' THEN p.NetProfitEx - lq.NetProfitEx ELSE p.NetProfitEx END,
		SQOperateIncome = 
			CASE WHEN p.QuaterNum != '1' THEN p.OperateIncome - lq.OperateIncome ELSE p.OperateIncome END,
		SQOperateProfit = 
			CASE WHEN p.QuaterNum != '1' THEN p.OperateProfit - lq.OperateProfit ELSE p.OperateProfit END,		
		EBIT = p.TotalProfit + isnull(p.InterestFee,0) 	-- ˰ǰ�����ܶ�-�����ɶ�����+��Ϣ����
		--EBI  = p.NetProfit   + isnull(p.InterestFee,0)  -- ������-�����ɶ�����+��Ϣ����
	FROM 
		#TempProfit p,
		(SELECT SecurityID, EndYear, QuaterNum, NetProfit, NetProfitEx, OperateIncome, OperateProfit FROM #TempProfit) lq 
																						-- ��ȡ�ϸ����ȵ�����ָ��
	WHERE
		lq.SecurityID = p.SecurityID
		AND lq.EndYear = p.EndYear
		AND (p.QuaterNum = '1' or p.QuaterNum%4 = (lq.QuaterNum+1)%4)
		AND p.SecurityID IN (SELECT SecurityID FROM #TempSecurityList)

	-- ����ttm������
	UPDATE #TempProfit
	SET
		ttmNetProfit = p.NetProfit + d.DeltaNP,
		ttmNetProfitEx = p.NetProfitEx + d.DeltaNetProfitEx,
		ttmOperateIncome = p.OperateIncome + d.DeltaOperateIncome,
		ttmOperateProfit = p.OperateProfit + d.DeltaOperateProfit
	FROM 
		#TempProfit p,
		(SELECT 
			a.SecurityID, a.EndYear, a.QuaterNum,
			(b.NetProfit - a.NetProfit) AS DeltaNP,		-- ȥ��DeltaProfit�����ڼ���ttmProfit
			(b.NetProfitEx - a.NetProfitEx) AS DeltaNetProfitEx,
			(b.OperateIncome - a.OperateIncome)	AS DeltaOperateIncome,
			(b.OperateProfit - a.OperateProfit)	AS DeltaOperateProfit
		 FROM #TempProfit a, #TempProfit b
		 WHERE
			a.SecurityID = b.SecurityID --AND a.SecurityID = 'S4063910'
			AND a.EndYear = b.EndYear AND b.QuaterNum = '4') d
	WHERE
		d.SecurityID = p.SecurityID AND (p.EndYear = d.EndYear+1 AND p.QuaterNum = d.QuaterNum)
		AND p.SecurityID IN (SELECT SecurityID FROM #TempSecurityList)

	-- ����ttm�����󣬵�4����Ӧ�����걨�е�NetProfit
	UPDATE #TempProfit
	SET
		ttmNetProfit = p.NetProfit,
		ttmNetProfitEx = p.NetProfitEx,
		ttmOperateIncome = p.OperateIncome,
		ttmOperateProfit = p.OperateProfit
	FROM #TempProfit p
	WHERE p.QuaterNum = '4'

	SELECT * FROM #TempProfit ORDER BY EndDate, IssueDate, SecurityID

GO

*/

