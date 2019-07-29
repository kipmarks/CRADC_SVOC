/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 203_excl_final_004_campaign_lead_variables.sas

Overview:     STUB AT PRESENT
              
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
%put INFO-203_excl_final_004_campaign_lead_variables.sas: STUB AT PRESENT;
%GetStarted;
DATA ExclTemp.CMP_LEAD_VARIABLES (RENAME=(IRD_NUMBER=IRDNUMBER));
 ATTRIB IRD_NUMBER LABEL = 'IRD Number'
		CUSTOMER_KEY LABEL = 'Customer Key'
		FIRSTNAME LABEL = 'First Name(s)'
		LASTNAME LABEL = 'Surname/Company Name'
		ACCOUNTNAME LABEL = 'Formatted Name' 
		CUSTOMERSEGMENT LABEL = 'Customer Segment'
		PHONE LABEL='Phone Details'
		SID LABEL = 'Security Incident Database'
		GEO LABEL = ''
		GEOSUBREGION LABEL = ''
		VALIDADDRESSINDICATOR LABEL = ''
		CUSTOMERSTATUS LABEL = 'Customer Status'
		PROPERTYOWNERSHIP LABEL = ''
		CURRENTNCPCPR LABEL = ''
		CURRENTFAMPAYMENTINDICATOR LABEL = ''
		TAXAGENTINDICATOR LABEL = ''
		STRIKEOFF LABEL = ''
		PREVIOUSBANKRUPTCY LABEL = ''
		CONTACTDETAILSEMAIL LABEL = ''
		CONTACTDETAILSALTERNATIVE LABEL = ''
		CONTACTDETAILSALTDSC LABEL = ''
		LASTCONTACTINBOUND LABEL = ''
		LASTPAYMENTMADE LABEL = ''
		AGEOFLASTACTIONHERITAGE LABEL = ''
		DEDUCTIONINPLACE LABEL = ''
		STARTARRPAYMENTPLANTYPE LABEL = ''
		STARTDEDUCTADHERE LABEL = ''
		GOVERNMENTINCOMESUPPORT LABEL = ''
		INCOMEEMPLOYEE LABEL = ''
		INCOMESELFEMPLOYED LABEL = ''
		INCOMEPASSIVE LABEL = ''
		INCOMERETURNATTACHMENT LABEL = ''
		INCOMETOTAL LABEL = ''
		INCOMEFAMILYTOTAL LABEL = ''
		AGEOFNRBSTART LABEL = ''
		SLS334DEBT LABEL = ''
		NZBN LABEL = ''
		SICCODE LABEL = 'SIC Code'
		SIC_GROUPING_LEVEL_1 LABEL = 'SIC Grouping Level 1'
		SIC_GROUPING_LEVEL_2 LABEL = 'SIC Grouping Level 2'
		SIC_GROUPING_LEVEL_3 LABEL = 'SIC Grouping Level 3'
		SIC_GROUPING_LEVEL_4 LABEL = 'SIC Grouping Level 4'
		MULTIPLE_SIC_CODES LABEL = 'Multiple SIC Codes Exist'
		CARAEXCLUSION LABEL = ''
		CARADIFFERENCE LABEL = ''
		ACTIVETRADING LABEL = ''
		LASTRETURNFILED LABEL = 'Last Return Filed'
		INCLRF LABEL = 'Last Return Filed (INC)'
		PAYLRF LABEL = 'Last Return Filed (PAY)'
		GSTLRF LABEL = 'Last Return Filed (GST)'
		OTHLRF LABEL = 'Last Return Filed (Other)'
		DEBTSCORE LABEL = ''
		PIRATIO LABEL = 'Penalty & Interest Ratio'
		RETURNSCORE LABEL = ''
		SPSCORE LABEL = ''
		CCOMSCORE LABEL = ''
		AUDITSCORE LABEL = ''
		CUSTOMERENGAGEMENT LABEL = ''
		DIGITALENGAGEMENT LABEL = ''
		AVERAGERETURNPAYMENT LABEL = ''
		LEADUSERID LABEL = '';

 MERGE EXCLTEMP.CUSTOMERDETAILS             (IN=A KEEP=IRD_NUMBER CUSTOMER_KEY CUSTOMERSEGMENT ENTITYTYPE ENTITYCLASS AGEENTITY)
       EXCLTEMP.CMP_GOVT_SUPPORT_INCOME     (IN=B KEEP=IRD_NUMBER GOVERNMENTINCOMESUPPORT)
	   EXCLWORK.PHONE_NUMBERS_NAMES         (IN=D)
	   ExclWork.CMP_PROPERTY_OWNERSHIP      (IN=C)
	   ExclWork.ALTERNATIVE                 (IN=E)
	   ExclWork.LEADS                       (IN=F)
	   ExclWork.AGEOFLASTACTIONHERITAGE     (IN=G)
	   ExclWork.CMP_AGE_OF_NRB_START        (IN=H)
	   ExclWork.EXCL_SLS_UNDER_334          (IN=K)
	   ExclWork.WFF                         (IN=L)
	   ExclWork.VALID_ADDRESS               (IN=M)
	   ExclWork.LAST_RETURN_FILED           (IN=N)
	   ExclWork.LASTCONTACTINBOUND          (IN=O)
	   EXCLTEMP.PREVIOUS_BANKRUPT           (IN=P)
	   EXCLTEMP.START_DEDUCTIONS            (IN=Q DROP=LOCATION_NUMBER)
	   ExclWork.CS                          (IN=R)
	   ExclWork.CARA_EXCLUSIONS             (IN=S)
	   EXCLTEMP.BIC_CODES_UNIQUE            (IN=T)
	   ExclWork.GEO                         (IN=U)
	   EXCLTEMP.CUSTOMER_STATUS_IRD_NUMBER  (IN=V KEEP=IRD_NUMBER CUSTOMER_STATUS RENAME=(CUSTOMER_STATUS=CUSTOMERSTATUS))
	   EXCLTEMP.TAX_AGENTS_UNIQUE           (IN=W)
	   ExclWork.START_P_I_RATIO             (IN=X)
;
/*WHERE IRD_NUMBER = 10002291;*/
BY IRD_NUMBER;
IF NOT A THEN MISSING_CUST_DETAILS = '!!!!';
IF IRD_NUMBER;

IF P THEN PREVIOUSBANKRUPTCY = 'Y'; ELSE PREVIOUSBANKRUPTCY = 'N';
IF Q THEN DEDUCTIONINPLACE   = 'Y';
IF S THEN CARAEXCLUSION      = 'Y';
IF W THEN TAXAGENTINDICATOR  = 'Y';
IF CUSTOMERSTATUS = '' THEN CUSTOMERSTATUS = 'A';


/*********************************************/
/*  Update once INCOME code is available
/*********************************************/
IncomeEmployee         = .;
IncomeSelfEmployed     = .;
IncomePassive          = .;
IncomeReturnAttachment = .;
IncomeTotal            = .;
IncomeFamilyTotal      = .;
/*********************************************/


CONTACTDETAILSEMAIL = '';
NZBN = '';
DEBTSCORE = .;
RETURNSCORE = .;
SPSCORE = .;
CCOMSCORE = .;
AUDITSCORE = .;
LASTPAYMENTMADE=.;
CUSTOMERENGAGEMENT = '';
DIGITALENGAGEMENT = '';

AVERAGERETURNPAYMENT =.;

RUN;


%ErrCheck;