/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 134_excl_audit_assessed_debt.sas

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
%put INFO-134_excl_audit_assessed_debt.sas: STUB ONLY;
%GetStarted;
/************************************************************************************************************************/
/* Audit Assessed Debt
/*********************/
/* Update FEB 2018 - Caleb Grove - needs to be updated after Release 2 KG
/* Update APR 2019 - Nisha Nair  - complete reconfiguration reqd as audits fully transitioned to
/*                                 START from eCase from Rel2
/*                               - approach taken is to combine ird numbers who have
/*                                 1. Category 1,2 AAD records in monthly updated Heritage table for 
/*                                    debt elements for products continuing to be mastered in START 
/*                                    created by audits prior to eCase decommission
/*                                 2. Category 1,2 AAD records from pre Rel3 run of Mar19 in Heritage
/*                                    table for FAM, INC & REB debt elements created by audits prior to 
/*                                    eCase decommission converted to START Rel3 and having a non-zero 
/*                                    balance in START
/*                                 3. AUDIT bill item types with non-zero balance in START
/*								   4. Debts posted to Heritage mastered accounts (e.g. PAY or Release 3
/*									  account types before Release 3) from Audits managed/completed in 
/*									  START since decommissioning of eCase also need to be included in 
/*									  this exclusion datapoint however no current TDW tables provide 
/*									  this info. Potential tables found in START database (via FCR)
/*									  tblNZ_AudHtgDiscValidating, tblNZ_AudHtgDiscManual, tblNZ_AudHtgDiscrepancies
/*						
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/* PRE REL3 CODE ----DO NOT UNCOMMENT----ONLY FOR REFERENCE*/
/*PROC SQL;*/
/*  CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP);*/
/*  CREATE TABLE AAD AS SELECT * FROM CONNECTION TO MYORACON (*/
/*        SELECT */
/*      DISTINCT A.RTN_PRD_IRD_NUMBER AS IRD_NUMBER,*/
/*               A.YEAR_MONTH,*/
/*               A.AAD_CATEGORY*/
/*          FROM BESSOWN.AUDIT_ASSESSED_DEBT A*/
/*         WHERE A.YEAR_MONTH = (SELECT MAX(YEAR_MONTH)*/
/*                                 FROM BESSOWN.AUDIT_ASSESSED_DEBT*/
/*                                WHERE AAD_CATEGORY IN (1,2)) AND*/
/*               A.AAD_CATEGORY IN (1,2));*/
/*DISCONNECT FROM MYORACON;*/
/*QUIT;*/
/************************************************************************************************************************/
/*1. Category 1,2 AAD records in monthly updated Heritage table for debt elements for products continuing to be mastered 
/*   in START created by audits prior to eCase decommission
/************************************************************************************************************************/

PROC SQL;
  CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP);
  CREATE TABLE Heritage_AAD AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT A.RTN_PRD_IRD_NUMBER AS IRD_NUMBER,
               A.YEAR_MONTH,
               A.AAD_CATEGORY
          FROM BESSOWN.AUDIT_ASSESSED_DEBT A
         WHERE A.YEAR_MONTH = (SELECT MAX(YEAR_MONTH) FROM BESSOWN.AUDIT_ASSESSED_DEBT) AND
               A.AAD_CATEGORY IN (1,2) AND
               A.TAX_TYPE NOT IN ('REB','FAM','INC') AND
               A.ELEMENT_DATE_END IS NULL AND
               A.DEBT_CASE_DATE_END IS NULL AND
               A.ELEMENT_BALANCE > 0);
DISCONNECT FROM MYORACON;
QUIT;
PROC SORT DATA=Heritage_AAD NODUPKEY; BY IRD_NUMBER YEAR_MONTH AAD_CATEGORY; RUN;

/************************************************************************************************************************/
/*2. Category 1,2 AAD records from pre Rel3 run of Mar19 in Heritage table for FAM, INC & REB debt elements created by 
/*   audits prior to eCase decommission converted to START Rel3 and having a non-zero balance in START
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE SS_DEBT_START AS 
        SELECT
      DISTINCT T.IRD_NUMBER,
               L.HERITAGE_LOCATION_NUMBER AS LOCATION_NUMBER,
               T.FILING_PERIOD,
               A.ACCOUNT_TYPE,
			IFC (A.ACCOUNT_TYPE IN ('IIT','ITN'), 'INC', A.ACCOUNT_TYPE, A.ACCOUNT_TYPE) AS ACCOUNT_TYPE_RECODE, /*recoding so can merge with heritage tax type INC records */
               T.STAGED AS DATE_START,
               P.TAX AS TAX_AMOUNT,
               P.INTEREST_BALANCE + P.PENALTY_BALANCE AS PENALTY_INTEREST_BALANCE,
               P.BALANCE AS BALANCE_AMOUNT,
			   T.BILL_TYPE
          FROM TDW_CURR.TBL_PERIODBILLITEM   T
    INNER JOIN TDW_CURR.TBL_PERIOD_CRADC_DEBT P ON T.ACCOUNT_KEY = P.ACCOUNT_KEY AND 
                                                   T.FILING_PERIOD = P.FILING_PERIOD AND
                                                   P.BALANCE > 0
     LEFT JOIN TDW_CURR.TBL_ACCOUNT          A ON T.ACCOUNT_KEY = A.ACCOUNT_KEY
     LEFT JOIN TDW_CURR.TBL_NZACCOUNTSTD     L ON A.DOC_KEY = L.ACCOUNT_DOC_KEY
         WHERE T.CLOSED = . AND T.STAGE = 'CRTCOL';
QUIT;

PROC SQL;
  CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP);
  CREATE TABLE Heritage_AAD_PRE_REL3 AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT A.RTN_PRD_IRD_NUMBER      AS IRD_NUMBER,
               A.RTN_PRD_LOCATION_NUMBER AS LOCATION_NUMBER,
               A.TAX_TYPE                AS ACCOUNT_TYPE,
               A.RETURN_PERIOD_DATE      AS FILING_PERIOD,
               A.YEAR_MONTH,
               A.AAD_CATEGORY
          FROM BESSOWN.AUDIT_ASSESSED_DEBT A
         WHERE A.YEAR_MONTH = 201903 AND
               A.AAD_CATEGORY IN (1,2) AND
               A.TAX_TYPE IN ('REB','FAM','INC') AND
               A.ELEMENT_DATE_END IS NULL AND
               A.DEBT_CASE_DATE_END IS NULL AND
               A.ELEMENT_BALANCE > 0);
DISCONNECT FROM MYORACON;
QUIT;
PROC SORT DATA = Heritage_AAD_PRE_REL3 NODUPKEY; BY _ALL_; RUN;
PROC SORT DATA = Heritage_AAD_PRE_REL3;          BY IRD_NUMBER LOCATION_NUMBER ACCOUNT_TYPE FILING_PERIOD; RUN;
PROC SORT DATA = SS_DEBT_START;                  BY IRD_NUMBER LOCATION_NUMBER ACCOUNT_TYPE_RECODE FILING_PERIOD; RUN;

DATA Heritage_AAD_In_START;
	MERGE SS_DEBT_START	        (KEEP =IRD_NUMBER LOCATION_NUMBER ACCOUNT_TYPE_RECODE ACCOUNT_TYPE FILING_PERIOD  IN =A)
	      Heritage_AAD_PRE_REL3 (KEEP =IRD_NUMBER LOCATION_NUMBER ACCOUNT_TYPE FILING_PERIOD RENAME= (ACCOUNT_TYPE =ACCOUNT_TYPE_RECODE) IN =B);
	BY IRD_NUMBER LOCATION_NUMBER ACCOUNT_TYPE_RECODE FILING_PERIOD;
IF A AND B;
DROP ACCOUNT_TYPE_RECODE;
RUN;
/************************************************************************************************************************/
/*3. AUDIT bill item types with non-zero balance in START
/************************************************************************************************************************/
DATA AAD_In_START (KEEP =IRD_NUMBER LOCATION_NUMBER ACCOUNT_TYPE FILING_PERIOD); 
	SET SS_DEBT_START;
WHERE BILL_TYPE ='AUDIT';
RUN;
/************************************************************************************************************************/
/*Combine 1, 2 and 3
/************************************************************************************************************************/
DATA EXCLTEMP.AAD;
	SET Heritage_AAD          (KEEP =IRD_NUMBER)
        Heritage_AAD_In_START (KEEP =IRD_NUMBER) 
        AAD_In_START          (KEEP =IRD_NUMBER);
RUN;
/************************************************************************************************************************/
/*Final datatset
/************************************************************************************************************************/
proc sort data=EXCLTEMP.AAD nodupkey; by ird_number; run;
/************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; DELETE Heritage_AAD: AAD_In_START SS_DEBT_START; RUN;

%ErrCheck;