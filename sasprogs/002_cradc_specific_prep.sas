/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 002_cradc_specific_prep.sas

Overview:     Creates work tables from TDW
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

26Jul2019   KM Use of eff_date adapted to give results consistent with heritage
June2019  	KM  Migration to DIP
            Original module is 07_CRADC_Specific_Prep.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/************************************************************************************************************************/
/*Using the tdw_curr tables, create specific (WORK) tables required for the CRAD_SVOC
/************************************************************************************************************************/
 DATA CradcWrk.CRADC_TBL_PERIODBILLITEM;
  SET tdw_curr.TBL_PERIODBILLITEM;
WHERE CLOSED = . AND STAGE = 'CRTCOL';
RUN;
/************************************************************************************************************************/
 DATA CradcWrk.CRADC_TBL_INDICATOR;
  SET tdw_curr.TBL_INDICATOR;
WHERE COMMENCE NE . AND (CEASE = . OR DATEPART(CEASE) > "&Eff_date."D + 1);
RUN;
/************************************************************************************************************************/
 DATA CradcWrk.SPECIAL_CUSTS (KEEP=CUSTOMER_KEY IRD_NUMBER CUSTOMER_LEVEL); 
  SET tdw_curr.TBL_CUSTOMERINFO; 
WHERE CUSTOMER_KEY > 0 AND CUSTOMER_LEVEL = 'SPCFIL'; RUN;
/************************************************************************************************************************/
PROC SORT DATA=CradcWrk.SPECIAL_CUSTS;     BY IRD_NUMBER; RUN;
/************************************************************************************************************************/
