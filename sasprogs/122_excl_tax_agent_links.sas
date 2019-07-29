/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 122_excl_tax_agent_links.sas

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
PROC SQL;
  CREATE TABLE TDW_LINKS AS 
        SELECT TO_IRD_NUMBER   AS IRD_NUMBER,
               TO_ACCOUNT_KEY  AS ACCOUNT_KEY,
               TO_CUSTOMER_KEY AS CUSTOMER_KEY
          FROM TDW_CURR.TBL_LINK A
         WHERE CURRENT_REC_FLAG = 'Y' AND
               (DATEPART(CEASE) >= "&eff_date."D OR CEASE = .) AND
               LINK_TYPE IN ('TAXAGT','CSTMAL') AND
               ACTIVE = 1 AND
               VER = 0;
QUIT;
/*********************************************************************************************************************************/
PROC SORT DATA=TDW_LINKS; 
BY ACCOUNT_KEY; 
RUN;
/*********************************************************************************************************************************/
DATA TDW_LINKS1;
MERGE TDW_LINKS (IN=A) 
      ExclWork.TDW_KEYS  (IN=B DROP= CUSTOMER_KEY);
BY ACCOUNT_KEY;
IF A;
IF NOT B THEN TAX_TYPE = 'CUS';
ELSE TAX_TYPE = ACCOUNTTYPE;
RUN;
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE LINKS AS 
        SELECT IRD_NUMBER,
               LOCATION_NUMBER,
               TAX_TYPE
          FROM EDW_CURR.CURRENT_TAX_REGISTRATIONS_VALL
         WHERE HAS_AGENT_IND = 'Y' 
           AND TREG_DATE_START <= "&eff_date."D 
           AND COALESCE(TREG_DATE_END,"&eff_date."D) >= "&eff_date."D 
           AND TAX_TYPE IN ('KSE','KSR');
QUIT;
/*********************************************************************************************************************************/
DATA ALL_LINKS; 
 SET LINKS 
     TDW_LINKS1 (RENAME=(HERITAGE_LOCATION_NUMBER = LOCATION_NUMBER)); 
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=ALL_LINKS; 
BY IRD_NUMBER LOCATION_NUMBER; 
RUN;
PROC SORT DATA=CRADC.CRADC_SVOC 
OUT=CRADC_SVOC; 
BY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/
DATA ALL_LINKS1;
	MERGE ALL_LINKS        (IN=A) 
		  CRADC.CRADC_SVOC (IN=B KEEP=IRD_NUMBER LOCATION_NUMBER 
                                 RETURNOSCOMBINATIONDESC DEBTCOMBINATIONDESC);
	BY IRD_NUMBER LOCATION_NUMBER;
	IF A;
	IF INDEX(RETURNOSCOMBINATIONDESC,TAX_TYPE) GE 1 THEN TAX_IND = 1;
	IF INDEX(DEBTCOMBINATIONDESC,TAX_TYPE) GE 1     THEN TAX_IND = 1;
	IF TAX_TYPE = 'CUS'                             THEN TAX_IND = 1;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=ALL_LINKS1; BY IRD_NUMBER LOCATION_NUMBER CUSTOMER_KEY DESCENDING TAX_IND; RUN;
/*********************************************************************************************************************************/
DATA ALL_LINKS2 (KEEP = IRD_NUMBER LOCATION_NUMBER CUSTOMER_KEY CUS INC GST PSO 
                        FAM REB SLS KSS DWT FBT OTH);
    SET ALL_LINKS1;

/*NO LOC ASSOCIATED WITH CUSTOMER KEY, SO MAKE ALL MISSING VALUES LOC 1 FOR GROUPING PURPOSES*/
IF LOCATION_NUMBER = . THEN LOCATION_NUMBER = 1; 

SELECT (TAX_TYPE);
	WHEN ('CUS')       CUS = CUSTOMER_KEY;
	WHEN ('IIT','ITN') INC = ACCOUNT_KEY;
	WHEN ('GST')       GST = ACCOUNT_KEY;
	WHEN ('PSO')       PSO = ACCOUNT_KEY;
	WHEN ('FAM')       FAM = ACCOUNT_KEY;
	WHEN ('REB')       REB = ACCOUNT_KEY;
	WHEN ('SLS')       SLS = ACCOUNT_KEY;
	WHEN ('KSE','KSR') KSS = 1; *STILL HELD IN FIRST;
	WHEN ('DWT')       DWT = ACCOUNT_KEY;
	WHEN ('FBT')       FBT = ACCOUNT_KEY;
	OTHERWISE          OTH = ACCOUNT_KEY;
	END;
RUN;
/*********************************************************************************************************************************/
PROC SQL;
  CREATE TABLE EXCLTEMP.TAX_AGENT_LINK AS
        SELECT IRD_NUMBER,
               LOCATION_NUMBER,
               MAX(CUSTOMER_KEY) AS CUSTOMER_KEY,
               MAX(CUS) AS CUS,
               MAX(INC) AS INC,
               MAX(GST) AS GST,
               MAX(PSO) AS PSO,
               MAX(FAM) AS FAM,
               MAX(REB) AS REB,
               MAX(SLS) AS SLS,
               MAX(KSS) AS KSS,
               MAX(DWT) AS DWT,
               MAX(FBT) AS FBT,
               MAX(OTH) AS OTH
          FROM ALL_LINKS2
      GROUP BY IRD_NUMBER,
               LOCATION_NUMBER;
RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; 
DELETE TDW_LINKS TDW_LINKS1 LINKS ALL_LINKS CRADC_SVOC ALL_LINKS1 ALL_LINKS2; 
RUN;
/*********************************************************************************************************************************/
