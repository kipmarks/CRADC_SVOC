/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 203_excl_final_002_cmp_extra_variables.sas

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
%put INFO-203_excl_final_002_cmp_extra_variables.sas: STUB AT PRESENT;
%GetStarted;
/*********************************************************************************************************************************/
/* Table [ExclTemp.CMP_ARRANGEMENTS_EXCLUSIONS_2] is quite detailed, and needs to be de-duped before using here;
/*********************************************************************************************************************************/
DATA ARRANGEMENT_DETAIL (RENAME=( DATE_END = DATEENDCNG));
 SET ExclTemp.CMP_ARRANGEMENTS_EXCLUSIONS_2 (KEEP=IRD_NUMBER ACTIVE_ARRANGEMENT DATE_END);
WHERE ACTIVE_ARRANGEMENT = 'Y';
RUN; 
PROC SORT DATA=ARRANGEMENT_DETAIL NODUPKEY;BY IRD_NUMBER;RUN;
/*********************************************************************************************************************************/

/*********************************************************************************************************************************/
DATA ExclTemp.CMP_EXTRA_VARIABLES (DROP=MULTI_COLLECTION ACTIVE_ARRANGEMENT RENAME=(IRD_NUMBER=IRDNUMBER));

	MERGE 	ExclTemp.ACTIVE_TRADING                  (IN=A KEEP=IRD_NUMBER) 
			ExclTemp.CAYD_INCOME                     (IN=C DROP=EMPLOYEE_IRD_NUMBER)
		  	EXCLWork.CMP_TAX_POOLING_EDS_UNIQUE      (IN=D)
			ExclTemp.SLS_CAL_ISSUES                  (IN=E KEEP=IRD_NUMBER)
			ExclTemp.START_COLLECTION_SVOC           (IN=F KEEP=IRD_NUMBER COLLECT_KEY COLLECTION_CODE COLLECT_TYPE MULTI_COLLECTION COLLECTION_STAGE  EXCL_COLLECTION 
                                                         RENAME=(COLLECT_KEY = STARTCOLLECTKEY  COLLECT_TYPE =COLLECTTYPE COLLECTION_STAGE =COLLECTIONSTAGE COLLECTION_CODE = COLLECTIONCODE EXCL_COLLECTION =COLLECTIONFLAG ))
			ARRANGEMENT_DETAIL /*See Above*/         (IN=G)
			ExclTemp.CMP_ARRANGEMENTS_EXCLUSIONS     (IN=H KEEP=IRD_NUMBER) 
			B10DEBT.ALERTS_DW_UNIQUE                 (IN=I KEEP=IRD_NUMBER)
			ExclTemp.START_ARRANGEMENTS              (IN=J KEEP=IRD_NUMBER STATUS ARRANGEMENT_ADHERE PAYMENT_PLAN_TYPE NEWA_COLLECTION  
                                                         RENAME=(STATUS = STARTARRSTATUSCODE ARRANGEMENT_ADHERE = STARTARRADHERINGINDICATOR PAYMENT_PLAN_TYPE = STARTARRPAYMENTPLANTYPE NEWA_COLLECTION=NEWACOLLECTION))

;
	BY IRD_NUMBER;
	IF A THEN ACTIVETRADING = 'Y'; ELSE ACTIVETRADING = 'N';
	IF D THEN IRDNUMBERTAXPOOLINGEDS = IRD_NUMBER;
	IF E THEN SLSCALISSUE = 'Y'; ELSE SLSCALISSUE = 'N';
	IF MULTI_COLLECTION >1 THEN MULTIPLECOLLECTIONS = 'Y'; ELSE MULTIPLECOLLECTIONS = 'N';
	IF G THEN IRDNUMBERARRANGEMENTCNE = IRD_NUMBER;
	IF H THEN IRDNUMBERARRANGEMENTS = IRD_NUMBER;
	IF I THEN ALERT = 'Y'; ELSE ALERT = 'N';
	LENGTH FIRSTACTIVEARRANGEMENT $2;
	FIRSTACTIVEARRANGEMENT = 	ACTIVE_ARRANGEMENT;

RUN;
/*********************************************************************************************************************************/
%ErrCheck;