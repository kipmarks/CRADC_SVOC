/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z026_current_fam_payment_indicator.sas

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
DATA TBL_NZ_FAMENTITLEMENT  (KEEP=ACCOUNT_KEY FAMENTITLEMENT_KEY 
                             FILING_PERIOD FILING CURRENTFAMPAYMENTINDICATOR LAG); 
 SET TDW_CURR.TBL_NZ_FAMENTITLEMENT_VALL (KEEP=ACCOUNT_KEY FAMENTITLEMENT_KEY 
                                     FILING_PERIOD FILING STATUS CURRENT_REC_FLAG);
WHERE FILING_PERIOD > DATETIME() 
  AND STATUS = 'PROG' 
  AND CURRENT_REC_FLAG = 'Y';
IF FILING IN ('FAMWK1','FAMFTO') THEN CURRENTFAMPAYMENTINDICATOR = 'C';
ELSE CURRENTFAMPAYMENTINDICATOR='B';
lag=intck('Month',"&eff_date."D,datepart(filing_period));
IF LAG > 13 THEN DELETE;
RUN;

PROC SORT DATA=TBL_NZ_FAMENTITLEMENT; 
BY ACCOUNT_KEY FILING_PERIOD; 
RUN;
/*********************************************************************************************************************************/
/*  Keep only then record with the closest filing_period
/*********************************************************************************************************************************/
DATA TBL_NZ_FAMENTITLEMENT; 
SET TBL_NZ_FAMENTITLEMENT; 
BY ACCOUNT_KEY; 
IF FIRST.ACCOUNT_KEY THEN OUTPUT; 
RUN;
/*********************************************************************************************************************************/
PROC SQL;
  CREATE TABLE ExclWork.WFF AS 
        SELECT B.IRD_NUMBER,
               A.CURRENTFAMPAYMENTINDICATOR
          FROM TBL_NZ_FAMENTITLEMENT A
    INNER JOIN TDW_CURR.TBL_ACCOUNT  B ON A.ACCOUNT_KEY = B.ACCOUNT_KEY AND
                                          B.CURRENT_REC_FLAG = 'Y';
QUIT;
/*********************************************************************************************************************************/
PROC SORT DATA=ExclWork.WFF;
BY IRD_NUMBER;
RUN;
/*********************************************************************************************************************************/