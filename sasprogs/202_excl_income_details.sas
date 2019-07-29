/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 202_excl_income_details.sas

Overview:     STUB ONLY at present
              
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
%put INFO-202_excl_income_details.sas: STUB ONLY;

/*********************************************************************************************************************************/
/*  This code sets up a macro that is coded so that it will only process the income details on a Sunday
/*  The final line of the code calls that macro
/*
/*  
/*********************************************************************************************************************************/

%Macro IncomeDetails;

/*********************************************************************************************************************************/
/*  Create a variable (dow) to hold the numeric day-of-the-week;
/*  1 - Sun, 2 - Mon, 3 - Tue, 4 - Wed, 5 - Thu, 6 - Fri, 7 - Sat
/*********************************************************************************************************************************/
%let dow = %sysfunc(weekday(%sysfunc(today())));
/*********************************************************************************************************************************/
/*  A quick check on the datasets.  This will check the datasets and force the code to run if needed.
/*********************************************************************************************************************************/
proc sql;
  CREATE TABLE INC_CHECK AS
        SELECT MEMNAME AS FileName    ,
               CRDATE  AS CreatedDate FORMAT=DATETIME20.,
               NOBS    AS Records
          FROM DICTIONARY.TABLES T
         WHERE UPPER(T.LIBNAME) = UPPER('ExclTemp') AND
		       MEMTYPE = 'DATA' AND
		       MEMNAME IN ('CMP_BENEFICIARIES_CURRENT2','CMP_INCOME_ALL_STREAMS','CMP_INCOME_TOTAL','CMP_GOVT_SUPPORT_INCOME');
QUIT;
/*********************************************************************************************************************************/
/*  If any of the conditions below are met, the variable (dow) is set to 1 to trigger the code to run
/*********************************************************************************************************************************/
DATA INC_CHECK;
IF NOBS < 4 THEN CALL SYMPUT('dow',1);          /*If any of the tables are missing (there should be four)*/
SET INC_CHECK NOBS=nobs;
AGE_OF_DATA=TODAY()-DATEPART(CreatedDate);
IF AGE_OF_DATA > 7 then call symput('dow',1);   /*If any of the tables are more than 7 days old*/
IF RECORDS     = 0 then call symput('dow',1);   /*If any of the tables are empty*/
RUN;
%put &dow.;
proc datasets lib=work nolist; delete inc_check; run;
/*********************************************************************************************************************************/
%if &dow. = 1 %then %do;
%GetStarted;
/*********************************************************************************************************************************/
/*******************************GOVERNMENT INCOME SUPPORT, BENEFICIARIES AND INCOME TABLES****************************************/
/*********************************************************************************************************************************/
/*RUNTIME: 1HR 27MIN*/
/*********************************************************************************************************************************/
/*CG 24MAY19	- The code below creates the following 4 CAMEXCL tables:*/
/*				- CMP_GOVT_SUPPORT_INCOME								*/
/*				- CMP_BENEFICIARIES_CURRENT2							*/
/*				- CMP_INCOME_ALL_STREAMS								*/
/*				- CMP_INCOME_TOTAL										*/
/*********************************************************************************************************************************/
DATA CradcWrk.INCOME_RAW
     CradcWrk.INCOME_RAW_EXLCUDED;
 SET TDW.TBL_NZ_INCOME_VALL (WHERE=(ACTIVE = 1 AND EFFECTIVE_TO IS NULL AND VER = 0 AND DATE_FLD >= '01Apr2018'd AND INCOME_STATUS = 'ACTUAL' AND REVERSED IS NULL));
BY CUSTOMER_KEY;
IF INCOME_TYPE IN ('CPR','EMPMOV','FAMEST','FAMNIL','NCP','OVRPTR','PACPR','PANCP','R&DCRD','SLS215','TXEXMP','TXEXOP') THEN OUTPUT CradcWrk.INCOME_RAW_EXLCUDED;
ELSE OUTPUT CradcWrk.INCOME_RAW;
RUN;
/*********************************************************************************************************************************/
/******************************************Extracting Income Base Data************************************************************/
/*********************************************************************************************************************************/
/*Need data to cover the most recent full filing year (e.g. 01Arp18 - 31Mar19) and everything up to today
/*Not including Reversed and Estimated income as it would incorrectly inflate income figures
/*Excluded the following income because it would not be considered "Income" by IRD typically
/*Child Support Received
/*Employer-Provided MV
/*FAM Income Estimate
/*Confirmed nil income
/*Child Support Paid
/*Non-Resident Partner
/*Private Maintenance - Received
/*Private Maintenance - Paid
/*Research & Development Credits
/*Income Adjustment - SLS
/*Tax-Exempt Income
/*Tax-Exempt Overseas Pensions

/*********************************************************************************************************************************/
/*********************************************CMP_GOVT_SUPPORT_INCOME*************************************************************/
/*********************************************************************************************************************************/
/*Want to know if a customer has received any of these government support income streams (Y/N)				*/
/*Also only if they have received in the last 3 months														*/
/*********************************************************************************************************************************/
DATA ExclWork.CMP_GOVT_SUPPORT_INCOME (KEEP=CUSTOMER_KEY MainBenefit NZSuper StudentAllow ACC PPL ACCAttendantCare GovernmentIncomeSupport);
 SET CRADCWRK.INCOME_RAW (WHERE=(DATEPART(DATE_FLD) >= INTNX('MONTH',TODAY(), -3)));
RETAIN MainBenefit NZSuper StudentAllow ACC PPL ACCAttendantCare;
BY CUSTOMER_KEY;
IF FIRST.CUSTOMER_KEY THEN DO;
	MainBenefit = 'N'; NZSuper = 'N'; StudentAllow = 'N'; ACC = 'N'; PPL = 'N'; ACCAttendantCare = 'N';
	END;
IF AMOUNT > 0 THEN DO;
	IF INCOME_TYPE = 'INCBEN'            THEN MainBenefit      = 'Y';
	IF INCOME_TYPE = 'PENSION'           THEN NZSuper          = 'Y';
	IF INCOME_TYPE = 'SLSALL'            THEN StudentAllow     = 'Y';
	IF INCOME_TYPE IN ('ACC', 'ACC2006') THEN ACC              = 'Y';
	IF INCOME_TYPE = 'PPL'               THEN PPL              = 'Y';
	IF INCOME_TYPE = 'ACCATC'            THEN ACCAttendantCare = 'Y';
	END;
IF LAST.CUSTOMER_KEY THEN DO;
	IF MainBenefit = NZSuper = StudentAllow = ACC = PPL = ACCAttendantCare = 'N' THEN DELETE;
	GovernmentIncomeSupport = 'Y';
	OUTPUT;
	END;
RUN;
/*********************************************************************************************************************************/
/**********************************CMP_BENEFICIARIES_CURRENT2*************************************************/
/*********************************************************************************************************************************/
/*Only want to know if the customer has receivied benefit income in the past 3 months
/*Need to know what other income they've had in the past 3 months and most recent months
/*Max month maybe greater than today's date because payments go towards the end of each month period
/*E.g. Today's date is 23rd May
/*Therefore an income payment on the 7th May will go to the 31st May 19 period in the data (DATE_FLD)
/*********************************************************************************************************************************/
PROC SQL;
  CREATE TABLE ExclWork.CMP_BENEFICIARIES_CURRENT2 AS
        SELECT CUSTOMER_KEY,
               SUM(CASE WHEN INCOME_TYPE =  'INCBEN' THEN AMOUNT ELSE 0 END)      AS GROSSEARNINGSBENE,
               SUM(CASE WHEN INCOME_TYPE <> 'INCBEN' THEN AMOUNT ELSE 0 END)      AS GROSSEARNINGSNONBENE, 
               MAX(CASE WHEN INCOME_TYPE =  'INCBEN' THEN DATEPART(DATE_FLD) END) AS LATESTBENEMONTH FORMAT = DATE9.,
               MAX(CASE WHEN INCOME_TYPE <> 'INCBEN' THEN DATEPART(DATE_FLD) END) AS LATESTNONBENEMONTH FORMAT = DATE9.,
               MAX(DATEPART(DATE_FLD)) AS LATESTMONTH FORMAT = DATE9.
          FROM CRADCWRK.INCOME_RAW
         WHERE DATEPART(DATE_FLD) >= INTNX('month',TODAY(),-3)
      GROUP BY CUSTOMER_KEY
        HAVING SUM(CASE WHEN INCOME_TYPE = 'INCBEN' THEN AMOUNT ELSE 0 END) > 0;
QUIT;


/*************************************************************************************************************/
/**************************************CMP_INCOME_ALL_STREAMS*************************************************/
/*************************************************************************************************************/
/*Annual income for all income streams for the most recent full filing year (e.g. 01Apr18 - 31Mar19)
/*There is a timestamp issue with the DATE_FLD, so 31Mar19 might not always get picked up in <=
/*Therefore to be safe we make the end date > 01Apr19, which will pick up all possible 31Mar19 timestamps
/*However will not pick up any 01Apr19 and next year's data
/*************************************************************************************************************/

PROC SQL;
  CREATE TABLE ExclWork.CMP_INCOME_ALL_STREAMS AS
        SELECT CUSTOMER_KEY AS CUSTOMER_KEY,
               SUM(CASE WHEN INCOME_TYPE = 'ACC'         THEN AMOUNT     ELSE 0 END) AS ACCIDENTCOMPENSATIONGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'ACC'         THEN DEDUCTIONS ELSE 0 END) AS ACCIDENTCOMPENSATIONDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'ACC2006'     THEN AMOUNT     ELSE 0 END) AS ACCIDENTCOMPENSATION2006GROSS,
               SUM(CASE WHEN INCOME_TYPE = 'ACC2006'     THEN DEDUCTIONS ELSE 0 END) AS ACCIDENTCOMPENSATION2006DEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'ACCATC'      THEN AMOUNT     ELSE 0 END) AS ACCATTENDANTCAREGROSS, 
               SUM(CASE WHEN INCOME_TYPE = 'ACCATC'      THEN DEDUCTIONS ELSE 0 END) AS ACCATTENDANTCAREDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'ACCEMP'      THEN AMOUNT     ELSE 0 END) AS ACCPAYMENTSFROMEMPLOYERGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'ACCEMP'      THEN DEDUCTIONS ELSE 0 END) AS ACCPAYMENTSFROMEMPLOYERDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'AIL'         THEN AMOUNT     ELSE 0 END) AS APPROVEDISSUERLEVYGROSS, 
               SUM(CASE WHEN INCOME_TYPE = 'AIL'         THEN DEDUCTIONS ELSE 0 END) AS APPROVEDISSUERLEVYDEDUCT, 
               SUM(CASE WHEN INCOME_TYPE = 'BUSINC'      THEN AMOUNT     ELSE 0 END) AS BUSINESSINCOMEGROSS, 
               SUM(CASE WHEN INCOME_TYPE = 'BUSINC'      THEN DEDUCTIONS ELSE 0 END) AS BUSINESSINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'CAE'         THEN AMOUNT     ELSE 0 END) AS CASUALAGRICULTURALEMPLOYEEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'CAE'         THEN DEDUCTIONS ELSE 0 END) AS CASUALAGRICULTURALEMPLOYEEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'CC'          THEN AMOUNT     ELSE 0 END) AS MAJORSHAREHOLDERINCCGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'CC'          THEN DEDUCTIONS ELSE 0 END) AS MAJORSHAREHOLDERINCCDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'CCC'         THEN AMOUNT     ELSE 0 END) AS CHILDMAJORSHAREHOLDERCCGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'CCC'         THEN DEDUCTIONS ELSE 0 END) AS CHILDMAJORSHAREHOLDERCCDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'CRDINT'      THEN AMOUNT     ELSE 0 END) AS CREDITINTERESTFROMIRGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'CRDINT'      THEN DEDUCTIONS ELSE 0 END) AS CREDITINTERESTFROMIRDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'DEBINT'      THEN AMOUNT     ELSE 0 END) AS DEBITINTERESTFROMIRGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'DEBINT'      THEN DEDUCTIONS ELSE 0 END) AS DEBITINTERESTFROMIRDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'DEPCR'       THEN AMOUNT     ELSE 0 END) AS DEPRECIATIONRECOVEREDGROSS, 
               SUM(CASE WHEN INCOME_TYPE = 'DEPCR'       THEN DEDUCTIONS ELSE 0 END) AS DEPRECIATIONRECOVEREDDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'DIVIDN'      THEN AMOUNT     ELSE 0 END) AS DIVIDENDSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'DIVIDN'      THEN DEDUCTIONS ELSE 0 END) AS DIVIDENDSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'DIVINT'      THEN AMOUNT     ELSE 0 END) AS DIVIDENDSTREATEDASINTERESTGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'DIVINT'      THEN DEDUCTIONS ELSE 0 END) AS DIVIDENDSTREATEDASINTERESTDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'EDW'         THEN AMOUNT     ELSE 0 END) AS ELECTIONDAYWORKERGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'EDW'         THEN DEDUCTIONS ELSE 0 END) AS ELECTIONDAYWORKERDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'EQUALR'      THEN AMOUNT     ELSE 0 END) AS INCOMEEQUALISATIONREFUNDGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'EQUALR'      THEN DEDUCTIONS ELSE 0 END) AS INCOMEEQUALISATIONREFUNDDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'EQUALS'      THEN AMOUNT     ELSE 0 END) AS INCOMEEQUALISATIONDEPOSITGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'EQUALS'      THEN DEDUCTIONS ELSE 0 END) AS INCOMEEQUALISATIONDEPOSITDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'ESS'         THEN AMOUNT     ELSE 0 END) AS EMPLOYEESHARESCHEMEGROSS, 
               SUM(CASE WHEN INCOME_TYPE = 'ESS'         THEN DEDUCTIONS ELSE 0 END) AS EMPLOYEESHARESCHEMEDEDUCT, 
               SUM(CASE WHEN INCOME_TYPE = 'EXCIMP'      THEN AMOUNT     ELSE 0 END) AS EXCESSIMPUTATIONCREDITSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'EXCIMP'      THEN DEDUCTIONS ELSE 0 END) AS EXCESSIMPUTATIONCREDITSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'EXPNSE'      THEN AMOUNT     ELSE 0 END) AS SCHEDULARPAYMENTEXPENSESGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'EXPNSE'      THEN DEDUCTIONS ELSE 0 END) AS SCHEDULARPAYMENTEXPENSESDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'FAM215'      THEN AMOUNT     ELSE 0 END) AS INCOMEADJUSTMENTFAMGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'FAM215'      THEN DEDUCTIONS ELSE 0 END) AS INCOMEADJUSTMENTFAMDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'FOREIGN'     THEN AMOUNT     ELSE 0 END) AS NONRESIDENTFOREIGNSOURCEDGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'FOREIGN'     THEN DEDUCTIONS ELSE 0 END) AS NONRESIDENTFOREIGNSOURCEDDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'FRINGE'      THEN AMOUNT     ELSE 0 END) AS ATTRIBUTABLEFRINGEBENEFITSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'FRINGE'      THEN DEDUCTIONS ELSE 0 END) AS ATTRIBUTABLEFRINGEBENEFITSDEDUCT, 
               SUM(CASE WHEN INCOME_TYPE = 'INCBEN'      THEN AMOUNT     ELSE 0 END) AS INCOMETESTEDBENEFITGROSS, 
               SUM(CASE WHEN INCOME_TYPE = 'INCBEN'      THEN DEDUCTIONS ELSE 0 END) AS INCOMETESTEDBENEFITDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'LOSCAR'      THEN AMOUNT     ELSE 0 END) AS LOSSCARRIEDFORWARDGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'LOSCAR'      THEN DEDUCTIONS ELSE 0 END) AS LOSSCARRIEDFORWARDDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'LTCINC'      THEN AMOUNT     ELSE 0 END) AS LTCINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'LTCINC'      THEN DEDUCTIONS ELSE 0 END) AS LTCINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'MANUAL'      THEN AMOUNT     ELSE 0 END) AS MANUALGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'MANUAL'      THEN DEDUCTIONS ELSE 0 END) AS MANUALDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'MAORI'       THEN AMOUNT     ELSE 0 END) AS MAORIAUTHORITYGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'MAORI'       THEN DEDUCTIONS ELSE 0 END) AS MAORIAUTHORITYDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'NONBUS'      THEN AMOUNT     ELSE 0 END) AS NONBUSINESSEXPENSEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'NONBUS'      THEN DEDUCTIONS ELSE 0 END) AS NONBUSINESSEXPENSEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'NRDIV'       THEN AMOUNT     ELSE 0 END) AS NONRESIDENTDIVIDENDSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'NRDIV'       THEN DEDUCTIONS ELSE 0 END) AS NONRESIDENTDIVIDENDSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'NRINT'       THEN AMOUNT     ELSE 0 END) AS NONRESIDENTINTERESTGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'NRINT'       THEN DEDUCTIONS ELSE 0 END) AS NONRESIDENTINTERESTDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'NZINT'       THEN AMOUNT     ELSE 0 END) AS INTERESTGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'NZINT'       THEN DEDUCTIONS ELSE 0 END) AS INTERESTDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'OTHINC'      THEN AMOUNT     ELSE 0 END) AS OTHERINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'OTHINC'      THEN DEDUCTIONS ELSE 0 END) AS OTHERINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'OTHPYM'      THEN AMOUNT     ELSE 0 END) AS OTHERPAYMENTSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'OTHPYM'      THEN DEDUCTIONS ELSE 0 END) AS OTHERPAYMENTSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'OVRINC'      THEN AMOUNT     ELSE 0 END) AS OVERSEASINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'OVRINC'      THEN DEDUCTIONS ELSE 0 END) AS OVERSEASINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'PASSIVE'     THEN AMOUNT     ELSE 0 END) AS PASSIVECHILDINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'PASSIVE'     THEN DEDUCTIONS ELSE 0 END) AS PASSIVECHILDINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'PENSION'     THEN AMOUNT     ELSE 0 END) AS NZSUPERANNUATIONORPENSIONGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'PENSION'     THEN DEDUCTIONS ELSE 0 END) AS NZSUPERANNUATIONORPENSIONDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'PENSION2'    THEN AMOUNT     ELSE 0 END) AS CERTAINPENSIONSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'PENSION2'    THEN DEDUCTIONS ELSE 0 END) AS CERTAINPENSIONSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'PIE'         THEN AMOUNT     ELSE 0 END) AS CERTIFICATESPIEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'PIE'         THEN DEDUCTIONS ELSE 0 END) AS CERTIFICATESPIEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'PPL'         THEN AMOUNT     ELSE 0 END) AS PAIDPARENTALLEAVEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'PPL'         THEN DEDUCTIONS ELSE 0 END) AS PAIDPARENTALLEAVEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'PRPRTY'      THEN AMOUNT     ELSE 0 END) AS PROPERTYPROFITORLOSSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'PRPRTY'      THEN DEDUCTIONS ELSE 0 END) AS PROPERTYPROFITORLOSSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'PTRINC'      THEN AMOUNT     ELSE 0 END) AS PARTNERSHIPINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'PTRINC'      THEN DEDUCTIONS ELSE 0 END) AS PARTNERSHIPINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RETIREDIS'   THEN AMOUNT     ELSE 0 END) AS RETIREMENTDISTRIBUTIONSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RETIREDIS'   THEN DEDUCTIONS ELSE 0 END) AS RETIREMENTDISTRIBUTIONSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RETIREPIE'   THEN AMOUNT     ELSE 0 END) AS RETIREMENTPIEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RETIREPIE'   THEN DEDUCTIONS ELSE 0 END) AS RETIREMENTPIEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RETSAV'      THEN AMOUNT     ELSE 0 END) AS RETIREMENTSAVINGSORSUPERGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RETSAV'      THEN DEDUCTIONS ELSE 0 END) AS RETIREMENTSAVINGSORSUPERDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RLTCRD'      THEN AMOUNT     ELSE 0 END) AS RLWTCREDITGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RLTCRD'      THEN DEDUCTIONS ELSE 0 END) AS RLWTCREDITDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RLTPNL'      THEN AMOUNT     ELSE 0 END) AS RLWTPENALTYGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RLTPNL'      THEN DEDUCTIONS ELSE 0 END) AS RLWTPENALTYDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RLWT'        THEN AMOUNT     ELSE 0 END) AS RLWTDEDUCTEDGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RLWT'        THEN DEDUCTIONS ELSE 0 END) AS RLWTDEDUCTEDDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RNTINC'      THEN AMOUNT     ELSE 0 END) AS RENTALINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RNTINC'      THEN DEDUCTIONS ELSE 0 END) AS RENTALINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'ROYALT'      THEN AMOUNT     ELSE 0 END) AS ROYALTIESGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'ROYALT'      THEN DEDUCTIONS ELSE 0 END) AS ROYALTIESDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RTNEXP'      THEN AMOUNT     ELSE 0 END) AS INCOMETAXRETURNEXPENSESGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RTNEXP'      THEN DEDUCTIONS ELSE 0 END) AS INCOMETAXRETURNEXPENSESDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'RWT'         THEN AMOUNT     ELSE 0 END) AS CERTIFICATESRWTGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'RWT'         THEN DEDUCTIONS ELSE 0 END) AS CERTIFICATESRWTDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'SALWAGE'     THEN AMOUNT     ELSE 0 END) AS SALARYORWAGESGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'SALWAGE'     THEN DEDUCTIONS ELSE 0 END) AS SALARYORWAGESDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'SHREMP'      THEN AMOUNT     ELSE 0 END) AS SHAREHOLDEREMPLOYEESALARYGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'SHREMP'      THEN DEDUCTIONS ELSE 0 END) AS SHAREHOLDEREMPLOYEESALARYDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'SLFINC'      THEN AMOUNT     ELSE 0 END) AS SELFEMPLOYEDINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'SLFINC'      THEN DEDUCTIONS ELSE 0 END) AS SELFEMPLOYEDINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'SLSALL'      THEN AMOUNT     ELSE 0 END) AS STUDENTALLOWANCEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'SLSALL'      THEN DEDUCTIONS ELSE 0 END) AS STUDENTALLOWANCEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'TRST'        THEN AMOUNT     ELSE 0 END) AS ESTATETRUSTINCOMEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'TRST'        THEN DEDUCTIONS ELSE 0 END) AS ESTATETRUSTINCOMEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'TRSTDIS'     THEN AMOUNT     ELSE 0 END) AS TRUSTDISTRIBUTIONSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'TRSTDIS'     THEN DEDUCTIONS ELSE 0 END) AS TRUSTDISTRIBUTIONSDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'TRSTE'       THEN AMOUNT     ELSE 0 END) AS ATTRIBUTABLETRUSTEEGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'TRSTE'       THEN DEDUCTIONS ELSE 0 END) AS ATTRIBUTABLETRUSTEEDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'VCHR'        THEN AMOUNT     ELSE 0 END) AS SHORTTERMCHARGEFACILLITIESGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'VCHR'        THEN DEDUCTIONS ELSE 0 END) AS SHORTTERMCHARGEFACILLITIESDEDUCT,
               SUM(CASE WHEN INCOME_TYPE = 'WT'          THEN AMOUNT     ELSE 0 END) AS SCHEDULARPAYMENTSGROSS,
               SUM(CASE WHEN INCOME_TYPE = 'WT'          THEN DEDUCTIONS ELSE 0 END) AS SCHEDULARPAYMENTSDEDUCT,
               SUM(AMOUNT) AS INCOMETOTALGROSS,
               SUM(DEDUCTIONS) AS INCOMETOTALDEDUCT
          FROM CRADCWRK.INCOME_RAW
         WHERE DATEPART(DATE_FLD) >= '01Apr2018'd AND DATEPART(DATE_FLD) < '01Apr2019'd
      GROUP BY CUSTOMER_KEY
;
QUIT;
/*********************************************************************************************************************************/
/*****************************************INCOME TOTAL TABLE FOR LEAD VARIABLES***************************************************/
/*********************************************************************************************************************************/
/*These are the Income variables we require for the lead file												
/*These variables are more general than the tbl_nz_income income types so we've had to group them up		
/*Therefore these groupings are subject to change and can be adjusted as needed *might be wrong*			
/*These are classifcations Ryan McGill and Caleb Grove chose based on the following logic we used for R2	
/*********************************************************************************************************************************/
/*IncomeEmployee 			- Income resulting from the customer's employment
/*IncomeReturnAttachment 	- Income coming from return attachment from a larger return e.g. Shareholder holder income
/*IncomePassive				- Passive income streams e.g. Interest, Royalties
/*IncomeSelfEmployed 		- Basically a catch all income group for those streams which haven't been captured above
/*IncomeFamilyTotal			- NA - until we group together customers - would not be included in Incometotal calculation regardless
/*IncomeTotal				- IncomeEmployee + IncomeReturnAttachment + IncomePassive + IncomeSelfEmployed
/*********************************************************************************************************************************/
/*Accident Compensation				- IncomeEmployee
/*Accident Compensation (2006)		- IncomeEmployee
/*ACC Attendant care				- IncomeEmployee
/*ACC payments from employer		- IncomeEmployee
/*Approved issuer levy				- IncomePassive
/*Business Income					- IncomeSelfEmployed
/*Casual Agricultural Employee		- IncomeEmployee - IncomeSelfEmployed
/*Major shareholder in a CC			- IncomeReturnAttachment
/*Child Major shareholder CC		- IncomeReturnAttachment
/*Child Support Received			- NA - Leave out of calculation
/*Credit Interest from IR			- IncomePassive
/*Debit Interest from IR*			- IncomePassive
/*Depreciation Recovered			- IncomeSelfEmployed
/*Dividends							- IncomePassive
/*Dividends treated as interest		- IncomePassive
/*Election Day Worker				- IncomeEmployee
/*Employer-Provided MV				- NA - Leave out of calculation
/*Income Equalisation Refund		- IncomeSelfEmployed
/*Income Equalisation Deposit		- IncomeSelfEmployed
/*Employee Share Scheme				- IncomePassive
/*Excess Imputation Credits			- IncomeSelfEmployed
/*Schedular Payment Expenses		- IncomeReturnAttachment
/*Income Adjustment - FAM			- IncomeSelfEmployed
/*FAM Income Estimate				- NA - Leave out Esimate?
/*Confirmed nil income				- NA - Leave out calculation
/*Non resident foreign sourced		- IncomeSelfEmployed
/*Attributable Fringe Benefits		- IncomeSelfEmployed
/*Income Tested Benefit				- IncomeEmployee
/*Loss carried forward				- IncomeReturnAttachment
/*LTC Income						- IncomeReturnAttachment
/*Manual							- IncomeSelfEmployed
/*Maori Authority					- IncomeSelfEmployed
/*Child Support Paid				- NA - Leave out of calculation?
/*Non-business expense				- IncomeSelfEmployed
/*Non-resident dividends			- IncomePassive
/*Non-resident interest				- IncomePassive
/*Interest							- IncomePassive
/*Other Income						- IncomeSelfEmployed
/*Other Payments					- IncomeSelfEmployed
/*Overseas Income					- IncomeSelfEmployed
/*Non-Resident Partner				- IncomeFamily - Leave out of calculation
/*Private Maintenance - Received	- NA - Child support not included in calculation
/*Private Maintenance - Paid		- NA - Child support not included in calculation
/*Passive child income				- IncomeSelfEmployed
/*NZ Superannuation or Pension		- IncomeEmployee
/*Certain Pensions and Annuities	- IncomeEmployee
/*Certificates (PIE)				- IncomePassive
/*Paid Parental Leave				- IncomeEmployee
/*Property Profit / Loss			- IncomeSelfEmployed
/*Partnership Income				- IncomeSelfEmployed
/*Research & Development Credits	- NA - Leave from calculation
/*Retirement Distributions			- IncomeSelfEmployed
/*Retirement PIE					- IncomePassive
/*Retirement Savings/Super			- IncomeSelfEmployed
/*RLWT Credit						- IncomeSelfEmployed
/*RLWT Penalty						- IncomeSelfEmployed
/*RLWT Deducted						- IncomeSelfEmployed
/*Rental Income						- IncomeSelfEmployed
/*Royalties							- IncomePassive
/*Income Tax Return Expenses		- IncomeSelfEmployed
/*Certificates (RWT)				- IncomePassive
/*Salary / Wages					- IncomeEmployee
/*Shareholder-Employee Salary		- IncomeReturnAttachment
/*Self Employed Income				- IncomeSelfEmployed
/*Income Adjustment - SLS			- NA - Leave from Calculation - Work how this and childsupport works with gross
/*Student Allowance					- IncomeEmployee
/*Estate / Trust Income*			- IncomeReturnAttachment
/*Trust Distributions				- IncomeSelfEmployed
/*Attributable Trustee				- IncomeSelfEmployed
/*Tax-Exempt Income					- NA - Leave from Calculation
/*Tax-Exempt Overseas Pensions		- NA - Leave from Calculationd
/*Short Term Charge Facillities		- IncomeSelfEmployed
/*Schedular Payments				- IncomeSelfEmployed
/*********************************************************************************************************************************/
PROC SQL;
  CREATE TABLE ExclWork.CMP_INCOME_TOTAL AS
    SELECT CUSTOMER_KEY,
           /*IncomeEmployee*/
           SUM(ACCIDENTCOMPENSATIONGROSS,
               ACCIDENTCOMPENSATION2006GROSS,
               ACCATTENDANTCAREGROSS,
               ACCPAYMENTSFROMEMPLOYERGROSS,
               CASUALAGRICULTURALEMPLOYEEGROSS,
               ELECTIONDAYWORKERGROSS,
               INCOMETESTEDBENEFITGROSS,
               NZSUPERANNUATIONORPENSIONGROSS,
               CERTAINPENSIONSGROSS,
               PAIDPARENTALLEAVEGROSS,
               SALARYORWAGESGROSS,
               STUDENTALLOWANCEGROSS) AS INCOMEEMPLOYEE
           
           /*IncomeReturnAttachment*/,
           SUM(MAJORSHAREHOLDERINCCGROSS,
               CHILDMAJORSHAREHOLDERCCGROSS,
               SCHEDULARPAYMENTEXPENSESGROSS,
               LOSSCARRIEDFORWARDGROSS,
               LTCINCOMEGROSS,
               SHAREHOLDEREMPLOYEESALARYGROSS,
               ESTATETRUSTINCOMEGROSS) AS INCOMERETURNATTACHMENT
           
           /*IncomePassive*/,
           SUM(APPROVEDISSUERLEVYGROSS,
               CREDITINTERESTFROMIRGROSS,
               DEBITINTERESTFROMIRGROSS,
               DIVIDENDSGROSS,
               DIVIDENDSTREATEDASINTERESTGROSS,
               EMPLOYEESHARESCHEMEGROSS,
               NONRESIDENTDIVIDENDSGROSS,
               NONRESIDENTINTERESTGROSS,
               INTERESTGROSS,
               CERTIFICATESPIEGROSS,
               RETIREMENTPIEGROSS,
               ROYALTIESGROSS,
               CERTIFICATESRWTGROSS) AS INCOMEPASSIVE
           
           /*IncomeSelfEmployed*/,
           SUM(BUSINESSINCOMEGROSS,
               DEPRECIATIONRECOVEREDGROSS,
               INCOMEEQUALISATIONREFUNDGROSS,
               INCOMEEQUALISATIONDEPOSITGROSS,
               EXCESSIMPUTATIONCREDITSGROSS,
               INCOMEADJUSTMENTFAMGROSS,
               NONRESIDENTFOREIGNSOURCEDGROSS,
               ATTRIBUTABLEFRINGEBENEFITSGROSS,
               MANUALGROSS,
               MAORIAUTHORITYGROSS,
               NONBUSINESSEXPENSEGROSS,
               OTHERINCOMEGROSS,
               OTHERPAYMENTSGROSS,
               OVERSEASINCOMEGROSS,
               PASSIVECHILDINCOMEGROSS,
               PROPERTYPROFITORLOSSGROSS,
               PARTNERSHIPINCOMEGROSS,
               RETIREMENTDISTRIBUTIONSGROSS,
               RETIREMENTSAVINGSORSUPERGROSS,
               RLWTCREDITGROSS,
               RLWTPENALTYGROSS,
               RLWTDEDUCTEDGROSS,
               RENTALINCOMEGROSS,
               INCOMETAXRETURNEXPENSESGROSS,
               SELFEMPLOYEDINCOMEGROSS,
               TRUSTDISTRIBUTIONSGROSS,
               ATTRIBUTABLETRUSTEEGROSS,
               SHORTTERMCHARGEFACILLITIESGROSS,
               SCHEDULARPAYMENTSGROSS) AS INCOMESELFEMPLOYED
           /*IncomeFamilyTotal*/,
           0 AS INCOMEFAMILYTOTAL
           /*IncomeTotal*/,
           INCOMETOTALGROSS AS INCOMETOTAL
      FROM ExclWork.CMP_INCOME_ALL_STREAMS;
QUIT;


PROC SORT DATA=TDW_CURR.TBL_CUSTOMERINFO (KEEP=CUSTOMER_KEY IRD_NUMBER) OUT=KEYS_CUS_BY_IRD; BY CUSTOMER_KEY; RUN;

PROC SORT DATA=ExclWork.CMP_BENEFICIARIES_CURRENT2; BY CUSTOMER_KEY; RUN;
PROC SORT DATA=ExclWork.CMP_INCOME_ALL_STREAMS;     BY CUSTOMER_KEY; RUN;
PROC SORT DATA=ExclWork.CMP_INCOME_TOTAL;           BY CUSTOMER_KEY; RUN;
PROC SORT DATA=ExclWork.CMP_GOVT_SUPPORT_INCOME;    BY CUSTOMER_KEY; RUN;

DATA ExclTemp.CMP_BENEFICIARIES_CURRENT2 (ALTER=&AP.); MERGE ExclWork.CMP_BENEFICIARIES_CURRENT2 (IN=A) KEYS_CUS_BY_IRD (IN=B);BY CUSTOMER_KEY;IF A;RUN;
DATA ExclTemp.CMP_INCOME_ALL_STREAMS     (ALTER=&AP.); MERGE ExclWork.CMP_INCOME_ALL_STREAMS     (IN=A) KEYS_CUS_BY_IRD (IN=B);BY CUSTOMER_KEY;IF A;RUN;
DATA ExclTemp.CMP_INCOME_TOTAL           (ALTER=&AP.); MERGE ExclWork.CMP_INCOME_TOTAL           (IN=A) KEYS_CUS_BY_IRD (IN=B);BY CUSTOMER_KEY;IF A;RUN;
DATA ExclTemp.CMP_GOVT_SUPPORT_INCOME    (ALTER=&AP.); MERGE ExclWork.CMP_GOVT_SUPPORT_INCOME    (IN=A) KEYS_CUS_BY_IRD (IN=B);BY CUSTOMER_KEY;IF A;RUN;

PROC SORT DATA=ExclTemp.CMP_BENEFICIARIES_CURRENT2 (ALTER=&AP.); BY IRD_NUMBER; RUN;
PROC SORT DATA=ExclTemp.CMP_INCOME_ALL_STREAMS     (ALTER=&AP.); BY IRD_NUMBER; RUN;
PROC SORT DATA=ExclTemp.CMP_INCOME_TOTAL           (ALTER=&AP.); BY IRD_NUMBER; RUN;
PROC SORT DATA=ExclTemp.CMP_GOVT_SUPPORT_INCOME    (ALTER=&AP.); BY IRD_NUMBER; RUN;

PROC DATASETS LIB=ExclWork NOLIST; DELETE CMP_BENEFICIARIES_CURRENT2 CMP_INCOME_ALL_STREAMS CMP_INCOME_TOTAL CMP_GOVT_SUPPORT_INCOME; RUN;




%ErrCheck;
%end;
%else %do;
%put Income Details Only Processed On Sunday;
%end;
%Mend IncomeDetails;
/*********************************************************************************************************************************/
/*Call the macro
/*********************************************************************************************************************************/
%IncomeDetails;
/*********************************************************************************************************************************/


