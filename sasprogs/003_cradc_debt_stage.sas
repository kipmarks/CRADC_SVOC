/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 003_cradc_debt_stage.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Original module was 08_CRADC_Debt_Stage.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/
/************************************************************************************************************************/
/*  Debt Section
/************************************************************************************************************************/
/*  Manipulate the data from elements (EDW/FIRST) 
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE CradcWrk.SS_DEBT_EDW AS
        SELECT IRD_NUMBER,
               LOCATION_NUMBER,
               RETURN_PERIOD_DATE AS FILING_PERIOD,
               TAX_TYPE AS ACCOUNT_TYPE,
               DATE_START,
               ASSESSMENT_AMOUNT AS TAX_AMOUNT,
               PENALTY_AND_INTEREST_AMOUNT AS PENALTY_INTEREST_AMOUNT,
               BALANCE AS BALANCE_AMOUNT,
               CASE WHEN DEFAULT_ASSESSMENT_INDICATOR = 'Y' THEN 1 ELSE 0 END AS DEFAULT_ASSESSMENT,
               CASE_NUMBER AS FIRST_CASE_NUMBER
          FROM edw_curr.CURRENT_ELEMENTS
         WHERE BALANCE > 0 AND TAX_TYPE NE 'GST';/*Added in these two limits to remove GST and zero balance elements*/
QUIT;
/************************************************************************************************************************/
/*  Manipulate the data from elements (START) 
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE CradcWrk.SS_DEBT_START AS 
        SELECT
      DISTINCT T.IRD_NUMBER,
               L.HERITAGE_LOCATION_NUMBER AS LOCATION_NUMBER,
               T.FILING_PERIOD,
               A.ACCOUNT_TYPE,
               STAGED AS DATE_START,
               P.TAX AS TAX_AMOUNT,
               P.INTEREST_BALANCE + P.PENALTY_BALANCE AS PENALTY_INTEREST_BALANCE,
               P.BALANCE AS BALANCE_AMOUNT,
               R.ESTIMATED AS DEFAULT_ASSESSMENT
          FROM CradcWrk.CRADC_TBL_PERIODBILLITEM      T
    INNER JOIN tdw_curr.TBL_PERIOD_CRADC_DEBT P ON T.ACCOUNT_KEY = P.ACCOUNT_KEY AND 
                                                   T.FILING_PERIOD = P.FILING_PERIOD AND
                                                   P.BALANCE > 0
     LEFT JOIN tdw_curr.TBL_RETURN            R ON T.ACCOUNT_KEY = R.ACCOUNT_KEY AND 
                                                   T.FILING_PERIOD = R.FILING_PERIOD AND
                                                   R.STATUS = 'RCVD'
     LEFT JOIN tdw_curr.TBL_ACCOUNT           A ON T.ACCOUNT_KEY = A.ACCOUNT_KEY
     LEFT JOIN tdw_curr.TBL_NZACCOUNTSTD      L ON A.DOC_KEY = L.ACCOUNT_DOC_KEY;
QUIT;

/************************************************************************************************************************/
/*  Merge the element level data from START and FIRST
/************************************************************************************************************************/
DATA CradcWrk.SS_DEBT;
 SET CradcWrk.SS_DEBT_START (IN=START)
     CradcWrk.SS_DEBT_EDW   (IN=EDW);
ACCOUNT_TYPE_ORIGINAL = ACCOUNT_TYPE;
LENGTH SOURCE_SYSTEM $5.;

     IF START AND EDW THEN SOURCE_SYSTEM = 'WTF';
ELSE IF START         THEN SOURCE_SYSTEM = 'START';
ELSE IF EDW           THEN SOURCE_SYSTEM = 'FIRST';


/************************************************************************************************************************/
/*Set flags to default value
/************************************************************************************************************************/
FLAG_DEBT_CN  = 'N';
FLAG_DEBT_CPR = 'N';
FLAG_DEBT_CSE = 'N';
FLAG_DEBT_NCP = 'N';

/************************************************************************************************************************/
/*Set the case numbers for the various case types (CN,CPR,CSE,NCP)
/************************************************************************************************************************/
     IF ACCOUNT_TYPE = 'CPR' THEN CASE_NUMBER_CPR = FIRST_CASE_NUMBER;
ELSE IF ACCOUNT_TYPE = 'CSE' THEN CASE_NUMBER_CSE = FIRST_CASE_NUMBER;
ELSE IF ACCOUNT_TYPE = 'NCP' THEN CASE_NUMBER_NCP = FIRST_CASE_NUMBER;
ELSE                              CASE_NUMBER_CN  = FIRST_CASE_NUMBER;

/************************************************************************************************************************/
/*Group the account types
/************************************************************************************************************************/
IF ACCOUNT_TYPE IN ('INC','GST','PAY','FAM','SLS','CPR','CSE','NCP') THEN ACCOUNT_TYPE = ACCOUNT_TYPE;
ELSE IF ACCOUNT_TYPE IN ('IIT','ITN') THEN ACCOUNT_TYPE = 'INC';
ELSE ACCOUNT_TYPE = 'OTH';

/************************************************************************************************************************/
/*Set flags
/************************************************************************************************************************/
IF ACCOUNT_TYPE NOT IN ('CSE','CPR','NCP') THEN DO;
    FLAG_DEBT_CN = 'Y'; 
    DEBT_BALANCE_CN_TOTAL = BALANCE_AMOUNT;
    DEBT_PERIODS_CN_TOTAL = 1;
    END;

IF ACCOUNT_TYPE = 'CPR' THEN FLAG_DEBT_CPR = 'Y';
IF ACCOUNT_TYPE = 'CSE' THEN FLAG_DEBT_CSE = 'Y';
IF ACCOUNT_TYPE = 'NCP' THEN FLAG_DEBT_NCP = 'Y';

IF ACCOUNT_TYPE IN ('CPR','CSE','NCP') THEN CASE_TYPE = ACCOUNT_TYPE;
ELSE CASE_TYPE = 'CN';

RUN;


/************************************************************************************************************************/
/*Build debt portion of CRAD_SVOC
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE CradcWrk.DEBT_SVOC AS
        SELECT D.IRD_NUMBER,
               D.LOCATION_NUMBER,
               MAX(CASE_NUMBER_CN)                                                     AS CASE_NUMBER_CN,
               MAX(CASE_NUMBER_CPR)                                                    AS CASE_NUMBER_CPR,
               MAX(CASE_NUMBER_CSE)                                                    AS CASE_NUMBER_CSE,
               MAX(CASE_NUMBER_NCP)                                                    AS CASE_NUMBER_NCP,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'INC' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_INC      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'GST' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_GST      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'PAY' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_PAY      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'FAM' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_FAM      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'SLS' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_SLS      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'OTH' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_OTH      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'CPR' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_CPR      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'CSE' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_CSE      FORMAT=COMMA12.0,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'NCP' THEN 1 ELSE 0 END)                 AS DEBT_PERIODS_NCP      FORMAT=COMMA12.0,
               SUM(DEBT_PERIODS_CN_TOTAL)                                              AS DEBT_PERIODS_CN_TOTAL FORMAT=COMMA12.0,
               
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'INC' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_INC      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'GST' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_GST      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'PAY' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_PAY      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'FAM' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_FAM      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'SLS' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_SLS      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'OTH' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_OTH      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'CPR' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_CPR      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'CSE' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_CSE      FORMAT=DOLLAR18.2,
               SUM(CASE WHEN D.ACCOUNT_TYPE = 'NCP' THEN D.BALANCE_AMOUNT ELSE 0 END)  AS DEBT_BALANCE_NCP      FORMAT=DOLLAR18.2,
               SUM(DEBT_BALANCE_CN_TOTAL)                                              AS DEBT_BALANCE_CN_TOTAL FORMAT=DOLLAR18.2,
               
               SUM(D.BALANCE_AMOUNT)                                                   AS TOTAL_DEBT_AMOUNT     FORMAT=DOLLAR18.2,
               COUNT(1)                                                                AS TOTAL_DEBT_PERIODS    FORMAT=COMMA12.0,
               SUM(CASE WHEN SOURCE_SYSTEM = 'START' THEN D.BALANCE_AMOUNT ELSE 0 END) AS TOTAL_DEBT_START      FORMAT=COMMA12.0,
               SUM(CASE WHEN SOURCE_SYSTEM = 'FIRST' THEN D.BALANCE_AMOUNT ELSE 0 END) AS TOTAL_DEBT_FIRST      FORMAT=COMMA12.0,

               SUM(DEFAULT_ASSESSMENT)                                                 AS TOTAL_DEFAULT_ASSESSMENTS FORMAT=COMMA12.0,
               MIN(DATEPART(FILING_PERIOD))                                            AS EARLIEST_DEBT         FORMAT=DATE9.,
               MAX(DATEPART(FILING_PERIOD))                                            AS LATEST_DEBT           FORMAT=DATE9.,

               MAX(FLAG_DEBT_CN)                                                       AS FLAG_DEBT_CN,
               MAX(FLAG_DEBT_CPR)                                                      AS FLAG_DEBT_CPR,
               MAX(FLAG_DEBT_CSE)                                                      AS FLAG_DEBT_CSE,
               MAX(FLAG_DEBT_NCP)                                                      AS FLAG_DEBT_NCP
               
          FROM CradcWrk.SS_DEBT D
      GROUP BY D.IRD_NUMBER,
               D.LOCATION_NUMBER;
quit;


/************************************************************************************************************************/
/*Sort the table in preperation for merging later
/************************************************************************************************************************/
PROC SORT DATA=CradcWrk.DEBT_SVOC; BY IRD_NUMBER LOCATION_NUMBER; RUN;

PROC SQL;
  CREATE TABLE CRADC.START_DEBT_SUMMARY AS 
        SELECT IRD_NUMBER,
               LOCATION_NUMBER,
               COUNT(FILING_PERIOD)          AS DEBT_PERIODS,
               SUM(PENALTY_INTEREST_BALANCE) AS PENALTY_INTEREST_BALANCE,
               SUM(BALANCE_AMOUNT)           AS BALANCE_AMOUNT
          FROM CradcWrk.SS_DEBT_START
      GROUP BY IRD_NUMBER,
               LOCATION_NUMBER;

QUIT;

PROC FREQ DATA=CradcWrk.SS_DEBT; TABLE ACCOUNT_TYPE_ORIGINAL * SOURCE_SYSTEM /NOCOL NOCUM NOPERCENT NOROW MISSING; RUN;

PROC FREQ DATA=CradcWrk.SS_DEBT; TABLE LOCATION_NUMBER * SOURCE_SYSTEM /NOCOL NOCUM NOPERCENT NOROW MISSING; RUN;

