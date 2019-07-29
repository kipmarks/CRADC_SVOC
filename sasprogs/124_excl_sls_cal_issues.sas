/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 124_excl_sas_cal_issues.sas

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
/*   SLS CAL Issues - For Corey
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE EXCLTEMP.SLS_CAL_ISSUES AS 
        SELECT A.IRD_NUMBER,
               A.LOCATION_NUMBER,
               A.YEAR_MONTH,
               A.CAL_LOAN_BALANCE_AMOUNT
          FROM EDW_CURR.CROWN_SL_OUTSTANDING_BLNS_VALL A
    INNER JOIN (SELECT MAX(YEAR_MONTH) AS YEAR_MONTH 
                  FROM EDW_CURR.CROWN_SL_OUTSTANDING_BLNS_VALL) B ON A.YEAR_MONTH = B.YEAR_MONTH
         WHERE A.CAL_LOAN_BALANCE_AMOUNT <= 0 AND
               A.TOTAL_LOAN_BALANCE_AMOUNT > 0;
QUIT;
/*********************************************************************************************************************************/
