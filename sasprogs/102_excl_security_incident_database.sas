/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 102_security_incident_database.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            From 002_Security_Incident_Database.sas
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/


/*********************************************************************************************************************************/
/*Create data around the SID history of our customers
/*********************************************************************************************************************************/
DATA TBL_LINK_VALL; 
 SET TDW_CURR.TBL_LINK (KEEP = TO_IRD_NUMBER FROM_IRD_NUMBER LINK_TYPE CURRENT_REC_FLAG EFFECTIVE_TO 
                       WHERE = (LINK_TYPE IN('AUDGRP','BNKOTN','DIRCMP','PARTNR','TRSTEE') AND CURRENT_REC_FLAG = 'Y' AND EFFECTIVE_TO IS NULL)); 
RUN;
DATA CROSS_REFERENCES_VALL;
 SET EDW_CURR.CROSS_REFERENCES (KEEP = IRD_NUMBER_TO IRD_NUMBER_FROM REFERENCE_TYPE DATE_CEASED 
                               WHERE = (REFERENCE_TYPE IN ('AAC','ASS','BAN','BEN','DEC','DIR','DUP','LTI','JVT','PTR','SUB','TEE','TRA') AND DATE_CEASED IS NULL));
RUN;
/*********************************************************************************************************************************/
/*Create data around the SID history of our customers
/*********************************************************************************************************************************/
/*identify security incidents from tdw table, join onto indicators to bring thought the level of risk(indicator_field)
/*********************************************************************************************************************************/
DATA SID_UPDATE(KEEP= CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD COMMENCE);
MERGE TDW_CURR.TBL_NZ_CASSECURTYINCIDENT (IN = A 
                                        KEEP = CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE CUSTOMER_KEY CURRENT_REC_FLAG EFFECTIVE_TO 
                                       WHERE = (IRD_NUMBER NOT IS NULL AND CURRENT_REC_FLAG = 'Y' AND EFFECTIVE_TO IS NULL))
      TDW_CURR.TBL_INDICATOR             (IN = B 
                                        KEEP = IRD_NUMBER CUSTOMER_KEY COMMENCE INDICATOR_FIELD EFFECTIVE_TO CEASE 
                                       WHERE = (INDICATOR_FIELD IN('LOWRSK','MEDRSK','HGHRSK') AND EFFECTIVE_TO IS NULL AND CEASE IS NULL));
	 BY IRD_NUMBER CUSTOMER_KEY;
IF A;
RUN;	 
/*********************************************************************************************************************************/
PROC SORT DATA= SID_UPDATE; BY CASE_DOC_KEY COMMENCE; RUN;
/*********************************************************************************************************************************/
DATA SID_UPDATE;
SET SID_UPDATE;
BY CASE_DOC_KEY COMMENCE ;
INCIDENTDATE = DATEPART(INCIDENT_DATE);
FORMAT INCIDENTDATE DATE9.;
DAYSREFERRED = TODAY()-INCIDENTDATE;
IF LAST.CASE_DOC_KEY THEN OUTPUT;
RUN;
/*********************************************************************************************************************************/
/*Going back 30 days as sometimes cases are updated with a risk level*/
/*********************************************************************************************************************************/
DATA SID_UPDATE(DROP=INCIDENTDATE DAYSREFERRED);
SET SID_UPDATE;
/*WHERE DAYSREFERRED < 30;*/
RUN;
/*********************************************************************************************************************************/
/*IDENTIFYING ASSOCIATED IRD NUMBERS*/
/*********************************************************************************************************************************/
PROC SORT DATA= SID_UPDATE; BY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/
/*START LINK(TO>FROM)
/*********************************************************************************************************************************/
PROC SORT DATA=TBL_LINK_VALL; BY TO_IRD_NUMBER; RUN;
DATA START_LINK1(KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD FROM_IRD_NUMBER);
MERGE WORK.SID_UPDATE(IN=A KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD)
      TBL_LINK_VALL  (IN=B RENAME=(TO_IRD_NUMBER = IRD_NUMBER));
	  BY IRD_NUMBER;
	  IF A AND B;
RUN;
/*********************************************************************************************************************************/
/*START LINK(FROM>TO)
/*********************************************************************************************************************************/
PROC SORT DATA=TBL_LINK_VALL; BY FROM_IRD_NUMBER; RUN;
DATA START_LINK2(KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD TO_IRD_NUMBER);
MERGE WORK.SID_UPDATE(IN=A KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD)
      TBL_LINK_VALL(IN=B RENAME=(FROM_IRD_NUMBER = IRD_NUMBER));
	  BY IRD_NUMBER;
	  IF A AND B;
RUN;
/*********************************************************************************************************************************/
/*FIRST LINK(TO>FROM)
/*********************************************************************************************************************************/
PROC SORT DATA=CROSS_REFERENCES_VALL; BY IRD_NUMBER_TO; RUN;
DATA FIRST_LINK1(KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD IRD_NUMBER_FROM);
MERGE WORK.SID_UPDATE(IN=A KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD)
      CROSS_REFERENCES_VALL (IN=B RENAME=(IRD_NUMBER_TO = IRD_NUMBER));
	  BY IRD_NUMBER;
	  IF A AND B;
RUN;
/*********************************************************************************************************************************/
/*FIRST LINK(FROM>TO)
/*********************************************************************************************************************************/
PROC SORT DATA=CROSS_REFERENCES_VALL; BY IRD_NUMBER_FROM; RUN;
DATA FIRST_LINK2(KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD IRD_NUMBER_TO);
MERGE WORK.SID_UPDATE(IN=A KEEP=CASE_DOC_KEY IRD_NUMBER INCIDENT_DATE INCIDENT_TYPE INDICATOR_FIELD)
      CROSS_REFERENCES_VALL (IN=B RENAME=(IRD_NUMBER_FROM = IRD_NUMBER));
	  BY IRD_NUMBER;
	  IF A AND B;
RUN;
/*********************************************************************************************************************************/
/*putting it all together in final table
/*********************************************************************************************************************************/
proc sql;
create table sid_history AS
SELECT DISTINCT
ird_number as IRDNumber,
incident_date as IncidentDate,
CASE WHEN incident_type='BOMB'   THEN 'Bomb'
	 WHEN incident_type='BREAK'  THEN 'Break In'
	 WHEN incident_type='BLDACC' THEN 'Building Access'
	 WHEN incident_type='DAMAGE' THEN 'Damage'
	 WHEN incident_type='DISSAT' THEN 'Dissatisfied customer'
	 WHEN incident_type='OLDBNK' THEN 'From old bankrupt number'
	 WHEN incident_type='IDTHFT' THEN 'Identity Theft'
	 WHEN incident_type='MNTHLT' THEN 'Mental Health Issues'
	 WHEN incident_type='NUISNC' THEN 'Nuisance'
	 WHEN incident_type='OBEHAV' THEN 'Offensive Behaviour'
	 WHEN incident_type='OMAIL'  THEN 'Offensive Mail'
	 WHEN incident_type='OTHER'  THEN 'Other'
	 WHEN incident_type='SLFHRM' THEN 'Self Harm'
	 WHEN incident_type='SUSPKG' THEN 'Suspect Package'
	 WHEN incident_type='TRSNTC' THEN 'Trespass Notice'
	 WHEN incident_type='VIOLNC' THEN 'Violence'
	 ELSE 'Unclassified' 
END AS IncidentType,
CASE WHEN indicator_field = 'LOWRSK' THEN 'Low'
     WHEN indicator_field = 'MEDRSK' THEN 'Medium'
     WHEN indicator_field = 'HGHRSK' THEN 'High'
END AS Risk,
associated as Associated,
incident_ird_number as IncidentIRDnumber
FROM(SELECT CASE_DOC_KEY, IRD_NUMBER,      INCIDENT_DATE, INCIDENT_TYPE, INDICATOR_FIELD, 'N' AS ASSOCIATED, .          AS INCIDENT_IRD_NUMBER FROM WORK.SID_UPDATE UNION 
     SELECT CASE_DOC_KEY, FROM_IRD_NUMBER, INCIDENT_DATE, INCIDENT_TYPE, INDICATOR_FIELD, 'Y' AS ASSOCIATED, IRD_NUMBER AS INCIDENT_IRD_NUMBER FROM START_LINK1     UNION 
     SELECT CASE_DOC_KEY, TO_IRD_NUMBER,   INCIDENT_DATE, INCIDENT_TYPE, INDICATOR_FIELD, 'Y' AS ASSOCIATED, IRD_NUMBER AS INCIDENT_IRD_NUMBER FROM START_LINK2     UNION 
	 SELECT CASE_DOC_KEY, IRD_NUMBER_FROM, INCIDENT_DATE, INCIDENT_TYPE, INDICATOR_FIELD, 'Y' AS ASSOCIATED, IRD_NUMBER AS INCIDENT_IRD_NUMBER FROM FIRST_LINK1     UNION 
	 SELECT CASE_DOC_KEY, IRD_NUMBER_TO,   INCIDENT_DATE, INCIDENT_TYPE, INDICATOR_FIELD, 'Y' AS ASSOCIATED, IRD_NUMBER AS INCIDENT_IRD_NUMBER FROM FIRST_LINK2)
ORDER BY INCIDENT_DATE, IRD_NUMBER;
QUIT;
/*********************************************************************************************************************************/
/*UPDATING NEW SID CASES INTO HISTORY TABLE
/*********************************************************************************************************************************/
PROC SORT DATA= SID_HISTORY; BY INCIDENTDATE IRDNUMBER; RUN;
PROC SORT DATA= CAMEXCL.SID_HISTORY; BY INCIDENTDATE IRDNUMBER; RUN;
/*********************************************************************************************************************************/
 DATA CAMEXCL.SID_HISTORY;
 MERGE CAMEXCL.SID_HISTORY 
       WORK.SID_HISTORY; 
BY INCIDENTDATE IRDNUMBER;
RUN;
/*********************************************************************************************************************************/
/* Update final table that gets pulled into daily exclusions
/*********************************************************************************************************************************/
 PROC SQL;
CREATE TABLE ExclTemp.SID AS SELECT DISTINCT IRDNumber as ird_number FROM CAMEXCL.SID_HISTORY;
QUIT;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST;
DELETE SID_UPDATE START_LINK1 START_LINK2 FIRST_LINK1 FIRST_LINK2 SID_HISTORY TBL_LINK_VALL CROSS_REFERENCES_VALL;
QUIT;
/*********************************************************************************************************************************/
