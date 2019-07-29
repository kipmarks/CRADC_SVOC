/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 131_excl_open_and_recent_ccom_interventions.sas

Overview:     STUB ONLY - Awaiting implementation
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/
%put INFO-131_open_and_recent_ccom_interventions.sas: STUB ONLY;
%GetStarted;
/*********************************************************************************************************************************/
/* 	----------------------- Customer Risk Review CCOM interventions within START -----------------------  *\
/* Extracting the data for advisory visit cases within START that are still currently open - only want to exclude them
if they are currently open
There are currently none open but Aaron spoke to someone from CCOM who recommended including this.
Want to keep the advisory visit seperate from the customer risk review as some people may not want these excluded*/
/*********************************************************************************************************************************/
PROC SQL;
  CREATE TABLE WORK.CCOM_VSTADV_CASES AS 
        SELECT 
      DISTINCT CUSTOMER_KEY,
               IRD_NUMBER,
               CASE WHEN CLOSED IS NULL THEN 'Y' ELSE '' END AS OPEN_CCOM_ADVISORYVISIT,
               CASE_TYPE AS VSTADV_CASE_TYPE,
               'Customer advisory visit' AS VSTADV_CASE_TYPE_DESC,
               STAGE AS VSTADV_CASE_STAGE
          FROM TDW_CURR.TBL_ALL_CASES 
         WHERE EFFECTIVE_TO eq . AND
               CLOSED IS NULL AND
               CURRENT_REC_FLAG = 'Y' AND
               ABORTED IS NULL AND
               IRD_NUMBER IS NOT NULL AND
               CASE_TYPE = 'VSTADV';
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=CCOM_VSTADV_CASES OUT=CCOM_VSTADV_CASES_2; BY CUSTOMER_KEY IRD_NUMBER DESCENDING OPEN_CCOM_ADVISORYVISIT; RUN;
/*********************************************************************************************************************************/
DATA START_CCOM_VSTADV_CASES;
 SET WORK.CCOM_VSTADV_CASES_2;
BY CUSTOMER_KEY IRD_NUMBER DESCENDING Open_CCom_AdvisoryVisit;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;
PROC SORT DATA=START_CCOM_VSTADV_CASES; BY IRD_NUMBER;RUN;
PROC DATASETS LIB=WORK NOLIST; DELETE CCOM_VSTADV_CASES CCOM_VSTADV_CASES_2; RUN;
/*********************************************************************************************************************************/
/* 	----------------------- Customer Risk Review CCOM interventions within START -----------------------  *\
/* Extracting the data for cases within START that are still currently open or closed within the past 2 years */
/*********************************************************************************************************************************/
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP);
CREATE TABLE WORK.CCOM_CCRSRW_CASES AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT 
      DISTINCT CAS.CUSTOMER_KEY,
               CAS.IRD_NUMBER,
               CASE WHEN CAS.CLOSED IS NULL THEN 'Y' ELSE '' END AS OPEN_CCOM_CUSRISKREVIEW,
               CAS.CLOSED AS CCOM_CCRSRW_CLOSED_DATE,
               CASE WHEN CAS.CLOSED IS NULL THEN '' ELSE 'Y' END AS RECENT_CCOM_CUSRISKREVIEW,
               CASE WHEN CAS.CLOSED IS NOT NULL THEN (ROUND(MONTHS_BETWEEN(SYSDATE,CAS.CLOSED),0)) ELSE NULL END AS MONTHS_CLOSED_CCOM_CCRSRW,
               CAS.CASE_TYPE AS CCRSRW_CASE_TYPE,
               'Customer risk review' AS CCRSRW_CASE_TYPE_DESC,
               CAS.CASE_CATEGORY AS CCRSRW_CASE_CATEGORY,
               CAS.STAGE AS CCRSRW_STAGE
          FROM TDW.TBL_ALL_CASES_VALL CAS
         WHERE (CAS.EFFECTIVE_TO IS NULL OR CAS.EFFECTIVE_TO = '') AND
               (ROUND(MONTHS_BETWEEN(SYSDATE,CAS.CLOSED),0) <= 24 OR CAS.CLOSED IS NULL) AND
               CAS.CURRENT_REC_FLAG = 'Y' AND
               CAS.ABORTED IS NULL AND
               CAS.IRD_NUMBER IS NOT NULL AND
               CAS.CASE_TYPE = 'CCRSRW');
DISCONNECT FROM MYORACON;
RUN;

PROC SORT DATA=CCOM_CCRSRW_CASES OUT=CCOM_CCRSRW_CASES_2;
BY CUSTOMER_KEY IRD_NUMBER DESCENDING Open_CCom_CusRiskReview DESCENDING CCOM_CCRSRW_CLOSED_DATE;
RUN;

DATA START_CCOM_CCRSRW_CASES;
SET WORK.CCOM_CCRSRW_CASES_2;
BY CUSTOMER_KEY IRD_NUMBER DESCENDING Open_CCom_CusRiskReview DESCENDING CCOM_CCRSRW_CLOSED_DATE;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;

PROC SORT DATA=START_CCOM_CCRSRW_CASES; BY IRD_NUMBER;RUN;

PROC DATASETS LIB=WORK NOLIST; DELETE CCOM_CCRSRW_CASES CCOM_CCRSRW_CASES_2; RUN;

/* -------------- CCom interventions within eCase  ------------- *\

Checked in with Jason Stewart (CCOM team leader) and while there are some ccom cases still open in eCase,
no one is working in ecase anymore and are moved to START. Therefore only need to look at the closed ones
to get those closed within the past 2 years. The most recent ones were closed 14 months ago, so next year 
will be able to get rid of the ecase stuff.

/* Extracting the data for CCom cases within eCases that have been closed in the last 2 years (24 months) */
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=DWP);
CREATE TABLE CCOM_ECASE 		AS
select * from connection to myoracon
(
SELECT  CCO.IRD_NUMBER,
CUS.CUSTOMER_KEY,
		CCO.LOCATION_NUMBER,
		CASE WHEN CCO.CASE_CLOSED_DATE IS NULL THEN '' ELSE 'Y' END AS Recent_CCom_ECase,

		CCO.CASE_SUB_TYPE_DESC,
 		CCO.CASE_OPEN_REASON_DESC 	AS CCOM_CASE_OPEN_REASON,
		CCO.CASE_SUB_TYPE_DESC    	AS CCOM_CASE_SUB_TYPE,
		CCO.CASE_CLOSE_REASON_DESC 	AS CCOM_CASE_CLOSE_REASON, 

		CASE WHEN CCO.CASE_CLOSED_DATE IS NOT NULL THEN (ROUND(months_between(sysdate,CCO.CASE_CLOSED_DATE),0)) ELSE NULL END AS MONTHS_CLOSED_CCOM_ECASE,
		CCO.CASE_CLOSED_DATE 		AS CCOM_CASE_CLOSED_DATE

FROM 	DSS.CM_COMPLIANCE_CASES_VALL	CCO

JOIN TDW.TBL_CUSTOMERINFO_VALL			CUS
ON CCO.IRD_NUMBER 						= CUS.IRD_NUMBER

WHERE 	CCO.DATE_CEASED             	IS  NULL
 AND	(ROUND(months_between(sysdate,CCO.CASE_CLOSED_DATE),0) <= 24)
 AND	CCO.IRD_NUMBER 				 	 > 	0
order by 1
);
disconnect from myoracon;
run;


PROC SORT DATA=CCOM_ECASE OUT=CCOM_ECASE_2;
BY IRD_NUMBER DESCENDING CCOM_CASE_CLOSED_DATE;
RUN;


DATA ECASE_CCOM_CASES;
SET WORK.CCOM_ECASE_2;
BY IRD_NUMBER DESCENDING CCOM_CASE_CLOSED_DATE;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;

PROC SORT DATA=ECASE_CCOM_CASES; BY IRD_NUMBER;RUN;

PROC DATASETS LIB=WORK NOLIST; DELETE CCOM_ECASE CCOM_ECASE_2; RUN;


/* Subject code 369 (proactive advisories) is another way that ccom log visits */


proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=DWP);
CREATE TABLE CCOM_369_FIRST 		AS
select * from connection to myoracon
(
SELECT DISTINCT
CLC.IRD_NUMBER,
		CUS.CUSTOMER_KEY,
		CLC.DATE_LODGED,
        'Y' AS  RECENT_CCOM_FIRST,
		ROUND(months_between(sysdate,CLC.DATE_LODGED),0) AS MONTHS_CLOSED_CCOM_FIRST

FROM 	DSS.CORRESPONDENCE_INBOUND_VALL						CLC

JOIN TDW.TBL_CUSTOMERINFO_VALL		CUS

ON CLC.IRD_NUMBER 				= CUS.IRD_NUMBER


WHERE 	(ROUND(months_between(sysdate,CLC.DATE_LODGED),0) 	<= 24)
AND		CLC.SUBJECT_CODE			 						=  369
order by 1
);
disconnect from myoracon;
run;

PROC SORT DATA=CCOM_369_FIRST OUT=CCOM_369_FIRST_2;
BY IRD_NUMBER  MONTHS_CLOSED_CCOM_FIRST;
RUN;

DATA FIRST_CCOM_369_CASES;
SET WORK.CCOM_369_FIRST_2;
BY IRD_NUMBER MONTHS_CLOSED_CCOM_FIRST;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;

PROC DATASETS LIB=WORK NOLIST; DELETE CCOM_369_FIRST CCOM_369_FIRST_2; RUN;

PROC SORT DATA=FIRST_CCOM_369_CASES; BY IRD_NUMBER;RUN;



DATA CCOM_INTERVENTIONS2;
MERGE START_CCOM_VSTADV_CASES START_CCOM_CCRSRW_CASES ECASE_CCOM_CASES FIRST_CCOM_369_CASES;
BY IRD_NUMBER CUSTOMER_KEY; RUN;


/*											Final open/recent CCOM table														*/

/* If there is an open customer risk review or advisory visit case in START then CComCurrentlyOpen = Y. 						*/

/* For the recently closed, there are three fields: RecentCComCusRiskReview, RecentCComECase and RecentCComFirst.
/* And three fields more months closed: MonthsClosedCComCusRiskReview, MonthsClosedCComECase and MonthsClosedCComFirst.			*/

/* ECASE hasn't been used for over a year now, so for the campaigns exclusions where we currently only exclude them if they are */
/* open, or closed in past two months, don't need to include the ecase stuff. The ecase stuff is just included if you are 		*/	
/* interested in past 2 years. As of Apr 19, the most recently closed ecase was 16 months ago.									*/	


/* If you did want to look over all of them, would need to do:	

/* eg. case when CComCurrentlyOpen = 'Y' or (RecentCComCusRiskReview = 'Y' and MonthsClosedCComCusRiskReview <= 2) 				*/
/*									  	 or (RecentCComECase = 'Y' and MonthsClosedCComECase <= 2)								*/
/*										 or (RecentCComFirst = 'Y' and MonthsClosedCComFirst <= 2) 								*/
/*																			then 'Y' else 'N' end as CurrentAuditCCOMLTSCase	*/

/* Also included a field on whether the open ccom case is an advisory visit or a customer risk review in case people 			*/
/* dont care about the advisory visits (OpenCComCusRiskReview and OpenCComAdvisoryVisit).										*/

/* For these ecase ccom cases, START cases and FIRST phone calls, I have ordered each by open case and then date closed 		*/
/* descending and then chosen the first line per ird number to get it down to one line per customer. This means that I only 	*/
/* have the details of the currently open case, or the most recently closed case for each person for each of the data sources	*/
/* (start, ecase and first).																									*/


PROC SQL;
CREATE TABLE CCOM_OPEN_AND_RECENT AS
SELECT DISTINCT

ird_number,
customer_key,

/* Overall Open CCOM */

CASE WHEN (Open_CCom_AdvisoryVisit 	 = 'Y' OR Open_CCom_CusRiskReview = 'Y') THEN 'Y' ELSE '' END AS CComCurrentlyOpen,

/*Recent and Open Customer Risk Review*/

Open_CCom_CusRiskReview 	as OpenCComCusRiskReview,
recent_ccom_CusRiskReview 	as RecentCComCusRiskReview,
MONTHS_CLOSED_CCOM_CCRSRW 	as MonthsClosedCComCusRiskReview,
CCRSRW_STAGE				as CusRiskReviewStage,
CCRSRW_CASE_TYPE			as CusRiskReviewCaseType,
CCRSRW_CASE_TYPE_DESC		as CusRiskReviewCaseTypeDesc,

/*Open Advisory Visit - don't care about recent ones*/

Open_CCom_AdvisoryVisit 	as OpenCComAdvisoryVisit,
VSTADV_CASE_STAGE			as AdvisoryVisitStage,
VSTADV_CASE_TYPE			as AdvisoryVisitCaseType,
VSTADV_CASE_TYPE_DESC		as AdvisoryVisitCaseTypeDesc,

/*Recent eCase CCOM*/

recent_ccom_ecase			as RecentCComECase,
MONTHS_CLOSED_CCOM_ECASE	as MonthsClosedCComECase,
case_sub_type_desc			as CComECaseSubType,

/*Recent FIRST CCOM*/

recent_ccom_first			as RecentCComFirst,
MONTHS_CLOSED_CCOM_FIRST	as MonthsClosedCComFirst

FROM CCOM_INTERVENTIONS2;
RUN;

PROC DATASETS LIB=WORK NOLIST; DELETE FIRST_CCOM_369_CASES ECASE_CCOM_CASES START_CCOM_CCRSRW_CASES START_CCOM_VSTADV_CASES CCOM_INTERVENTIONS2; RUN;


DATA EXCLTEMP.CCOM_OPEN_AND_RECENT; SET CCOM_OPEN_AND_RECENT; RUN;

%ErrCheck;


