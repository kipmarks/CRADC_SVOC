/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 113_excl_overseas_taxpayers.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Changed direct connection to Oracle to use of data extracted to EDW_CURR
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/*********************************************************************************************************************************/
/*  Identify those who are not residing in NZ (Overseas taxpayers). ;
/*********************************************************************************************************************************/
/*Notes:			Only changes made to remove limit to only radc svoc customers. Also added
/*				Child Support from Richards provided code.
/*
/*				(cmp_Overseas_ClientC) - known issue with this. Sometimes staff end 
/*				date the BDA/NRB records whilst the customer is still out of the country. 
/*				If the customer pays off the loan whilst overseas we never receive
/*				future departure/arrival dates...meaning they look like they're
/*				overseas - should be low volume.
/*
/*  Notes CG 14Mar19:	The Overseas Address/Non-Resident information across FIRST and START does not exactly line up
/*  The main problem is there is 140K customers in FIRST who are Ceased, Struck Off or Deceased
/*  These records were not migrated into START so the customers do not exist in START
/*  These records will still exist in DSS.CUSTOMERS_CURRENT so can be continued to be extracted from there
/*  Only 4 of these 140K customers are in CRADC so not a major issue them not being in START
/*  Co-Existence Status				Number of Customers		% Total Overseas Customers		% Total Overseas Exclude Ceased
/*  Both FIRST and START            489,707					75%								95%
/*  FIRST Only (Ceased, Stuck Off)	140,141					21%								-
/*  FIRST Only (Other)				 14,143					2%								3%
/*  START Only						 13,114					2%								2%
/*  Total							657,105
/*********************************************************************************************************************************/
/*  *PART 1: FIRST 
/*********************************************************************************************************************************/
/*a. Overseas indicator from Client Codes table where Client_Code_Value = 'NRB' - Non Resident Borrower 
/*  'BDA' - Border Departure/Arrive to explore at a later date.
/*********************************************************************************************************************************/
proc sql;
create table EXCLTEMP.cmp_Overseas_ClientC 
(label = 'This contains all IRD_number with a NRB client_code') AS
        SELECT IRD_NUMBER,
               LOCATION_NUMBER,
               CLIENT_CODE_VALUE
          FROM EDW_CURR.CLIENT_CODES_VALL
         WHERE DATE_CEASED IS NULL AND
               CLIENT_CODE_VALUE IN ('NRB') AND
               DATEPART(DATE_START) <= "&eff_date."D AND
               (DATEPART(DATE_END) > "&eff_date."D OR DATE_END IS NULL);
QUIT;
/*********************************************************************************************************************************/
/*b. Overseas indicator from Customers Current table where Address_Status = 'O' OR Resident_Indicator = 'N'
/*				(cmp_Overseas_Addr_Res) - Identical to the old camexcl process, has a
/*				limit on location 1 - have left as is.
/* Updated Feb 2018 Aaron Parker KG																		  
/*********************************************************************************************************************************/
proc sql;
CREATE TABLE OVERSEAS_ADDR_RES AS 
        SELECT A.IRD_NUMBER,
               A.LOCATION_NUMBER,
               A.ADDRESS_STATUS,
               A.RESIDENT_INDICATOR AS ResidentIndicatorFIRST /*Need to use both FIRST and START*/
          FROM EDW_CURR.CUSTOMERS_CURRENT_VALL A
         WHERE (A.ADDRESS_STATUS = 'O' OR A.RESIDENT_INDICATOR = 'N') AND
               A.LOCATION_NUMBER = 1;
QUIT;

/*********************************************************************************************************************************/
/* c. Have overseas Child support
/* Added Feb2018 Aaron Parker KG
/*********************************************************************************************************************************/
DATA OVERSEAS_CHILD_SUPPORT_DEBT (KEEP=IRD_NUMBER LOCATION_NUMBER TAX_TYPE);
SET EDW_CURR.CASES;
WHERE CASE_TYPE_CODE = 'CSR';
IF CASE_CATEGORY_CODE IN (30,31,32) THEN TAX_TYPE = 'NCP';
IF CASE_CATEGORY_CODE IN (40,41,42) THEN TAX_TYPE = 'CPR';
IF TAX_TYPE = '' THEN DELETE;
RUN;
DATA OVERSEAS_CHILD_SUPPORT_ASMT (KEEP=IRD_NUMBER LOCATION_NUMBER TAX_TYPE);
RETAIN IRD_NUMBER LOCATION_NUMBER;
SET EDW_CURR.CS_ASSESSMENTS;
LOCATION_NUMBER = 1;
RUN;
DATA OVERSEAS_CHILD_SUPPORT_USER (KEEP=IRD_NUMBER LOCATION_NUMBER TAX_TYPE OFFICER_USER_ID);
SET EDW_CURR.TAX_CSA;
RUN;
PROC SORT DATA=OVERSEAS_CHILD_SUPPORT_DEBT; BY IRD_NUMBER LOCATION_NUMBER TAX_TYPE; RUN;
PROC SORT DATA=OVERSEAS_CHILD_SUPPORT_ASMT; BY IRD_NUMBER LOCATION_NUMBER TAX_TYPE; RUN;
PROC SORT DATA=OVERSEAS_CHILD_SUPPORT_USER; BY IRD_NUMBER LOCATION_NUMBER TAX_TYPE; RUN;
DATA OVERSEAS_CHILD_SUPPORT;
MERGE  OVERSEAS_CHILD_SUPPORT_DEBT (IN=DEBT)
       OVERSEAS_CHILD_SUPPORT_ASMT (IN=ASMT)
       OVERSEAS_CHILD_SUPPORT_USER (IN=USER);
BY IRD_NUMBER LOCATION_NUMBER;
IF (DEBT OR ASMT) AND OFFICER_USER_ID IN ('27RECINZ','27RECICN','27INTLP', '27INTLN', 
                                          '27OZPT',  '27RECIP3','27OZTR',  '27RECIRI',
                                          '27RECIN', '27RECIOT','27RECIGE','27OZCO')
   THEN OUTPUT;
RUN;
PROC SORT DATA=OVERSEAS_CHILD_SUPPORT(KEEP=IRD_NUMBER LOCATION_NUMBER OFFICER_USER_ID) NODUPKEY;BY IRD_NUMBER LOCATION_NUMBER; RUN;
PROC SORT DATA=EXCLTEMP.cmp_OVERSEAS_CLIENTC NODUPKEY; BY IRD_NUMBER LOCATION_NUMBER; RUN;
PROC SORT DATA=OVERSEAS_ADDR_RES NODUPKEY; BY IRD_NUMBER LOCATION_NUMBER; RUN;

*********************************************************************;
*PART 2: START ;
*********************************************************************;
*********************************************************************;
*a. Customer Country START;
/*If you bring in Mailing Address customers you can add another 1K~ customers*/
*********************************************************************;
DATA WORK.OVERSEAS_START_CUSTOMER (KEEP = IRD_NUMBER CUSTOMER_KEY ADDRESS_TYPE CITY COUNTRY
                                 RENAME = (ADDRESS_TYPE = ADDRESS_TYPE_S_C CITY = CITY_S_C COUNTRY = COUNTRY_S_C));
 SET TDW_CURR.TBL_CUSTOMERINFO_VALL;  
WHERE EFFECTIVE_TO IS NULL AND COUNTRY NE 'NEZ' AND COUNTRY NE '' AND ADDRESS_TYPE = 'LOC' AND CEASE_DATE IS NULL AND CURRENT_REC_FLAG = 'Y';
RUN;
*********************************************************************;
*b. Current Tax Resident Indicator in START;
*********************************************************************;
DATA WORK.OVERSEAS_TAX_RESIDENT (KEEP=IRD_NUMBER CUSTOMER_KEY CURRENT_TAX_RESIDENCY RENAME=(CURRENT_TAX_RESIDENCY = CurrentTaxResidency));
MERGE   TDW_CURR.TBL_CUSTOMER_VALL       (IN=A KEEP=IRD_NUMBER CUSTOMER_KEY DOC_KEY CURRENT_REC_FLAG 	WHERE= (CURRENT_REC_FLAG = 'Y'))
		TDW_CURR.TBL_NZ_CUSTOMERSTD_VALL (IN=B KEEP=DOC_KEY CURRENT_REC_FLAG CURRENT_TAX_RESIDENCY 		WHERE= (CURRENT_REC_FLAG = 'Y' AND CURRENT_TAX_RESIDENCY NE 'NEZ' AND CURRENT_TAX_RESIDENCY NE ''));
BY DOC_KEY;
IF A AND B;
RUN;
*********************************************************************;
*c. Address Record in START
*********************************************************************;
/*Address, City and Country get a _S_A at the end*/
/*This is to help with the final table so you can tell these variables are from START and Addresses table*/
DATA WORK.OVERSEAS_START_ADDRESS (KEEP=IRD_NUMBER CUSTOMER_KEY ADDRESS_TYPE CITY COUNTRY RENAME=(ADDRESS_TYPE = ADDRESS_TYPE_S_A CITY = CITY_S_A COUNTRY = CountrySTARTAddress));
SET TDW_CURR.TBL_ADDRESSRECORD_VALL;
WHERE ADDRESS_TYPE = 'LOC' AND COUNTRY NE 'NEZ' AND COUNTRY NE '' AND ACTIVE = 1 AND CURRENT_REC_FLAG = 'Y';
RUN;

PROC SORT DATA=WORK.OVERSEAS_START_CUSTOMER NODUPKEY; BY IRD_NUMBER; RUN;
PROC SORT DATA=WORK.OVERSEAS_TAX_RESIDENT   NODUPKEY; BY IRD_NUMBER; RUN;
PROC SORT DATA=WORK.OVERSEAS_START_ADDRESS  NODUPKEY; BY IRD_NUMBER; RUN;

/*********************************************************************************************************************************/
/*PART 3: FINAL 
/*********************************************************************************************************************************/
DATA CMP_OVERSEAS_ADDR_RES ;
	MERGE 	WORK.OVERSEAS_ADDR_RES
			EXCLTEMP.CMP_OVERSEAS_CLIENTC
			WORK.OVERSEAS_CHILD_SUPPORT (RENAME=(OFFICER_USER_ID=NCP_OFFICER_USER_ID))
			WORK.OVERSEAS_START_CUSTOMER
			WORK.OVERSEAS_TAX_RESIDENT
			WORK.OVERSEAS_START_ADDRESS
			;
BY IRD_NUMBER;
RUN;

PROC SORT DATA=CMP_OVERSEAS_ADDR_RES NODUPKEY; BY IRD_NUMBER; RUN;

data EXCLTEMP.CMP_OVERSEAS_ADDR_RES; SET CMP_OVERSEAS_ADDR_RES; RUN;

PROC DATASETS LIB=WORK NOLIST; 
DELETE	OVERSEAS_ADDR_RES
		OVERSEAS_CHILD_SUPPORT_DEBT
      	OVERSEAS_CHILD_SUPPORT_ASMT
     	OVERSEAS_CHILD_SUPPORT_USER
       	OVERSEAS_CHILD_SUPPORT
		OVERSEAS_START_CUSTOMER 
		OVERSEAS_TAX_RESIDENT
		OVERSEAS_START_ADDRESS;
RUN;
/*********************************************************************************************************************************/
