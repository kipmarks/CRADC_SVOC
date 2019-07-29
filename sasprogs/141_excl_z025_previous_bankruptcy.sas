/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z025_previous_bankruptcy.sas

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
  CREATE TABLE EXCLTEMP.PREVIOUS_BANKRUPT AS
        SELECT IRD_NUMBER 
        FROM TDW_CURR.TBL_INDICATOR_VALL 
        WHERE INDICATOR_FIELD = 'UNDSCH' 
          AND CURRENT_REC_FLAG = 'Y' 
  UNION
        SELECT IRD_NUMBER_TO AS IRD_NUMBER 
        FROM EDW_CURR.CROSS_REFERENCES 
        WHERE REFERENCE_TYPE = 'BAN';
QUIT;
PROC SORT DATA=EXCLTEMP.PREVIOUS_BANKRUPT; 
BY IRD_NUMBER; RUN;
