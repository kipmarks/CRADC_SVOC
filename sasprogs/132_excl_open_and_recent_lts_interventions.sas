/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 132_excl_open_and_recent_lts_interventions.sas

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
%put INFO-132_open_and_recent_lts_interventions.sas: STUB ONLY;

%GetStarted;


/* 	----------------------- Legal Cases within START -----------------------  *\

/* Extracting the data for 'legal' type cases within START that are still currently open or closed within the past 2 years */

PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP);
CREATE TABLE WORK.LTS_CASES AS SELECT * FROM CONNECTION TO MYORACON (

SELECT DISTINCT 
CAS.CUSTOMER_KEY,
CAS.IRD_NUMBER,

CASE WHEN CAS.CLOSED IS NULL THEN 'Y' ELSE '' END AS Open_Legal_Type_Start_Case,
CAS.CLOSED AS START_LEGAL_DATE_CLOSED,
CASE WHEN CAS.CLOSED IS NULL THEN '' ELSE 'Y' END AS Recent_Legal_Type_Start_Case,
CASE WHEN CAS.CLOSED IS NOT NULL THEN (ROUND(MONTHS_BETWEEN(SYSDATE,CAS.CLOSED),0)) ELSE NULL END AS Legal_Type_Case_Months_Closed,

CAS.CASE_KEY,
CAS.CASE_TYPE as Legal_Case_Type,

CASE WHEN CASE_TYPE = 'CTACSE' THEN 'Critical Task Assurance'
     WHEN CASE_TYPE = 'TIGISS' THEN 'TIG Issues'
     WHEN CASE_TYPE = 'FTAPRS' THEN 'FTA Prosecution Review'
     WHEN CASE_TYPE = 'FTFPRS' THEN 'FTF Prosecution Review'
     WHEN CASE_TYPE = 'OPIADV' THEN 'Opinion or Advice'
     WHEN CASE_TYPE = 'TRFPRC' THEN 'Transfer Pricing ACR'
     WHEN CASE_TYPE = 'ESCALA' THEN 'OCTC Escalations and Advising'
     WHEN CASE_TYPE = 'MGMT'   THEN 'General Legal Management'
     WHEN CASE_TYPE = 'LITPRO' THEN 'Litigation & Prosecution'
     WHEN CASE_TYPE = 'DRUOCT' THEN 'OCTC Disputes Review'
     WHEN CASE_TYPE = 'BINDRU' THEN 'OCTC Taxpayer Rulings'
     WHEN CASE_TYPE = 'PUBSTM' THEN 'Published Statements'
     WHEN CASE_TYPE = 'RECRET' THEN 'Record Retention Exemption'
     WHEN CASE_TYPE = 'PUBRUL' THEN 'OCTC Public Rulings'
     WHEN CASE_TYPE = 'ESCADV' THEN 'OCTC Escalations and Advising'
     ELSE 'Other' END AS Legal_Type_Case_Desc,

CAS.CASE_CATEGORY	as Legal_case_category,
CAS.STAGE         				AS Legal_Type_Case_Stage

FROM TDW.TBL_ALL_CASES_VALL     CAS

WHERE (CAS.EFFECTIVE_TO IS NULL 					OR CAS.EFFECTIVE_TO = '') 

AND	(ROUND(months_between(sysdate,CAS.CLOSED),0) 	<= 24 OR CAS.CLOSED IS NULL)
AND CAS.CURRENT_REC_FLAG 							= 'Y' 
AND CAS.ABORTED 									IS NULL
AND CAS.IRD_NUMBER 									IS NOT NULL 
AND CAS.CASE_CATEGORY = 'Legal'
/*AND CAS.CASE_TYPE IN ('CTACSE','TIGISS','FTAPRS','FTFPRS','OPIADV','TRFPRC','ESCALA','MGMT','LITPRO','DRUOCT','BINDRU','PUBSTM')*/
);
DISCONNECT FROM MYORACON;
RUN;

PROC SORT DATA=LTS_CASES OUT=LTS_CASES_2;
BY CUSTOMER_KEY IRD_NUMBER DESCENDING Open_Legal_Type_Start_Case DESCENDING START_LEGAL_DATE_CLOSED;
RUN;

DATA START_LTS_CASES;
SET WORK.LTS_CASES_2;
BY CUSTOMER_KEY IRD_NUMBER DESCENDING Open_Legal_Type_Start_Case DESCENDING START_LEGAL_DATE_CLOSED;
IF FIRST.IRD_NUMBER THEN OUTPUT;

RUN;

PROC DATASETS LIB=WORK NOLIST; DELETE LTS_CASES LTS_CASES_2; RUN;

PROC SORT DATA=START_LTS_CASES;BY IRD_NUMBER;RUN;

/* ------------------ LTS interventions within eCase ------------------ *\


/* Extracting the data for CCom cases within eCases that have been closed in the last 2 years (24 months)
No work done in ecase anymore so only getting the 'recent' cases. Should be able to get rid of this soon
when the last closed one is outside of 24 months */

proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=DWP);
CREATE TABLE LTS_ECASE 		AS
select * from connection to myoracon
(
SELECT

 		LTS.IRD_NUMBER,
		CUS.CUSTOMER_KEY,
		LTS.LOCATION_NUMBER,
		CASE WHEN LTS.CASE_CLOSED_DATE IS NULL THEN 'N' ELSE 'Y' END AS RECENT_LTS_ECASE,
		LTS.CASE_CLOSED_DATE		AS LTS_ECASE_CLOSED_DATE,
		CASE WHEN LTS.CASE_CLOSED_DATE IS NOT NULL THEN (ROUND(months_between(sysdate,LTS.CASE_CLOSED_DATE),0)) ELSE NULL END AS LTS_ECASE_MONTHS_CLOSED,
		LTS.CASE_SUB_TYPE_DESC		AS	LTS_ECASE_SUB_TYPE,
/*		LTS.SUB_GROUP				AS  LTS_ECASE_SUB_GROUP,*/
		LTS.CASE_OPEN_REASON_DESC	AS	LTS_ECASE_OPEN_REASON,
		LTS.CASE_CLOSE_REASON_DESC	AS	LTS_ECASE_CLOSE_REASON

FROM 	DSS.CM_LTS_CASES_VALL		LTS

JOIN 	TDW.TBL_CUSTOMERINFO_VALL	CUS
ON 		LTS.IRD_NUMBER 				= CUS.IRD_NUMBER

WHERE 	LTS.DATE_CEASED             IS  NULL
 AND	(ROUND(months_between(sysdate,LTS.CASE_CLOSED_DATE),0) <= 24)
 AND	LTS.IRD_NUMBER 				 	 > 	0
order by 1
);
disconnect from myoracon;
run;

PROC SORT DATA=LTS_ECASE OUT=LTS_ECASE_2;
BY IRD_NUMBER DESCENDING LTS_ECASE_CLOSED_DATE;
RUN;

DATA ECASE_LTS_CASES;
SET WORK.LTS_ECASE_2;
BY IRD_NUMBER DESCENDING LTS_ECASE_CLOSED_DATE;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;

PROC DATASETS LIB=WORK NOLIST; DELETE LTS_ECASE LTS_ECASE_2; RUN;

PROC SORT DATA=ECASE_LTS_CASES;BY IRD_NUMBER;RUN;



DATA LEGAL_INTERVENTIONS2 (drop=LTS_ECASE_CLOSED_DATE START_LEGAL_DATE_CLOSED LOCATION_NUMBER);
MERGE START_LTS_CASES ECASE_LTS_CASES; BY IRD_NUMBER CUSTOMER_KEY;
RUN;
	

/*										      	Final open/recent LTS table								 								*/

/* This looks at the open and recent cases in START with a case category of 'Legal', and the recently closed ecase LTS cases. 			*/
/* There are three fields: RecentLTSECase, OpenLegalTypeStartCase, RecentLegalTypeStartCase. 
/* Then have the months closed data in LTSECaseMonthsClosed and LegalTypeCaseMonthsClosed.

/* ECASE hasn't been used for over a year now, so for the campaigns exclusions where we currently only exclude them if they are 		*/
/* open, or closed in past two months, don't need to include the ecase stuff. The ecase stuff is just included if you are 				*/	
/* interested in past 2 years. As of Apr 19, the most recently closed ecase was 15 months ago.											*/	

/* For these ecase cases and START cases, I have ordered it by open case and then date closed descending and then chosen the first line */
/* per ird number. This means that I only have the details of the currently open case, or the most recently closed case for each person.*/
/* Therefore if someone has more than one open Legal type case in START, you will only see the details of one of them 					*/

/*	There are 12 different case types in START under the 'Legal' category (Critical Task Assurance, TIG Issues, FTA Prosecution Review,	*/
/*	FTF Prosecution Review, Opinion or Advice, Transfer Pricing ACR, OCTC Escalations and Advising, General Legal Management, 			*/
/*	Litigation & Prosecution, OCTC Disputes Review, OCTC Taxpayer Rulings and Published Statements). I have included these details for 	*/
/*	each case incase people don't care about any/some of these.																			*/

PROC SQL;
CREATE TABLE ExclTemp.LEGAL_OPEN_AND_RECENT AS
SELECT
ird_number,
customer_key,

/*Recent eCase*/

RECENT_LTS_ECASE 				as RecentLTSECase,
LTS_ECASE_MONTHS_CLOSED			as LTSECaseMonthsClosed,
LTS_ECASE_SUB_TYPE				as LTSECaseSubType,
LTS_ECASE_OPEN_REASON			as LTSECaseOpenReason, 

/*Open and recent 'Legal' type START cases*/

OPEN_LEGAL_TYPE_START_CASE 		as OpenLegalTypeStartCase,
RECENT_LEGAL_TYPE_START_CASE 	as RecentLegalTypeStartCase,
LEGAL_TYPE_CASE_MONTHS_CLOSED 	as LegalTypeCaseMonthsClosed,
LEGAL_CASE_CATEGORY				as LegalCaseCategory,
LEGAL_CASE_TYPE					as LegalCaseType,
LEGAL_TYPE_CASE_DESC			as LegalTypeCaseDesc,
LEGAL_TYPE_CASE_STAGE			as LegalTypeCaseStage

from LEGAL_INTERVENTIONS2;
run;

PROC DATASETS LIB=WORK NOLIST; DELETE ECASE_LTS_CASES START_LTS_CASES LEGAL_INTERVENTIONS2 START_LTS_CASES ECASE_LTS_CASES; RUN;


	


%ErrCheck;