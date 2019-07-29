/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 118_excl_investigation_halts.sas

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
/*  May need to be unioned to previous FIRST halts, however assumption is that this shouldnt be needed two of the audit indicators 
/*  are to pick up indicator that have been converted from FIRST
/*********************************************************************************************************************************/
DATA INVESTIGATIONS_HALTS (KEEP=IRD_NUMBER CUSTOMER_KEY);
 SET TDW_CURR.TBL_INDICATOR;
WHERE CEASE IS NULL AND ACTIVE = 1 
  AND CURRENT_REC_FLAG = 'Y' 
  AND INDICATOR_FIELD LIKE 'AU%';
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=INVESTIGATIONS_HALTS 
          OUT=EXCLTEMP.INVESTIGATIONS_HALTS NODUPKEY; 
BY IRD_NUMBER CUSTOMER_KEY; 
RUN;
PROC DATASETS LIB=WORK NOLIST; 
DELETE INVESTIGATIONS_HALTS; 
RUN;
/*********************************************************************************************************************************/
