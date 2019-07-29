/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 009_cradc_days_in_debt.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

26Jul2019   KM Use of eff_date adapted to give results consistent with heritage.
               Updated with new code from Overnight_Processes_v0025.egp
June2019  	KM  Migration to DIP
            Original modules were 14_Days_In_Debt.sas, 15_Days_In_Debt_Summary.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/


	
/************************************************************************************************************************/
%MACRO ZEROMISS;
ARRAY NUMS _NUMERIC_;
DO OVER NUMS;
IF NUMS=. THEN NUMS=0;
END;
%MEND;	
/************************************************************************************************************************/
PROC SORT DATA=TDW_CURR.TBL_ACCOUNT       
       OUT=DID_TMP.TBL_ACCOUNT
       (RENAME=(DOC_KEY=ACCOUNT_DOCUMENT_KEY)
          KEEP=ACCOUNT_KEY IRD_NUMBER DOC_KEY ACCOUNT_TYPE); BY DOC_KEY; RUN; 
PROC SORT DATA=TDW_CURR.TBL_NZACCOUNTSTD 
       OUT=DID_TMP.TBL_NZACCOUNTSTD
     (KEEP=ACCOUNT_DOC_KEY HERITAGE_LOCATION_NUMBER rename=(ACCOUNT_DOC_KEY = ACCOUNT_DOCUMENT_KEY HERITAGE_LOCATION_NUMBER = HERITAGPROFILENUMBER));
       BY ACCOUNT_DOC_KEY; RUN;
/************************************************************************************************************************/
DATA DID_TMP.CRM;
MERGE DID_TMP.TBL_ACCOUNT DID_TMP.TBL_NZACCOUNTSTD;
BY ACCOUNT_DOCUMENT_KEY;
%ZEROMISS;
RUN;
/************************************************************************************************************************/
PROC FREQ DATA=DID_TMP.CRM;TABLE HERITAGPROFILENUMBER/MISSING;RUN;
/************************************************************************************************************************/
PROC SORT DATA=DID_TMP.CRM DUPOUT=DID_TMP.CRM_DROPS NODUPKEY; BY ACCOUNT_KEY; RUN;
/************************************************************************************************************************/
DATA DID_TMP.START_ELEMENTS_RAW;
SET TDW_CURR.TBL_PERIODBILLITEM_R;
WHERE (STAGE EQ 'CRTCOL' AND PRIOR_STAGE NE 'CRTCOL') OR (STAGE NE 'CRTCOL' AND PRIOR_STAGE = 'CRTCOL');
/*STANDARDISE CASE (REMOVE MIXED OR LOWER CASE)*/
STAGE       = UPCASE(STAGE);
PRIOR_STAGE = UPCASE(PRIOR_STAGE);
LENGTH ELEMENT_EVENT $6.;
 IF STAGE EQ 'CRTCOL'      THEN DO;
    ELEMENT_EVENT='OPENED';
    ELEMENT_SCORE=1;
    END;
 IF PRIOR_STAGE = 'CRTCOL' THEN DO;
    ELEMENT_EVENT='CLOSED';
    ELEMENT_SCORE=-1;
    END;
RUN;
/*proc datasets lib=tdw_raw nolist; delete TBL_PERIODBILLITEM; run;*/
/************************************************************************************************************************/
PROC SORT DATA=DID_TMP.START_ELEMENTS_RAW  OUT=DID_TMP.START_ELEMENTS DUPOUT=DID_TMP.START_ELEMENTS_DUPES NODUPKEY; BY BILL_ITEM_KEY STAGED STAGE; RUN;
/************************************************************************************************************************/
/************************************************************************************************************************/
PROC SORT DATA=DID_TMP.START_ELEMENTS; BY ACCOUNT_KEY; RUN;
/************************************************************************************************************************/
DATA DID_TMP.START_ELEMENTS_FINAL(KEEP=IRD_NUMBER HERITAGPROFILENUMBER ACCOUNT_TYPE FILING_PERIOD ELEMENT_EVENT ELEMENT_SCORE STAGED
                    RENAME=(STAGED=ELEMENT_EVENT_DATE));
RETAIN IRD_NUMBER HERITAGPROFILENUMBER ACCOUNT_TYPE FILING_PERIOD ELEMENT_EVENT ELEMENT_SCORE ELEMENT_EVENT_DATE;
MERGE DID_TMP.START_ELEMENTS DID_TMP.CRM;
BY ACCOUNT_KEY;
IF BILL_ITEM_KEY = . THEN DELETE;
RUN;
/************************************************************************************************************************/
/*PROC FREQ DATA=DID_TMP.START_ELEMENTS_FINAL; TABLE HERITAGPROFILENUMBER/MISSING;RUN;*/
/************************************************************************************************************************/
DATA DID_TMP.FIRST_ELEMENTS_OPENED DID_TMP.FIRST_ELEMENTS_CLOSED;
 SET EDW_CURR.ELEMENTS_ALL;
                      OUTPUT DID_TMP.FIRST_ELEMENTS_OPENED;
IF DATE_END NE . THEN OUTPUT DID_TMP.FIRST_ELEMENTS_CLOSED;
RUN;
/************************************************************************************************************************/
DATA DID_TMP.FIRST_ELEMENTS_OPENED_FN (KEEP=IRD_NUMBER LOCATION_NUMBER TAX_TYPE ELEMENT_EVENT ELEMENT_SCORE ELEMENT_EVENT_DATE RETURN_PERIOD_DATE
                                     RENAME=(TAX_TYPE = ACCOUNT_TYPE LOCATION_NUMBER = HERITAGPROFILENUMBER RETURN_PERIOD_DATE=FILING_PERIOD)); 
RETAIN IRD_NUMBER HERITAGPROFILENUMBER ACCOUNT_TYPE FILING_PERIOD ELEMENT_EVENT ELEMENT_SCORE ELEMENT_EVENT_DATE;
SET DID_TMP.FIRST_ELEMENTS_OPENED;
FORMAT ELEMENT_EVENT_DATE DATETIME20.;
ELEMENT_EVENT='OPENED';
ELEMENT_SCORE=1;
ELEMENT_EVENT_DATE = DATE_START;
RUN;
PROC DATASETS LIB=DID_TMP NOLIST; DELETE FIRST_ELEMENTS_OPENED; RUN;
/************************************************************************************************************************/
DATA DID_TMP.FIRST_ELEMENTS_CLOSED_FN (KEEP=IRD_NUMBER LOCATION_NUMBER TAX_TYPE ELEMENT_EVENT ELEMENT_SCORE ELEMENT_EVENT_DATE RETURN_PERIOD_DATE
                                     RENAME=(TAX_TYPE = ACCOUNT_TYPE LOCATION_NUMBER = HERITAGPROFILENUMBER RETURN_PERIOD_DATE=FILING_PERIOD)); 
RETAIN IRD_NUMBER HERITAGPROFILENUMBER ACCOUNT_TYPE FILING_PERIOD ELEMENT_EVENT ELEMENT_SCORE ELEMENT_EVENT_DATE;
SET DID_TMP.FIRST_ELEMENTS_CLOSED; 
FORMAT ELEMENT_EVENT_DATE DATETIME20.;
ELEMENT_EVENT='CLOSED'; 
ELEMENT_SCORE=-1;
ELEMENT_EVENT_DATE = DATE_END; 
RUN;
PROC DATASETS LIB=DID_TMP NOLIST; DELETE FIRST_ELEMENTS_CLOSED; RUN;

/************************************************************************************************************************/
DATA DID_TMP.ELEMENTS;
RETAIN IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE ACCOUNT_TYPE FILING_PERIOD ELEMENT_EVENT ELEMENT_SCORE ELEMENT_EVENT_DATE;
SET DID_TMP.START_ELEMENTS_FINAL
    DID_TMP.FIRST_ELEMENTS_OPENED_FN
    DID_TMP.FIRST_ELEMENTS_CLOSED_FN;
 IF ACCOUNT_TYPE = 'NCP' THEN CASE_TYPE = 'NCP';
ELSE IF ACCOUNT_TYPE = 'CPR' THEN CASE_TYPE = 'CPR';
ELSE IF ACCOUNT_TYPE = 'CSE' THEN CASE_TYPE = 'CSE';
ELSE CASE_TYPE = 'CN';
IF ELEMENT_EVENT='CLOSED' AND ELEMENT_EVENT_DATE='03FEB2017:00:00:00'DT THEN ELEMENT_EVENT_DATE='06FEB2017:00:00:00'DT;
IF ELEMENT_EVENT='CLOSED' AND ELEMENT_EVENT_DATE='20APR2019:00:00:00'DT THEN ELEMENT_EVENT_DATE='22APR2019:00:00:00'DT;
RUN;
PROC FREQ DATA=DID_TMP.ELEMENTS;TABLE ELEMENT_EVENT CASE_TYPE;RUN;
/************************************************************************************************************************/
/************************************************************************************************************************/
proc datasets lib=DID_TMP nolist; delete first_elements_closed first_elements_closed_fn first_elements_opened first_elements_opened_fn; run;
/************************************************************************************************************************/
/************************************************************************************************************************/
PROC SORT DATA=DID_TMP.ELEMENTS; 
            BY IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE ELEMENT_EVENT_DATE FILING_PERIOD ACCOUNT_TYPE ;
RUN;
/************************************************************************************************************************/
PROC SORT DATA=DID_TMP.ELEMENTS
           OUT=DID_TMP.ELEMENT_HIST_CASE; 
/*         WHERE IRD_NUMBER = 14388958;*/
            BY IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE ELEMENT_EVENT_DATE DESCENDING ELEMENT_EVENT; 
RUN;

proc datasets lib=DID_TMP nolist; delete ELEMENTS; run;
/************************************************************************************************************************/
DATA DID_TMP.ELEMENT_HIST_CASE;
 SET DID_TMP.ELEMENT_HIST_CASE;
BY IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE;
RETAIN CASE_TYP_SCORE;
IF FIRST.CASE_TYPE THEN DO;
   CASE_TYP_SCORE = 0;
   CASE_TYP_BREAK = 'CASE FIRST';
   END;
IF LAST.CASE_TYPE THEN CASE_TYP_BREAK = 'CASE LAST';
CASE_TYP_SCORE = CASE_TYP_SCORE + ELEMENT_SCORE;
OUTPUT;
RUN;
/************************************************************************************************************************/
DATA DID_TMP.ELEMENT_HIST_CASE (DROP=CASE_TYP_SCORE_PREV);
 SET DID_TMP.ELEMENT_HIST_CASE;
BY IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE;
CASE_TYP_SCORE_PREV  = LAG(CASE_TYP_SCORE);
IF FIRST.CASE_TYPE THEN CASE_TYP_SCORE_PREV=0;
IF CASE_TYP_SCORE =  1 AND CASE_TYP_SCORE_PREV  = 0 THEN CASE_TYP_EVENT  = 'OPENED';
IF CASE_TYP_SCORE =  0 AND CASE_TYP_SCORE_PREV  = 1 THEN CASE_TYP_EVENT  = 'CLOSED';
RUN;
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
PROC SORT DATA=DID_TMP.ELEMENT_HIST_CASE 
           OUT=DID_TMP.ELEMENT_HIST_LOCATION; 
BY IRD_NUMBER HERITAGPROFILENUMBER ELEMENT_EVENT_DATE DESCENDING ELEMENT_EVENT;
RUN;
proc datasets lib=DID_TMP nolist; delete element_hist_case; run;
/************************************************************************************************************************/
DATA DID_TMP.ELEMENT_HIST_LOCATION;
 SET DID_TMP.ELEMENT_HIST_LOCATION;
BY IRD_NUMBER HERITAGPROFILENUMBER;
RETAIN LOCATION_SCORE;
IF FIRST.HERITAGPROFILENUMBER THEN DO;
   LOCATION_SCORE = 0;
   LOCATION_BREAK = 'LOCATION FIRST';
   END;
IF LAST.HERITAGPROFILENUMBER THEN LOCATION_BREAK = 'LOCATION LAST';
LOCATION_SCORE = LOCATION_SCORE + ELEMENT_SCORE;
OUTPUT;
RUN;
/************************************************************************************************************************/
DATA DID_TMP.ELEMENT_HIST_LOCATION (DROP=LOCATION_SCORE_PREV);
 SET DID_TMP.ELEMENT_HIST_LOCATION;
BY IRD_NUMBER HERITAGPROFILENUMBER;
LOCATION_SCORE_PREV  = LAG(LOCATION_SCORE);
IF FIRST.HERITAGPROFILENUMBER THEN LOCATION_SCORE_PREV=0;
IF LOCATION_SCORE =  1 AND LOCATION_SCORE_PREV  = 0 THEN LOCATION_EVENT  = 'OPENED';
IF LOCATION_SCORE =  0 AND LOCATION_SCORE_PREV  = 1 THEN LOCATION_EVENT  = 'CLOSED';
RUN;
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
PROC SORT DATA=DID_TMP.ELEMENT_HIST_LOCATION 
           OUT=DID_TMP.ELEMENT_HIST_CUSTOMER; 
BY IRD_NUMBER ELEMENT_EVENT_DATE DESCENDING ELEMENT_EVENT;
RUN;
proc datasets lib=DID_TMP nolist; delete element_hist_location; run;
/************************************************************************************************************************/
DATA DID_TMP.ELEMENT_HIST_CUSTOMER;
 SET DID_TMP.ELEMENT_HIST_CUSTOMER;
BY IRD_NUMBER;
RETAIN CUSTOMER_SCORE;
IF FIRST.IRD_NUMBER THEN DO;
   CUSTOMER_SCORE = 0;
   CUSTOMER_BREAK = 'CUSTOMER FIRST';
   END;
IF LAST.IRD_NUMBER THEN CUSTOMER_BREAK = 'CUSTOMER LAST';
CUSTOMER_SCORE = CUSTOMER_SCORE + ELEMENT_SCORE;
OUTPUT;
RUN;
/************************************************************************************************************************/
DATA DID_TMP.ELEMENT_HIST_CUSTOMER (DROP=CUSTOMER_SCORE_PREV);
 SET DID_TMP.ELEMENT_HIST_CUSTOMER;
BY IRD_NUMBER;
CUSTOMER_SCORE_PREV  = LAG(CUSTOMER_SCORE);
IF FIRST.IRD_NUMBER THEN CUSTOMER_SCORE_PREV=0;
IF CUSTOMER_SCORE =  1 AND CUSTOMER_SCORE_PREV  = 0 THEN CUSTOMER_EVENT  = 'OPENED';
IF CUSTOMER_SCORE =  0 AND CUSTOMER_SCORE_PREV  = 1 THEN CUSTOMER_EVENT  = 'CLOSED';
RUN;
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
DATA DID_TMP.DAYS_IN_DEBT_CASE_TYP (KEEP=IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE ELEMENT_EVENT_DATE CASE_TYP_EVENT)
     DID_TMP.DAYS_IN_DEBT_LOCATION (KEEP=IRD_NUMBER HERITAGPROFILENUMBER           ELEMENT_EVENT_DATE LOCATION_EVENT)
     DID_TMP.DAYS_IN_DEBT_CUSTOMER (KEEP=IRD_NUMBER                                ELEMENT_EVENT_DATE CUSTOMER_EVENT);
 SET DID_TMP.ELEMENT_HIST_CUSTOMER;
IF CASE_TYP_EVENT NE '' THEN OUTPUT DID_TMP.DAYS_IN_DEBT_CASE_TYP;
IF LOCATION_EVENT NE '' THEN OUTPUT DID_TMP.DAYS_IN_DEBT_LOCATION;
IF CUSTOMER_EVENT NE '' THEN OUTPUT DID_TMP.DAYS_IN_DEBT_CUSTOMER;
RUN;
proc datasets lib=DID_TMP nolist; delete ELEMENT_HIST_CUSTOMER; run;
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE DID_TMP.DAYS_IN_DEBT_CASE_TYP_TN AS
        SELECT O.IRD_NUMBER,
               O.HERITAGPROFILENUMBER,
               O.CASE_TYPE,
               DATEPART(O.ELEMENT_EVENT_DATE)      AS DEBT_OPENED_CASE_TYP FORMAT=DDMMYY10.,
               MIN(DATEPART(C.ELEMENT_EVENT_DATE)) AS DEBT_CLOSED_CASE_TYP FORMAT=DDMMYY10.
          FROM DID_TMP.DAYS_IN_DEBT_CASE_TYP O
     LEFT JOIN DID_TMP.DAYS_IN_DEBT_CASE_TYP C ON O.IRD_NUMBER = C.IRD_NUMBER AND
                                                   O.HERITAGPROFILENUMBER = C.HERITAGPROFILENUMBER AND
                                                   O.CASE_TYPE = C.CASE_TYPE AND
                                                   O.ELEMENT_EVENT_DATE <= C.ELEMENT_EVENT_DATE AND
                                                   C.CASE_TYP_EVENT = 'CLOSED'
         WHERE O.CASE_TYP_EVENT = 'OPENED'
      GROUP BY O.IRD_NUMBER,
               O.HERITAGPROFILENUMBER,
               O.CASE_TYPE,
               O.ELEMENT_EVENT_DATE;

  CREATE TABLE DID_TMP.DAYS_IN_DEBT_LOCATION_FN AS
        SELECT O.IRD_NUMBER,
               O.HERITAGPROFILENUMBER,
               DATEPART(O.ELEMENT_EVENT_DATE)      AS DEBT_OPENED_LOCATION FORMAT=DDMMYY10.,
               MIN(DATEPART(C.ELEMENT_EVENT_DATE)) AS DEBT_CLOSED_LOCATION FORMAT=DDMMYY10.
          FROM DID_TMP.DAYS_IN_DEBT_LOCATION O
     LEFT JOIN DID_TMP.DAYS_IN_DEBT_LOCATION C ON O.IRD_NUMBER = C.IRD_NUMBER AND
                                                   O.HERITAGPROFILENUMBER = C.HERITAGPROFILENUMBER AND
                                                   O.ELEMENT_EVENT_DATE <= C.ELEMENT_EVENT_DATE AND
                                                   C.LOCATION_EVENT = 'CLOSED'
         WHERE O.LOCATION_EVENT = 'OPENED'
      GROUP BY O.IRD_NUMBER,
               O.HERITAGPROFILENUMBER,
               O.ELEMENT_EVENT_DATE;

  CREATE TABLE DID_TMP.DAYS_IN_DEBT_CUSTOMER_FN AS
        SELECT O.IRD_NUMBER,
               DATEPART(O.ELEMENT_EVENT_DATE)      AS DEBT_OPENED_CUSTOMER FORMAT=DDMMYY10.,
               MIN(DATEPART(C.ELEMENT_EVENT_DATE)) AS DEBT_CLOSED_CUSTOMER FORMAT=DDMMYY10.
          FROM DID_TMP.DAYS_IN_DEBT_CUSTOMER O
     LEFT JOIN DID_TMP.DAYS_IN_DEBT_CUSTOMER C ON O.IRD_NUMBER = C.IRD_NUMBER AND
                                                   O.ELEMENT_EVENT_DATE <= C.ELEMENT_EVENT_DATE AND
                                                   C.CUSTOMER_EVENT = 'CLOSED'
         WHERE O.CUSTOMER_EVENT = 'OPENED'
      GROUP BY O.IRD_NUMBER,
               O.ELEMENT_EVENT_DATE;


QUIT;

DATA DID_TMP.DAYS_IN_DEBT_CASE_TYP_TN; 
 SET DID_TMP.DAYS_IN_DEBT_CASE_TYP_TN; 
IF DEBT_CLOSED_CASE_TYP = . THEN DAYS_IN_DEBT          = "&eff_date."D + 1    - DEBT_OPENED_CASE_TYP; 
ELSE                             DAYS_IN_DEBT          = DEBT_CLOSED_CASE_TYP - DEBT_OPENED_CASE_TYP; 
RUN;
/************************************************************************************************************************/
DATA DID_TMP.DAYS_IN_DEBT_LOCATION_FN; 
 SET DID_TMP.DAYS_IN_DEBT_LOCATION_FN; 
IF DEBT_CLOSED_LOCATION = . THEN DAYS_IN_DEBT_LOCATION = "&eff_date."D + 1    - DEBT_OPENED_LOCATION; 
ELSE                             DAYS_IN_DEBT_LOCATION = DEBT_CLOSED_LOCATION - DEBT_OPENED_LOCATION; 
RUN;
/************************************************************************************************************************/
DATA DID_TMP.DAYS_IN_DEBT_CUSTOMER_FN; 
 SET DID_TMP.DAYS_IN_DEBT_CUSTOMER_FN; 
IF DEBT_CLOSED_CUSTOMER = . THEN DAYS_IN_DEBT_CUSTOMER = "&eff_date."D + 1    - DEBT_OPENED_CUSTOMER; 
ELSE                             DAYS_IN_DEBT_CUSTOMER = DEBT_CLOSED_CUSTOMER - DEBT_OPENED_CUSTOMER; 
RUN;
/************************************************************************************************************************/
PROC SQL;
  CREATE TABLE DID_TMP.DAYS_IN_DEBT_CASE_TYP_FN AS
        SELECT IRD_NUMBER,
               HERITAGPROFILENUMBER,
               MAX(CASE WHEN CASE_TYPE = 'CN'  THEN DAYS_IN_DEBT END) AS DAYS_IN_DEBT_CN,
               MAX(CASE WHEN CASE_TYPE = 'CPR' THEN DAYS_IN_DEBT END) AS DAYS_IN_DEBT_CPR,
               MAX(CASE WHEN CASE_TYPE = 'CSE' THEN DAYS_IN_DEBT END) AS DAYS_IN_DEBT_CSE,
               MAX(CASE WHEN CASE_TYPE = 'NCP' THEN DAYS_IN_DEBT END) AS DAYS_IN_DEBT_NCP,

               MAX(CASE WHEN CASE_TYPE = 'CN'  THEN DEBT_OPENED_CASE_TYP END) AS DEBT_OPENED_CN FORMAT=DATE9.,
               MAX(CASE WHEN CASE_TYPE = 'CPR' THEN DEBT_OPENED_CASE_TYP END) AS DEBT_OPENED_CPR FORMAT=DATE9.,
               MAX(CASE WHEN CASE_TYPE = 'CSE' THEN DEBT_OPENED_CASE_TYP END) AS DEBT_OPENED_CSE FORMAT=DATE9.,
               MAX(CASE WHEN CASE_TYPE = 'NCP' THEN DEBT_OPENED_CASE_TYP END) AS DEBT_OPENED_NCP FORMAT=DATE9.

          FROM DID_TMP.DAYS_IN_DEBT_CASE_TYP_TN
         WHERE DEBT_CLOSED_CASE_TYP = .
      GROUP BY IRD_NUMBER,
               HERITAGPROFILENUMBER;
QUIT;
/************************************************************************************************************************/
DATA DID_TMP.DAYS_IN_DEBT_TEMP;
MERGE DID_TMP.DAYS_IN_DEBT_CASE_TYP_FN
      DID_TMP.DAYS_IN_DEBT_LOCATION_FN (WHERE=(DEBT_CLOSED_LOCATION = .));
BY IRD_NUMBER HERITAGPROFILENUMBER;
RUN;
/************************************************************************************************************************/
DATA TDW_CURR.DAYS_IN_DEBT 
     (DROP=DEBT_CLOSED_LOCATION DEBT_CLOSED_CUSTOMER
    RENAME=(HERITAGPROFILENUMBER=LOCATION_NUMBER));
MERGE DID_TMP.DAYS_IN_DEBT_TEMP
      DID_TMP.DAYS_IN_DEBT_CUSTOMER_FN (WHERE=(DEBT_CLOSED_CUSTOMER = .));
BY IRD_NUMBER;
RUN;
PROC SORT DATA=TDW_CURR.DAYS_IN_DEBT; BY IRD_NUMBER LOCATION_NUMBER;RUN;



/************************************************************************************************************************/
/* Days-In-Debt Summary Data
/*  This code produces two tables;
/*  1 - CRADC.DEBT_HISTORY
/*      This is a permanant SAS dataset that will reside in "/data/shared/iic/intel_delivery/common/temp_data/cradc/"
/*      containing a complete history for every debt case for every customer.
/*
/*  2 - CRADC_DEBT_HISTORY_SUMM
/*      This is a work dataset that will get incorporated in the CRADC_SVOC table, bringing in some variable such as;
/*       - Average_Collection_Time (by _CN, _CPR, _CSE and _NCP case types)
/*       - Last_Case_Closed        (by _CN, _CPR, _CSE and _NCP case types)
/*       - First_Time_Debt         (by _CN, _CPR, _CSE and _NCP case types)
/************************************************************************************************************************/
%let syscc=0; 

PROC SORT DATA=Did_Tmp.DAYS_IN_DEBT_CASE_TYP_TN; BY IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE DEBT_OPENED_CASE_TYP; RUN;


DATA CRADC.DEBT_HISTORY;
 SET Did_Tmp.DAYS_IN_DEBT_CASE_TYP_TN;
  BY IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE;
RETAIN DID_CLOSED CASE_COUNT;
 IF FIRST.CASE_TYPE THEN DO;
    DID_CLOSED = 0;
    Case_Count = 1;
    First_Time_Debt = 'Y';
    END;
ELSE DO;
    First_Time_Debt = 'N';
    Case_Count = CASE_COUNT + 1;
    END;
IF DEBT_CLOSED_CASE_TYP NE . THEN DO;
    DID_CLOSED = DID_CLOSED + DAYS_IN_DEBT;
    END;
IF Case_Count > 1 THEN Average_Collection_Time = ROUND(DID_CLOSED/CASE_COUNT,1);



OUTPUT;
RUN;

/*PROC DATASETS LIB=DID_TMP NOLIST; DELETE DAYS_IN_DEBT_CASE_TYP_TN; RUN; QUIT;*/

/*PROC FREQ DATA=CRADC.DEBT_HISTORY; WHERE First_Time_Debt = 'Y'; TABLE Average_Collection_Time; RUN;*/

DATA CradcWrk.CRADC_DEBT_HISTORY_CN  (RENAME=(Case_Count = Case_Count_CN  Average_Collection_Time = Average_Collection_Time_CN  DEBT_CLOSED_CASE_TYP = Last_Case_Closed_CN  First_Time_Debt = First_Time_Debt_CN)  KEEP=IRD_NUMBER HERITAGPROFILENUMBER Case_Count Average_Collection_Time DEBT_CLOSED_CASE_TYP First_Time_Debt)
     CradcWrk.CRADC_DEBT_HISTORY_CPR (RENAME=(Case_Count = Case_Count_CPR Average_Collection_Time = Average_Collection_Time_CPR DEBT_CLOSED_CASE_TYP = Last_Case_Closed_CPR First_Time_Debt = First_Time_Debt_CPR) KEEP=IRD_NUMBER HERITAGPROFILENUMBER Case_Count Average_Collection_Time DEBT_CLOSED_CASE_TYP First_Time_Debt)
     CradcWrk.CRADC_DEBT_HISTORY_CSE (RENAME=(Case_Count = Case_Count_CSE Average_Collection_Time = Average_Collection_Time_CSE DEBT_CLOSED_CASE_TYP = Last_Case_Closed_CSE First_Time_Debt = First_Time_Debt_CSE) KEEP=IRD_NUMBER HERITAGPROFILENUMBER Case_Count Average_Collection_Time DEBT_CLOSED_CASE_TYP First_Time_Debt)
     CradcWrk.CRADC_DEBT_HISTORY_NCP (RENAME=(Case_Count = Case_Count_NCP Average_Collection_Time = Average_Collection_Time_NCP DEBT_CLOSED_CASE_TYP = Last_Case_Closed_NCP First_Time_Debt = First_Time_Debt_NCP) KEEP=IRD_NUMBER HERITAGPROFILENUMBER Case_Count Average_Collection_Time DEBT_CLOSED_CASE_TYP First_Time_Debt);
 SET CRADC.DEBT_HISTORY;
  BY IRD_NUMBER HERITAGPROFILENUMBER CASE_TYPE;
IF LAST.CASE_TYPE THEN DO;
    IF DEBT_CLOSED_CASE_TYP  THEN First_Time_Debt = '';
    IF CASE_TYPE = 'CN'  THEN OUTPUT CradcWrk.CRADC_DEBT_HISTORY_CN;
    IF CASE_TYPE = 'CPR' THEN OUTPUT CradcWrk.CRADC_DEBT_HISTORY_CPR;
    IF CASE_TYPE = 'CSE' THEN OUTPUT CradcWrk.CRADC_DEBT_HISTORY_CSE;
    IF CASE_TYPE = 'NCP' THEN OUTPUT CradcWrk.CRADC_DEBT_HISTORY_NCP;
    END;
RUN;


DATA CradcWrk.CRADC_DEBT_HISTORY_SUMM_CC (KEEP=IRD_NUMBER HERITAGPROFILENUMBER CASE_COUNT:    RENAME=(HERITAGPROFILENUMBER = LOCATION_NUMBER))
     CradcWrk.CRADC_DEBT_HISTORY_SUMM_AC (KEEP=IRD_NUMBER HERITAGPROFILENUMBER AVERAGE_CO:    RENAME=(HERITAGPROFILENUMBER = LOCATION_NUMBER))
     CradcWrk.CRADC_DEBT_HISTORY_SUMM_LC (KEEP=IRD_NUMBER HERITAGPROFILENUMBER LAST_CASE_:    RENAME=(HERITAGPROFILENUMBER = LOCATION_NUMBER))
     CradcWrk.CRADC_DEBT_HISTORY_SUMM_FT (KEEP=IRD_NUMBER HERITAGPROFILENUMBER FIRST_TIME:    RENAME=(HERITAGPROFILENUMBER = LOCATION_NUMBER));
MERGE CradcWrk.CRADC_DEBT_HISTORY_CN
      CradcWrk.CRADC_DEBT_HISTORY_CPR
      CradcWrk.CRADC_DEBT_HISTORY_CSE
      CradcWrk.CRADC_DEBT_HISTORY_NCP;
BY IRD_NUMBER HERITAGPROFILENUMBER;
RUN;

DATA CradcWrk.CRADC_DEBT_HISTORY_SUMM;
MERGE CradcWrk.CRADC_DEBT_HISTORY_SUMM_CC
      CradcWrk.CRADC_DEBT_HISTORY_SUMM_AC
      CradcWrk.CRADC_DEBT_HISTORY_SUMM_LC
      CradcWrk.CRADC_DEBT_HISTORY_SUMM_FT;
BY IRD_NUMBER LOCATION_NUMBER;

PROC SORT DATA=CradcWrk.CRADC_DEBT_HISTORY_SUMM; BY IRD_NUMBER LOCATION_NUMBER; RUN;

PROC DATASETS LIB=CradcWrk NOLIST; 
DELETE CRADC_DEBT_HISTORY_CN 
CRADC_DEBT_HISTORY_CPR 
CRADC_DEBT_HISTORY_CSE 
CRADC_DEBT_HISTORY_NCP

CRADC_DEBT_HISTORY_SUMM_CC
CRADC_DEBT_HISTORY_SUMM_AC
CRADC_DEBT_HISTORY_SUMM_LC
CRADC_DEBT_HISTORY_SUMM_FT;
RUN;



