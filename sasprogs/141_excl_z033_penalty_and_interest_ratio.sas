/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z033_penalty_and_interest_ratio.sas

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
/********************************************************************************************************/
/* PIRatio																							*/
/* Code supplied by Aaron Parker																					*/	
/********************************************************************************************************/
/* Only looking at START information, Penalties and interest as a % of current start balance           ; */
/* Created as part of Richards CRADC code - this is just grabbing from there (consider scheduling)   ;*/
***************************************************************************************************** ;
PROC SQL;
  CREATE TABLE ExclWork.START_P_I_RATIO AS 
        SELECT IRD_NUMBER,
		       SUM(PENALTY_INTEREST_BALANCE) AS PENALTY_INTEREST_BALANCE,
			   SUM(BALANCE_AMOUNT)           AS BALANCE_AMOUNT
          FROM CRADC.START_DEBT_SUMMARY
	  GROUP BY IRD_NUMBER;
QUIT;
DATA ExclWork.START_P_I_RATIO (KEEP= IRD_NUMBER PIRatio);
 SET ExclWork.START_P_I_RATIO;
PIRatio = ROUND(PENALTY_INTEREST_BALANCE / BALANCE_AMOUNT, .01);
RUN;
