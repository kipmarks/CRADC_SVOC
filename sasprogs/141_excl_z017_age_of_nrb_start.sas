/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z017_age_of_nrb_start.sas

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
CREATE TABLE ExclWork.CMP_AGE_OF_NRB_START AS 
        SELECT IRD_NUMBER,
               NRB_DURATION AS AGEOFNRBSTART
          FROM EDW_CURR.SL_OBB_MONTHLY_SUMMARY_VALL
         WHERE NZB_OBB = 'OBB' AND
               YEAR_MONTH = (SELECT MAX(YEAR_MONTH) FROM EDW_CURR.SL_OBB_MONTHLY_SUMMARY_VALL)
      ORDER BY IRD_NUMBER;
QUIT;

