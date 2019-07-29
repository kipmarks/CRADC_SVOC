/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 006_cradc_customer_keys.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Original module is 11_Customer_Keys.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/************************************************************************************************************************/
/*Extract IRD Number and Customer Key
/************************************************************************************************************************/
DATA CRADC.CUSTOMER_KEYS (KEEP=IRD_NUMBER CUSTOMER_KEY);
 SET tdw_curr.TBL_CUSTOMERINFO;
RETAIN IRD_NUMBER CUSTOMER_KEY;
RUN;
/************************************************************************************************************************/
/*Sort table for merging later
/************************************************************************************************************************/
PROC SORT DATA=CRADC.CUSTOMER_KEYS;BY IRD_NUMBER;RUN;
