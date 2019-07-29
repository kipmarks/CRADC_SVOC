/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z018_lead_user_id.sas

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

PROC SORT DATA=TDW_CURR.TBL_LEAD (KEEP=IRD_NUMBER CUSTOMER_KEY LAST_ACTION_ACTUAL LAST_ACTION_WHO 
		 WHERE=(LAST_ACTION_WHO NOT IN('',' ')  AND LAST_ACTION_ACTUAL IS NOT MISSING)) 
           OUT=ExclWork.LEADS;
BY IRD_NUMBER CUSTOMER_KEY LAST_ACTION_ACTUAL;
RUN;

DATA ExclWork.LEADS (DROP=LAST_ACTION_ACTUAL RENAME=(LAST_ACTION_WHO = LEADUSERID));
 SET ExclWork.LEADS;
BY IRD_NUMBER CUSTOMER_KEY LAST_ACTION_ACTUAL;
IF LAST.CUSTOMER_KEY;
RUN;
