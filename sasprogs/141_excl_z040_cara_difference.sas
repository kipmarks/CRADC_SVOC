/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z040_cara_difference.sas

Overview:     STUB AT PRESENT
              
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
%put INFO-141_excl_z040_cara_difference.sas: STUB AT PRESENT;
%GetStarted;
PROC SQL;
  CREATE TABLE ExclWork.CARA_EXCLUSIONS AS
        SELECT E.IRD_NUMBER,
               E.LOCATION_NUMBER,
               E.CASE_NUMBER,
               E.TAX_TYPE,
               E.RETURN_PERIOD_DATE,
               E.BALANCE AS ELEMENTS_BALANCE,
               C.TOTAL_BALANCE_AMT,
               SUM(E.BALANCE) AS OVERALL_ELEMENTS_BALANCE,
			   SUM(C.TOTAL_BALANCE_AMT) AS OVERALL_TOTAL_BALANCE_AMT,
			   ROUND(ABS(SUM(E.BALANCE)-SUM(C.TOTAL_BALANCE_AMT)),.01) AS CARADIFFERENCE
          FROM DSS.ELEMENTS_VALL              E 
    INNER JOIN DSS.CLIENT_INC_INDICATORS_VALL C ON E.IRD_NUMBER = C.IRD_NUMBER AND
                                                   E.LOCATION_NUMBER = C.LOCATION_NUMBER AND
                                                   E.TAX_TYPE = C.TAX_TYPE AND
                                                   E.RETURN_PERIOD_DATE = C.RETURN_PERIOD_DATE
         WHERE E.CASE_TYPE_CODE = 'CN' AND
/*               E.IRD_NUMBER = 10010381 AND*/
               E.DATE_END IS NULL AND
               E.DATE_CEASED IS NULL AND
               E.ELEMENT_TYPE = 'C'
      GROUP BY E.IRD_NUMBER,
               E.LOCATION_NUMBER,
               E.CASE_NUMBER;
QUIT;
DATA ExclWork.CARA_EXCLUSIONS ( KEEP=IRD_NUMBER CARADIFFERENCE);
 SET ExclWork.CARA_EXCLUSIONS;
WHERE OVERALL_ELEMENTS_BALANCE NE OVERALL_TOTAL_BALANCE_AMT AND CARADIFFERENCE >1;
RUN;
PROC SORT DATA=ExclWork.CARA_EXCLUSIONS NODUPKEY; BY IRD_NUMBER ; RUN;
%ErrCheck;