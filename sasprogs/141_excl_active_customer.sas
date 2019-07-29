/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_active_customer.sas

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
/*********************************************/  
/* Step One - Create the following base tables:
Company Status
Deceased
Bankrupt
Undischarged Bankrupt
/*********************************************/ 

/********************************************/   
/*Company Status*/
/********************************************/

/* 
AMLGMD - Amalgamated Company
AMLGMG - Amalgamating Company
INSPRG - Insolvency In Progress
INSMTR - Insolvency Missing Trustee
INSPRG - Insolvency In Progress	
INSOLV - Prd Insolvency Finalised	
INSOLA - Prd Insolvency In Progress	
INSFIN - Insolvency Finalised	
INSCBK - Bankruptcy in progress
INSPBK - Bankruptcy in progress	
INSCLF - Liquidation finalised	
INSCLQ - Liquidation in progress	
INSPLQ - Liquidation in progress
INSLQD - Liquidation finalised	
INSCNA - No Asset Procedure
INSNAP - No Asset Procedure	
INSCRC - Receivership
INSREC - Receivership
INSCVA - Voluntary Administration
INSVOL - Voluntary Administration
INSOLP - Legal Action	
*/

PROC SQL;
CREATE TABLE COMPANY_STATUS_R3 AS
        SELECT D.CUSTOMER_KEY,
               D.IRD_NUMBER,
               D.COMPANY_STATUS
          FROM (SELECT A.CUSTOMER_KEY,
                       A.EFFECTIVE_FROM,
                       B.IRD_NUMBER,
                       CASE WHEN INDICATOR_FIELD IN ('AMLGMG') THEN 'M'
                            WHEN INDICATOR_FIELD IN ('INSCLQ','INSCLF','INSLQD','INSPLQ') THEN 'L'
                            WHEN INDICATOR_FIELD IN ('INSCRC','INSREC') THEN 'R'
                            WHEN INDICATOR_FIELD IN ('INSCVA','INSVOL') THEN 'V'
                            ELSE '' END AS COMPANY_STATUS
                       FROM TDW_CURR.TBL_INDICATOR_VALL A
                 INNER JOIN TDW_CURR.TBL_CUSTOMER_VALL  B ON A.CUSTOMER_KEY = B.CUSTOMER_KEY AND
                                                        A.CURRENT_REC_FLAG = 'Y' AND
                                                        A.CEASE IS NULL AND
                                                        A.ACTIVE = 1
                      WHERE A.INDICATOR_FIELD IN ('AMLGMG','INSCLQ','INSCLF','INSLQD','INSPLQ','INSCRC','INSREC','INSCVA','INSVOL') AND
                            B.CUSTOMER_TYPE = 'COM' AND
                            B.CURRENT_REC_FLAG = 'Y' ) D /*AND a.level_field = 0*/
    INNER JOIN (SELECT C.CUSTOMER_KEY,
                       MAX (C.EFFECTIVE_FROM) AS MAX_DATE
                 FROM  TDW_CURR.TBL_INDICATOR_VALL C
                WHERE  C.INDICATOR_FIELD IN ('AMLGMG','INSCLQ','INSCLF','INSLQD','INSPLQ','INSCRC','INSREC','INSCVA','INSVOL') AND     
                       C.CURRENT_REC_FLAG = 'Y' AND    
                       C.CEASE IS NULL AND    
                       C.ACTIVE = 1
              GROUP BY C.CUSTOMER_KEY) F ON D.EFFECTIVE_FROM = F.MAX_DATE AND
                                            D.CUSTOMER_KEY = F.CUSTOMER_KEY;
QUIT;
run;

/********************************************/   
/*Deceased*/
/* Uses EXCLTEMP.DEATH_NOTICES
/********************************************/


/********************************************/   
/*Undischarged Bankrupt*/
/********************************************/
PROC SQL;
  CREATE TABLE UND_BANKRUPT_R3 as
        SELECT C.IRD_NUMBER,
               C.CUSTOMER_KEY,
               'U' AS STATUS
          FROM TDW_CURR.TBL_CUSTOMERINFO_VALL C
    INNER JOIN TDW_CURR.TBL_INDICATOR_VALL    I ON C.CUSTOMER_KEY = I.CUSTOMER_KEY
         WHERE C.CUSTOMER_TYPE = 'IND' AND
               C.PROFILE_NUMBER = 1 AND
               C.CURRENT_REC_FLAG = 'Y' AND
               I.INDICATOR_FIELD = 'UNDSCH' AND
               I.CURRENT_REC_FLAG = 'Y' AND
               I.ACTIVE = 1 AND
               I.CEASE IS NULL;
quit;
run;
 
/********************************************/   
/*Bankrupt*/
/********************************************/
proc sql;
CREATE TABLE BANKRUPT_R3 as
        SELECT I.IRD_NUMBER,
               C.CUSTOMER_KEY,
               'B' AS STATUS
          FROM TDW_CURR.TBL_CUSTOMERINFO_VALL C
    INNER JOIN TDW_CURR.TBL_INDICATOR_VALL    I ON C.CUSTOMER_KEY = I.CUSTOMER_KEY
     LEFT JOIN TDW_CURR.TBL_ID_VALL           D ON I.CUSTOMER_KEY = D.CUSTOMER_KEY
         WHERE C.CUSTOMER_TYPE = 'IND' AND
               C.PROFILE_NUMBER = 1 AND
               C.CURRENT_REC_FLAG = 'Y' AND
               I.CURRENT_REC_FLAG = 'Y' AND
               D.CURRENT_REC_FLAG = 'Y' AND
               I.INDICATOR_FIELD = 'UNDSCH' AND
               D.ID_TYPE = 'IRD' AND
               D.PROFILE_NUMBER = 0 AND 
               C.IRD_NUMBER <> I.IRD_NUMBER;
QUIT;   
run; 



/********************************************************************/     
/* Step Two: Make a base table of customer keys in the status tables*/
/********************************************************************/ 
 PROC SQL;
  CREATE TABLE R3_STATUS_BASE AS 
        SELECT CUSTOMER_KEY, IRD_NUMBER FROM COMPANY_STATUS_R3 UNION
        SELECT CUSTOMER_KEY, IRD_NUMBER FROM EXCLTEMP.DEATH_NOTICES WHERE CUSTOMER_KEY NE . UNION
        SELECT CUSTOMER_KEY, IRD_NUMBER FROM UND_BANKRUPT_R3 UNION
        SELECT CUSTOMER_KEY, IRD_NUMBER FROM BANKRUPT_R3;
QUIT;
run;


/**********************************************************************/ 
/* Step 3: Make indicators for all customers in the Status Base table*/
/**********************************************************************/  
PROC SQL;
CREATE TABLE CUSTOMER_STATUS_CUSTOMER_KEY as
        SELECT A.CUSTOMER_KEY,
               MAX(CASE WHEN B.COMPANY_STATUS = 'M'                    THEN 'Y' ELSE 'N' END) AS AMALGAMATED,
               MAX(CASE WHEN B.COMPANY_STATUS = 'L'                    THEN 'Y' ELSE 'N' END) AS LIQUIDATED,
               MAX(CASE WHEN B.COMPANY_STATUS = 'R'                    THEN 'Y' ELSE 'N' END) AS RECEIVERSHIP,
               MAX(CASE WHEN B.COMPANY_STATUS = 'V'                    THEN 'Y' ELSE 'N' END) AS VOLADMIN,
               MAX(CASE WHEN C.CUSTOMER_KEY > 1                        THEN 'Y' ELSE 'N' END) AS DECEASED,
               MAX(CASE WHEN D.IRD_NUMBER > 1                          THEN 'Y' ELSE 'N' END) AS UND_BANKRUPT,
               MAX(CASE WHEN E.IRD_NUMBER > 1 AND D.IRD_NUMBER IS NULL THEN 'Y' ELSE 'N' END) AS BANKRUPT
          FROM R3_STATUS_BASE A
     LEFT JOIN COMPANY_STATUS_R3 B      ON A.CUSTOMER_KEY = B.CUSTOMER_KEY AND A.IRD_NUMBER = B.IRD_NUMBER
     LEFT JOIN EXCLTEMP.DEATH_NOTICES C ON A.CUSTOMER_KEY = C.CUSTOMER_KEY AND A.IRD_NUMBER = C.IRD_NUMBER
     LEFT JOIN UND_BANKRUPT_R3 D        ON A.CUSTOMER_KEY = D.CUSTOMER_KEY AND A.IRD_NUMBER = D.IRD_NUMBER
     LEFT JOIN BANKRUPT_R3 E            ON A.CUSTOMER_KEY = E.CUSTOMER_KEY AND A.IRD_NUMBER = E.IRD_NUMBER
      GROUP BY A.CUSTOMER_KEY;
quit;
run;

proc sql;
  CREATE TABLE CUSTOMER_STATUS_IRD_NUMBER as
        SELECT A.CUSTOMER_KEY,
		       A.IRD_NUMBER,
               MAX(CASE WHEN B.COMPANY_STATUS = 'M'                    THEN 'Y' ELSE 'N' END) AS AMALGAMATED,
               MAX(CASE WHEN B.COMPANY_STATUS = 'L'                    THEN 'Y' ELSE 'N' END) AS LIQUIDATED,
               MAX(CASE WHEN B.COMPANY_STATUS = 'R'                    THEN 'Y' ELSE 'N' END) AS RECEIVERSHIP,
               MAX(CASE WHEN B.COMPANY_STATUS = 'V'                    THEN 'Y' ELSE 'N' END) AS VOLADMIN,
               MAX(CASE WHEN C.CUSTOMER_KEY > 1                        THEN 'Y' ELSE 'N' END) AS DECEASED,
               MAX(CASE WHEN D.IRD_NUMBER > 1                          THEN 'Y' ELSE 'N' END) AS UND_BANKRUPT,
               MAX(CASE WHEN E.IRD_NUMBER > 1 AND D.IRD_NUMBER IS NULL THEN 'Y' ELSE 'N' END) AS BANKRUPT
          FROM R3_STATUS_BASE A
     LEFT JOIN COMPANY_STATUS_R3 B      ON A.CUSTOMER_KEY = B.CUSTOMER_KEY AND A.IRD_NUMBER = B.IRD_NUMBER
     LEFT JOIN EXCLTEMP.DEATH_NOTICES C ON A.CUSTOMER_KEY = C.CUSTOMER_KEY AND A.IRD_NUMBER = C.IRD_NUMBER
     LEFT JOIN UND_BANKRUPT_R3 D        ON A.CUSTOMER_KEY = D.CUSTOMER_KEY AND A.IRD_NUMBER = D.IRD_NUMBER
     LEFT JOIN BANKRUPT_R3 E            ON A.CUSTOMER_KEY = E.CUSTOMER_KEY AND A.IRD_NUMBER = E.IRD_NUMBER
      GROUP BY A.CUSTOMER_KEY,
		       A.IRD_NUMBER;
QUIT;
run;


DATA EXCLTEMP.CUSTOMER_STATUS_CUSTOMER_KEY;
 SET CUSTOMER_STATUS_CUSTOMER_KEY;
LENGTH CUSTOMER_STATUS $10.;
IF AMALGAMATED  ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'M';
IF LIQUIDATED   ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'L';
IF RECEIVERSHIP ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'R';
IF VOLADMIN     ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'V';
IF DECEASED     ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'D';
IF UND_BANKRUPT ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'U';
IF BANKRUPT     ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'B';
RUN;

DATA EXCLTEMP.CUSTOMER_STATUS_IRD_NUMBER;
 SET CUSTOMER_STATUS_IRD_NUMBER;
LENGTH CUSTOMER_STATUS $10.;
IF AMALGAMATED  ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'M';
IF LIQUIDATED   ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'L';
IF RECEIVERSHIP ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'R';
IF VOLADMIN     ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'V';
IF DECEASED     ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'D';
IF UND_BANKRUPT ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'U';
IF BANKRUPT     ='Y' THEN CUSTOMER_STATUS=STRIP(CUSTOMER_STATUS) || 'B';
RUN;

TITLE "Frequency at Customer_Key Level";
PROC FREQ DATA=EXCLTEMP.CUSTOMER_STATUS_CUSTOMER_KEY; 
TABLE CUSTOMER_STATUS; 
RUN;

TITLE "Frequency at IRD_Number Level";
PROC FREQ DATA=EXCLTEMP.CUSTOMER_STATUS_IRD_NUMBER;   
TABLE CUSTOMER_STATUS; 
RUN;
TITLE;


PROC SORT DATA=EXCLTEMP.CUSTOMER_STATUS_CUSTOMER_KEY; 
BY CUSTOMER_KEY; 
RUN;
PROC SORT DATA=EXCLTEMP.CUSTOMER_STATUS_IRD_NUMBER;   
BY IRD_NUMBER;   
RUN;
/*PROC DATASETS LIB=WORK NOLIST; DELETE COMPANY_STATUS_R3 UND_BANKRUPT_R3 BANKRUPT_R3 R3_STATUS_BASE R3_STATUS_INDICATORS CUSTOMER_STATUS; RUN;*/
