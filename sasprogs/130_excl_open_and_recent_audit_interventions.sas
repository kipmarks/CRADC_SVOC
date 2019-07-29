/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 130_excl_open_and_recent_audit_interventions.sas

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
%put INFO-130_open_and_recent_audit_interventions.sas: STUB ONLY;
%GetStarted;
/*********************************************************************************************************************************/
/*    START AUDITS
/*********************************************************************************************************************************/
/*Getting all the data for open and recently closed audits (within 24 months)
/*********************************************************************************************************************************/
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP);
CREATE TABLE START_AUDIT AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT SUB.*,
               CASE WHEN SUB.AUDIT_CASE_CURRENTLY_OPEN = 'Y' OR SUB.AUDIT_GROUP_CURRENTLY_OPEN = 'Y' THEN 'Y'
                    ELSE '' END AS AUDITCURRENTLYOPEN,
               CASE WHEN SUB.AUDIT_GROUP_CLOSED = 'Y' AND (SUB.AUDIT_CASE_CLOSED = 'Y' OR SUB.AUDIT_CASE_CURRENTLY_OPEN IS NULL) 
                    THEN 'Y' ELSE '' END AS AUDITRECENTLYCLOSED
          FROM (SELECT DISTINCT CUS.IRD_NUMBER,
                                CUS.CUSTOMER_KEY,
                                DET.CUSTOMER_KEY AS AUDITDETAILCUSTOMER_KEY,
                                CASE WHEN (DET.CUSTOMER_KEY IS NOT NULL AND (GRP.CUSTOMER_KEY = DET.CUSTOMER_KEY)) 
                                     THEN 'Y'
                                     WHEN (DET.CUSTOMER_KEY IS NOT NULL AND (GRP.CUSTOMER_KEY <> DET.CUSTOMER_KEY)) 
                                     THEN 'N' END AS SAME_GROUP_CK_AS_CASE_CK,
                                AGC.AUDIT_GROUP_KEY,
                                GRP.CUSTOMER_KEY AS AUDIT_GROUP_CUSTOMER_KEY,
                                GRP.IRD_NUMBER AS AUDIT_GROUP_IRD_NUMBER,
                                GRP.CREATED_WHEN AS AUDIT_GROUP_CREATED_WHEN,
                                GRP.CLOSED_WHEN AS AUDIT_GROUP_CLOSED_WHEN,
                                CASE WHEN GRP.CLOSED_WHEN IS NULL OR GRP.CLOSED_WHEN = '' 
                                     THEN 'Y' ELSE '' END AS AUDIT_GROUP_CURRENTLY_OPEN,
                                CASE WHEN GRP.CLOSED_WHEN IS NULL OR GRP.CLOSED_WHEN = '' 
                                     THEN ROUND(MONTHS_BETWEEN(SYSDATE, GRP.CREATED_WHEN),0)
                                     ELSE ROUND(MONTHS_BETWEEN(GRP.CLOSED_WHEN,GRP.CREATED_WHEN),0) END AS MONTHS_AUDIT_GROUP_OPEN,
                                CASE WHEN GRP.CLOSED_WHEN IS NOT NULL THEN 'Y' ELSE '' END AS AUDIT_GROUP_CLOSED,
                                ROUND(MONTHS_BETWEEN(SYSDATE,GRP.CLOSED_WHEN),0) AS AUDIT_GROUP_MONTHS_CLOSED,
                                GRP.EFFECTIVE_FROM AS AUDIT_GROUP_EFFECTIVE_FROM,
                                ATT.AUD_CUSTOMER_GROUP AS AUDIT_GROUP_CUSTOMER_GROUP,
                                ATT.AUD_COMPLIANCE_BEHAVIOUR AS AUDIT_GRP_COMPLIANCE_BEHAVIOUR,
                                ATT.AUD_RISK_DESCRIPTION AS AUDIT_GROUP_RISK_DESCRIPTION,
                                AUD.AUDIT_KEY AS AUDIT_KEY,
                                AUD.AUDIT_ID AS AUDITID,
                                AUD.POSTED AS POSTED,
                                AUD.POSTED_DATE AS POSTED_DATE,
                                AUD.DOC_KEY AS DOC_KEY,
                                DET.AUDIT_STATUS,
                                CASE WHEN DET.AUDIT_STATUS NOT IN ('CLOSE','REJECT','PRECLS') THEN 'Y' ELSE '' END AS AUDIT_CASE_CURRENTLY_OPEN,
                                CASE WHEN DET.AUDIT_STATUS IN ('CLOSE','REJECT','PRECLS') THEN 'Y' ELSE '' END AS AUDIT_CASE_CLOSED,
                                CASE WHEN DET.AUDIT_STATUS IN ('CLOSE','REJECT','PRECLS') THEN ROUND(MONTHS_BETWEEN(SYSDATE,DET.EFFECTIVE_FROM),0)
                                     ELSE NULL END AS AUDIT_CASE_MONTHS_CLOSED,
                                DET.EFFECTIVE_FROM,
                                DET.AUDIT_STAGE,
                                DET.AUDIT_PROGRAM,
                                DET.AUDIT_SOURCE,
                                DET.POSTING_PERIOD,
                                DET.ACCOUNT_KEY,
                                DET.FILING_PERIOD_FROM,
                                DET.FILING_PERIOD_TO
                           FROM TDW.TBL_CUSTOMERINFO_VALL       CUS
                     INNER JOIN TDW.TBL_AUDITGROUPCUSTOMER_VALL AGC ON CUS.CUSTOMER_KEY = AGC.CUSTOMER_KEY AND
                                                                       AGC.ACTIVE = 1
                      LEFT JOIN TDW.TBL_AUDITGROUP_VALL         GRP ON AGC.AUDIT_GROUP_KEY = GRP.AUDIT_GROUP_KEY AND
                                                                       GRP.CURRENT_REC_FLAG = 'Y'
                      LEFT JOIN TDW.TBL_NZ_AUDSELECTNATTRS_VALL ATT ON GRP.DOC_KEY = ATT.AUDIT_GROUP_DOC_KEY AND
                                                                       ATT.CURRENT_REC_FLAG = 'Y' AND
                                                                       ATT.EFFECTIVE_TO IS NULL
                      LEFT JOIN TDW.TBL_AUDIT_VALL              AUD ON GRP.AUDIT_GROUP_KEY = AUD.AUDIT_GROUP_KEY AND
                                                                       CUS.CUSTOMER_KEY = AUD.CUSTOMER_KEY AND
                                                                       AUD.CURRENT_REC_FLAG = 'Y' AND
                                                                       AUD.EFFECTIVE_TO IS NULL
                      LEFT JOIN TDW.TBL_AUDITDETAIL_VALL        DET ON AUD.AUDIT_KEY = DET.AUDIT_KEY AND
                                                                       CUS.CUSTOMER_KEY = DET.CUSTOMER_KEY AND
                                                                       DET.CURRENT_REC_FLAG = 'Y' AND
                                                                       DET.EFFECTIVE_TO IS NULL
                          WHERE CUS.CURRENT_REC_FLAG = 'Y'
                       ORDER BY CUS.IRD_NUMBER) SUB
         WHERE SUB.AUDIT_CASE_CURRENTLY_OPEN = 'Y' OR
               SUB.AUDIT_GROUP_CURRENTLY_OPEN = 'Y' OR
               SUB.AUDIT_GROUP_MONTHS_CLOSED < 25 OR
               AUDIT_CASE_MONTHS_CLOSED < 25);
DISCONNECT FROM MYORACON;
QUIT;
/*********************************************************************************************************************************/
PROC SORT DATA=START_AUDIT; BY IRD_NUMBER AUDIT_GROUP_KEY; RUN;
/*********************************************************************************************************************************/
/* Splitting into open and recent so can include both in final table in the one line per customer
/*********************************************************************************************************************************/
data OPEN_AUDIT RECENT_AUDIT;
  SET START_AUDIT;
  by IRD_NUMBER AUDIT_GROUP_KEY;
  if AUDITCURRENTLYOPEN 	 = 'Y'  then output OPEN_AUDIT;
  else if AUDITCURRENTLYOPEN = '' 	then output RECENT_AUDIT;
run;

/*********************************************************************************************************************************/
/* Getting rid of multiple lines caused by the case details that we don't care about
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE OPEN_AUDIT_STEP1 AS 
SELECT DISTINCT
IRD_NUMBER, 
CUSTOMER_KEY, 
AUDITCURRENTLYOPEN,
AUDIT_GROUP_KEY, 
AUDIT_GROUP_CURRENTLY_OPEN, 
AUDIT_GROUP_CUSTOMER_GROUP, 
AUDIT_GRP_COMPLIANCE_BEHAVIOUR
FROM WORK.OPEN_AUDIT
ORDER BY IRD_NUMBER;
run;

proc sort data=work.OPEN_AUDIT_STEP1; by ird_number audit_group_key; run;
/*********************************************************************************************************************************/
/* Where there is multiple audit groups open for each ird number, putting a 'MULTIPLE' flag in the customer group and compliance 
/*  behaviour field
/*********************************************************************************************************************************/

data work.OPEN_AUDIT_STEP2;
set work.OPEN_AUDIT_STEP1;
by ird_number audit_group_key;
if first.ird_number and last.ird_number = 0 then do;
								OPEN_AUD_CUSTOMER_GROUP = 'MULTIPLE';
								OPEN_AUD_COMPLIANCE_BEHAVIOUR = 'MULTIPLE';
								output OPEN_AUDIT_STEP2;
								end; 
if first.ird_number and last.ird_number then do;
								OPEN_AUD_CUSTOMER_GROUP = AUDIT_GROUP_CUSTOMER_GROUP;
								OPEN_AUD_COMPLIANCE_BEHAVIOUR = AUDIT_GRP_COMPLIANCE_BEHAVIOUR;
								output OPEN_AUDIT_STEP2;
								end;run;

data work.OPEN_AUDIT_STEP3 (KEEP= IRD_NUMBER CUSTOMER_KEY AUDITCURRENTLYOPEN OPEN_AUD_CUSTOMER_GROUP OPEN_AUD_COMPLIANCE_BEHAVIOUR);SET OPEN_AUDIT_STEP2;RUN;

/*********************************************************************************************************************************/
/* Getting rid of multiple lines caused by the case details that we don't care about */
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE RECENT_AUDIT_STEP1 AS 
SELECT DISTINCT
IRD_NUMBER, 
CUSTOMER_KEY, 
AUDITCURRENTLYOPEN,
AUDITRECENTLYCLOSED,
AUDIT_GROUP_KEY, 
AUDIT_GROUP_CURRENTLY_OPEN, 
AUDIT_GROUP_CLOSED, 
AUDIT_GROUP_MONTHS_CLOSED, 
AUDIT_GROUP_CUSTOMER_GROUP, 
AUDIT_GRP_COMPLIANCE_BEHAVIOUR, 
AUDIT_CASE_CURRENTLY_OPEN,
AUDIT_CASE_CLOSED,
AUDIT_CASE_MONTHS_CLOSED
FROM WORK.RECENT_AUDIT
ORDER BY IRD_NUMBER;run;

proc sort data=work.RECENT_AUDIT_STEP1; by ird_number AUDIT_GROUP_MONTHS_CLOSED; run;

/*********************************************************************************************************************************/
/* Where there is multiple audit groups closed recently for each ird number, putting a 'MULTIPLE' flag in the customer group and 
/*  compliance behaviour field
/*********************************************************************************************************************************/
data work.RECENT_AUDIT_STEP2;
set work.RECENT_AUDIT_STEP1;
by ird_number AUDIT_GROUP_MONTHS_CLOSED;
if first.ird_number and last.ird_number = 0 then do;
								RECENT_AUD_CUSTOMER_GROUP 		= 'MULTIPLE';
								RECENT_AUD_COMPLIANCE_BEHAVIOUR = 'MULTIPLE';
								output RECENT_AUDIT_STEP2;
								end; 
if first.ird_number and last.ird_number then do;
								RECENT_AUD_CUSTOMER_GROUP 		= AUDIT_GROUP_CUSTOMER_GROUP;
								RECENT_AUD_COMPLIANCE_BEHAVIOUR 	= AUDIT_GRP_COMPLIANCE_BEHAVIOUR;
								output RECENT_AUDIT_STEP2;
								end;run;

data work.RECENT_AUDIT_STEP3 (KEEP= IRD_NUMBER CUSTOMER_KEY AUDITRECENTLYCLOSED AUDIT_GROUP_MONTHS_CLOSED RECENT_AUD_CUSTOMER_GROUP RECENT_AUD_COMPLIANCE_BEHAVIOUR);SET RECENT_AUDIT_STEP2;RUN;

PROC SORT DATA=RECENT_AUDIT_STEP3; BY IRD_NUMBER;RUN;
PROC SORT DATA=OPEN_AUDIT_STEP3; BY IRD_NUMBER;RUN;

/*********************************************************************************************************************************/
/* Joining the two together again to get one line per customer for open and recent START audits */
/*********************************************************************************************************************************/
DATA START_AUDIT_DETAILS;
MERGE OPEN_AUDIT_STEP3
RECENT_AUDIT_STEP3;
BY IRD_NUMBER CUSTOMER_KEY;RUN;

PROC SORT DATA=START_AUDIT_DETAILS; BY IRD_NUMBER;RUN;

/*********************************************************************************************************************************/
/* Deleting working tables
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; DELETE START_AUDIT OPEN_AUDIT RECENT_AUDIT OPEN_AUDIT_STEP1 OPEN_AUDIT_STEP2 OPEN_AUDIT_STEP3 RECENT_AUDIT_STEP1 RECENT_AUDIT_STEP2 RECENT_AUDIT_STEP3; RUN;

/*********************************************************************************************************************************/
/*    ECASE AUDITS
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/* 	----------------------- Audits within eCase ----------------------  *\
/*********************************************************************************************************************************/
/*  Checked in with Rob Nicol (Technical Specialist) and while there are some audit cases still open in eCase,
/*  no one is working in ecase anymore and the cases have been moved to START. Therefore only need to look at 
/*  the closed ones to get those closed within the past 2 years. The most recent ones were closed 14 months ago, 
/*  so next year will be able to get rid of the ecase stuff.
/*********************************************************************************************************************************/
/*                    Audit cases from eCase closed within the past two years
/*********************************************************************************************************************************/
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP);
CREATE TABLE ECASE_AUDITS AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT AUD.IRD_NUMBER,
		cus.customer_key,
               AUD.LOCATION_NUMBER,
               AUD.CASE_SUB_TYPE_DESC,
               AUD.CASE_OPENED_DATE,
			   AUD.CASE_CLOSED_DATE,
               AUD.CASE_OPEN_REASON_DESC,
               AUD.CASE_CLOSE_REASON_DESC,

		CASE WHEN AUD.CASE_CLOSED_DATE IS NULL THEN '' ELSE 'Y' END AS ECASE_AUD_RECENTLY_CLOSED,
		CASE WHEN AUD.CASE_CLOSED_DATE IS NOT NULL THEN (ROUND(months_between(sysdate,AUD.CASE_CLOSED_DATE),0)) ELSE NULL END AS Months_Closed_ECase_Audit

 FROM DSS.CM_AUDIT_CASES_VALL 		AUD
 join tdw.tbl_customerinfo_VALL		cus
 on aud.ird_number = cus.ird_number

WHERE AUD.DATE_CEASED IS NULL
AND   (ROUND(MONTHS_BETWEEN(SYSDATE,AUD.CASE_CLOSED_DATE),0) <= 24)
AND   AUD.IRD_NUMBER > 0

      ORDER BY 1);
DISCONNECT FROM MYORACON;
quit;
/*********************************************************************************************************************************/
PROC SORT DATA=ECASE_AUDITS OUT=ECASE_AUDITS_2;
BY IRD_NUMBER DESCENDING CASE_CLOSED_DATE;
RUN;
/*********************************************************************************************************************************/
DATA ECASE_AUD_CASES;
SET WORK.ECASE_AUDITS_2;
BY IRD_NUMBER DESCENDING CASE_CLOSED_DATE;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; DELETE ECASE_AUDITS ECASE_AUDITS_2; RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=ECASE_AUD_CASES; BY IRD_NUMBER;RUN;
/*********************************************************************************************************************************/
/*    START AUDITS
/*********************************************************************************************************************************/
/* 	----------------------- Audit cases within START -----------------------
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/* Extracting the data for CASES with the Audit category within START that are still currently open or clsoed within 2 years
/*********************************************************************************************************************************/
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP);
CREATE TABLE WORK.AUDIT_CASES AS SELECT * FROM CONNECTION TO MYORACON (

SELECT DISTINCT CAS.CUSTOMER_KEY,
               CAS.IRD_NUMBER,
               CAS.CASE_KEY,
               CAS.CASE_TYPE,

		   
CASE WHEN CASE_TYPE = 'AUDNCS' THEN 'Audit – Customer Not Registered'
WHEN CASE_TYPE = 'CNDIDT' THEN 'Pre-Audit Review'
WHEN CASE_TYPE = 'COMISH' THEN 'Commissioners Powers'
WHEN CASE_TYPE = 'DISPU2' THEN 'Audit Disputes'
WHEN CASE_TYPE = 'DISPUT' THEN 'Audit Disputes'
WHEN CASE_TYPE = 'SERSKR' THEN 'SE Annual Review'
ELSE 'Other' END AS CASE_TYPE_DESCRIPTION,

               CAS.CASE_CATEGORY,
               CAS.STAGE         AS CASE_STAGE,
               CAS.CREATED       AS CASE_CREATED_DATE,
			   CAS.CLOSED		 AS CASE_CLOSED_DATE,


               /*---->>> CREATED FIELDS BELOW*/

CASE WHEN CAS.CLOSED IS NULL THEN 'Y' ELSE '' END AS Open_Audit_Type_Start_Case,
CASE WHEN CAS.CLOSED IS NULL THEN '' ELSE 'Y' END AS Recent_Audit_Type_Start_Case,

CASE WHEN CAS.CLOSED IS NOT NULL THEN (ROUND(MONTHS_BETWEEN(SYSDATE,CAS.CLOSED),0)) ELSE NULL END AS AUD_CASE_TYPE_MONTHS_CLOSED

FROM TDW.TBL_ALL_CASES_VALL     CAS

WHERE (CAS.EFFECTIVE_TO IS NULL 					OR CAS.EFFECTIVE_TO = '') 

 AND	(ROUND(months_between(sysdate,CAS.CLOSED),0) <= 24 OR CAS.CLOSED IS NULL)
AND CAS.CURRENT_REC_FLAG 							= 'Y' 
AND CAS.ABORTED 									IS NULL
AND CAS.IRD_NUMBER 									IS NOT NULL 
AND CAS.CASE_CATEGORY IN ('Audit','AUDIT')
/*AND CAS.CASE_TYPE IN ('AUDNCS','CNDIDT','COMISH','DISPU2','DISPUT','SERSKR')*/
);
DISCONNECT FROM MYORACON;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=AUDIT_CASES OUT=AUDIT_CASES_2;
BY CUSTOMER_KEY IRD_NUMBER DESCENDING Open_Audit_Type_Start_Case DESCENDING CASE_CLOSED_DATE;
RUN;
/*********************************************************************************************************************************/
DATA START_AUDIT_CASES;
SET WORK.AUDIT_CASES_2;
BY CUSTOMER_KEY IRD_NUMBER DESCENDING Open_Audit_Type_Start_Case DESCENDING CASE_CLOSED_DATE;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; DELETE AUDIT_CASES AUDIT_CASES_2; RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=START_AUDIT_CASES; BY IRD_NUMBER;RUN;
/*********************************************************************************************************************************/
/*    PULL IT ALL TOGETHER
/*********************************************************************************************************************************/
DATA AUDIT_INTERVENTIONS2;
MERGE START_AUDIT_DETAILS
START_AUDIT_CASES
ECASE_AUD_CASES;
BY IRD_NUMBER CUSTOMER_KEY;
RUN;

/*********************************************************************************************************************************/
/*Final current and recent audit table - START Audit, eCase Audit and START 'Audit' type cases
/*********************************************************************************************************************************/
/* AuditCurrentlyOpen is all open audits from START. No longer need to include open ecase audits as there is no work done in ecase 
/* anymore.  For the recently closed, there are two fields: StartAuditRecentlyClosed and ECaseAuditRecentlyClosed, and two fields 
/* for months closed: MonthsClosedStartAudit and MonthsClosedECaseAudit.
/* ECASE hasn't been used for over a year now, so for the campaigns exclusions where we currently only exclude them if they are 
/* open or closed in past two months, don't need to include the ecase stuff. The ecase stuff is just included if you are 
/* interested in past 2 years.  As of Apr 19, the most recently closed ecase was 15 months ago.
/* If you did want to look over both of them, would need to do:
/* eg. case when AuditCurrentlyOpen = 'Y' or (StartAuditRecentlyClosed = 'Y' and MonthsClosedStartAudit <= 2) or 
/* (ECaseAuditRecentlyClosed = 'Y' and MonthsClosedECaseAudit <= 2) then 'Y' else 'N' end as CurrentAuditCCOMLTSCase
/* Where someone has more then one open audit or more than one recent audit, I have put "MULTIPLE" in the customer group and 
/*  compliance behaviour field.
/* At the end of the table is the details regarding the START cases with the case_category of 'Audit'. There are five case types 
/* with the category of 'Audit' (Audit – Customer Not Registered, Pre-Audit Review, Commissioners Powers, Audit Disputes, and 
/* SE Annual Review). I have kept these seperate to the actual audit stuff as I'm not sure these need to be excluded normally, 
/* but the information is there if people do want to exclude them.
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE audits_open_and_recent AS
        SELECT DISTINCT IRD_NUMBER,
               CUSTOMER_KEY,
               /*Open Audits*/
               AUDITCURRENTLYOPEN            AS AUDITCURRENTLYOPEN,
               OPEN_AUD_CUSTOMER_GROUP       AS OPENAUDITCUSTOMERGROUP,
               OPEN_AUD_COMPLIANCE_BEHAVIOUR AS OPENAUDITCOMPLIANCEBEHAVIOUR,
               /*Recently Closed START*/
               AUDITRECENTLYCLOSED             AS STARTAUDITRECENTLYCLOSED,
               AUDIT_GROUP_MONTHS_CLOSED       AS MONTHSCLOSEDSTARTAUDIT,
               RECENT_AUD_CUSTOMER_GROUP       AS RECENTAUDITCOMPLIANCEGROUP,
               RECENT_AUD_COMPLIANCE_BEHAVIOUR AS RECENTAUDITCOMPLIANCEBEHAVIOUR,
               /*Recently Closed eCase*/
               ECASE_AUD_RECENTLY_CLOSED AS ECASEAUDITRECENTLYCLOSED,
               MONTHS_CLOSED_ECASE_AUDIT AS MONTHSCLOSEDECASEAUDIT,
               CASE_SUB_TYPE_DESC        AS AUDITECASESUBTYPE,
               /*START 'Audit' type cases*/
               CASE WHEN OPEN_AUDIT_TYPE_START_CASE = 'Y' THEN 'Y' ELSE '' END AS OPENAUDITTYPESTARTCASE,
               CASE WHEN RECENT_AUDIT_TYPE_START_CASE = 'Y' THEN 'Y' ELSE '' END AS RECENTAUDITTYPESTARTCASE,
               AUD_CASE_TYPE_MONTHS_CLOSED AS AUDITTYPECASEMONTHSCLOSED,
               CASE_TYPE AS AUDITCASETYPE,
               CASE_TYPE_DESCRIPTION AS AUDITTYPECASEDESC,
               CASE_STAGE AS AUDITTYPECASESTAGE
          FROM AUDIT_INTERVENTIONS2;
RUN;

DATA EXCLTEMP.AUDITS_OPEN_AND_RECENT; SET AUDITS_OPEN_AND_RECENT; RUN;

PROC DATASETS LIB=WORK NOLIST; DELETE AUDIT_INTERVENTIONS2 START_AUDIT_DETAILS ECASE_AUD_CASES START_AUDIT_CASES AUDITS_OPEN_AND_RECENT; RUN;

%ErrCheck;
