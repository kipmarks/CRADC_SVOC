/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 126_excl_credit_list.sas

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
DATA FIRST_CREDITS (KEEP=IRD_NUMBER TAX_TYPE RETURN_PERIOD_DATE CREDIT_AMOUNT_FIRST 
                    RENAME=(RETURN_PERIOD_DATE=PERIOD));
 SET EDW_CURR.CLIENT_INC_INDICATORS_VALL;
WHERE SUBSTR(RETURN_TYPE,1,1) NE 'X' 
  AND TAX_TYPE NE 'CPR' 
  AND TAX_TYPE NE 'NCP' 
  AND TOTAL_BALANCE_AMT < 0;
CREDIT_AMOUNT_FIRST = TOTAL_BALANCE_AMT * -1;
RUN;
/*********************************************************************************************************************************/
DATA START_CREDITS                   (KEEP=IRD_NUMBER CREDIT_AMOUNT_START TAX_TYPE FILING_PERIOD 
                                    RENAME=(FILING_PERIOD = PERIOD));
 SET TDW_CURR.tbl_period_credit_list (KEEP=IRD_NUMBER VER CURRENT_REC_FLAG FILING FILING_PERIOD BALANCE);  
WHERE DATEPART(FILING_PERIOD) < INTNX('DAY',"&SYSDATE"D,-1,'END') AND VER = 0 AND CURRENT_REC_FLAG = 'Y' AND BALANCE <0;
LENGTH TAX_TYPE $3;
CREDIT_AMOUNT_START = BALANCE *-1;
TAX_TYPE = SUBSTR(FILING,1,3);
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=FIRST_CREDITS; 
BY IRD_NUMBER; 
RUN;
PROC SORT DATA=START_CREDITS; 
BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
DATA ExclTemp.ALL_CREDITS_DETAIL;
	SET FIRST_CREDITS (IN=A)  
        START_CREDITS (IN=B);
	BY IRD_NUMBER;
/*********************************************************************************************************************************/
/*Have discussed with collections and they would like an indicator to say where the credit is located
/*********************************************************************************************************************************/
IF A THEN FIRST_CREDIT_IND = "Y"; ELSE FIRST_CREDIT_IND = "N";
IF B THEN START_CREDIT_IND = "Y"; ELSE START_CREDIT_IND = "N";
IF CREDIT_AMOUNT_START = . THEN CREDIT_AMOUNT_START = 0;
IF CREDIT_AMOUNT_FIRST = . THEN CREDIT_AMOUNT_FIRST = 0;
CREDIT_AMOUNT_TOTAL = CREDIT_AMOUNT_START + CREDIT_AMOUNT_FIRST;
RUN;
/*********************************************************************************************************************************/
PROC SUMMARY DATA= ExclTemp.ALL_CREDITS_DETAIL NWAY MISSING;
BY IRD_NUMBER;
VAR CREDIT_AMOUNT_TOTAL;
OUTPUT OUT=ExclTemp.ALL_CREDITS (DROP=_FREQ_ _TYPE_ LABEL= 'This dataset contains all IRD numbers where the customer has a credit in either START or FIRST') sum=CREDIT_AMOUNT_TOTAL;
RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; 
DELETE FIRST_CREDITS START_CREDITS; 
RUN;
/*********************************************************************************************************************************/
