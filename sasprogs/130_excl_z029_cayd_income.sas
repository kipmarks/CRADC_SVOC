/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 130_excl_z029_cayd_income.sas

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
CREATE TABLE ExclTemp.CAYD_INCOME AS 
        SELECT A.EMPLOYEE_IRD_NUMBER AS IRD_NUMBER,
               A.EMPLOYEE_IRD_NUMBER,
               SUM(A.GROSS_EARNINGS_AMOUNT) AS IncomeEmployee
          FROM EDW_CURR.EMPLOYEE_PAYE_SUMMARIES_VALL A
         WHERE DATEPART(A.RETURN_PERIOD_DATE) BETWEEN 
                                            INTNX('MONTH',"&eff_date."D,-15,'BEGINNING')
                                        AND INTNX('MONTH',"&eff_date."D,-3,'BEGINNING') 
      GROUP BY A.EMPLOYEE_IRD_NUMBER
	  ORDER BY IRD_NUMBER;
QUIT;
