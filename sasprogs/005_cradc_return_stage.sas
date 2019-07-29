/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 005_cradc_return_stage.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

25JUL2019   KM Made use of dates consistent
June2019  	KM  Migration to DIP
            Original module was 10_CRADC_Return_Stage.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/
/************************************************************************************************************************/
/*  Returns Section
/************************************************************************************************************************/
/*  Manipulate the data from outstanding returns (EDW/FIRST) 
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE CradcWrk.SS_RTNS_EDW AS 
        SELECT T.IRD_NUMBER,
               T.LOCATION_NUMBER,
               T.RETURN_TYPE,
               CASE WHEN T.RETURN_TYPE IN ('IR3', 'IR3A', 'IR3NR', 'IR4', 'IR5', 'IR5FS','IR6', 'IR7', 'IR8', 'IR9') THEN 'INC'
                    WHEN T.RETURN_TYPE = 'IR101' THEN 'GST'
                    WHEN T.RETURN_TYPE = 'IR348' THEN 'PAY'
                    ELSE 'OTH' END AS ACCOUNT_TYPE,
               T.RETURN_PERIOD_DATE AS FILING_PERIOD
          FROM edw_curr.POLICING_PROFILES T
         WHERE T.RETURN_TYPE NE 'IR101';  /*Nisha said "Ignore These...!!!" - Kieran concurred*/
QUIT;
proc freq data=CradcWrk.ss_rtns_edw; table return_type; run;
/************************************************************************************************************************/
/*  Manipulate the data from outstanding returns (START) 
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE CradcWrk.SS_RTNS_TDW_TEMP AS 
        SELECT T.IRD_NUMBER,
               T.ACCOUNT_KEY,
               L.HERITAGE_LOCATION_NUMBER AS LOCATION_NUMBER,
               T.DOC_TYPE AS RETURN_TYPE,
               A.ACCOUNT_TYPE,
               T.FILING_PERIOD,
               T.STATUS,
               I.INDICATOR_FIELD
          FROM tdw_curr.TBL_RETURN T
     LEFT JOIN tdw_curr.TBL_ACCOUNT             A ON T.ACCOUNT_KEY = A.ACCOUNT_KEY
     LEFT JOIN CradcWrk.CRADC_TBL_INDICATOR     I ON T.ACCOUNT_KEY = I.ACCOUNT_KEY AND
                                                     T.FILING_PERIOD >= I.FILING_PERIOD AND
                                                     T.FILING_PERIOD <= COALESCE(I.FILING_PERIOD_TO,I.FILING_PERIOD) AND
                                                     I.INDICATOR_FIELD = 'RTNUNP'
    INNER JOIN TDW_CURR.TBL_PERIOD_CRADC_RETURN P ON T.ACCOUNT_KEY = P.ACCOUNT_KEY AND
                                                     T.FILING_PERIOD = P.FILING_PERIOD 
     LEFT JOIN tdw_curr.TBL_NZACCOUNTSTD        L ON A.DOC_KEY = L.ACCOUNT_DOC_KEY
         WHERE DATEPART(T.DUE) < "&eff_date."D + 1 - 20 AND
/*               A.ACCOUNT_TYPE = 'GST' and*/
               I.ACCOUNT_KEY IS NULL AND
               (T.STATUS IN ('GNR','GHOST') OR (T.STATUS = 'RCVD' AND T.ESTIMATED = 1));
QUIT;

DATA CradcWrk.SS_RTNS_TDW; 
 SET CradcWrk.SS_RTNS_TDW_TEMP;
ACCOUNT_TYPE_ORIGINAL = ACCOUNT_TYPE;

     IF ACCOUNT_TYPE_ORIGINAL = 'GST'          THEN ACCOUNT_TYPE = 'GST';
ELSE IF ACCOUNT_TYPE_ORIGINAL = 'PSO'          THEN ACCOUNT_TYPE = 'PAY';
ELSE IF ACCOUNT_TYPE_ORIGINAL IN ('IIT','ITN') THEN ACCOUNT_TYPE = 'INC';
ELSE ACCOUNT_TYPE = 'OTH';

IF ACCOUNT_TYPE_ORIGINAL = 'REB' THEN DELETE; /*Because Nisha said so :) */

RUN;

/************************************************************************************************************************/
/*  Merge the return level data from START and FIRST
/************************************************************************************************************************/
DATA CradcWrk.SS_RTNS;
 SET CradcWrk.SS_RTNS_TDW  (IN=START)
     CradcWrk.SS_RTNS_EDW  (IN=EDW);
LENGTH SOURCE_SYSTEM $5.;

     IF START AND EDW THEN SOURCE_SYSTEM = 'WTF';
ELSE IF START         THEN SOURCE_SYSTEM = 'START';
ELSE IF EDW           THEN SOURCE_SYSTEM = 'FIRST';


RUN;


/************************************************************************************************************************/
/*Build debt portion of CRADC_SVOC
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE CradcWrk.RTNS_SVOC AS 
        SELECT IRD_NUMBER,
               LOCATION_NUMBER,
               SUM(CASE WHEN ACCOUNT_TYPE = 'INC' THEN 1 ELSE 0 END) AS RTNS_INC FORMAT=COMMA12.0,
               SUM(CASE WHEN ACCOUNT_TYPE = 'GST' THEN 1 ELSE 0 END) AS RTNS_GST FORMAT=COMMA12.0,
               SUM(CASE WHEN ACCOUNT_TYPE = 'PAY' THEN 1 ELSE 0 END) AS RTNS_PAY FORMAT=COMMA12.0,
               SUM(CASE WHEN ACCOUNT_TYPE = 'OTH' THEN 1 ELSE 0 END) AS RTNS_OTH FORMAT=COMMA12.0,
               SUM(1)                                                AS TOTAL_OS_RETURNS FORMAT=COMMA12.0,
               MIN(DATEPART(FILING_PERIOD))                          AS EARLIEST_RTN FORMAT=DATE9.,
               MAX(DATEPART(FILING_PERIOD))                          AS LATEST_RTN   FORMAT=DATE9.,
               'Y' AS FLAG_RTN
          FROM CradcWrk.SS_RTNS
      GROUP BY IRD_NUMBER,
               LOCATION_NUMBER;


QUIT;


PROC SORT DATA=CradcWrk.RTNS_SVOC; BY IRD_NUMBER LOCATION_NUMBER; RUN;


PROC FREQ DATA=CradcWrk.SS_RTNS; TABLE RETURN_TYPE * SOURCE_SYSTEM /NOCOL NOCUM NOPERCENT NOROW MISSING; RUN;

PROC FREQ DATA=CradcWrk.SS_RTNS; TABLE LOCATION_NUMBER * SOURCE_SYSTEM /NOCOL NOCUM NOPERCENT NOROW MISSING; RUN;

/*PROC DATASETS LIB=TDW_CURR NOLIST; DELETE TBL_RETURN; RUN;*/

