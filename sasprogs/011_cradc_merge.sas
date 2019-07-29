/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 11_cradc_merge.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Original module was 17_Combine_And_Migrate_To_EDW.sas
            Links back to EDW completely severed. EFF_DATE now determined in autoexec -
            eventually this will be passed through from parent process.
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/************************************************************************************************************************/
/*Now, we put all the hard work to practical use, and slap it all together.  Get ready...
/*
/*Most of the data tables in the prebuild are aligned along IRD Number/Location number.  However, some are just aligned
/*  along IRD Number.  So, the merging will happen in stages.
/*
/*First, we merge the DEBT and RETURNS section together with the CASE OFFICER data from first
/************************************************************************************************************************/
 DATA CradcWrk.CRADC_SVOC_TEMP_INITIAL;
MERGE CradcWrk.DEBT_SVOC          (IN=DEBT)
      CradcWrk.RTNS_SVOC          (IN=RTNS)
      CradcWrk.CASE_OFFICER_FIRST (IN=CASE_OFFICER);
BY IRD_NUMBER LOCATION_NUMBER;

/************************************************************************************************************************/
/*Only keep those where there is a debt or an outstanding return
/************************************************************************************************************************/
IF DEBT OR RTNS THEN OUTPUT;

RUN;

/************************************************************************************************************************/
/*Now we merge the initial table with the CUSTOMER KEY and CASE OFFICER data from START, as these are aligned by 
/*  IRD Number
/************************************************************************************************************************/
DATA CradcWrk.CRADC_SVOC_TEMP;
MERGE CRADC.CUSTOMER_KEYS                (IN=KEY)
      CradcWrk.CASE_OFFICER_START        (IN=START)
      CradcWrk.CRADC_SVOC_TEMP_INITIAL   (IN=SVOC);
BY IRD_NUMBER;
IF SVOC THEN OUTPUT;
RUN;

/************************************************************************************************************************/
/*Split the table into the base components, so it can be 
/*  'reconstructed' with the fields in the order I WANT them to be..
/************************************************************************************************************************/
DATA CradcWrk.CRADC_SVOC_TEMP_BASE     (DROP=DEBT: RTNS: FLAG: TOTAL: CASE_NUMBER: CASE_OFFICER: );     SET CradcWrk.CRADC_SVOC_TEMP; RUN;

DATA CradcWrk.CRADC_SVOC_TEMP_DEBT     (KEEP=IRD_NUMBER LOCATION_NUMBER DEBT:         ); SET CradcWrk.CRADC_SVOC_TEMP; RUN;
DATA CradcWrk.CRADC_SVOC_TEMP_CASE_NBR (KEEP=IRD_NUMBER LOCATION_NUMBER CASE_NUMBER:  ); SET CradcWrk.CRADC_SVOC_TEMP; RUN;
DATA CradcWrk.CRADC_SVOC_TEMP_CASE_OFF (KEEP=IRD_NUMBER LOCATION_NUMBER CASE_OFFICER: ); SET CradcWrk.CRADC_SVOC_TEMP; RUN;
DATA CradcWrk.CRADC_SVOC_TEMP_RTNS     (KEEP=IRD_NUMBER LOCATION_NUMBER RTNS:         ); SET CradcWrk.CRADC_SVOC_TEMP; RUN;
DATA CradcWrk.CRADC_SVOC_TEMP_FLAG     (KEEP=IRD_NUMBER LOCATION_NUMBER FLAG:         ); SET CradcWrk.CRADC_SVOC_TEMP; RUN;
DATA CradcWrk.CRADC_SVOC_TEMP_TOTAL    (KEEP=IRD_NUMBER LOCATION_NUMBER TOTAL:        ); SET CradcWrk.CRADC_SVOC_TEMP; RUN;


/************************************************************************************************************************/
/*Re-merge the data.  The order of the tables dictates the order
/*  of the fields in the final table.
/************************************************************************************************************************/
DATA  CradcWrk.CRADC_SVOC;
MERGE CradcWrk.CRADC_SVOC_TEMP_BASE (IN=BASE)
      CradcWrk.CRADC_SVOC_TEMP_FLAG
      CradcWrk.CRADC_SVOC_TEMP_TOTAL
      CradcWrk.CRADC_SVOC_TEMP_CASE_NBR
      CradcWrk.CRADC_SVOC_TEMP_CASE_OFF
      CradcWrk.CRADC_SVOC_TEMP_DEBT
      CradcWrk.CRADC_SVOC_TEMP_RTNS
      TDW_CURR.DAYS_IN_DEBT
      CradcWrk.AGE_OF_ELEMENTS_SUMM
      CradcWrk.ACTIONS_LAST_NEXT
      CradcWrk.CRADC_DEBT_HISTORY_SUMM;

BY IRD_NUMBER LOCATION_NUMBER;

IF BASE;

/************************************************************************************************************************/
/*Set the formats, so the the fields go into EDW with the correct
/*  format, not as 'BINARY DOUBLE' fields.
/************************************************************************************************************************/
FORMAT CUSTOMER_KEY                   22.0
       DEBT_BALANCE:                  18.2
       DEBT_PERIODS:                   9.0
       CASE_NUMBER:                    3.0
       RTNS:                           9.0
       TOTAL_DEBT_AMOUNT              18.2
       TOTAL_DEBT_START               18.2
       TOTAL_DEBT_FIRST               18.2
       TOTAL_DEFAULT_ASSESSMENTS       9.0
       TOTAL_DEBT_PERIODS              9.0
       TOTAL_OS_RETURNS                9.0;

/************************************************************************************************************************/
/*Set all the nulls to a default value, to maintain consistancy
/************************************************************************************************************************/
IF DEBT_BALANCE_CPR = .              THEN DEBT_BALANCE_CPR = 0;
IF DEBT_BALANCE_CSE = .              THEN DEBT_BALANCE_CSE = 0;
IF DEBT_BALANCE_FAM = .              THEN DEBT_BALANCE_FAM = 0;
IF DEBT_BALANCE_GST = .              THEN DEBT_BALANCE_GST = 0;
IF DEBT_BALANCE_INC = .              THEN DEBT_BALANCE_INC = 0;
IF DEBT_BALANCE_NCP = .              THEN DEBT_BALANCE_NCP = 0;
IF DEBT_BALANCE_OTH = .              THEN DEBT_BALANCE_OTH = 0;
IF DEBT_BALANCE_PAY = .              THEN DEBT_BALANCE_PAY = 0;
IF DEBT_BALANCE_SLS = .              THEN DEBT_BALANCE_SLS = 0;
IF DEBT_PERIODS_CPR = .              THEN DEBT_PERIODS_CPR = 0;
IF DEBT_PERIODS_CSE = .              THEN DEBT_PERIODS_CSE = 0;
IF DEBT_PERIODS_FAM = .              THEN DEBT_PERIODS_FAM = 0;
IF DEBT_PERIODS_GST = .              THEN DEBT_PERIODS_GST = 0;
IF DEBT_PERIODS_INC = .              THEN DEBT_PERIODS_INC = 0;
IF DEBT_PERIODS_NCP = .              THEN DEBT_PERIODS_NCP = 0;
IF DEBT_PERIODS_OTH = .              THEN DEBT_PERIODS_OTH = 0;
IF DEBT_PERIODS_PAY = .              THEN DEBT_PERIODS_PAY = 0;
IF DEBT_PERIODS_SLS = .              THEN DEBT_PERIODS_SLS = 0;

IF DEBT_PERIODS_CN_TOTAL = .         THEN DEBT_PERIODS_CN_TOTAL = 0;
IF DEBT_BALANCE_CN_TOTAL = .         THEN DEBT_BALANCE_CN_TOTAL = 0;
IF RTNS_GST = .                      THEN RTNS_GST = 0;
IF RTNS_INC = .                      THEN RTNS_INC = 0;
IF RTNS_OTH = .                      THEN RTNS_OTH = 0;
IF RTNS_PAY = .                      THEN RTNS_PAY = 0;

IF TOTAL_DEBT_AMOUNT = .             THEN TOTAL_DEBT_AMOUNT             = 0;
IF TOTAL_DEFAULT_ASSESSMENTS = .     THEN TOTAL_DEFAULT_ASSESSMENTS     = 0;
IF TOTAL_DEBT_PERIODS = .            THEN TOTAL_DEBT_PERIODS            = 0;
IF TOTAL_OS_RETURNS = .              THEN TOTAL_OS_RETURNS              = 0;

IF FLAG_DEBT_CN  = ''                THEN FLAG_DEBT_CN  = 'N';
IF FLAG_DEBT_CPR = ''                THEN FLAG_DEBT_CPR = 'N';
IF FLAG_DEBT_CSE = ''                THEN FLAG_DEBT_CSE = 'N';
IF FLAG_DEBT_NCP = ''                THEN FLAG_DEBT_NCP = 'N';
IF FLAG_RTN      = ''                THEN FLAG_RTN      = 'N';

IF FLAG_DEBT_CN  = 'N' THEN CASE_OFFICER_CN  = '';
IF FLAG_DEBT_CPR = 'N' THEN CASE_OFFICER_CPR = '';
IF FLAG_DEBT_CSE = 'N' THEN CASE_OFFICER_CSE = '';
IF FLAG_DEBT_NCP = 'N' THEN CASE_OFFICER_NCP = '';

/*DebtComboCode */
DebtCode  = 1 * (Debt_Periods_INC > 0) + 2 * (Debt_Periods_GST > 0) + 4 * (Debt_Periods_PAY > 0) + 8 * (Debt_Periods_FAM > 0) + 16 * (Debt_Periods_SLS > 0) + 32 * (Debt_Periods_Oth > 0);
CSCode  = 1 * (Debt_Periods_CPR > 0) + 2 * (Debt_Periods_CSE > 0) + 4 * (Debt_Periods_NCP > 0);

DebtCombinationCode = Round(DebtCode+(CSCode/10),.1);
LENGTH TaxCodeGroup $40;
     IF DebtCombinationCode = 0          THEN TaxCodeGroup  = '';
ELSE IF DebtCombinationCode = 1          THEN TaxCodeGroup  = 'INC_ONLY';
ELSE IF DebtCombinationCode = 2          THEN TaxCodeGroup  = 'GST_ONLY';
ELSE IF DebtCombinationCode IN (3,5,6,7) THEN TaxCodeGroup  = 'INC_GST_PAYE';
ELSE IF DebtCombinationCode = 4          THEN TaxCodeGroup  = 'PAYE_ONLY';
ELSE IF DebtCombinationCode = 8          THEN TaxCodeGroup  = 'FAM_ONLY';
ELSE IF DebtCombinationCode = 9          THEN TaxCodeGroup  = 'INC_FAM';
ELSE IF DebtCombinationCode = 16         THEN TaxCodeGroup  = 'SLS_ONLY';
ELSE IF DebtCombinationCode = 17         THEN TaxCodeGroup  = 'INC_SLS';
ELSE IF DebtCombinationCode = 32         THEN TaxCodeGroup  = 'OTH_ONLY';
ELSE IF DebtCombinationCode > 32         THEN TaxCodeGroup  = 'COMBO_TAX_DEBT';

ELSE IF DebtCombinationCode = .1         THEN TaxCodeGroup  = 'CS_CPR_ONLY';
ELSE IF DebtCombinationCode = .2         THEN TaxCodeGroup  = 'CS_CSE_ONLY';
ELSE IF DebtCombinationCode = .4         THEN TaxCodeGroup  = 'CS_NCP_ONLY';
ELSE IF DebtCombinationCode = < 1        THEN TaxCodeGroup  = 'CS_COMBO_ONLY';

/* The CSCode is now part of the overall DebtCombinationCode code and is included after the demical point, eg if a customer had GST and FAM debt
as well as CPR and NCP debt then their DebtCombinationCode would be 10.5 (2+8, and 1+4 concatenated together)*/

ELSE TaxCodeGroup  = 'ALL_OTHER';

/*ReturnsComboCode */

ReturnOSCombinationCode = 1 * (Rtns_INC > 0 ) + 2 * (Rtns_GST > 0) + 4 * (Rtns_PAY > 0 )  + 32 * (Rtns_Oth > 0);
FORMAT ReturnsCodeGroup $40.;
     IF ReturnOSCombinationCode = 0      THEN ReturnsCodeGroup = '';
ELSE IF ReturnOSCombinationCode = 1      THEN ReturnsCodeGroup = 'INC_ONLY';
ELSE IF ReturnOSCombinationCode = 2      THEN ReturnsCodeGroup = 'GST_ONLY'; 
ELSE IF ReturnOSCombinationCode = 3      THEN ReturnsCodeGroup = 'INC_GST'; 
ELSE IF ReturnOSCombinationCode = 4      THEN ReturnsCodeGroup = 'PAY_ONLY'; 
ELSE IF ReturnOSCombinationCode = 5      THEN ReturnsCodeGroup = 'INC_PAY';
ELSE IF ReturnOSCombinationCode = 6      THEN ReturnsCodeGroup = 'GST_PAY';
ELSE IF ReturnOSCombinationCode = 7      THEN ReturnsCodeGroup = 'INC_GST_PAY'; 
ELSE IF ReturnOSCombinationCode = 32     THEN ReturnsCodeGroup = 'OTH_ONLY';
ELSE IF ReturnOSCombinationCode > 32     THEN ReturnsCodeGroup = 'COMBO_OTH';


/*code to show what type of elements are on the cases so we can insert this into START if Collections wants*/
IF Debt_Periods_INC >0 THEN INCCode = Debt_Periods_INC||''||'INC'; ELSE INCCode = '';
IF Debt_Periods_GST >0 THEN GSTCode = Debt_Periods_GST||''||'GST'; ELSE GSTCode = '';
IF Debt_Periods_PAY >0 THEN PAYCode = Debt_Periods_PAY||''||'PAY'; ELSE PAYCode = '';
IF Debt_Periods_FAM >0 THEN FAMCode = Debt_Periods_FAM||''||'FAM'; ELSE FAMCode = '';
IF Debt_Periods_SLS >0 THEN SLSCode = Debt_Periods_SLS||''||'SLS'; ELSE SLSCode = '';
IF Debt_Periods_NCP >0 THEN NCPCode = Debt_Periods_NCP||''||'NCP'; ELSE NCPCode = '';
IF Debt_Periods_CPR >0 THEN CPRCode = Debt_Periods_CPR||''||'CPR'; ELSE CPRCode = '';
IF Debt_Periods_CSE >0 THEN CSECode = Debt_Periods_CSE||''||'CSE'; ELSE CSECode = '';
IF Debt_Periods_Oth >0 THEN OTHCode = Debt_Periods_Oth||''||'OTH'; ELSE OTHCode = '';
DebtCombinationDesc = CATX(' + ',INCCode,GSTCode,PAYCode,FAMCode,SLSCode,NCPCode,CPRCode,CSECode,OTHCode);

IF Rtns_INC >0 THEN INCCodeRtn = Rtns_INC||''||'INC'; ELSE INCCodeRtn = '';
IF Rtns_GST >0 THEN GSTCodeRtn = Rtns_GST||''||'GST'; ELSE GSTCodeRtn = '';
IF Rtns_PAY >0 THEN PAYCodeRtn = Rtns_PAY||''||'PAY'; ELSE PAYCodeRtn = '';
IF Rtns_Oth >0 THEN OTHCodeRtn = Rtns_Oth||''||'OTH'; ELSE OTHCodeRtn = '';
ReturnOSCombinationDesc = CATX(' + ',INCCodeRtn,GSTCodeRtn,PAYCodeRtn,OTHCodeRtn);

drop INCCodeRtn GSTCodeRtn PAYCodeRtn OTHCodeRtn INCCode GSTCode PAYCode FAMCode SLSCode NCPCode CPRCode CSECode OTHCode;




RUN;
PROC DATASETS LIB=CradcWrk nolist; DELETE CRADC_SVOC_TEMP: ; RUN;






/************************************************************************************************************************/
/*Merge in the special customers data, as this is at IRD Number level
/*  Restricted = 1
/*  Standard   = 0
/************************************************************************************************************************/
DATA CRADC.CRADC_SVOC;
MERGE CradcWrk.CRADC_SVOC        (IN=BASE)
      TDW_CURR.SPECIAL_CUSTOMERS (KEEP=IRD_NUMBER IN=SPECIAL);
BY IRD_NUMBER;

EARLIEST_DEBT = DATEPART(MIN(OLDEST_ELEMENT_START_DATE_CN,OLDEST_ELEMENT_START_DATE_CPR,OLDEST_ELEMENT_START_DATE_CSE,OLDEST_ELEMENT_START_DATE_NCP));
LATEST_DEBT   = DATEPART(MAX(LATEST_ELEMENT_START_DATE_CN,LATEST_ELEMENT_START_DATE_CPR,LATEST_ELEMENT_START_DATE_CSE,LATEST_ELEMENT_START_DATE_NCP));

IF SPECIAL THEN RESTRICTED = 1;
ELSE RESTRICTED = 0;
FORMAT EFFECTIVE_DATE DDMMYY10.;
EFFECTIVE_DATE = "&EFF_DATE."d ;

/*if _n_ > 50 then delete;*/

IF BASE THEN OUTPUT;

RUN;

/*PROC DATASETS LIB=CradcWrk NOLIST; DELETE CRADC_SVOC; RUN;*/
/**/
PROC FREQ DATA=CRADC.CRADC_SVOC; 
TABLE TaxCodeGroup ReturnsCodeGroup / MISSING; 
TABLE LAST_CASE_ACTION_TYPE_CODE_CN  * NEXT_CASE_ACTION_TYPE_CODE_CN  / NOCOL NOCUM NOPERCENT NOROW MISSING;
TABLE LAST_CASE_ACTION_TYPE_CODE_CPR * NEXT_CASE_ACTION_TYPE_CODE_CPR / NOCOL NOCUM NOPERCENT NOROW MISSING;
TABLE LAST_CASE_ACTION_TYPE_CODE_CSE * NEXT_CASE_ACTION_TYPE_CODE_CSE / NOCOL NOCUM NOPERCENT NOROW MISSING;
TABLE LAST_CASE_ACTION_TYPE_CODE_NCP * NEXT_CASE_ACTION_TYPE_CODE_NCP / NOCOL NOCUM NOPERCENT NOROW MISSING;
TABLE LOCATION_NUMBER;
RUN;




