/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 119_excl_special_audit_halts.sas

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
/*  Spoke to Jo Mcgregor who advised that special audit account halt for speacial audit customer will just have audit indicators 
/*  and the specical files customer level Halt that arent for special files customer but have been using thier unit (like account 
/*  review/fraud checks) are no longer going to sit with special audit Still need to have a think about what the original code was 
/*  trying to accomplish, will speak to Ryan abpout this
/*********************************************************************************************************************************/
DATA SPECIAL_AUDIT_HALTS       (KEEP=IRD_NUMBER CUSTOMER_KEY);
 SET TDW_CURR.TBL_CUSTOMERINFO (WHERE=(CURRENT_REC_FLAG = 'Y' 
                                   AND CUSTOMER_LEVEL = 'SPCAUD'));
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=SPECIAL_AUDIT_HALTS 
          OUT=EXCLTEMP.SPECIAL_AUDIT_HALTS NODUPKEY; 
BY IRD_NUMBER CUSTOMER_KEY; 
RUN;
PROC DATASETS LIB=WORK NOLIST; 
DELETE SPECIAL_AUDIT_HALTS; 
RUN;
/*********************************************************************************************************************************/
