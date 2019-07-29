/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 121_excl_is_a_tax_agent.sas

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
PROC SORT DATA=TDW_CURR.TBL_CUSTOMERINFO 
               (KEEP=IRD_NUMBER CUSTOMER_KEY CUSTOMER_DOCUMENT_KEY CURRENT_REC_FLAG 
                WHERE=(CURRENT_REC_FLAG = 'Y'))   
          OUT=TBL_CUSTOMERINFO;
BY CUSTOMER_KEY;              
RUN;
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE TDW_AGENTS AS 
        SELECT A.CUSTOMER_KEY AS CUSTOMER_KEY,
               COUNT(A.ID_KEY) AS LISTS
          FROM TDW_CURR.TBL_ID_VALL A
         WHERE A.CURRENT_REC_FLAG = 'Y' AND
               COALESCE(A.CEASE,"&eff_date."D) >= "&eff_date."D AND
               A.ID_TYPE = 'LSTID' AND
               A.ACTIVE = 1 AND
               A.VER = 0
      GROUP BY A.CUSTOMER_KEY;
QUIT;
/*********************************************************************************************************************************/
PROC SORT DATA=TDW_AGENTS; 
BY CUSTOMER_KEY; 
RUN;

DATA TDW_AGENTS1; 
	MERGE TDW_AGENTS (IN=A) 
  	    TBL_CUSTOMERINFO (IN=B); 
BY CUSTOMER_KEY; 
IF A; 
RUN;

PROC SORT DATA=CRADC.CRADC_SVOC 
          OUT=CRADC_SVOC; 
BY IRD_NUMBER; 
RUN;

PROC SORT DATA=TDW_AGENTS1; 
BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
DATA ALL_AGENTS1;
	MERGE 	TDW_AGENTS1 (IN=A) 
			CRADC_SVOC (IN=B KEEP=IRD_NUMBER LOCATION_NUMBER RETURNOSCOMBINATIONDESC 
                                 DEBTCOMBINATIONDESC);
	BY IRD_NUMBER;
	IF A;
RUN;

PROC SORT DATA=ALL_AGENTS1; 
BY IRD_NUMBER LOCATION_NUMBER; 
RUN;
/*********************************************************************************************************************************/
DATA EXCLTEMP.TAX_AGENTS (KEEP=IRD_NUMBER LOCATION_NUMBER CUSTOMER_KEY TAXAGENTINDICATOR);
 SET ALL_AGENTS1;
 TAXAGENTINDICATOR = 'Y';
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=EXCLTEMP.TAX_AGENTS 
          OUT=EXCLTEMP.TAX_AGENTS_UNIQUE (KEEP=IRD_NUMBER TAXAGENTINDICATOR) NODUPKEY; 
	BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; 
DELETE TBL_CUSTOMERINFO TDW_AGENTS TDW_AGENTS1 ALL_AGENTS1 CRADC_SVOC; 
RUN;
/*********************************************************************************************************************************/
