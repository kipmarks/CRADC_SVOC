/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 111_excl_start_arrangements.sas

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
/*********************************************************************************************************************************/
/* START Arrangement Code
/*********************************************************************************************************************************/
/* This code is designed to get the most recent arrangement for a customer, whether or not the 
/*   arrangement is active.  Pulling out the most recent record for the Arrangement 
/* NEW START ARRANGEMENT CODE
/* Change this to camexl once final table is in camexcl schema
/*
/* Initial base population of all customers in the START arrangement table getting all their open 
/*  collections so we can work out eventually if all the debt is under arrangement
/*********************************************************************************************************************************/

/*DATA TBL_COLLECTPAYMENTPLAN_VALL;   SET TDW.TBL_COLLECTPAYMENTPLAN_VALL;   WHERE EFFECTIVE_TO = . AND CURRENT_REC_FLAG = 'Y' AND ACTIVE = 1; RUN;*/
/*DATA TBL_COLLECT_VALL;              SET TDW.TBL_COLLECT_VALL;              WHERE EFFECTIVE_TO = . AND CURRENT_REC_FLAG = 'Y' AND VER =0 AND CLOSED_DATE = .; RUN;*/
/*DATA TBL_NZ_INSTALMENTAGMTDEF_VALL; SET TDW.TBL_NZ_INSTALMENTAGMTDEF_VALL; WHERE EFFECTIVE_TO = . AND CURRENT_REC_FLAG = 'Y' AND VER =0; RUN;*/


PROC SQL;
  CREATE TABLE ARR_COL AS 
        SELECT A.IRD_NUMBER,
               A.CUSTOMER_KEY,
               B.COLLECT_KEY
          FROM TDW_CURR.TBL_COLLECTPAYMENTPLAN A
    INNER JOIN TDW_CURR.TBL_COLLECT            B ON A.IRD_NUMBER = B.IRD_NUMBER
         WHERE A.EFFECTIVE_TO IS NULL AND
               A.CURRENT_REC_FLAG = 'Y' AND
               A.ACTIVE = 1 AND
               B.VER = 0 AND
               B.EFFECTIVE_TO IS NULL AND
               B.CURRENT_REC_FLAG = 'Y' AND
               B.CLOSED_DATE IS NULL;
/*This 2nd part is to get a small amount of customers with an active arrangement, but a closed collection*/
/*Still want to keep these people as they have a new collection*/
  CREATE TABLE ARR_ALL AS 
        SELECT A.IRD_NUMBER,
               A.CUSTOMER_KEY,
               A.COLLECT_KEY
          FROM TDW_CURR.TBL_COLLECTPAYMENTPLAN A
         WHERE A.EFFECTIVE_TO IS NULL AND
               A.CURRENT_REC_FLAG = 'Y' AND
               A.ACTIVE = 1;

/*Unioning together the two datasets*/
CREATE TABLE WORK.START_ARRANGEMENT_BUILD1 AS
        SELECT A.* FROM ARR_ALL A UNION
        SELECT B.* FROM ARR_COL B WHERE B.COLLECT_KEY NOT IN (SELECT COLLECT_KEY FROM ARR_ALL);
QUIT;

proc sql;
CREATE TABLE START_ARRANGEMENT_BUILD2 AS
        SELECT 
      DISTINCT A.IRD_NUMBER,
               A.COLLECT_KEY,
               A.CUSTOMER_KEY,
               1 AS LOCATION_NUMBER /*this will have the location number from CRADC SVOC once its running*/,
               B.PAYMENT_PLAN_KEY,
               B.FOLDER_KEY,
               B.INDICATOR_KEY,
               B.PAYMENT_PLAN_TYPE,
               B.STATUS,
               B.OWNER,
               B.CREATED,
               B.FREQUENCY,
               B.INSTALL_TYPE,
               B.INSTALLMENTS,
               ROUND(B.INSTALLMENT_AMOUNT,2) AS INSTALLMENT_AMOUNT,
               B.NEXT_INSTALLMENT_DUE,
               ROUND(B.PLAN_AMOUNT,2) AS PLAN_AMOUNT,
               ROUND(B.DOWNPAYMENT,2) AS DOWNPAYMENT,
               B.EFFECTIVE_FROM,
               ROUND(D.DIFFERENCE,2) AS DIFFERENCE,
               D.NEXTPOLICE,
               COUNT(A.CUSTOMER_KEY) AS NBR_OF_RECORDS,
               COUNT(DISTINCT A.COLLECT_KEY) AS NBR_OF_COLLECTION,
               COUNT(DISTINCT B.PAYMENT_PLAN_KEY) AS NBR_OF_ARRANGEMENT
          FROM START_ARRANGEMENT_BUILD1           A
     LEFT JOIN tdw_curr.TBL_COLLECTPAYMENTPLAN    B ON A.IRD_NUMBER = B.IRD_NUMBER AND
                                                       A.CUSTOMER_KEY = B.CUSTOMER_KEY AND
                                                       A.COLLECT_KEY = B.COLLECT_KEY AND
                                                       B.EFFECTIVE_TO IS NULL AND
                                                       B.CURRENT_REC_FLAG = 'Y' AND
                                                       B.ACTIVE = 1
     LEFT JOIN tdw_curr.TBL_NZ_INSTALMENTAGMTDEF  D ON A.IRD_NUMBER = D.IRD_NUMBER AND
                                                       A.CUSTOMER_KEY = D.CUSTOMER_KEY AND
                                                       B.PAYMENT_PLAN_KEY = D.PAYMENT_PLAN_KEY AND
                                                       D.VER = 0 AND
                                                       D.EFFECTIVE_TO IS NULL AND
                                                       D.CURRENT_REC_FLAG = 'Y'
/*Once CRADC SVOC is running use this join to get location number*/
/*  left join "67AWCH".cradc_svoc_vall c*/
/*      on a.ird_number=b.ird_number*/
/*      and a.customer_key=b.customer_key*/
      GROUP BY A.IRD_NUMBER,
               A.CUSTOMER_KEY,
               LOCATION_NUMBER;


QUIT;

/*Working out adherence*/

DATA START_ARRANGEMENT_BUILD4;
SET START_ARRANGEMENT_BUILD2;
/*********************************************************************************************************************************/
/*If the payment plan key is blank then that means there is no arrangement for the collection
/*When a customer has one collection under arrangement and the other collection is not under arrangement
/*then we count the collection not under arrangement as a NEWA element similar to FIRST 
/*A NEWA collection is given an adhering flag, so the customers adherence is based on their arrangement for the other collection
/*The NEWA collection will be dealt with the NEWA campaigns
/*********************************************************************************************************************************/
IF PAYMENT_PLAN_KEY = '' THEN NEWA = 1;
ELSE NEWA = 0;

/*********************************************************************************************************************************/
/*1st check on adherence
/*This is doing the same thing as the FIRST arrangement ahderence code essentially
/*Working out customers who have missed 3 payments are behind by a erain threshold (depending on the size of their arrangement)
/*********************************************************************************************************************************/
     IF PLAN_AMOUNT > 10000.01 AND ROUND((COALESCE(DIFFERENCE)/COALESCE(PLAN_AMOUNT))*100, 2) > 5 AND DIFFERENCE > COALESCE(INSTALLMENT_AMOUNT * 3) THEN PAYMENT_ADHERE ='N';
ELSE IF PLAN_AMOUNT > 1000.01  AND ROUND((COALESCE(DIFFERENCE)/COALESCE(PLAN_AMOUNT))*100, 2) > 10 AND DIFFERENCE > COALESCE(INSTALLMENT_AMOUNT * 3) THEN PAYMENT_ADHERE ='N';
ELSE IF PLAN_AMOUNT < 1000     AND PLAN_AMOUNT > 0.01 AND ROUND((COALESCE(DIFFERENCE)/COALESCE(PLAN_AMOUNT))*100, 2) > 30 AND DIFFERENCE > COALESCE(INSTALLMENT_AMOUNT * 3) THEN PAYMENT_ADHERE ='N';
ELSE PAYMENT_ADHERE='Y';

/*********************************************************************************************************************************/
/*2nd check on adherence
/*If the customers has anything above a strike 2 then are counted as not adhering
/*********************************************************************************************************************************/
     if status in ('ACT', 'APPROV', 'PNDAP1', 'PNDAP2', 'PNDAP3', 'PNDAP4', 'PNDAPP', 'STRKE1') then STATUS_ADHERE='Y';
else if status in ('STRKE2', 'STRKE3', 'DEF', 'CAN') then STATUS_ADHERE='N';
else STATUS_ADHERE='';


/*********************************************************************************************************************************/
/*If a customer is not adhering in either check then they get an arrangement_good = 0
/*********************************************************************************************************************************/
IF PAYMENT_ADHERE = 'N' OR STATUS_ADHERE = 'N' THEN ARRANGEMENT_GOOD = 0;
ELSE ARRANGEMENT_GOOD = 1;
RUN;

/*********************************************************************************************************************************/
/*Summing the NEWA elements and Arrangements Adherence so we can go back to SVOC
/*Ryan had issues with names
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE START_ARRANGEMENT_BUILD5 AS
        SELECT 
      DISTINCT A.IRD_NUMBER,
               A.LOCATION_NUMBER,
               A.CUSTOMER_KEY,
               SUM(NEWA) AS NBR_OF_NEWA,
               SUM(ARRANGEMENT_GOOD) AS NBR_OF_GOOD_ARR
          FROM START_ARRANGEMENT_BUILD4 A
      GROUP BY A.IRD_NUMBER,
               A.LOCATION_NUMBER,
               A.CUSTOMER_KEY;
QUIT;

/*********************************************************************************************************************************/
/*If the sum of good arrangements equals your total number of arrangements then you adhering
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE START_ARRANGEMENT_BUILD6 as

        SELECT 
      DISTINCT A.*,
               B.NBR_OF_NEWA,
               CASE WHEN B.NBR_OF_NEWA > 0 THEN 'Y' ELSE 'N' END AS NEWA_COLLECTION,
               CASE WHEN A.NBR_OF_RECORDS > B.NBR_OF_GOOD_ARR THEN 'N'
                    WHEN A.NBR_OF_RECORDS = B.NBR_OF_GOOD_ARR THEN 'Y'
                    ELSE '???' END AS ARRANGEMENT_ADHERE
          FROM START_ARRANGEMENT_BUILD4 A
    INNER JOIN START_ARRANGEMENT_BUILD5 B ON A.IRD_NUMBER = B.IRD_NUMBER AND
                                             A.CUSTOMER_KEY = B.CUSTOMER_KEY AND
                                             A.LOCATION_NUMBER = B.LOCATION_NUMBER;
QUIT;

/*********************************************************************************************************************************/
/*there are instances where customers have more than one active arrangement.
/*If this is the case classify the customer as a multi arrangement customer
/*Creating a final SVOC table
/*********************************************************************************************************************************/
PROC SORT DATA=START_ARRANGEMENT_BUILD6; BY IRD_NUMBER CUSTOMER_KEY LOCATION_NUMBER NEWA ARRANGEMENT_GOOD; RUN;
Data START_Arrangement_Build7; SET START_Arrangement_Build6; BY IRD_NUMBER CUSTOMER_KEY LOCATION_NUMBER; IF FIRST.IRD_NUMBER THEN output; RUN;
/*********************************************************************************************************************************/
/*Creating table with final variables
/*Need to change from work to camexcl
/*********************************************************************************************************************************/
PROC SQL;
  CREATE TABLE START_ARRANGEMENTS AS
        SELECT IRD_NUMBER,
               COLLECT_KEY,
               LOCATION_NUMBER,
               PAYMENT_PLAN_KEY,
               CUSTOMER_KEY,
               FOLDER_KEY,
               INDICATOR_KEY,
               PAYMENT_PLAN_TYPE,
               STATUS,
               OWNER,
               CREATED,
               FREQUENCY,
               INSTALL_TYPE,
               INSTALLMENTS,
               INSTALLMENT_AMOUNT,
               NEXT_INSTALLMENT_DUE,
               PLAN_AMOUNT,
               DOWNPAYMENT,
               EFFECTIVE_FROM,
               NBR_OF_RECORDS,
               NBR_OF_COLLECTION,
               NBR_OF_ARRANGEMENT,
               NEXTPOLICE,
               DIFFERENCE,
               NBR_OF_NEWA,
               NEWA_COLLECTION,
               PAYMENT_ADHERE,
               STATUS_ADHERE,
               ARRANGEMENT_ADHERE
          FROM START_ARRANGEMENT_BUILD7;
QUIT;

DATA EXCLTEMP.START_ARRANGEMENTS; SET START_ARRANGEMENTS; RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB = WORK NOLIST; DELETE ARR_: START_: TBL_:  ; RUN;
/*********************************************************************************************************************************/

