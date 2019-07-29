/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 127_excl_txt_opt_out.sas

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
DATA EXCLTEMP.TXT_OPT_OUT (KEEP=IRD_NUMBER SUBJECT_CODE); 
 SET EDW_CURR.CORRESPONDENCE_INBOUND_VALL (WHERE=(SUBJECT_CODE = 787 AND DELETED_INDICATOR='N'));
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=EXCLTEMP.TXT_OPT_OUT NODUPKEY; 
BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/

