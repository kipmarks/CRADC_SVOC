/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 105_excl_returns_prosecutions.sas

Overview:     Customers being prosecuted for outstanding returns.
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            From 0005_Returns_Prosections.sas
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/
/*********************************************************************************************************************************/
/*  Customers that are currently being prosecuted for Outstanding returns    
/*********************************************************************************************************************************/
DATA RETURN_PROSECUTIONS (KEEP = IRD_NUMBER);
	MERGE tdw_curr.TBL_INDICATOR  (IN =A KEEP = IRD_NUMBER INDICATOR_FIELD ACTIVE VER COMMENCE CEASE 
                                   WHERE = (COMMENCE NE . AND (CEASE = . OR DATEPART(CEASE) > TODAY()) 
                                            AND VER =0 AND ACTIVE =1 AND INDICATOR_FIELD ='PRSRVW'))
		  tdw_curr.TBL_ALL_CASES  (IN =B KEEP = IRD_NUMBER CLOSED ABORTED CASE_TYPE                  
                                   WHERE = (MISSING (CLOSED) AND MISSING (ABORTED) AND CASE_TYPE ='FTFPRS'))
		  tdw_curr.TBL_ALL_CASES  (IN =C KEEP = IRD_NUMBER CLOSED ABORTED CASE_TYPE                  
                                   WHERE = (MISSING (CLOSED) AND MISSING (ABORTED) AND CASE_TYPE ='FTAPRS'));
	BY IRD_NUMBER;
	IF B OR (A AND NOT(C));	/*Choose FTF Prosecution cases + Prosecution Indicators with no FTF/FTA cases as this could be for a FTF prosecution activity */
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=RETURN_PROSECUTIONS OUT=ExclTemp.RETURN_PROSECUTIONS NODUP; BY IRD_NUMBER; RUN;
PROC DATASETS LIB=WORK NOLIST; DELETE RETURN_PROSECUTIONS; RUN;
/*********************************************************************************************************************************/