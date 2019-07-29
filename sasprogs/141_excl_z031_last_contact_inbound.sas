/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z031_last_contact_inbound.sas

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
CREATE TABLE WORK.LASTINBOUNDCONTACT_BUILD AS 
        SELECT A.CUSTOMER_KEY,
               MAX(A.COMPLETED) AS LAST_INBOUND_DATE
          FROM TDW_CURR.TBL_TASKCLOSED_VALL A
         WHERE UPPER(A.TASK_TYPE) = 'MNGCAL' AND
               UPPER(A.STAGE) = 'COMPLETE' AND
               A.VER = 0 AND
               A.EFFECTIVE_TO IS NULL
      GROUP BY A.CUSTOMER_KEY
      ORDER BY A.CUSTOMER_KEY;
QUIT;


DATA ExclWork.LASTCONTACTINBOUND (KEEP=IRD_NUMBER LASTCONTACTINBOUND);
MERGE LASTINBOUNDCONTACT_BUILD (IN=A) 
      ExclWork.TDW_KEYS1       (IN=B KEEP=CUSTOMER_KEY IRD_NUMBER);
BY CUSTOMER_KEY;
IF A;
FORMAT   LAST_INBOUND_DATE DATE9.;
LAST_INBOUND_DATE = DATEPART(LAST_INBOUND_DATE);
LASTCONTACTINBOUND = (TODAY()- LAST_INBOUND_DATE);
RUN;


PROC SORT DATA=ExclWork.LASTCONTACTINBOUND; 
BY IRD_NUMBER; 
RUN;

