/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 123_excl_collection_stages.sas

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
PROC SQL;
CREATE TABLE WORK.TARGET_SCOPING_START AS
        SELECT 
      DISTINCT TODAY() AS DATE_EXTRACTED FORMAT = DATE9.,
               A.IRD_NUMBER,
               CASE WHEN B.HERITAGPROFILENUMBER IS NOT NULL THEN B.HERITAGPROFILENUMBER ELSE 1 END AS LOCATION_NUMBER,
               C.LAST_ACTION_DATE_CN AS LAST_ACTION_DATE,
               C.LAST_CASE_ACTION_TYPE_CODE_CN AS LAST_ACTION_CODE,
               C.NEXT_ACTION_DATE_CN AS NEXT_ACTION_DATE,
               C.NEXT_CASE_ACTION_TYPE_CODE_CN AS NEXT_ACTION_CODE,
               C.FIRST_TIME_DEBT_CN AS FIRST_CASE
          FROM TDW_CURR.TBL_COLLECT       A
     LEFT JOIN TDW_CURR.TBL_NZ_ACCGSTINFO B ON A.IRD_NUMBER = B.IRD_NUMBER AND
                                               A.CUSTOMER_KEY = B.CUSTOMER_KEY AND
                                               B.EFFECTIVE_TO IS NULL AND
                                               B.CURRENT_REC_FLAG = 'Y'
     LEFT JOIN CRADC.CRADC_SVOC           C ON B.IRD_NUMBER = C.IRD_NUMBER AND
                                               B.HERITAGPROFILENUMBER = C.LOCATION_NUMBER
         WHERE A.VER = 0 AND
               A.CURRENT_REC_FLAG = 'Y' AND
               A.CLOSED_DATE IS NULL AND
               A.EFFECTIVE_TO IS NULL;

QUIT;


/*********************************************************************************************************************************/
/*  Aim is to have SVOC of customer even with multiple locations - Multi Loc customers will be dealt with separately in their own
/*  campaign
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE WORK.SCOPING_W_CT_START
AS SELECT a.*,
       COUNT(a.IRD_NUMBER) AS Multi_Loc
FROM WORK.TARGET_SCOPING_START AS a
GROUP BY a.IRD_NUMBER;
QUIT;

Proc Sort data = WORK.SCOPING_W_CT_START;
	BY IRD_NUMBER LOCATION_NUMBER;
RUN;

Data WORK.SCOPING_W_CT_START;
	SET WORK.SCOPING_W_CT_START;
		BY IRD_NUMBER LOCATION_NUMBER ;
	IF FIRST.IRD_NUMBER THEN output;
RUN;

/*********************************************************************************************************************************/
/*Now we have a SVOC we join back onto TDW for Collection Info*/
/*multiple collections present at this stage*/
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE WORK.START_COLLECTION_INFO AS
        SELECT 
      DISTINCT A.*,
               B.COLLECT_KEY,
               B.VER,
               B.CATEGORY_FIELD,
               B.COLLECT_TYPE,
               B.CUSTOMER_KEY,
               B.CREATION_DATE,
               B.OWNER,
               B.CLOSED_DATE,
               B.STAGE,
               B.EFFECTIVE_FROM
          FROM WORK.SCOPING_W_CT_START A
     LEFT JOIN TDW_CURR.TBL_COLLECT    B ON A.IRD_NUMBER = B.IRD_NUMBER
         WHERE B.VER = 0 AND
               B.CURRENT_REC_FLAG = 'Y' AND
               B.CLOSED_DATE IS NULL AND
               B.EFFECTIVE_TO IS NULL;
QUIT;
/*Creating a work table for all collections*/

DATA EXCLTEMP.START_COLLECTION_ALL;
SET WORK.START_COLLECTION_INFO;
/*UPDATING OWNER FIELD TO REPLACE THE SPACES WITH NULLS*/
OWNER = COMPBL(OWNER);
RUN;

/*********************************************************************************************************************************/
/*creating a table for collection count summary*/
/*multiple collections present at this stage*/
/*********************************************************************************************************************************/

PROC SQL;
  CREATE TABLE WORK.START_COLLECTION_CODES_ADJ AS 
        SELECT A.*,
               CASE WHEN A.STAGE='DEDMAN' THEN 1 ELSE 0 END AS DEDMAN_CODE,
               CASE WHEN A.STAGE='CLSPEN' THEN 1 ELSE 0 END AS CLSPEN_CODE,
               CASE WHEN A.STAGE='INSPRO' THEN 1 ELSE 0 END AS INSPRO_CODE,
               CASE WHEN A.STAGE='PRPSEC' THEN 1 ELSE 0 END AS PRPSEC_CODE,
               CASE WHEN A.STAGE='PRPLQD' THEN 1 ELSE 0 END AS PRPLQD_CODE,
               CASE WHEN A.STAGE='PRPBNK' THEN 1 ELSE 0 END AS PRPBNK_CODE,
               CASE WHEN A.STAGE='RECWRT' THEN 1 ELSE 0 END AS RECWRT_CODE,
               CASE WHEN A.STAGE='LGLHLD' THEN 1 ELSE 0 END AS LGLHLD_CODE,
               CASE WHEN A.STAGE='INAUD'  THEN 1 ELSE 0 END AS INAUD_CODE,
               CASE WHEN A.STAGE='NEGPRO' THEN 1 ELSE 0 END AS NEGPRO_CODE,
               CASE WHEN A.STAGE='STRNEG' THEN 1 ELSE 0 END AS STRNEG_CODE,
               CASE WHEN A.STAGE='OBJLDG' THEN 1 ELSE 0 END AS OBJLDG_CODE,
               CASE WHEN A.STAGE='NOTREC' THEN 1 ELSE 0 END AS NOTREC_CODE,
               CASE WHEN A.STAGE='ADJPEN' THEN 1 ELSE 0 END AS ADJPEN_CODE,
               CASE WHEN A.STAGE='CSTPRO' THEN 1 ELSE 0 END AS CSTPRO_CODE,
               CASE WHEN A.STAGE='CMPBNK' THEN 1 ELSE 0 END AS CMPBNK_CODE,
               CASE WHEN A.STAGE='CMPLQD' THEN 1 ELSE 0 END AS CMPLQD_CODE,
               CASE WHEN A.STAGE='CMPPRO' THEN 1 ELSE 0 END AS CMPPRO_CODE,
               CASE WHEN A.STAGE='CMPREC' THEN 1 ELSE 0 END AS CMPREC_CODE,
               CASE WHEN A.STAGE='CMPSEC' THEN 1 ELSE 0 END AS CMPSEC_CODE,
               CASE WHEN A.STAGE='DISPUT' THEN 1 ELSE 0 END AS DISPUT_CODE,
               CASE WHEN A.STAGE='SUBADM' THEN 1 ELSE 0 END AS SUBADM_CODE,
               CASE WHEN A.STAGE='SUBBNK' THEN 1 ELSE 0 END AS SUBBNK_CODE,
               CASE WHEN A.STAGE='SUBLQD' THEN 1 ELSE 0 END AS SUBLQD_CODE,
               CASE WHEN A.STAGE='SUBPRO' THEN 1 ELSE 0 END AS SUBPRO_CODE,
               CASE WHEN A.STAGE='SUBSEC' THEN 1 ELSE 0 END AS SUBSEC_CODE,
               CASE WHEN A.STAGE='ENTRIA' THEN 1 ELSE 0 END AS ENTRIA_CODE,
               CASE WHEN A.STAGE='AVAIL'  THEN 1 ELSE 0 END AS AVAIL_CODE,
               CASE WHEN A.STAGE='ISSCOR' THEN 1 ELSE 0 END AS ISSCOR_CODE,
               CASE WHEN A.STAGE='MANDEF' THEN 1 ELSE 0 END AS MANDEF_CODE,
               CASE WHEN A.STAGE='PRPADM' THEN 1 ELSE 0 END AS PRPADM_CODE,
               CASE WHEN A.STAGE='PRPPRO' THEN 1 ELSE 0 END AS PRPPRO_CODE,
               CASE WHEN A.STAGE='THRPTY' THEN 1 ELSE 0 END AS THRPTY_CODE,
               CASE WHEN A.STAGE='TOCALL' THEN 1 ELSE 0 END AS TOCALL_CODE,
               CASE WHEN A.STAGE='INCAMP' THEN 1 ELSE 0 END AS INCAMP_CODE,
               CASE WHEN A.STAGE='DECEAS' THEN 1 ELSE 0 END AS DECEAS_CODE,
               CASE WHEN A.STAGE='NEWARR' THEN 1 ELSE 0 END AS NEWARR_CODE,
               CASE WHEN A.STAGE='LGLINP' THEN 1 ELSE 0 END AS LGLINP_CODE
            FROM WORK.START_COLLECTION_INFO A;
QUIT;

/*********************************************************************************************************************************/
/*Ranking the collections so we can put the most important collection through*/
/*So when we go back to SVOC we have the most important collection*/
/*ADDD IN THE DIFFERENT CATEGORIES TO EXPLAINING RANKINGS*/
/*********************************************************************************************************************************/

DATA WORK.START_COLLECTION_CODES_ADJ1;
 SET WORK.START_COLLECTION_CODES_ADJ;

/*********************************************************************************************************************************/
/*There are three different type of collections*/
/*1. Exclude regardless of other collections - sometimes we will require certain action codes in FIRST (Green in Excel Doc)*/
/*2. Exclude if its their only collection or if the other collections are in the exclude list - 
		sometimes will require certain action codes in FIRST (Blue/Yellow in Excel Doc)*/
/*3. Allow collection - these collections are OK to campaign (Pink in Excl Doc) */
/*The collections have been ranked by which of the three groups they fall into*/
/*********************************************************************************************************************************/
/*1. Exclude regardless of other collections - sometimes we will require certain action codes in FIRST (Green in Excel Doc)*/
/*********************************************************************************************************************************/

IF LGLHLD_code > 0 THEN COLLECTION_RANK = 1;
ELSE IF INAUD_code > 0 THEN COLLECTION_RANK = 2;
ELSE IF NEGPRO_code > 0 THEN COLLECTION_RANK = 3;
ELSE IF STRNEG_code > 0 THEN COLLECTION_RANK = 4;
ELSE IF OBJLDG_code > 0 THEN COLLECTION_RANK = 5;
ELSE IF NOTREC_code > 0 THEN COLLECTION_RANK = 6;
ELSE IF ADJPEN_code > 0 THEN COLLECTION_RANK = 7;
ELSE IF CSTPRO_code > 0 THEN COLLECTION_RANK = 8;
ELSE IF CMPBNK_code > 0 THEN COLLECTION_RANK = 9;
ELSE IF CMPLQD_code > 0 THEN COLLECTION_RANK = 10;
ELSE IF CMPPRO_code > 0 THEN COLLECTION_RANK = 11;
ELSE IF CMPREC_code > 0 THEN COLLECTION_RANK = 12;
ELSE IF CMPSEC_code > 0 THEN COLLECTION_RANK = 13;
ELSE IF DISPUT_code > 0 THEN COLLECTION_RANK = 14;
ELSE IF SUBADM_code > 0 THEN COLLECTION_RANK = 15;
ELSE IF SUBBNK_code > 0 THEN COLLECTION_RANK = 16;
ELSE IF SUBLQD_code > 0 THEN COLLECTION_RANK = 17;
ELSE IF SUBPRO_code > 0 THEN COLLECTION_RANK = 18;
ELSE IF SUBSEC_code > 0 THEN COLLECTION_RANK = 19;
ELSE IF DECEAS_Code > 0 THEN COLLECTION_RANK = 20; 
ELSE IF LGLINP_Code > 0 THEN COLLECTION_RANK = 21; 

/*2. Exclude if its their only collection or if the other collections are in the exclude list - 
		sometimes will require certain action codes in FIRST (Blue/Yellow in Excel Doc)*/

ELSE IF PRPLQD_code > 0 THEN COLLECTION_RANK = 22;
ELSE IF PRPSEC_code > 0 THEN COLLECTION_RANK = 23;
ELSE IF PRPBNK_code > 0 THEN COLLECTION_RANK = 24;
ELSE IF RECWRT_code > 0 THEN COLLECTION_RANK = 25;
ELSE IF CLSPEN_code > 0 THEN COLLECTION_RANK = 26;
ELSE IF INSPRO_code > 0 THEN COLLECTION_RANK = 27;

/*3. Allow collection - these collections are OK to campaign (Pink in Excl Doc) */

ELSE IF NEWARR_Code > 0 THEN COLLECTION_RANK = 28; 
ELSE IF DEDMAN_code > 0 THEN COLLECTION_RANK = 29;
ELSE IF ENTRIA_code > 0 THEN COLLECTION_RANK = 30;
ELSE IF ISSCOR_code > 0 THEN COLLECTION_RANK = 31;
ELSE IF MANDEF_code > 0 THEN COLLECTION_RANK = 32;
ELSE IF PRPADM_code > 0 THEN COLLECTION_RANK = 33;
ELSE IF PRPPRO_code > 0 THEN COLLECTION_RANK = 34;
ELSE IF THRPTY_code > 0 THEN COLLECTION_RANK = 35;
ELSE IF TOCALL_code > 0 THEN COLLECTION_RANK = 36;
ELSE IF INCAMP_code > 0 THEN COLLECTION_RANK = 37;
ELSE IF AVAIL_code > 0  THEN COLLECTION_RANK = 38;
ELSE COLLECTION_RANK = 999;

run;

/*********************************************************************************************************************************/
/*  There are instances where customers have more than one active collection. If this is the case classify the customer as a Multi 
/*  collection customer compressing the columns created above to a single ird number result is a a record with ird number as 
/*  primary key, count of collections in start and column for count of each stage the collection is at
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE WORK.START_COLLECTION_INFO_1
AS SELECT a.*,
sum(DEDMAN_Code) as DEDMAN_count,
sum(CLSPEN_Code) as CLSPEN_count,
sum(INSPRO_Code) as INSPRO_count,
sum(PRPSEC_Code) as PRPSEC_count,
sum(PRPLQD_Code) as PRPLQD_count,
sum(PRPBNK_Code) as PRPBNK_count,
sum(RECWRT_Code) as RECWRT_count,
sum(LGLHLD_Code) as LGLHLD_count,
sum(INAUD_Code) as  INAUD_count,
sum(NEGPRO_Code) as NEGPRO_count,
sum(STRNEG_Code) as STRNEG_count,
sum(OBJLDG_Code) as OBJLDG_count,
sum(NOTREC_Code) as NOTREC_count,
sum(ADJPEN_Code) as ADJPEN_count,
sum(CSTPRO_Code) as CSTPRO_count,
sum(CMPBNK_Code) as CMPBNK_count,
sum(CMPLQD_Code) as CMPLQD_count,
sum(CMPPRO_Code) as CMPPRO_count,
sum(CMPREC_Code) as CMPREC_count,
sum(CMPSEC_Code) as CMPSEC_count,
sum(DISPUT_Code) as DISPUT_count,
sum(SUBADM_Code) as SUBADM_count,
sum(SUBBNK_Code) as SUBBNK_count,
sum(SUBLQD_Code) as SUBLQD_count,
sum(SUBPRO_Code) as SUBPRO_count,
sum(SUBSEC_Code) as SUBSEC_count,
sum(ENTRIA_Code) as ENTRIA_count,
sum(AVAIL_Code) as  AVAIL_count,
sum(ISSCOR_Code) as ISSCOR_count,
sum(MANDEF_Code) as MANDEF_count,
sum(PRPADM_Code) as PRPADM_count,
sum(PRPPRO_Code) as PRPPRO_count,
sum(THRPTY_Code) as THRPTY_count,
sum(TOCALL_Code) as TOCALL_count,
sum(INCAMP_Code) as INCAMP_count,
sum(DECEAS_Code) as DECEAS_count,
sum(NEWARR_Code) as NEWARR_count,
sum(LGLINP_Code) as LGLINP_count
FROM WORK.start_collection_codes_adj1 a
GROUP BY a.IRD_NUMBER
;
QUIT;

/*********************************************************************************************************************************/
/*  There are instances where customers have more than one active collection. If this is the case classify the customer as a Multi 
/*  customer
/*  We now go back to SVOC and indicate with the multi collection variable where more than one collection exists
/*********************************************************************************************************************************/

PROC SQL;
CREATE TABLE WORK.START_COLLECTION_INFO_2
AS SELECT a.*,
COUNT(a.IRD_NUMBER) AS Multi_Collection
FROM WORK.START_COLLECTION_INFO_1 a
GROUP BY a.IRD_NUMBER;
QUIT;
/*********************************************************************************************************************************/
Proc Sort data = WORK.START_COLLECTION_INFO_2;
BY IRD_NUMBER COLLECTION_RANK LOCATION_NUMBER;
RUN;
/*********************************************************************************************************************************/
Data WORK.START_COLLECTION_INFO_2;
SET WORK.START_COLLECTION_INFO_2;
BY IRD_NUMBER COLLECTION_RANK LOCATION_NUMBER ;
IF FIRST.IRD_NUMBER THEN output;
RUN;

/*********************************************************************************************************************************/
/*  variable EXCL_COLLECTION = 'Y' acts an exclusion flag
/*  We have colloborated with Collections to decide what collections we would want to exclude
/*  Also what to do when there are multiple collections, debt in FIRST etc
/*  
/*  There are three different scenarios
/*  1. Exclude regardless of other collections - sometimes we will require certain action codes in FIRST (Green in Excel Doc)
/*  2. Exclude if its their only collection or if the other collections are in the exclude list - 
/*     sometimes will require certain action codes in FIRST (Blue/Yellow in Excel Doc)
/*  3. Allow collection - these collections are OK to campaign (Pink in Excl Doc)
/*
/*  Excluding these customers regardless of other collections
/*********************************************************************************************************************************/

DATA WORK.START_COLLECTION_INFO_3;
SET WORK.START_COLLECTION_INFO_2;

length      COLLECTION_STAGE $40;

/*1. Exclude regardless of other collections - sometimes we will require certain action codes in FIRST (Green in Excel Doc)*/

IF ((LGLHLD_count > 0 AND FIRST_CASE = 'N') 
OR (LGLHLD_count > 0
AND (LAST_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ', 'CS', '218', 'LIQ', 'LQPD', 'VAD', 'RCPD', 'VAPD', 'WO2', 'W03', 'W04', 'W07')
OR NEXT_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ', 'CS', '218', 'LIQ', 'LQPD', 'VAD', 'RCPD', 'VAPD', 'WO2', 'W03', 'W04', 'W07'))))

OR 
((LGLINP_count > 0 AND FIRST_CASE = 'N') 
OR (LGLINP_count > 0
AND (LAST_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ', 'CS', '218', 'LIQ', 'LQPD', 'VAD', 'RCPD', 'VAPD', 'WO2', 'W03', 'W04', 'W07')
OR NEXT_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ', 'CS', '218', 'LIQ', 'LQPD', 'VAD', 'RCPD', 'VAPD', 'WO2', 'W03', 'W04', 'W07'))))

OR 
((INAUD_count > 0 AND FIRST_CASE = 'N')
OR (INAUD_count > 0
AND (LAST_ACTION_CODE IN ('INV', 'HLT', 'CS', 'DS', 'LQPD')
OR NEXT_ACTION_CODE IN ('INV', 'HLT', 'CS', 'DS', 'LQPD'))))

OR 
((NEGPRO_count > 0 AND FIRST_CASE = 'N')
OR (NEGPRO_count > 0
AND (LAST_ACTION_CODE IN ('NEG8', '218', 'CS', 'DS', 'LQPD', 'W07', 'W08')
OR NEXT_ACTION_CODE IN ('NEG8', '218', 'CS', 'DS', 'LQPD', 'W07', 'W08'))))

OR 
((STRNEG_count > 0 AND FIRST_CASE = 'N')
OR (STRNEG_count > 0
AND (LAST_ACTION_CODE IN ('NEG8', 'CS', 'LIQ', '218', 'DS', 'HRD', 'HRDA', 'W07', 'W08')
OR NEXT_ACTION_CODE IN ('NEG8', 'CS', 'LIQ', '218', 'DS', 'HRD', 'HRDA', 'W07', 'W08'))))

OR 
((OBJLDG_count > 0 AND FIRST_CASE = 'N')
OR (OBJLDG_count > 0
AND (LAST_ACTION_CODE IN ('OBJ', '218', 'CS', 'LIQ', 'EOJ', 'INV')
OR NEXT_ACTION_CODE IN ('OBJ', '218', 'CS', 'LIQ', 'EOJ', 'INV'))))

OR 
((NOTREC_count > 0 AND FIRST_CASE = 'N')
OR (NOTREC_count > 0
AND (LAST_ACTION_CODE IN ('RCVR', 'RCPD', 'LQPD', 'LIQ')
OR NEXT_ACTION_CODE IN ('RCVR', 'RCPD', 'LQPD', 'LIQ'))))

OR 
((ADJPEN_count > 0 AND FIRST_CASE = 'N')
OR (ADJPEN_count > 0
AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8', '218', 'CS', 'LIQ', 'INV', 'LQPD')
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8', '218', 'CS', 'LIQ', 'INV', 'LQPD'))))

OR 
((CSTPRO_count > 0 AND FIRST_CASE = 'N')
OR (CSTPRO_count > 0
AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8', '218', 'CS', 'DS', 'BKPT', 'INV')
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8', '218', 'CS', 'DS', 'BKPT', 'INV'))))

OR 
(CMPBNK_count > 0 OR CMPLQD_count > 0 OR CMPPRO_count > 0 OR CMPREC_count > 0 OR CMPSEC_count > 0 OR DISPUT_count > 0 
OR SUBADM_count > 0 OR SUBBNK_count > 0 OR SUBLQD_count > 0 OR SUBPRO_count > 0 OR SUBSEC_count > 0 OR DECEAS_count > 0)

THEN EXCL_COLLECTION ='Y';


/*2. Exclude if its their only collection or if the other collections are in the exclude list - 
		sometimes will require certain action codes in FIRST (Blue/Yellow in Excel Doc)*/

/*Excluding these customers if it's their only collection*/
ELSE IF 
MULTI_COLLECTION = 1 AND

(

/*We don't require CLSPEN collections to have debt as they an still be open and have no debt*/
/*OR */
((CLSPEN_count > 0 AND FIRST_CASE = 'N') 
OR (CLSPEN_count > 0 AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8') 
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8'))))

OR
((INSPRO_count > 0 AND FIRST_CASE = 'N')
OR (INSPRO_count > 0 AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8') 
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8'))))

OR
((PRPSEC_count > 0 AND FIRST_CASE = 'N')
OR (PRPSEC_count > 0 AND (LAST_ACTION_CODE IN ('CHOR', 'DW') 
OR NEXT_ACTION_CODE IN ('CHOR', 'DW'))))

OR
((PRPLQD_count > 0 AND FIRST_CASE = 'N')
OR (PRPLQD_count > 0 AND (LAST_ACTION_CODE IN ('CS', '218', 'LIQ', 'LQPD', 'OBJ') 
OR NEXT_ACTION_CODE IN ('CS', '218', 'LIQ', 'LQPD', 'OBJ'))))

OR
((PRPBNK_count > 0 AND FIRST_CASE = 'N')
OR (PRPBNK_count > 0 AND (LAST_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ')
OR NEXT_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ'))))

OR
((RECWRT_count > 0 AND FIRST_CASE = 'N')
OR (RECWRT_count > 0 AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8') 
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8'))))
)
THEN EXCL_COLLECTION ='Y';

/*Excluding applicable multi collection customers*/
ELSE IF
MULTI_COLLECTION > 1 AND

(

/*We don't require CLSPEN collections to have debt as they an still be open and have no debt*/
/*OR */
((CLSPEN_count > 0 AND FIRST_CASE = 'N')
OR (CLSPEN_count > 0 AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8') 
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8'))))

OR
((INSPRO_count > 0 AND FIRST_CASE = 'N')
OR (INSPRO_count > 0 AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8') 
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8'))))

OR
((PRPSEC_count > 0 AND FIRST_CASE = 'N')
OR (PRPSEC_count > 0 AND (LAST_ACTION_CODE IN ('CHOR', 'DW') 
OR NEXT_ACTION_CODE IN ('CHOR', 'DW'))))

OR
((PRPLQD_count > 0 AND FIRST_CASE = 'N')
OR (PRPLQD_count > 0 AND (LAST_ACTION_CODE IN ('CS', '218', 'LIQ', 'LQPD', 'OBJ') 
OR NEXT_ACTION_CODE IN ('CS', '218', 'LIQ', 'LQPD', 'OBJ'))))

OR
((PRPBNK_count > 0 AND FIRST_CASE = 'N')
OR (PRPBNK_count > 0 AND (LAST_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ')
OR NEXT_ACTION_CODE IN ('DS', 'DDS', 'EOJ', 'COJ', 'BKPD', 'BKPT', 'OBJ'))))

OR
((RECWRT_count > 0 AND FIRST_CASE = 'N')
OR (RECWRT_count > 0 AND (LAST_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8') 
OR NEXT_ACTION_CODE IN ('WO1', 'WO2', 'WO3', 'WO4', 'WO5', 'WO6', 'WO7', 'WO8', 'WO9', 'WO10', 'WO11', 'HRDA', 'HRD', 'NEG8'))))
)

AND
(ENTRIA_count = 0 AND AVAIL_count = 0 AND ISSCOR_count = 0 AND MANDEF_count = 0 AND PRPADM_count = 0 AND PRPPRO_count = 0 
AND THRPTY_count = 0 AND TOCALL_count = 0 AND INCAMP_count = 0 AND DEDMAN_count = 0 AND NEWARR_count = 0)

THEN EXCL_COLLECTION ='Y';

/*3. Allow collection - these collections are OK to campaign (Pink in Excl Doc) */

/*Everyone Else*/
ELSE EXCL_COLLECTION ='N';

/*Giving Collections the full names*/

IF STAGE = 'DEDMAN' THEN COLLECTION_STAGE ='Manual Deduction';
ELSE IF STAGE = 'ENTRIA' THEN COLLECTION_STAGE ='Enter Into Instalment Arrangement';
ELSE IF STAGE = 'AVAIL' THEN COLLECTION_STAGE ='Available';
ELSE IF STAGE = 'ISSCOR' THEN COLLECTION_STAGE ='Issue Correspondence';
ELSE IF STAGE = 'MANDEF' THEN COLLECTION_STAGE ='Manual Deferral';
ELSE IF STAGE = 'PRPADM' THEN COLLECTION_STAGE ='Prepare Voluntary Administration';
ELSE IF STAGE = 'PRPPRO' THEN COLLECTION_STAGE ='Prepare Prosecution';
ELSE IF STAGE = 'THRPTY' THEN COLLECTION_STAGE ='Third Party Managed';
ELSE IF STAGE = 'TOCALL' THEN COLLECTION_STAGE ='Make Contact';
ELSE IF STAGE = 'INCAMP' THEN COLLECTION_STAGE ='In Campaign';
ELSE IF STAGE = 'CLSPEN' THEN COLLECTION_STAGE ='Close Pending';
ELSE IF STAGE = 'INSPRO' THEN COLLECTION_STAGE ='Resolution Pending';
ELSE IF STAGE = 'PRPSEC' THEN COLLECTION_STAGE ='Prepare Security';
ELSE IF STAGE = 'PRPLQD' THEN COLLECTION_STAGE ='Prepare Liquidation';
ELSE IF STAGE = 'PRPBNK' THEN COLLECTION_STAGE ='Prepare Insolvency';
ELSE IF STAGE = 'RECWRT' THEN COLLECTION_STAGE ='Prepare and Submit Recommendation';
ELSE IF STAGE = 'LGLHLD' THEN COLLECTION_STAGE ='Post Legal';
ELSE IF STAGE = 'INAUD' THEN COLLECTION_STAGE ='In Audit';
ELSE IF STAGE = 'NEGPRO' THEN COLLECTION_STAGE ='Negotiation In Progress';
ELSE IF STAGE = 'STRNEG' THEN COLLECTION_STAGE ='Start Negotiation';
ELSE IF STAGE = 'OBJLDG' THEN COLLECTION_STAGE ='Objection Lodged';
ELSE IF STAGE = 'NOTREC' THEN COLLECTION_STAGE ='Notification of Receivership';
ELSE IF STAGE = 'ADJPEN' THEN COLLECTION_STAGE ='Adjustment Pending';
ELSE IF STAGE = 'CSTPRO' THEN COLLECTION_STAGE ='Consider Customers Proposal';
ELSE IF STAGE = 'CMPBNK' THEN COLLECTION_STAGE ='Insolvency Completed';
ELSE IF STAGE = 'CMPLQD' THEN COLLECTION_STAGE ='Liquidation Completed';
ELSE IF STAGE = 'CMPPRO' THEN COLLECTION_STAGE ='Prosecution Completed';
ELSE IF STAGE = 'CMPREC' THEN COLLECTION_STAGE ='Receivership Completed';
ELSE IF STAGE = 'CMPSEC' THEN COLLECTION_STAGE ='Security Completed';
ELSE IF STAGE = 'DISPUT' THEN COLLECTION_STAGE ='In Dispute';
ELSE IF STAGE = 'SUBADM' THEN COLLECTION_STAGE ='Submit Voluntary Administration';
ELSE IF STAGE = 'SUBBNK' THEN COLLECTION_STAGE ='Submit Insolvency';
ELSE IF STAGE = 'SUBLQD' THEN COLLECTION_STAGE ='Submit Liquidation';
ELSE IF STAGE = 'SUBPRO' THEN COLLECTION_STAGE ='Submit Prosecution';
ELSE IF STAGE = 'SUBSEC' THEN COLLECTION_STAGE ='Submit Security';
ELSE IF STAGE = 'DECEAS' THEN COLLECTION_STAGE ='Deceased';
ELSE IF STAGE = 'LGLINP' THEN COLLECTION_STAGE ='Legal Action in Progress';
ELSE IF STAGE = 'NEWARR' THEN COLLECTION_STAGE ='New Arrears';
ELSE COLLECTION_STAGE='???';

Run;

/*********************************************************************************************************************************/
/*This will be the final work SVOC table for the Collection Info*/
/*********************************************************************************************************************************/
proc sql;
create table ExclTemp.start_collection_svoc as
select

a.DATE_EXTRACTED
,a.IRD_NUMBER
,a.LOCATION_NUMBER
,a.LAST_ACTION_DATE
,a.LAST_ACTION_CODE
,a.NEXT_ACTION_DATE
,a.NEXT_ACTION_CODE
,a.FIRST_CASE
,a.MULTI_LOC
,a.COLLECT_KEY
,a.VER
,a.CATEGORY_FIELD
,a.COLLECT_TYPE
,a.CUSTOMER_KEY
,a.CREATION_DATE
,a.CLOSED_DATE
,a.STAGE AS COLLECTION_CODE
,a.COLLECTION_STAGE
,a.OWNER
,a.EFFECTIVE_FROM
,a.COLLECTION_RANK
,a.MULTI_COLLECTION
,a.EXCL_COLLECTION

from WORK.START_COLLECTION_INFO_3 a;
quit;
PROC DATASETS LIB=WORK NOLIST; DELETE 
START_COLLECTION_CODES_ADJ TARGET_SCOPING_START SCOPING_W_CT_START 
START_COLLECTION_INFO START_COLLECTION_CODES_ADJ1 START_COLLECTION_INFO_1 
START_COLLECTION_INFO_2 START_COLLECTION_INFO_3;
RUN;
/*********************************************************************************************************************************/

