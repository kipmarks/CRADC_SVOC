/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 08_cradc_special_customers.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Original module was 13_Special_Customers.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/************************************************************************************************************************/
/*Build the SPECIAL FILES data using the data from both START and FIRST.  There are a few discrepencies between the
/*  two datasets, so it was decided we'd take a better-safe-than-sorry approach and deem them to be restricted if they
/*  appeared in EITHER dataset
/************************************************************************************************************************/
DATA TDW_CURR.SPECIAL_CUSTOMERS;
 MERGE CradcWrk.SPECIAL_CUSTS   (IN=TDW)
       edw_curr.SPECIAL_CLIENTS (IN=EDW);
BY IRD_NUMBER;
SPECIAL_TDW = 'N';
SPECIAL_EDW = 'N';
IF TDW AND CUSTOMER_LEVEL = 'SPCFIL' THEN SPECIAL_TDW='Y';
IF EDW THEN SPECIAL_EDW='Y';
RUN;

/************************************************************************************************************************/
/*Sort for merging later
/************************************************************************************************************************/
PROC SORT DATA=TDW_CURR.SPECIAL_CUSTOMERS; BY IRD_NUMBER;RUN;
/************************************************************************************************************************/

