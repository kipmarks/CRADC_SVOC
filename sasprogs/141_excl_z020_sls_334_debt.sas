/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z020_sls_334_debt.sas

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
PROC SQL;
CREATE TABLE ExclWork.EXCL_SLS_UNDER_334 AS 
        SELECT IRD_NUMBER,
               COUNT(DISTINCT RETURN_PERIOD_DATE) AS SLS334DEBT
          FROM EDW_CURR.ELEMENTS_VALL
         WHERE CASE_TYPE_CODE = 'CN' AND
               DATE_CEASED IS NULL AND
               DATE_END IS NULL AND
               TAX_TYPE = 'SLS' AND
               BALANCE > 0 AND
               BALANCE < 334.00 AND
               ELEMENT_TYPE = 'C' AND
               PENALTY_AND_INTEREST_AMOUNT = 0
      GROUP BY IRD_NUMBER
      ORDER BY IRD_NUMBER;
QUIT;