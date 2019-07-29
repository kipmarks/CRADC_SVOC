/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 007_cradc_case_officers.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

26Jul2019   KM Attrib statements to hide non-material comparison changes
June2019  	KM  Migration to DIP
            Original module was 12_Case_Officers.sas
            Stripped out direct connection to Oracle. Does not belong here.
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/************************************************************************************************************************/
/*Child support 'case officers' are determined by the UserID in CRM for the applicable Tax Type/Location
/************************************************************************************************************************/
/* NB Have changed this to use tax_csa instead of tax_csa_vall */
PROC SQL;
CREATE TABLE CradcWrk.CASE_OFFICER_CSR AS 
        SELECT T.IRD_NUMBER,
               T.LOCATION_NUMBER,
               MAX(CASE WHEN T.TAX_TYPE = 'CPR' THEN T.OFFICER_USER_ID END) AS CASE_OFFICER_CPR label="CASE_OFFICER_CPR" format=$8. informat=$8.,
               MAX(CASE WHEN T.TAX_TYPE = 'CSE' THEN T.OFFICER_USER_ID END) AS CASE_OFFICER_CSE label="CASE_OFFICER_CSE" format=$8. informat=$8.,
               MAX(CASE WHEN T.TAX_TYPE = 'NCP' THEN T.OFFICER_USER_ID END) AS CASE_OFFICER_NCP label="CASE_OFFICER_NCP" format=$8. informat=$8.
          FROM edw_curr.TAX_CSA T
         WHERE T.DATE_CEASED IS NULL AND
               T.TREG_DATE_END IS NULL
      GROUP BY T.IRD_NUMBER,
               T.LOCATION_NUMBER;
quit;
run;

/************************************************************************************************************************/
/*CN Case Officers are determined by the MAINFRAME_USER_ID UserID in the 'next action' from the CASE_ACTIONS table
/************************************************************************************************************************/
PROC SQL;
CREATE TABLE CradcWrk.CASE_OFFICER_CN AS 
        SELECT T.IRD_NUMBER,
               T.LOCATION_NUMBER,
               T.CASE_NUMBER,
               A.MAINFRAME_USER_ID AS CASE_OFFICER_CN label="CASE_OFFICER_CN" format=$8. informat=$8.
          FROM edw_curr.CASES_VALL T
          JOIN edw_curr.CASE_ACTIONS_VALL A ON T.CASE_KEY = A.CASE_KEY AND
                                          A.SEQUENCE_NUMBER = 999
         WHERE T.DATE_END IS NULL AND
               T.DATE_CEASED IS NULL AND
               T.CASE_TYPE_CODE = 'CN';
quit;
run;

/************************************************************************************************************************/
/*START Case Officers are determined by the OWNER field from the TBL_COLLECT table
/************************************************************************************************************************/
DATA CradcWrk.CASE_OFFICER_START(KEEP=IRD_NUMBER CASE_OFFICER_START);
 SET tdw_curr.TBL_COLLECT;
WHERE CLOSED_DATE = . AND OWNER NE '';
CASE_OFFICER_START = UPCASE(OWNER);
RUN;

/************************************************************************************************************************/
/*Pre-sort the CASE_OFFICER_CN by IRD_NUMBER LOCATION_NUMBER *AND* DESCENDING CASE_NUMBER.  This will ensure ONLY the
/*  case officer for the current case is retained (there were some wonky records)
/************************************************************************************************************************/
PROC SORT DATA=CradcWrk.CASE_OFFICER_CN;  BY IRD_NUMBER LOCATION_NUMBER DESCENDING CASE_NUMBER;


/************************************************************************************************************************/
/*Sort the data, retaining only the unique records
/************************************************************************************************************************/
PROC SORT DATA=CradcWrk.CASE_OFFICER_CSR   NODUPKEY; BY IRD_NUMBER LOCATION_NUMBER;
PROC SORT DATA=CradcWrk.CASE_OFFICER_CN    NODUPKEY; BY IRD_NUMBER LOCATION_NUMBER;
PROC SORT DATA=CradcWrk.CASE_OFFICER_START NODUPKEY; BY IRD_NUMBER;

/************************************************************************************************************************/
/*Merge the data from the FIRST records together by Ird Number and Location Number.  
/*  Note:  The START data will get merged later by IRD Number ONLY.
/************************************************************************************************************************/
DATA CradcWrk.CASE_OFFICER_FIRST (DROP=CASE_NUMBER);
MERGE CradcWrk.CASE_OFFICER_CN
      CradcWrk.CASE_OFFICER_CSR;
   BY IRD_NUMBER LOCATION_NUMBER;
RUN;

