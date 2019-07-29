/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 101_excl_child_support_debt_exclusion.sas

Overview:     
              
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
/*********************************************************************************************************************************/
/*  Exclusion 001 - Child Support Debt Exclusion
/*********************************************************************************************************************************/
PROC SORT DATA=CSDR.CS_DAILY_DEBT_REPORT_HIST OUT=DATES (KEEP=BUILD_DATE) NODUPKEY; BY DESCENDING BUILD_DATE; RUN;
DATA DATES; SET DATES; IF _N_ = 1 THEN OUTPUT; RUN;
DATA CS_DAILY_DEBT_REPORT;
MERGE CSDR.CS_DAILY_DEBT_REPORT_HIST  (IN=A)
      DATES                           (IN=B);
BY BUILD_DATE;
IF A AND B;
RUN;
/*********************************************************************************************************************************/
proc sql;
create table ExclTemp.CMP_CS_INCL_NEW_a as
SELECT a.ird_number,
a.debt_balance_ncp as NCP_DEBT,
a.debt_balance_CSE as CSE_DEBT,
a.debt_balance_cpr as CPR_DEBT,
b.NON_CS_CMP_EXCL,

CASE WHEN a.FLAG_DEBT_CSE = 'Y' AND a.FLAG_DEBT_NCP = 'N' THEN 'CSE Only'
     WHEN a.FLAG_DEBT_CPR = 'Y' AND a.FLAG_DEBT_NCP = 'N' THEN 'CPR Only'
     WHEN b.stream = 'International' THEN 'International'
     WHEN b.stream = 'Legal' THEN 'Legal'
     WHEN b.stream = 'Special Audit' THEN 'Special Audit'
     WHEN b.CJB_PLAN_TYPE IS NOT NULL AND b.NEXT_CASE_ACTION_TYPE_CODE NE 'DFIA' THEN 'NCP Under Arrangement'
     WHEN b.ASSESSMENT_DEBT=0 AND b.TOTAL_DEBT_AMOUNT > 0 THEN 'Penalty Only'
     WHEN b.NUMBER_OF_DEBT_PERIODS = 0  THEN 'No Debt(CARA)'
     WHEN SUBSTR(b.USER_ID,1,7) = '27RECIN' THEN 'Aust_Reciprocal'
      
     ELSE 'NCP No Arrangement'
     END AS CS_INCL_REASON


FROM CRADC.CRADC_SVOC a
LEFT JOIN CS_DAILY_DEBT_REPORT b
ON a.ird_number = b.ird_number
WHERE a.FLAG_DEBT_CN='Y'
AND (a.FLAG_DEBT_NCP = 'Y' OR a.FLAG_DEBT_CPR = 'Y' OR a.FLAG_DEBT_CSE = 'Y');
quit;
/*********************************************************************************************************************************/
DATA ExclTemp.CMP_CS_INCL_NEW1 (DROP=NON_CS_CMP_EXCL);
SET ExclTemp.CMP_CS_INCL_NEW_a;
IF (NON_CS_CMP_EXCL = 'N' OR NON_CS_CMP_EXCL = '') AND CS_INCL_REASON IN ('NCP Under Arrangement','Penalty Only','No Debt(CARA)','CSE Only','CPR Only') THEN CS_INCL = 'Y'; 
ELSE CS_INCL = 'N';
RUN;