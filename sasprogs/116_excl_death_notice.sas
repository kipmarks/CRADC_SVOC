/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 116_excl_death_notice.sas

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
CREATE TABLE TEMP_DC_NOTES AS 
        SELECT A.IRD_NUMBER,
               B.CUSTOMER_KEY
          FROM TDW_CURR.TBL_CSTINDINFO_VALL A
    INNER JOIN TDW_CURR.TBL_CRMLOG_VALL     B ON A.CUSTOMER_KEY = B.CUSTOMER_KEY
         WHERE (UPPER(B.DATA_TEXT) LIKE '%DECEASED%' 
            OR UPPER(B.DATA_TEXT) LIKE '%PASSED AWAY%' 
            OR UPPER(B.DATA_TEXT) LIKE '%DEATH CERT%') 
           AND B.CURRENT_REC_FLAG = 'Y' 
           AND A.CURRENT_REC_FLAG = 'Y';
quit;
run;

/*********************************************************************************************************************************/
proc sql;
CREATE TABLE TEMP_DC_CASES AS 
        SELECT IRD_NUMBER,
               CUSTOMER_KEY
          FROM TDW_CURR.TBL_ALL_CASES
         WHERE CASE_TYPE = 'INDCES' AND
               STAGE NOT IN ('DISCRD','DUPCSE','REJECT') AND
               CURRENT_REC_FLAG = 'Y' AND
               ID_TYPE = 'IRD';
quit;
run;
/*********************************************************************************************************************************/
proc sql;
CREATE TABLE TEMP_DC_INDICATOR AS 
        SELECT IRD_NUMBER,
               CUSTOMER_KEY
          FROM TDW_CURR.TBL_INDICATOR
         WHERE INDICATOR_FIELD = 'CSTDEC';
quit;
run;
/*********************************************************************************************************************************/
proc sql;
CREATE TABLE DEATH_NOTICES_FIRST AS 
        SELECT F.IRD_NUMBER,
               MAX(F.SUBJECT_CODE) AS SUBJECT_CODE
          FROM EDW_CURR.CORRESPONDENCE_INBOUND_VALL F
         WHERE F.SUBJECT_CODE IN (975, 640) AND
               DELETED_INDICATOR = 'N'
      GROUP BY F.IRD_NUMBER;
quit;
run;
/*********************************************************************************************************************************/
DATA DEATH_NOTICES_START;  
    SET TEMP_DC_: ; 
RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; 
DELETE TEMP_DC_: ; 
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=DEATH_NOTICES_START NODUPKEY; 
BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=DEATH_NOTICES_FIRST NODUPKEY; 
BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
DATA EXCLTEMP.DEATH_NOTICES;
MERGE DEATH_NOTICES_START (IN=A)
      DEATH_NOTICES_FIRST (IN=B);
BY IRD_NUMBER;
START='N'; FIRST='N';
IF A THEN START='Y';
IF B THEN FIRST='Y';
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=EXCLTEMP.DEATH_NOTICES; 
BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; 
DELETE DEATH_NOTICES_: ; 
RUN;
/*********************************************************************************************************************************/
